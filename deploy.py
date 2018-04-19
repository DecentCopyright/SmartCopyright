import json
import web3

from web3 import Web3, TestRPCProvider
from solc import compile_source
from web3.contract import ConciseContract

# Solidity source code
file = open("contracts/Copyright.sol", "r")
contract_source_code = file.read()

compiled_sol = compile_source(contract_source_code) # Compiled source code
contract_interface = compiled_sol['<stdin>:Copyright']

# web3.py instance
w3 = Web3(TestRPCProvider())

# Instantiate and deploy contract
contract = w3.eth.contract(abi=contract_interface['abi'], bytecode=contract_interface['bin'])


# Get transaction hash from deployed contract
tx_hash = contract.constructor().transact({'from': w3.eth.accounts[0]}) #contract.deploy(transaction={'from': w3.eth.accounts[0], 'gas': 520000})

# Get tx receipt to get contract address
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
contract_address = tx_receipt['contractAddress']
print('Contract address: {}'.format(contract_address))

# Contract instance in concise mode
contract_instance = w3.eth.contract(abi=contract_interface['abi'], address=contract_address, ContractFactoryClass=ConciseContract)

# Getters + Setters for web3.eth.contract object
# print('Contract value: {}'.format(contract_instance.greet()))
# v = contract_instance.setGreeting('Nihao', transact={'from': w3.eth.accounts[0]})
# print('result?: {}'.format(Web3.toText(v)))
# print('Setting value to: Nihao')
# print('Contract value: {}'.format(contract_instance.greet()))
