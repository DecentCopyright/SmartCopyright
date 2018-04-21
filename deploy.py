import json
import web3
from web3 import Web3, IPCProvider
from solc import compile_files
import time

compiled_sol = compile_files(['contracts/Copyright.sol']) # Compiled source code
contract_interface = compiled_sol['contracts/Copyright.sol:Copyright']

# web3.py instance
# Instantiate and deploy contract
w3 = Web3(IPCProvider("./data/geth.ipc"))
contract = w3.eth.contract(abi=contract_interface['abi'], bytecode=contract_interface['bin'])

# Get transaction hash from deployed contract
# Get tx receipt to get contract address
tx_hash = contract.constructor().transact({'from': w3.eth.accounts[0], 'value': '0x64', 'gas': '0xF4240' })
print("-------------TX_HASH-------------")
# print(Web3.toText(tx_hash))
tx_receipt = None
counter = 0
while tx_receipt is None:
	tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
	time.sleep(1)
	counter += 1
print("Number of seconds for it to be mined: ", counter)
contract_address = tx_receipt['contractAddress']
print('Contract address: {}'.format(contract_address))
print('Deployed!\n')

deployed_result = {}
deployed_result['contract_address'] = contract_address
deployed_result['abi'] = contract_interface['abi']

with open('smart-copyright.info', 'w') as outfile:
    print('Writing deploy info file...')
    json.dump(deployed_result, outfile)
