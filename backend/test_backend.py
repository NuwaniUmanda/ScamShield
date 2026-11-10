
import unittest
import sys
import os

from types import SimpleNamespace
from unittest.mock import patch

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
)

from fastapi.testclient import TestClient

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger
from main import app, compute_report_hash
from logic import decide_status

client = TestClient(app)


# ---------------------------------------------------------------------------
# Decision Logic Tests
# ---------------------------------------------------------------------------

class TestDecisionLogic(unittest.TestCase):

    def test_low_risk_should_be_suspicious(self):

        result = decide_status(0.93, 25)

        self.assertEqual(result, "suspicious")

    def test_high_risk_should_be_verified(self):

        result = decide_status(0.93, 99)

        self.assertEqual(result, "verified")

    def test_confidence_at_60_percent_should_be_suspicious(self):

        result = decide_status(0.60, 99)

        self.assertEqual(result, "suspicious")


# ---------------------------------------------------------------------------
# Backend AI and Blockchain Tests
# ---------------------------------------------------------------------------

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

        self.assertGreaterEqual(
            result["risk_score"],
            80
        )

        self.assertEqual(
            result["risk_level"],
            "CRITICAL"
        )

        self.assertTrue(
            any(
                "domain" in s.lower() or "tld" in s.lower()
                for s in result["signals"]
            )
        )

    def test_blockchain_ledger_recording_and_verification(self):

        block_entry = blockchain_ledger.record_scam_on_chain(
            report_id="test-uuid-99",
            title="Crypto Doubler Scheme",
            scam_type="crypto_investment",
            risk_score=92,
            target_info="0x32Be343B94f860124dC4fEe278FDCBD38C102D88"
        )

        self.assertTrue(
            block_entry["tx_hash"].startswith("0x")
        )

        self.assertEqual(
            block_entry["status"],
            "VERIFIED_ON_CHAIN"
        )

        verification = blockchain_ledger.verify_hash(
            block_entry["tx_hash"]
        )

        self.assertTrue(verification["is_valid"])


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------

class TestScamShieldAPI(unittest.TestCase):

    def test_health_check(self):

        res = client.get("/")

        self.assertEqual(res.status_code, 200)

        self.assertEqual(
            res.json()["status"],
            "online"
        )

    def test_invalid_category_rejected(self):

        res = client.post(
            "/api/reports/submit",
            json={
                "title": "Test",
                "description": "Test",
                "scam_type": "crypto"
            }
        )

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
            files={
                "file": ("test.txt", b"hello", "text/plain")
            },
        )

        self.assertEqual(res.status_code, 400)

    def test_upload_rejects_file_larger_than_5mb(self):

        large_file = b"x" * (5 * 1024 * 1024 + 1)

        res = client.post(
            "/api/upload-screenshot",
            files={
                "file": ("large.png", large_file, "image/png")
            },
        )

        self.assertEqual(res.status_code, 400)

        self.assertEqual(
            res.json()["detail"],
            "File too large (max 5 MB)"
        )

    def test_search_returns_expected_shape(self):

        res = client.get(
            "/api/reports/search",
            params={"url": "secure-login"}
        )

        self.assertEqual(res.status_code, 200)

        body = res.json()

        self.assertIn("found", body)

        self.assertIn("results", body)

    # -----------------------------------------------------------------------
    # Duplicate Report Detection Test
    # -----------------------------------------------------------------------

    def test_duplicate_report_returns_409(self):

        report_data = {
            "title": "Repeated scam report",
            "description": "Please verify your bank account immediately",
            "scam_type": "phishing",
            "target_url": "https://example-suspicious.test/login",
            "target_account": "fake-bank-page",
            "message_text": "Please verify your bank account immediately"
        }

        existing_report = SimpleNamespace(
            data=[
                {
                    "id": "existing-report-123",
                    "status": "suspicious",
                    "created_at": "2026-11-05T12:00:00+00:00",
                    "category": "phishing",
                    "description": "Please verify your bank account immediately",
                    "target_url": "https://example-suspicious.test/login",
                    "target_account": "fake-bank-page",
                    "message_text": "Please verify your bank account immediately",
                    "is_duplicate": False
                }
            ]
        )

        with patch(
            "main.ai_engine.analyze_report",
            return_value={
                "confidence": 0.93,
                "risk_score": 25
            }
        ) as mock_ai:

            with patch(
                "main.with_retry",
                side_effect=lambda operation: operation()
            ):

                with patch(
                    "main.supabase_admin.table"
                ) as mock_table:

                    with patch(
                        "main.blockchain_ledger.record_scam_on_chain"
                    ) as mock_blockchain:

                        (
                            mock_table.return_value
                            .select.return_value
                            .eq.return_value
                            .execute.return_value
                        ) = existing_report

                        res = client.post(
                            "/api/reports/submit",
                            json=report_data
                        )

                        self.assertEqual(
                            res.status_code,
                            409
                        )

                        body = res.json()

                        self.assertEqual(
                            body["detail"]["message"],
                            "An identical report already exists"
                        )

                        self.assertEqual(
                            body["detail"]["existing_report_id"],
                            "existing-report-123"
                        )

                        mock_ai.assert_called_once()

                        mock_blockchain.assert_not_called()

                        mock_table.return_value.insert.assert_not_called()

    # -----------------------------------------------------------------------
    # Pending Blockchain Workflow Success Test
    # -----------------------------------------------------------------------

    def test_verified_report_pending_then_updated_after_blockchain(self):

        report_data = {
            "title": "Urgent Bank Verification",
            "description": "Verify your bank account immediately",
            "scam_type": "phishing",
            "target_url": "https://test-suspicious.example/login",
            "message_text": "Verify your account now"
        }

        no_duplicates = SimpleNamespace(data=[])

        transaction_hash = "0x123456789"

        with patch(
            "main.ai_engine.analyze_report",
            return_value={
                "confidence": 0.93,
                "risk_score": 99
            }
        ):

            with patch(
                "main.with_retry",
                side_effect=lambda operation: operation()
            ):

                with patch(
                    "main.supabase_admin.table"
                ) as mock_table:

                    with patch(
                        "main.blockchain_ledger.record_scam_on_chain",
                        return_value={
                            "tx_hash": transaction_hash
                        }
                    ) as mock_blockchain:

                        table = mock_table.return_value

                        # No existing duplicate report
                        (
                            table.select.return_value
                            .eq.return_value
                            .execute.return_value
                        ) = no_duplicates

                        response = client.post(
                            "/api/reports/submit",
                            json=report_data
                        )

                        self.assertEqual(
                            response.status_code,
                            200
                        )

                        body = response.json()

                        # Final response should be verified
                        self.assertEqual(
                            body["status"],
                            "verified"
                        )

                        self.assertEqual(
                            body["saved"][0]["status"],
                            "verified"
                        )

                        self.assertEqual(
                            body["saved"][0]["blockchain_tx_hash"],
                            transaction_hash
                        )

                        # Initial database insertion must be pending
                        insert_data = table.insert.call_args.args[0]

                        self.assertEqual(
                            insert_data["status"],
                            "pending_blockchain"
                        )

                        self.assertIsNone(
                            insert_data["blockchain_tx_hash"]
                        )

                        self.assertFalse(
                            insert_data["is_duplicate"]
                        )

                        # Database update after blockchain success
                        update_data = table.update.call_args.args[0]

                        self.assertEqual(
                            update_data["status"],
                            "verified"
                        )

                        self.assertEqual(
                            update_data["blockchain_tx_hash"],
                            transaction_hash
                        )

                        mock_blockchain.assert_called_once()

                        table.update.assert_called_once()

    # -----------------------------------------------------------------------
    # Pending Blockchain Workflow Failure Test
    # -----------------------------------------------------------------------

    def test_blockchain_failure_keeps_report_pending(self):

        report_data = {
            "title": "Blockchain Failure Test",
            "description": "Suspicious bank account verification request",
            "scam_type": "phishing",
            "target_url": "https://failure-test.example/login",
            "message_text": "Verify your account"
        }

        no_duplicates = SimpleNamespace(data=[])

        with patch(
            "main.ai_engine.analyze_report",
            return_value={
                "confidence": 0.93,
                "risk_score": 99
            }
        ):

            with patch(
                "main.with_retry",
                side_effect=lambda operation: operation()
            ):

                with patch(
                    "main.supabase_admin.table"
                ) as mock_table:

                    with patch(
                        "main.blockchain_ledger.record_scam_on_chain",
                        side_effect=Exception("Blockchain unavailable")
                    ) as mock_blockchain:

                        table = mock_table.return_value

                        # No existing duplicate report
                        (
                            table.select.return_value
                            .eq.return_value
                            .execute.return_value
                        ) = no_duplicates

                        response = client.post(
                            "/api/reports/submit",
                            json=report_data
                        )

                        self.assertEqual(
                            response.status_code,
                            502
                        )

                        body = response.json()

                        self.assertIn(
                            "Report saved, but blockchain recording failed",
                            body["detail"]["message"]
                        )

                        self.assertIn(
                            "report_id",
                            body["detail"]
                        )

                        # Initial database insertion must be pending
                        insert_data = table.insert.call_args.args[0]

                        self.assertEqual(
                            insert_data["status"],
                            "pending_blockchain"
                        )

                        self.assertIsNone(
                            insert_data["blockchain_tx_hash"]
                        )

                        # Failed blockchain must not update database
                        table.update.assert_not_called()

                        mock_blockchain.assert_called_once()


# ---------------------------------------------------------------------------
# Report Hash Tests
# ---------------------------------------------------------------------------

class TestReportHash(unittest.TestCase):

    def test_same_input_same_hash(self):

        h1 = compute_report_hash(
            "desc", "spam", None, None, "msg"
        )

        h2 = compute_report_hash(
            "desc", "spam", None, None, "msg"
        )

        self.assertEqual(h1, h2)

        self.assertEqual(len(h1), 64)

    def test_changed_input_changes_hash(self):

        original = compute_report_hash(
            "desc", "spam", None, None, "msg"
        )

        tampered = compute_report_hash(
            "desc EDITED", "spam", None, None, "msg"
        )

        self.assertNotEqual(original, tampered)

    def test_verify_unknown_id_returns_error(self):

        res = client.get(
            "/api/reports/verify/00000000-0000-0000-0000-000000000000"
        )

        self.assertEqual(res.status_code, 404)


# ---------------------------------------------------------------------------
# Run Tests
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    unittest.main()
