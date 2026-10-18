import unittest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger
from main import app

client = TestClient(app)


class TestScamShieldBackend(unittest.TestCase):

    def test_ai_scam_evaluator(self):
        result = ai_engine.analyze_report(
            title="Urgent Bank Account Verification Alert",
            description="SMS sent asking to login and verify bank details immediately at fake URL.",
            scam_type="phishing",
            target_url="http://secure-login-bank.xyz/login",
            target_phone="+18005550199",
            financial_loss=1200.0
        )
        self.assertGreaterEqual(result["risk_score"], 80)
        self.assertEqual(result["risk_level"], "CRITICAL")
        self.assertTrue(any("domain" in s.lower() or "tld" in s.lower() for s in result["signals"]))

    def test_blockchain_ledger_recording_and_verification(self):
        block_entry = blockchain_ledger.record_scam_on_chain(
            report_id="test-uuid-99",
            title="Crypto Doubler Scheme",
            scam_type="crypto_investment",
            risk_score=92,
            target_info="0x32Be343B94f860124dC4fEe278FDCBD38C102D88"
        )
        self.assertTrue(block_entry["tx_hash"].startswith("0x"))
        self.assertEqual(block_entry["status"], "VERIFIED_ON_CHAIN")

        verification = blockchain_ledger.verify_hash(block_entry["tx_hash"])
        self.assertTrue(verification["is_valid"])


class TestScamShieldAPI(unittest.TestCase):

    def test_health_check(self):
        res = client.get("/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "online")

    def test_invalid_category_rejected(self):
        res = client.post("/api/reports/submit", json={
            "title": "Test",
            "description": "Test",
            "scam_type": "crypto"
        })
        self.assertEqual(res.status_code, 422)

    def test_search_requires_param(self):
        res = client.get("/api/reports/search")
        self.assertEqual(res.status_code, 400)

    def test_stats_shape(self):
        res = client.get("/api/stats")
        self.assertEqual(res.status_code, 200)
        self.assertIn("total", res.json())
        self.assertIn("by_category", res.json())

    def test_upload_rejects_non_image(self):
        res = client.post(
            "/api/upload-screenshot",
            files={"file": ("test.txt", b"hello", "text/plain")},
        )
        self.assertEqual(res.status_code, 400)

    def test_search_returns_expected_shape(self):
        res = client.get("/api/reports/search", params={"url": "secure-login"})
        self.assertEqual(res.status_code, 200)
        body = res.json()
        self.assertIn("found", body)
        self.assertIn("results", body)


if __name__ == "__main__":
    unittest.main()