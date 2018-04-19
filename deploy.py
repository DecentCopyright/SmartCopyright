import json
import web3

from web3 import Web3, EthereumTesterProvider
from solc import compile_files
from web3.contract import ConciseContract

compiled_sol = compile_files(['contracts/Copyright.sol']) # Compiled source code
contract_interface = compiled_sol['contracts/Copyright.sol:Copyright']

# web3.py instance
# Instantiate and deploy contract
w3 = Web3(EthereumTesterProvider())
contract = w3.eth.contract(abi=contract_interface['abi'], bytecode=contract_interface['bin'])

with open('copyring.abi', 'w') as outfile:
    print('Writing abi file...')
    json.dump(contract_interface['abi'], outfile)

# Get transaction hash from deployed contract
# Get tx receipt to get contract address
tx_hash = contract.constructor().transact({'from': w3.eth.accounts[0]}) 
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
contract_address = tx_receipt['contractAddress']
print('Contract address: {}'.format(contract_address))


# Contract instance in concise mode
abifile = open('copyring.abi', 'r')
abi = json.load(abifile)
abifile.close()

contract_instance = w3.eth.contract(abi=abi, address=contract_address, ContractFactoryClass=ConciseContract)

# Getters + Setters for web3.eth.contract object
# print('Contract value: {}'.format(contract_instance.greet()))
# v = contract_instance.setGreeting('Nihao', transact={'from': w3.eth.accounts[0]})
# print('result?: {}'.format(Web3.toText(v)))
# print('Setting value to: Nihao')
# print('Contract value: {}'.format(contract_instance.greet()))
