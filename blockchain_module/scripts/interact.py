from web3 import Web3
import json

# Connect to Ganache
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))
print("Connected:", w3.is_connected())

# Load contract ABI from Hardhat's compiled artifact
with open("artifacts/contracts/ScamReport.sol/ScamReport.json") as f:
    contract_json = json.load(f)
    abi = contract_json["abi"]

# deployed contract address
contract_address = "0xA41b493fcFB457dBa587CF0EB526E36C80b12BBA"

contract = w3.eth.contract(address=contract_address, abi=abi)

# Use the first Ganache account to send the transaction
account = w3.eth.accounts[0]

# Store a report
tx_hash = contract.functions.storeReport("report002", "pythonhash456").transact({"from": account})
w3.eth.wait_for_transaction_receipt(tx_hash)
print("Report stored via Python!")

# Read it back
result = contract.functions.getReport("report002").call()
print("Retrieved report:", result)

total = contract.functions.getTotalReports().call()
print("Total reports:", total)