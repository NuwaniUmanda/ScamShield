"""
Deploy the ScamReport contract to the Ganache at RPC_URL and print its address.

Run from the blockchain_module folder:
    python scripts\\deploy_contract.py

Needs the compiled artifact (run `npx hardhat compile` first if it is missing).
"""
import json
import os
import sys

from dotenv import load_dotenv
from web3 import Web3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT_PATH = os.path.join(
    BASE_DIR, "artifacts", "contracts", "ScamReport.sol", "ScamReport.json"
)

load_dotenv(os.path.join(BASE_DIR, ".env"))
RPC_URL = os.getenv("RPC_URL", "http://127.0.0.1:7545")


def main() -> None:
    w3 = Web3(Web3.HTTPProvider(RPC_URL, request_kwargs={"timeout": 10}))
    if not w3.is_connected():
        sys.exit(f"Could not connect to Ganache at {RPC_URL}. Is it running?")

    if not os.path.exists(ARTIFACT_PATH):
        sys.exit(f"Artifact not found at {ARTIFACT_PATH}. Run: npx hardhat compile")

    with open(ARTIFACT_PATH) as f:
        artifact = json.load(f)

    contract = w3.eth.contract(abi=artifact["abi"], bytecode=artifact["bytecode"])
    tx_hash = contract.constructor().transact({"from": w3.eth.accounts[0]})
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)

    print("Contract deployed.")
    print(f"CONTRACT_ADDRESS={receipt['contractAddress']}")
    print("Copy the line above into blockchain_module\\.env")


if __name__ == "__main__":
    main()
