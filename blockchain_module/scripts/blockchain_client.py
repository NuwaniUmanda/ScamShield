from web3 import Web3
import json
import hashlib
import os

# Path setup (works regardless of where this is called from)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ABI_PATH = os.path.join(BASE_DIR, "artifacts", "contracts", "ScamReport.sol", "ScamReport.json")

CONTRACT_ADDRESS = "0xA41b493fcFB457dBa587CF0EB526E36C80b12BBA"
RPC_URL = "http://127.0.0.1:7545"


class BlockchainClient:
    def __init__(self):
        self.w3 = Web3(Web3.HTTPProvider(RPC_URL))
        if not self.w3.is_connected():
            raise ConnectionError("Could not connect to Ganache. Is it running?")

        with open(ABI_PATH) as f:
            abi = json.load(f)["abi"]

        self.contract = self.w3.eth.contract(address=CONTRACT_ADDRESS, abi=abi)
        self.account = self.w3.eth.accounts[0]

    def hash_report(self, content: str) -> str:
        """Generate a SHA-256 hash of report content."""
        return hashlib.sha256(content.encode()).hexdigest()

    def store_report(self, report_id: str, content: str) -> str:
        """Hash the content and store it on-chain. Returns the hash."""
        report_hash = self.hash_report(content)
        tx_hash = self.contract.functions.storeReport(report_id, report_hash).transact(
            {"from": self.account}
        )
        self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return report_hash

    def get_report(self, report_id: str) -> dict:
        """Retrieve a stored report by ID."""
        result = self.contract.functions.getReport(report_id).call()
        return {
            "reportHash": result[0],
            "timestamp": result[1],
            "submitter": result[2],
        }

    def get_total_reports(self) -> int:
        return self.contract.functions.getTotalReports().call()


# Quick test when run directly
if __name__ == "__main__":
    client = BlockchainClient()
    h = client.store_report("report004", "This is a sample scam report content")
    print("Stored with hash:", h)
    print("Retrieved:", client.get_report("report003"))
    print("Total reports:", client.get_total_reports())