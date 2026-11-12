from web3 import Web3
from web3.exceptions import ContractLogicError, Web3RPCError, TransactionNotFound
from requests.exceptions import ConnectionError as RequestsConnectionError
from dotenv import load_dotenv
import hashlib
import json
import os
import time

# Path setup (works regardless of where this is called from)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ABI_PATH = os.path.join(BASE_DIR, "artifacts", "contracts", "ScamReport.sol", "ScamReport.json")

load_dotenv(os.path.join(BASE_DIR, ".env"))
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")
RPC_URL = os.getenv("RPC_URL", "http://127.0.0.1:7545")


class BlockchainError(Exception):
    """Base error for all blockchain client problems."""


class BlockchainOfflineError(BlockchainError):
    """Ganache is not reachable."""


class ReportAlreadyExistsError(BlockchainError):
    """A report with this ID is already stored on-chain."""


class ReportNotFoundError(BlockchainError):
    """No report with this ID exists on-chain."""


class BlockchainClient:
    def __init__(self):
        if not CONTRACT_ADDRESS:
            raise BlockchainError("CONTRACT_ADDRESS is missing in blockchain_module/.env")

        self.w3 = Web3(Web3.HTTPProvider(RPC_URL, request_kwargs={"timeout": 10}))
        if not self.w3.is_connected():
            raise BlockchainOfflineError(f"Could not connect to Ganache at {RPC_URL}. Is it running?")

        try:
            with open(ABI_PATH) as f:
                abi = json.load(f)["abi"]
        except FileNotFoundError as e:
            raise BlockchainError(f"ABI file not found at {ABI_PATH}. Run the Hardhat compile first.") from e

        self.contract = self.w3.eth.contract(
            address=Web3.to_checksum_address(CONTRACT_ADDRESS), abi=abi
        )
        self.account = self.w3.eth.accounts[0]

    # ------------------------------------------------------------------
    # Hashing
    # ------------------------------------------------------------------
    def hash_report(self, content: str) -> str:
        """SHA-256 of a plain string. Used only for standalone tests.
        The backend should pass Volga's compute_report_hash() digest to
        store_report_hash() instead."""
        return hashlib.sha256(content.encode("utf-8")).hexdigest()

    # ------------------------------------------------------------------
    # Write
    # ------------------------------------------------------------------
    def store_report_hash(self, report_id: str, report_hash: str) -> dict:
        """Store an already-computed hash on-chain. Returns transaction info."""
        try:
            tx_hash = self.contract.functions.storeReport(report_id, report_hash).transact(
                {"from": self.account}
            )
            receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=30)
        except RequestsConnectionError as e:
            raise BlockchainOfflineError("Lost connection to Ganache.") from e
        except (ContractLogicError, Web3RPCError, ValueError) as e:
            if "Report already exists" in str(e):
                raise ReportAlreadyExistsError(f"Report '{report_id}' already exists.") from e
            raise BlockchainError(f"Transaction failed: {e}") from e

        block = self.w3.eth.get_block(receipt["blockNumber"])
        return {
            "report_id": report_id,
            "report_hash": report_hash,
            "tx_hash": Web3.to_hex(tx_hash),
            "block_number": receipt["blockNumber"],
            "timestamp": block["timestamp"],
            "contract_address": self.contract.address,
        }

    def store_report(self, report_id: str, content: str) -> str:
        """Hash the content and store it on-chain. Returns the hash."""
        report_hash = self.hash_report(content)
        self.store_report_hash(report_id, report_hash)
        return report_hash

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------
    def get_report(self, report_id: str) -> dict:
        """Retrieve a stored report by ID."""
        try:
            result = self.contract.functions.getReport(report_id).call()
        except RequestsConnectionError as e:
            raise BlockchainOfflineError("Lost connection to Ganache.") from e
        except (ContractLogicError, Web3RPCError, ValueError) as e:
            if "Report not found" in str(e):
                raise ReportNotFoundError(f"Report '{report_id}' not found.") from e
            raise BlockchainError(f"Call failed: {e}") from e
        return {
            "reportHash": result[0],
            "timestamp": result[1],
            "submitter": result[2],
        }

    def get_total_reports(self) -> int:
        try:
            return self.contract.functions.getTotalReports().call()
        except RequestsConnectionError as e:
            raise BlockchainOfflineError("Lost connection to Ganache.") from e
        except (ContractLogicError, Web3RPCError, ValueError) as e:
            raise BlockchainError(f"Call failed: {e}") from e

    # ------------------------------------------------------------------
    # Verify
    # ------------------------------------------------------------------
    def verify_report_hash(self, report_id: str, report_hash: str) -> dict:
        """Check that report_hash matches what is stored on-chain for report_id."""
        try:
            stored = self.get_report(report_id)
        except ReportNotFoundError:
            return {
                "verified": False,
                "reason": "not_found",
                "computed_hash": report_hash,
            }
        match = stored["reportHash"] == report_hash
        return {
            "verified": match,
            "reason": "match" if match else "hash_mismatch",
            "computed_hash": report_hash,
            "stored_hash": stored["reportHash"],
            "timestamp": stored["timestamp"],
            "submitter": stored["submitter"],
        }

    def verify_report(self, report_id: str, content: str) -> dict:
        """Check that plain-string content matches the hash stored for report_id."""
        return self.verify_report_hash(report_id, self.hash_report(content))

    def verify_tx(self, tx_hash: str) -> dict:
        """Verify a storeReport transaction by its tx hash.
        Used by the backend's /api/blockchain/verify/{tx_hash} endpoint."""
        try:
            tx = self.w3.eth.get_transaction(tx_hash)
            receipt = self.w3.eth.get_transaction_receipt(tx_hash)
        except TransactionNotFound:
            return {"verified": False, "reason": "tx_not_found"}
        except RequestsConnectionError as e:
            raise BlockchainOfflineError("Lost connection to Ganache.") from e
        except (Web3RPCError, ValueError) as e:
            raise BlockchainError(f"Lookup failed: {e}") from e

        if receipt["status"] != 1:
            return {"verified": False, "reason": "tx_failed"}
        if not tx["to"] or tx["to"].lower() != self.contract.address.lower():
            return {"verified": False, "reason": "not_a_contract_tx"}

        try:
            func, args = self.contract.decode_function_input(tx["input"])
        except Exception:
            return {"verified": False, "reason": "undecodable_input"}
        if func.fn_name != "storeReport":
            return {"verified": False, "reason": "wrong_function"}

        report_id = args["_reportId"]
        check = self.verify_report_hash(report_id, args["_reportHash"])
        block = self.w3.eth.get_block(receipt["blockNumber"])
        return {
            "verified": check["verified"],
            "reason": check["reason"],
            "tx_hash": Web3.to_hex(receipt["transactionHash"]),
            "block_number": receipt["blockNumber"],
            "timestamp": block["timestamp"],
            "report_id": report_id,
            "report_hash": args["_reportHash"],
            "contract_address": self.contract.address,
            "submitter": check.get("submitter"),
        }


# Quick test when run directly
if __name__ == "__main__":
    client = BlockchainClient()

    rid = f"test_{int(time.time())}"
    h = client.store_report(rid, "This is a sample scam report content")
    print("Stored with hash:", h)
    print("Retrieved:", client.get_report(rid))
    print("Verify by content:", client.verify_report(rid, "This is a sample scam report content"))

    rid2 = f"test_{int(time.time())}_b"
    info = client.store_report_hash(rid2, "a" * 64)
    print("store_report_hash:", info)
    print("verify_tx:", client.verify_tx(info["tx_hash"]))

    try:
        client.store_report(rid, "This is a sample scam report content")
    except ReportAlreadyExistsError as e:
        print("Duplicate handled:", e)

    try:
        client.get_report("does_not_exist")
    except ReportNotFoundError as e:
        print("Not found handled:", e)

    print("Total reports:", client.get_total_reports())
