"""ollama_service — call a local Ollama model for empathetic check-ins.

After a maker writes a journal entry, makerbook asks a locally-running
Ollama instance to read the journal and generate a short reflective
question with actionable choices.

If Ollama is unavailable or returns invalid JSON the function returns
None silently — check-ins are a nice-to-have, never a hard dependency.
"""

import json
import urllib.request
import urllib.error

from src.conversation.models.checkin import CheckinResult

OLLAMA_URL   = "http://localhost:11434/api/chat"
OLLAMA_MODEL = "gemma2:2b"

_CHECKIN_SYSTEM = (
    "You are a supportive companion embedded in a maker's worklog. "
    "Read the journal and generate one brief empathetic check-in. "
    'Return ONLY valid JSON: {"question": "...", "choices": ["...", "...", "...", "..."]}. '
    "The question should be short and personal (max 12 words). "
    "Choices should be human and actionable — mix emotional states with concrete next steps. "
    "Always include at least one of: take a break, ask Claude, reach out to someone."
)


def call_ollama_checkin(journal_text: str) -> CheckinResult | None:
    """Send the last 2 000 characters of *journal_text* to Ollama.

    Returns a :class:`CheckinResult` on success, ``None`` if Ollama is
    unavailable or the response cannot be parsed.
    """
    context = journal_text[-2000:].strip()
    payload = json.dumps({
        "model":    OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": _CHECKIN_SYSTEM},
            {"role": "user",   "content": f"My worklog:\n\n{context}"},
        ],
        "format": "json",
        "stream": False,
    }).encode()

    try:
        req = urllib.request.Request(
            OLLAMA_URL,
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            body     = json.loads(resp.read())
            content  = body.get("message", {}).get("content", "")
            data     = json.loads(content)
            question = data.get("question", "")
            choices  = [c for c in data.get("choices", []) if isinstance(c, str) and c.strip()]
            if isinstance(question, str) and question and choices:
                return CheckinResult(question=question.strip(), choices=choices)
    except Exception:
        pass

    return None
