CONFIDENCE_THRESHOLD = 0.60
RISK_THRESHOLD = 50


def decide_status(confidence: float, risk_score: int) -> str:
    """Verified only if confidence > 60% AND risk score >= 50, else suspicious."""
    if confidence > CONFIDENCE_THRESHOLD and risk_score >= RISK_THRESHOLD:
        return "verified"
    return "suspicious"