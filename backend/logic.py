CONFIDENCE_THRESHOLD = 0.60


def decide_status(confidence: float) -> str:
    """Return 'verified' if confidence is above 60%, else 'suspicious'."""
    if confidence > CONFIDENCE_THRESHOLD:
        return "verified"
    return "suspicious"