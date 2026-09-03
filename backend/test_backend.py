import unittest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger

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
        print("\n[AI Module Test] Risk Evaluation Result:")
        print(f"Risk Score: {result['risk_score']}/100, Level: {result['risk_level']}")
        print(f"Summary: {result['summary']}")

    def test_blockchain_ledger_recording_and_verification(self):
        report_id = "test-uuid-99"
        title = "Crypto Doubler Scheme"
        scam_type = "crypto_investment"
        risk_score = 92
        target_info = "0x32Be343B94f860124dC4fEe278FDCBD38C102D88"

        # Record on chain
        block_entry = blockchain_ledger.record_scam_on_chain(
            report_id=report_id,
            title=title,
            scam_type=scam_type,
            risk_score=risk_score,
            target_info=target_info
        )
        self.assertTrue(block_entry["tx_hash"].startswith("0x"))
        self.assertEqual(block_entry["status"], "VERIFIED_ON_CHAIN")

        # Verify hash
        verification = blockchain_ledger.verify_hash(block_entry["tx_hash"])
        self.assertTrue(verification["is_valid"])
        self.assertEqual(verification["status"], "VERIFIED_ON_CHAIN")
        print("\n[Blockchain Ledger Test] Block Recorded & Verified:")
        print(f"Tx Hash: {verification['tx_hash']}")
        print(f"Block #: {verification['block_number']}, Proof: {verification['proof']}")

if __name__ == "__main__":
    unittest.main()
