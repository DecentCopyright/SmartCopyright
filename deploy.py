import json
import web3
from web3 import Web3, EthereumTesterProvider
from solc import compile_files

compiled_sol = compile_files(['contracts/Copyright.sol']) # Compiled source code
contract_interface = compiled_sol['contracts/Copyright.sol:Copyright']

# web3.py instance
# Instantiate and deploy contract
w3 = Web3(EthereumTesterProvider())
contract = w3.eth.contract(abi=contract_interface['abi'], bytecode=contract_interface['bin'])

# Get transaction hash from deployed contract
# Get tx receipt to get contract address
tx_hash = contract.constructor().transact({'from': w3.eth.accounts[0]})
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
contract_address = tx_receipt['contractAddress']
print('Contract address: {}'.format(contract_address))
print('Deployed!\n')

deployed_result = {}
deployed_result['contract_address'] = contract_address
deployed_result['abi'] = contract_interface['abi']

with open('smart-copyright.info', 'w') as outfile:
    print('Writing deploy info file...')
    json.dump(deployed_result, outfile)
