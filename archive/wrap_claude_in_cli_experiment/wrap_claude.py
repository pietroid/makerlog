#!/usr/bin/env python3
"""
Wraps the `claude` CLI in a PTY, feeding output through pyte to maintain
a virtual screen. The real terminal still shows everything live; pyte
gives you the reconstructed screen state you can inspect or process.
"""

import fcntl
import os
import select
import struct
import subprocess
import sys
import termios
import tty

import pyte


def get_terminal_size():
    size = os.get_terminal_size()
    return size.columns, size.lines


def set_pty_size(fd, cols, rows):
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))


def run(command: list[str]):
    cols, rows = get_terminal_size()

    screen = pyte.Screen(cols, rows)
    stream = pyte.ByteStream(screen)

    master_fd, slave_fd = os.openpty()
    set_pty_size(slave_fd, cols, rows)

    proc = subprocess.Popen(
        command,
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        close_fds=True,
        preexec_fn=os.setsid,
    )
    os.close(slave_fd)

    old_settings = termios.tcgetattr(sys.stdin)
    tty.setraw(sys.stdin.fileno())

    try:
        while proc.poll() is None:
            r, _, _ = select.select([master_fd, sys.stdin], [], [], 0.05)

            if master_fd in r:
                try:
                    data = os.read(master_fd, 4096)
                except OSError:
                    break
                if not data:
                    break

                # Update virtual screen state
                stream.feed(data)

                # Pass through to the real terminal unchanged
                os.write(sys.stdout.fileno(), data)

                # --- Hook: inspect dirty rows after each chunk ---
                # dirty_rows = sorted(screen.dirty)
                # for row in dirty_rows:
                #     line = screen.display[row].rstrip()
                #     if line:
                #         pass  # do something with `line`
                # screen.reset_dirty()

            if sys.stdin in r:
                try:
                    data = os.read(sys.stdin.fileno(), 1024)
                except OSError:
                    break
                if data:
                    os.write(master_fd, data)

    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
        try:
            os.close(master_fd)
        except OSError:
            pass

    proc.wait()

    # Final screen snapshot — non-empty lines only
    print("\r\n--- pyte screen snapshot ---\r")
    for line in screen.display:
        if line.strip():
            print(f"\r{line.rstrip()}\r")


if __name__ == "__main__":
    run(["claude"] + sys.argv[1:])
