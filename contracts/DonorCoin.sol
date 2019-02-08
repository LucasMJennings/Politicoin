pragma solidity ^0.4.24;

import "./Politicoin.sol";

contract DonorCoin is Politicoin {
  string public constant name = "Politicoin - DonorCoin";
  string public constant symbol = "PDC";
  uint8 public constant decimals = 0;

  uint256 public constant INITIAL_SUPPLY = 0 * (10 **uint(decimals));

  constructor() public {
    mint(msg.sender, INITIAL_SUPPLY);
  }

}
