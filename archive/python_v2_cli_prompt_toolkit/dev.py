#!/usr/bin/env python3
"""
dev.py — Hot-reload wrapper for main.py.

How it works
─────────────
1. Launch main.py as a child process that shares our terminal (no pipes,
   no redirection — prompt_toolkit needs a real TTY).
2. Snapshot every file under src/ (path → mtime) every 200 ms using
   Path.rglob() + os.stat() — no third-party file-watcher needed.
3. On any change (modify, create, delete): send SIGINT to the child.
   prompt_toolkit registers a SIGINT handler that feeds Ctrl-C into its
   key-binding queue, so our `c-c` handler fires → app.exit() → terminal
   is fully restored before the process ends.
4. Wait for the child to finish (proc.wait()), then spawn a fresh copy.

Why SIGINT and not SIGTERM?
────────────────────────────
SIGTERM's default Python behaviour is immediate process death — no cleanup
code runs, so the terminal stays in raw/no-echo mode.  SIGINT goes through
prompt_toolkit's event loop and triggers the same graceful teardown as
pressing Ctrl-C inside the app.

Why poll instead of inotify / FSEvents?
─────────────────────────────────────────
Polling is three lines of stdlib and works identically on macOS, Linux, and
Windows.  At 200 ms the latency is imperceptible for a save-and-reload flow,
and the CPU cost (one syscall per interval) is negligible.

Usage:
    python3 dev.py
"""

import signal
import subprocess
import sys
import time
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────────
TARGET    = Path(__file__).parent / "main.py"   # entry point to run
WATCH_DIR = Path(__file__).parent / "src"       # directory to watch recursively
INTERVAL  = 0.2                                 # poll interval in seconds


# ── Helpers ───────────────────────────────────────────────────────────────────
def snapshot() -> dict[Path, float]:
    """Return {path: mtime} for every file under WATCH_DIR.

    Comparing two snapshots detects modifications (mtime changed),
    additions (new key), and deletions (missing key) in one dict equality check.
    """
    result = {}
    for p in WATCH_DIR.rglob("*"):
        if p.is_file():
            try:
                result[p] = p.stat().st_mtime
            except FileNotFoundError:
                pass   # deleted between rglob and stat — harmless
    return result


def launch() -> subprocess.Popen:
    """Spawn chat.py as a child process sharing our stdin/stdout/stderr.

    No pipes: the child needs direct access to the TTY so that prompt_toolkit
    can put the terminal into raw mode and draw full-screen output.
    """
    return subprocess.Popen([sys.executable, str(TARGET)])


def reset_terminal() -> None:
    """Restore the terminal to a sane state after a child crash.

    If prompt_toolkit did not run its cleanup (e.g., the crash happened before
    or during initialisation), the terminal may be left in raw / no-echo mode.
    'stty sane' recovers it so subsequent output is readable.
    """
    try:
        subprocess.run(["stty", "sane"], check=False)
    except FileNotFoundError:
        pass  # non-POSIX platform


def graceful_stop(proc: subprocess.Popen) -> None:
    """Ask the child to exit cleanly, then wait for it.

    SIGINT lets prompt_toolkit run its teardown (terminal restore).
    If the process ignores it, we escalate to SIGKILL after 2 seconds.
    """
    if proc.poll() is not None:
        return   # already exited
    proc.send_signal(signal.SIGINT)
    try:
        proc.wait(timeout=2)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


# ── Main loop ─────────────────────────────────────────────────────────────────
def main() -> None:
    last = snapshot()
    proc: subprocess.Popen | None = launch()

    try:
        while True:
            time.sleep(INTERVAL)

            # ── Detect file changes ───────────────────────────────────────────
            current = snapshot()
            if current != last:
                last = current
                if proc is not None:
                    graceful_stop(proc)
                # The terminal needs a brief moment after the child's cleanup
                # code runs before the next process can safely take it over.
                time.sleep(0.05)
                proc = launch()
                continue

            # ── Detect child exit ─────────────────────────────────────────────
            if proc is not None and proc.poll() is not None:
                rc = proc.returncode
                proc = None

                if rc == 0:
                    # Clean quit (Ctrl-C / Ctrl-Q inside the app) — stop watching.
                    break

                # Error exit: the terminal may be in raw mode if prompt_toolkit
                # didn't finish its cleanup.  Reset it so the leaked traceback
                # output stops corrupting the display, then wait for the
                # developer to fix the error and save a file to trigger restart.
                reset_terminal()
                print(
                    f"\n[dev] process exited with code {rc} — "
                    "save a file to restart …",
                    flush=True,
                )

    except KeyboardInterrupt:
        # Ctrl-C pressed in the outer shell: SIGINT is delivered to the entire
        # foreground process group, so the child is already stopping.
        # graceful_stop() handles the "already exited" case safely.
        if proc is not None:
            graceful_stop(proc)


if __name__ == "__main__":
    main()
