import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'package:js/js_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
    final String _rpcUrl = "http://127.0.0.1:7545";
    final String _wsUrl = "ws://127.0.0.1:7545/";
    // Use the provided MetaMask account for local testing (desktop/mobile only)
    final String _privateKey =
      "0xa8b3e07073251fa2efeae617b2674f81fe3a05a0fdce072436f6dd5576cbeb18";

  late Web3Client _client;
  bool isLoading = true;

  late String _abiCode;
  late EthereumAddress _contractAddress;

  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;

  String deployedName = "";

  // CORRECTION ICI : On utilise BigInt pour le Chain ID
  late BigInt _chainId;

  ContractLinking() {
    initialSetup();
  }

  Future<void> initialSetup() async {
    if (kIsWeb) {
      // Initialize web3.js client on web
      final result = await js.context['web3Client'].callMethod('initialize', []);
      if (result['success'] == true) {
        print('Web3 initialized: ${result['account']}');
      } else {
        print('Web3 initialization error: ${result['error']}');
      }
      await getName();
    } else {
      // Use web3dart for desktop/mobile
      _client = Web3Client(
        _rpcUrl,
        Client(),
        socketConnector: () {
          return IOWebSocketChannel.connect(_wsUrl).cast<String>();
        },
      );
      await getAbi();
      await getCredentials();
      await getDeployedContract();
    }
  }

  late dynamic _abiJson;
  Future<void> getAbi() async {
    String abiStringFile = await rootBundle.loadString(
      "src/artifacts/HelloWorld.json",
    );
    var jsonAbi = jsonDecode(abiStringFile);
    _abiJson = jsonAbi["abi"];
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(
      jsonAbi["networks"]["5777"]["address"],
    );
  }

  Future<void> getCredentials() async {
    _credentials = await _client.credentialsFromPrivateKey(_privateKey);

    // CORRECTION ICI : On récupère le ChainID (1337 souvent) et non le NetworkID (5777)
    _chainId = await _client.getChainId();
    print("Chain ID réel utilisé pour la signature : $_chainId");
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HelloWorld"),
      _contractAddress,
    );
    _yourName = _contract.function("yourName");
    _setName = _contract.function("setName");
    getName();
  }

  getName() async {
    isLoading = true;
    notifyListeners();
    
    if (kIsWeb) {
      try {
        // Reset the ready flag
        js.context['web3ClientResult']['nameReady'] = false;
        // Call the async JavaScript function
        js.context['web3Client'].callMethod('getNameForDart', []);
        
        // Poll for result
        int attempts = 0;
        while (!js.context['web3ClientResult']['nameReady'] && attempts < 100) {
          await Future.delayed(Duration(milliseconds: 50));
          attempts++;
        }
        
        final result = js.context['web3ClientResult']['nameResult'];
        deployedName = result?.toString() ?? '';
        print('Got name from web3: $deployedName');
      } catch (e) {
        print('Error getting name: $e');
        deployedName = '';
      }
    } else {
      var currentName = await _client.call(
        contract: _contract,
        function: _yourName,
        params: [],
      );
      deployedName = currentName[0];
    }
    
    isLoading = false;
    notifyListeners();
  }

  setName(String nameToSet) async {
    isLoading = true;
    notifyListeners();

    if (kIsWeb) {
      try {
        // Reset the ready flag
        js.context['web3ClientResult']['setNameReady'] = false;
        // Call the async JavaScript function
        js.context['web3Client'].callMethod('setNameForDart', [nameToSet]);
        
        // Poll for result
        int attempts = 0;
        while (!js.context['web3ClientResult']['setNameReady'] && attempts < 100) {
          await Future.delayed(Duration(milliseconds: 50));
          attempts++;
        }
        
        final result = js.context['web3ClientResult']['setNameResult'];
        print('Set name result: $result');
      } catch (e) {
        print('Error calling setName: $e');
      }
    } else {
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _setName,
          parameters: [nameToSet],
        ),
        chainId: _chainId.toInt(),
      );
    }

    await getName();
  }
}
