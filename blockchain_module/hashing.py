import hashlib
import json


def compute_report_hash(description, category, target_url, target_account, message_text) -> str:
    """Identical to backend/main.py. Do not change without telling Volga."""
    return hashlib.sha256(
        json.dumps(
            {
                "description": description,
                "category": category,
                "target_url": target_url,
                "target_account": target_account,
                "message_text": message_text,
            },
            sort_keys=True,
        ).encode("utf-8")
    ).hexdigest()


def hash_to_bytes32(hex_hash: str) -> bytes:
    h = hex_hash.strip().lower().removeprefix("0x")
    if len(h) != 64:
        raise ValueError(f"Expected 64 hex chars, got {len(h)}")
    return bytes.fromhex(h)