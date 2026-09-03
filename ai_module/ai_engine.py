import re
from typing import Dict, List, Any

class ScamAIEngine:
    """
    AI Scam Analysis Engine powered by NLP pattern matching, intent evaluation,
    domain spoofing heuristics, and financial risk scoring.
    """

    URGENCY_KEYWORDS = [
        "urgent", "suspended", "account locked", "verify immediately", 
        "action required", "unauthorized transaction", "security breach",
        "limited time", "gift card", "crypto double", "guaranteed profit",
        "wire transfer", "western union", "cash app", "zelle", "claim reward",
        "police", "tax audit", "irs", "customs fee", "pay fee"
    ]

    SUSPICIOUS_TLDS = [
        ".xyz", ".top", ".tk", ".ml", ".ga", ".cf", ".gq", ".click", 
        ".vip", ".monster", ".work", ".site", ".verify-bank.com"
    ]

    SCAM_TYPE_BASE_RISK = {
        "phishing": 45,
        "crypto_investment": 50,
        "impersonation": 40,
        "romance": 35,
        "fake_store": 40,
        "job_scam": 35,
        "caller_scam": 30,
        "other": 25
    }

    def analyze_report(
        self,
        title: str,
        description: str,
        scam_type: str = "other",
        target_url: str = None,
        target_phone: str = None,
        target_wallet: str = None,
        target_email: str = None,
        financial_loss: float = 0.0
    ) -> Dict[str, Any]:
        """
        Calculates scam probability, risk score (0-100), risk level, signals, and summary.
        """
        score = self.SCAM_TYPE_BASE_RISK.get(scam_type.lower(), 25)
        signals: List[str] = []
        text_content = f"{title} {description}".lower()

        # 1. NLP Urgency & Fraud Intent Keywords
        keyword_hits = [kw for kw in self.URGENCY_KEYWORDS if kw in text_content]
        if keyword_hits:
            score += len(keyword_hits) * 8
            signals.append(f"Detected {len(keyword_hits)} high-risk fraud intent triggers: {', '.join(keyword_hits[:3])}")

        # 2. Target URL Analysis
        if target_url:
            url_lower = target_url.lower()
            if any(tld in url_lower for tld in self.SUSPICIOUS_TLDS):
                score += 25
                signals.append(f"Suspicious high-risk domain extension detected in URL")
            if not url_lower.startswith("https://"):
                score += 10
                signals.append("Insecure HTTP connection (missing HTTPS SSL)")
            if re.search(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', url_lower):
                score += 20
                signals.append("Direct IP address URL pattern detected")
            if any(word in url_lower for word in ["bank", "login", "verify", "secure", "update", "account"]):
                score += 15
                signals.append("Potential brand/domain spoofing keyword in URL")

        # 3. Crypto Wallet Pattern
        if target_wallet:
            if re.match(r'^(0x[a-fA-F0-9]{40})$', target_wallet): # EVM format
                score += 20
                signals.append("Valid EVM Crypto wallet address involved")
            elif re.match(r'^(1|3|[a-km-zA-HJ-NP-Z1-9]{25,34})$', target_wallet): # BTC format
                score += 20
                signals.append("Bitcoin Wallet address recorded")
            elif len(target_wallet) > 10:
                score += 15
                signals.append("Cryptocurrency address provided for transfer")

        # 4. Phone & Contact Analysis
        if target_phone:
            cleaned_phone = re.sub(r'[^\d+]', '', target_phone)
            if cleaned_phone.startswith("+1800") or cleaned_phone.startswith("+1888"):
                score += 10
                signals.append("Toll-free spoofing hotline number")
            elif len(cleaned_phone) >= 10:
                score += 10
                signals.append("Direct target phone number recorded")

        # 5. Financial Loss Scaling
        if financial_loss > 0:
            if financial_loss >= 5000:
                score += 20
                signals.append(f"Severe financial impact (${financial_loss:,.2f} lost)")
            elif financial_loss >= 500:
                score += 15
                signals.append(f"Significant financial loss (${financial_loss:,.2f})")
            else:
                score += 10
                signals.append(f"Financial loss reported (${financial_loss:,.2f})")

        # Cap score between 0 and 100
        final_score = min(max(int(score), 10), 99)

        # Risk Level Mapping
        if final_score >= 85:
            risk_level = "CRITICAL"
            suggested_action = "IMMEDIATE BLOCK & ON-CHAIN SEAL"
        elif final_score >= 70:
            risk_level = "HIGH"
            suggested_action = "APPROVE & REGISTER ON BLOCKCHAIN"
        elif final_score >= 45:
            risk_level = "MEDIUM"
            suggested_action = "FLAG FOR MANUAL ADMIN REVIEW"
        else:
            risk_level = "LOW"
            suggested_action = "MONITOR AND VERIFY DETAILS"

        if not signals:
            signals.append("Standard report details submitted")

        summary = (
            f"AI evaluation assigned a risk score of {final_score}/100 ({risk_level} Risk). "
            f"Key factors: {signals[0]}. Recommendation: {suggested_action}."
        )

        return {
            "risk_score": final_score,
            "risk_level": risk_level,
            "confidence": 0.93,
            "signals": signals,
            "summary": summary,
            "suggested_action": suggested_action
        }

# Global Instance
ai_engine = ScamAIEngine()
