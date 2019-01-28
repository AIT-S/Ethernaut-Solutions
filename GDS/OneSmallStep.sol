pragma solidity ^0.5.0;

import "./IOneSmallStep.sol";

contract OneSmallStep is IOneSmallStep {
    
    function quote() external pure returns (string memory) {
        return "That's one small step for man, one giant leap for mankind.";
    }
    
}