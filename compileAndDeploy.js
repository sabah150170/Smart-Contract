
const path = require('path');
const Tx = require('ethereumjs-tx').Transaction //to sign transaction and broadcast to the eth network
const fs = require('fs-extra');
const solc = require('solc');
const Web3 = require('web3')

const config = require('./config.json');
const web3 = new Web3('http://127.0.0.1:7545')

//compile the source code
var privateKey = Buffer.from(config.PrivateKey, 'hex') 
var content = fs.readFileSync("./contracts/Lottery.sol", 'utf8')

var sourceCode = {
   'Lottery.sol': {
      content: content
   }
}

const input = {
   language: 'Solidity',
   sources: sourceCode,
   settings: {
      outputSelection: {
         '*': {
            '*': [ 'abi', 'evm.bytecode' ]
         }
      }
   }
}

const compileContracts = () => {
   var compiledContracts = JSON.parse(solc.compile(JSON.stringify(input))).contracts;
   compiledContracts = compiledContracts['Lottery.sol'][config.contractName]

   fs.outputJsonSync( path.resolve("./src/", `${config.contractName}.json`), compiledContracts.abi,{ spaces: 2 });

   deployContract(compiledContracts.abi, compiledContracts.evm.bytecode.object );
}

function deployContract(abi, byteData) {

   //DEPLOY SMART CONTRACT TO THE ETH BLOCKCHAIN
   web3.eth.getTransactionCount(config.account, async (err, txCount) => {
      const txObject_2 = { //build transaction
         nonce: web3.utils.toHex(txCount), //previous transaction count; when broadcasting, race conditions can be occured with different transaction so this prevent double spent
         gasLimit: web3.utils.toHex(3000000), //safeguard
         gasPrice: web3.utils.toHex(web3.utils.toWei('15', 'gwei')),
         data: '0x' + byteData //byte code of smart contract which will be deployed
      }

      var tx2 = new Tx(txObject_2) //, {chain:config.network}); //chain is necessary for this ver of ethereum-js
      tx2.sign(privateKey) //sender private key, sign the transaction

      const serializedTransaction2 = tx2.serialize()
      const raw2 = '0x' + serializedTransaction2.toString('hex')
      //web3.eth.sendSignedTransaction(raw2, (err, txHash) => { console.log('txHash: ', txHash , '\nerror: ', error) }) //broadcast the transaction, txHash --> the contract on Etherscan
      const receipt = await web3.eth.sendSignedTransaction(raw2)
      console.log("contract address: ", receipt.contractAddress)
   })
}


compileContracts();






