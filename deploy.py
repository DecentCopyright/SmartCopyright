import json
import web3
from web3 import Web3, EthereumTesterProvider
from solc import compile_files
from web3.contract import ConciseContract

import argparse
import os
import tarfile
import random
import string
import ipfsapi
from simplecrypt import encrypt, decrypt

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
print('Deployed!\n')

# Contract instance in concise mode
abifile = open('copyring.abi', 'r')
abi = json.load(abifile)
abifile.close()

c = w3.eth.contract(abi=abi, address=contract_address)

print('Register users')
c.functions.userRegister().transact({'from': w3.eth.accounts[0]})
c.functions.userRegister().transact({'from': w3.eth.accounts[1]})
u0 = c.functions.amIRegistered().call({'from': w3.eth.accounts[0]})
u1 = c.functions.amIRegistered().call({'from': w3.eth.accounts[1]})
assert(u0 and u1)

print('Uploading a song')
songName = 'ssongSsong'
price = 1000
holders = [w3.eth.accounts[0]]
shares = [100]

# ------------- ipfs / encryption stuff
ipfs = ipfsapi.connect('127.0.0.1', 5001)
tar_path = "__temp.tar"
# generate random password key
password = ''.join([random.choice(string.ascii_letters + string.digits) for n in range(16)])
# get file path
path = 'to_upload/DemoZero.mp3'
basename = os.path.basename(path)
# create archive
tar = tarfile.open(tar_path, "w")
tar.add(path, arcname=basename)
tar.close()
# encrypt
print("encrypting......")
file = open(tar_path, mode='rb')
encrypted_data = encrypt(password, file.read())
# upload to ipfs
print("uploading to IPFS......")
ipfs_hash = ipfs.add_bytes(encrypted_data)
fileInfo = '{} {}'.format(ipfs_hash, password)
print("\tfileInfo: " + fileInfo)
# ----------------------

tx_hash = c.functions.registerCopyright(songName, fileInfo, price, holders, shares).transact({'from': w3.eth.accounts[0]})
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
logs = c.events.registerEvent().processReceipt(tx_receipt)
songID = Web3.toHex(logs[0]['args']['songID'])
print("\tsongID: " + songID)

print('Purchasing a song')
tx_hash = c.functions.buyLicense(songID).transact({'from': w3.eth.accounts[1], 'value': price})
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
logs = c.events.licenseEvent().processReceipt(tx_receipt)
purchased_songID = Web3.toHex(logs[0]['args']['songID'])
print("\tpurchased_songID: " + purchased_songID)

print('Get file info')
purchased_fileInfo = c.functions.getDownloadInfo(songID).call({'from': w3.eth.accounts[1]});
print("\tpurchased_fileInfo: " + purchased_fileInfo)

# ------------- ipfs / decryption stuff
# parse file info
splitted = purchased_fileInfo.split()
purchased_url = splitted[0]
purchased_key = splitted[1]
print("downloading from IPFS......")
ipfs.get(purchased_url)
# decrypt
print("decrypting......")
downloaded_file = open(purchased_url, mode='rb')
decrypted_data = decrypt(purchased_key, downloaded_file.read())
# remove raw ipfs data
os.remove(purchased_url)
# write to tar file
tar_output = open(tar_path, 'wb')
tar_output.write(decrypted_data)
tar_output.close()
# extract data from tar
print("extracting......")
tar = tarfile.open(tar_path)
tar.extractall()
tar.close()
# ----------------------
os.remove(tar_path)