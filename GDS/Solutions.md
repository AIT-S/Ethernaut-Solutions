Solutions to GDShive

=========
= Hello =
=========

password = govtech_ethernaut

- it's not clear enough from the phrasing that I should get started by doing "await contract.methods.info().call()"

Can make it harder by trying to get them to retrieve the password via getStorage as opposed to calling the public variable; await web3.eth.getStorageAt(contract.address, 0)


==================
= One Small Step =
==================

very simple, not much feedback.

===================
= Stamp Collector =
===================

Using abi.encodeWithSignature to verify an externally deployed contract. 

=========
= ERC20 =
=========

Copied and pasted entire solution from OpenZeppelin. I think this can replace "One Small Step" except maybe with a different interface implementation. 

============
= FizzBuzz =
============

Read instructions properly! Using Oraclize. 


General Feedback

0. I didn't know that you could do this lol
1. Really like that is upgraded to solidity 0.5.0 and web3 1.0.0 and above.
2. Should be testing about solidity best practices as well e.g. reentrancy attack, DoS, forcibly sending ether to a contract, integer overflow etc.
3. Can also test about more advanced concepts like creating upgradable and modular contracts
4. Can also test truffle / status embark 



