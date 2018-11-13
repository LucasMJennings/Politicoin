pragma solidity^0.4.24;

import "./libraries/roles/MinterRole.sol";

contract LockedToken is MinterRole {

  mapping(address => bool) public lockedTokens;

  address[] public lockedTokensArray;

  function lockTokensMaster (address lockAddress) public onlyMinter returns (bool) {
    lockedTokens[lockAddress] = true;
    lockedTokensArray.push(lockAddress);
  }

  function lockTokens () public {
    lockedTokens[msg.sender] = true;
    lockedTokensArray.push(msg.sender);
  }

  function isLocked(address checkAddress) public view returns (bool) {
    bool isAddyLocked = lockedTokens[checkAddress];
    return isAddyLocked;
  }

  function showLockedTokens() public view returns (address[]) {
    return lockedTokensArray;
  }

  function unlockAllTokens () public onlyMinter returns (bool) {
    uint arrayLength = lockedTokensArray.length;
    for (uint i=0; i<arrayLength; i++) {
      address check = lockedTokensArray[i];
      lockedTokens[check] = false;
    }
    lockedTokensArray = new address[](0);
  }

  function unlockAddress(address addressToUnlock) public onlyMinter {
    lockedTokens[addressToUnlock] = false;
  }

  modifier addressUnlocked(address checkAddress) {
    require(lockedTokens[checkAddress] == false);
    _;
  }

}
