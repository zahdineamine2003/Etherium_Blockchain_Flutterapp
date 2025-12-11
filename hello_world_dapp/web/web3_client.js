// web3_client.js
// Communicates with Ganache using web3.js

let web3;
let contract;
let accounts;

const CONTRACT_ADDRESS = "0xA7E0c2e5a10069676FB966CDDCe3f184305dCeA9";
const CONTRACT_ABI = [
  {
    "inputs": [],
    "name": "yourName",
    "outputs": [{"internalType": "string", "name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "string", "name": "newName", "type": "string"}],
    "name": "setName",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const PRIVATE_KEY = "0xa8b3e07073251fa2efeae617b2674f81fe3a05a0fdce072436f6dd5576cbeb18";

async function initializeWeb3() {
  if (typeof window.Web3 === 'undefined') {
    return { error: 'Web3 library not loaded' };
  }

  try {
    web3 = new window.Web3('http://127.0.0.1:7545');
    contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
    
    const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    accounts = [account.address];
    web3.eth.accounts.wallet.add(account);
    web3.eth.defaultAccount = account.address;
    
    console.log('Web3 initialized successfully with account:', account.address);
    return { success: true, account: account.address };
  } catch (e) {
    console.error('Web3 initialization error:', e);
    return { error: e.message };
  }
}

async function getName() {
  try {
    if (!contract) {
      console.error('Contract not initialized');
      return null;
    }
    const result = await contract.methods.yourName().call();
    console.log('Got name from contract:', result);
    return result;
  } catch (e) {
    console.error('Error getting name:', e);
    return null;
  }
}

async function setName(newName) {
  try {
    if (!contract || !web3) {
      return { error: 'Web3 or contract not initialized' };
    }
    
    const account = web3.eth.accounts.wallet[0];
    if (!account) {
      return { error: 'Account not found' };
    }
    
    console.log('Setting name to:', newName);
    const tx = contract.methods.setName(newName);
    const gas = await tx.estimateGas({ from: account.address });
    const gasPrice = await web3.eth.getGasPrice();
    
    const signedTx = await web3.eth.accounts.signTransaction({
      to: CONTRACT_ADDRESS,
      data: tx.encodeABI(),
      gas: gas,
      gasPrice: gasPrice,
      from: account.address
    }, PRIVATE_KEY);

    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
    console.log('Transaction receipt:', receipt);
    return { success: true, receipt: receipt };
  } catch (e) {
    console.error('Error setting name:', e);
    return { error: e.message };
  }
}

// Global variables to store results for Dart to read
window.web3ClientResult = {
  nameResult: null,
  setNameResult: null,
  nameReady: false,
  setNameReady: false
};

// Expose functions to Dart via window object
window.web3Client = {
  initialize: initializeWeb3,
  async getNameForDart() {
    try {
      const result = await getName();
      window.web3ClientResult.nameResult = result;
      window.web3ClientResult.nameReady = true;
      console.log('Name result stored:', result);
      return result;
    } catch (e) {
      console.error('Error in getNameForDart:', e);
      window.web3ClientResult.nameResult = null;
      window.web3ClientResult.nameReady = true;
      return null;
    }
  },
  async setNameForDart(newName) {
    try {
      const result = await setName(newName);
      window.web3ClientResult.setNameResult = result;
      window.web3ClientResult.setNameReady = true;
      console.log('SetName result stored:', result);
      return result;
    } catch (e) {
      console.error('Error in setNameForDart:', e);
      window.web3ClientResult.setNameResult = null;
      window.web3ClientResult.setNameReady = true;
      return { error: e.message };
    }
  }
};
