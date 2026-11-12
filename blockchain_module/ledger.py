"""
ScamShield ledger: drop-in replacement for the local JSON ledger.

Keeps the same public names the backend already uses
(blockchain_ledger, record_scam_on_chain, verify_hash) but records
to the real ScamReport contract on Ganache through BlockchainClient.
"""
import hashlib
import json
from typing import Any, Dict, Optional

try:
    from blockchain_module.scripts.blockchain_client import BlockchainClient, BlockchainError
except ImportError:
    from scripts.blockchain_client import BlockchainClient, BlockchainError


class ScamShieldLedger:
    def __init__(self):
        # Connect lazily so the backend still starts if Ganache is offline.
        self._client: Optional[BlockchainClient] = None

    @property
    def client(self) -> BlockchainClient:
        if self._client is None:
            self._client = BlockchainClient()  # raises BlockchainOfflineError if Ganache is down
        return self._client

    def record_scam_on_chain(
        self,
        report_id: str,
        title: str,
        scam_type: str,
        risk_score: int,
        target_info: str = "",
        report_hash: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Stores the report's content hash on-chain.
        Pass report_hash=compute_report_hash(...) from main.py.
        Raises a BlockchainError subclass on failure (the caller's except handles it).
        """
        if not report_hash:
            # Fallback only: deterministic hash of the fields this method receives.
            report_hash = hashlib.sha256(
                json.dumps(
                    {
                        "title": title,
                        "scam_type": scam_type,
                        "risk_score": risk_score,
                        "target_info": target_info,
                    },
                    sort_keys=True,
                ).encode("utf-8")
            ).hexdigest()

        result = self.client.store_report_hash(report_id, report_hash)
        return {
            "block_number": result["block_number"],
            "tx_hash": result["tx_hash"],
            "report_id": report_id,
            "report_hash": report_hash,
            "contract_address": result["contract_address"],
            "scam_type": scam_type,
            "risk_score": risk_score,
            "timestamp": result["timestamp"],
            "status": "VERIFIED_ON_CHAIN",
        }

    def verify_hash(self, tx_hash: str) -> Dict[str, Any]:
        """Verifies a storeReport transaction by tx_hash."""
        try:
            result = self.client.verify_tx(tx_hash.strip())
        except BlockchainError as e:
            return {"is_valid": False, "message": str(e)}

        if not result["verified"]:
            return {
                "is_valid": False,
                "message": f"Verification failed: {result['reason']}",
            }
        return {
            "is_valid": True,
            "block_number": result["block_number"],
            "tx_hash": result["tx_hash"],
            "contract_address": result["contract_address"],
            "timestamp": result["timestamp"],
            "report_id": result["report_id"],
            "report_hash": result["report_hash"],
            "status": "VERIFIED_ON_CHAIN",
        }

    def verify_report(self, report_id: str, report_hash: str) -> Dict[str, Any]:
        """Verify by report_id + content hash (what the contract indexes on)."""
        return self.client.verify_report_hash(report_id, report_hash)


# Global instance (does not connect until first use)
blockchain_ledger = ScamShieldLedger()
