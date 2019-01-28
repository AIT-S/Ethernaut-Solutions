pragma solidity ^0.5.0;

import "./IStampCollector.sol";

contract StampCollector is IStampCollector {
    mapping(address => bool) public collectedStamps;
    
    
    function isCollected(address stamp) external returns (bool) {
        return collectedStamps[stamp];
    }
    
    function collectStamp(address stamp) external {
        bytes memory payload = abi.encodeWithSignature("id()");
        (bool success, bytes memory returnData) = stamp.call(payload);
        require(success);
        collectedStamps[stamp] = true;
    }
}


