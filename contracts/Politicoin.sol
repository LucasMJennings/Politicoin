pragma solidity ^0.4.24;

import "./libraries/erc20/ERC20Mintable.sol";

contract Politicoin is ERC20Mintable {

  mapping (address => bool) public whitelist;
  address[] public whitelistArray;

  struct Ballot {
    string name;
    uint endTime;
    uint yesVotes;
    uint noVotes;
  }

  Ballot[] public ballots;

  function distribute (address[] addresses, uint[] amounts) public onlyMinter returns (bool[]) {
    uint arrayLength = addresses.length;
    for (uint i=0; i<arrayLength; i++) {
      mint(addresses[i], amounts[i]);
    }
  }

  function whitelistAddress (address whiteListAddy) public onlyMinter {
    whitelist[whiteListAddy] = true;
    whitelistArray.push(whiteListAddy);
  }

  function whiteListAddresses (address[] whiteListAddys) public onlyMinter {
    uint arrayLength = whiteListAddys.length;
    for (uint i=0; i<arrayLength; i++) {
      whitelistAddress(whiteListAddys[i]);
    }
  }

  modifier whitelistedAddy(address checkAddress) {
    require(whitelist[checkAddress] == true);
    _;
  }

  function isWhiteListed(address checkAddress) public view returns (bool) {
    bool isAddyWhiteListed = whitelist[checkAddress];
    return isAddyWhiteListed;
  }

  function createBallot (string ballotName) public onlyMinter returns (uint ballotId)  {
    Ballot memory newBallot = Ballot(ballotName, now + 1 days, 0, 0);
    ballots.push(newBallot);
    return ballots.length-1;
  }

  modifier ballotOpen (uint ballotId) {
    require(ballots[ballotId].endTime >= now);
    _;
  }

  function showBallot(uint ballotId) public view returns (string ballotName, uint ballotEndTime, uint ballotYesVotes, uint ballotNoVotes) {
    return (ballots[ballotId].name, ballots[ballotId].endTime, ballots[ballotId].yesVotes, ballots[ballotId].noVotes);
  }

  function getHighestBallotId() public view returns (uint) {
    return ballots.length-1;
  }

  function castVote (uint ballotId, bool YesVote) public whitelistedAddy(msg.sender) addressUnlocked(msg.sender) ballotOpen(ballotId) {
    lockTokens();
    uint votes = _balances[msg.sender];
    if (YesVote == true) {
      ballots[ballotId].yesVotes += votes;
    }
    else {
      ballots[ballotId].noVotes += votes;
    }
  }

}
