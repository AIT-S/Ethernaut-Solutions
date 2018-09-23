// Level 1

pragma solidity ^0.4.18;

import 'github.com/openzeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract Fallback is Ownable {

  mapping(address => uint) public contributions;

  constructor() public {
    contributions[msg.sender] = 1000 * (1 ether); // owner has 1k ether balance
  }

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner()]) {
      transferOwnership(msg.sender);
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    owner().transfer(address(this).balance);
  }

  function() payable public {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    transferOwnership(msg.sender);
  }
}

// [
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": true,
//         "name": "previousOwner",
//         "type": "address"
//       },
//       {
//         "indexed": true,
//         "name": "newOwner",
//         "type": "address"
//       }
//     ],
//     "name": "OwnershipTransferred",
//     "type": "event"
//   },
  // {
  //   "constant": false,
  //   "inputs": [],
  //   "name": "contribute",
  //   "outputs": [],
  //   "payable": true,
  //   "stateMutability": "payable",
  //   "type": "function"
  // },
//   {
//     "constant": false,
//     "inputs": [],
//     "name": "renounceOwnership",
//     "outputs": [],
//     "payable": false,
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "constant": false,
//     "inputs": [
//       {
//         "name": "newOwner",
//         "type": "address"
//       }
//     ],
//     "name": "transferOwnership",
//     "outputs": [],
//     "payable": false,
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "constant": false,
//     "inputs": [],
//     "name": "withdraw",
//     "outputs": [],
//     "payable": false,
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": true,
//         "name": "previousOwner",
//         "type": "address"
//       }
//     ],
//     "name": "OwnershipRenounced",
//     "type": "event"
//   },
//   {
//     "payable": true,
//     "stateMutability": "payable",
//     "type": "fallback"
//   },
//   {
//     "inputs": [],
//     "payable": false,
//     "stateMutability": "nonpayable",
//     "type": "constructor"
//   },
//   {
//     "constant": true,
//     "inputs": [
//       {
//         "name": "",
//         "type": "address"
//       }
//     ],
//     "name": "contributions",
//     "outputs": [
//       {
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "payable": false,
//     "stateMutability": "view",
//     "type": "function"
//   },
//   {
//     "constant": true,
//     "inputs": [],
//     "name": "getContribution",
//     "outputs": [
//       {
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "payable": false,
//     "stateMutability": "view",
//     "type": "function"
//   },
//   {
//     "constant": true,
//     "inputs": [],
//     "name": "isOwner",
//     "outputs": [
//       {
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "payable": false,
//     "stateMutability": "view",
//     "type": "function"
//   },
//   {
//     "constant": true,
//     "inputs": [],
//     "name": "owner",
//     "outputs": [
//       {
//         "name": "",
//         "type": "address"
//       }
//     ],
//     "payable": false,
//     "stateMutability": "view",
//     "type": "function"
//   }
// ]



// Solution

// 1) You can contribute until you have more balance than the owner and the contribute function will automatically make you the owner or ...
// 2) Contribute once then send ether again and cause the fallback function to make you an owner instead.
// 3) Then call withdraw. 


