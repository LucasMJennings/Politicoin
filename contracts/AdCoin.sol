pragma solidity ^0.4.24;

import "./Politicoin.sol";

contract AdCoin is Politicoin {
  string public constant name = "Politicoin - AdCoin";
  string public constant symbol = "PAC";
  uint8 public constant decimals = 2;

  uint256 public constant INITIAL_SUPPLY = 0 * (10 **uint(decimals));

  constructor() public {
    mint(msg.sender, INITIAL_SUPPLY);
  }

}
