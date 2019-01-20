pragma solidity ^0.4.24;

import "./libraries/erc20/ERC20Mintable.sol";

contract Politicoin is ERC20Mintable {
  using SafeMath for uint256;

  mapping (address => bool) private whitelist;

  uint private maxBallotId;

  struct Ballot {
    string name;
    bool open;
    uint yesVotes;
    uint noVotes;
  }

  mapping (uint => Ballot) public ballots;
  uint[] private ballotIds;
  uint[] private openBallots;
  mapping (uint => uint) private openBallotIdIndex;
  /* Stores the index at which a given ballotId exists in openBallots array */

  struct CastVote {
    uint yesVotes;
    uint noVotes;
  }

  mapping (uint => mapping (address => CastVote)) private ballotAddressVotes;
  /* Used to store current votes on a given ballotId for an address.  Index position 0 is yesVotes and position 1 is no votes.  Only one of these can be a non-zero value */

  function distribute (address[] _addresses, uint[] _amounts) public onlyMinter returns (bool[]) {
    for (uint i = 0; i < _addresses.length; i++) {
      mint(_addresses[i], _amounts[i]);
    }
  }

  function whitelistAddress (address _whiteListAddy) public onlyMinter returns (bool) {
    whitelist[_whiteListAddy] = true;
    return true;
  }

  function whiteListAddresses (address[] _whiteListAddys) public onlyMinter returns (bool[]) {
    for (uint i = 0; i < _whiteListAddys.length; i++) {
      whitelistAddress(_whiteListAddys[i]);
    }
  }

  modifier whitelistedAddy(address _checkAddress) {
    require(whitelist[_checkAddress] == true);
    _;
  }

  function isWhiteListed(address _checkAddress) public view returns (bool) {
    return whitelist[_checkAddress];
  }

  function createBallot (string _ballotName) public onlyMinter returns (uint ballotId)  {
    maxBallotId++;
    ballots[maxBallotId] = Ballot(_ballotName, false, 0, 0);
    ballotIds.push(maxBallotId);
    return maxBallotId;
  }

  function isBallotOpen (uint _ballotId) public view validBallot(_ballotId) returns (bool) {
    return ballots[_ballotId].open;
  }

  modifier ballotOpen (uint _ballotId) {
    require(isBallotOpen(_ballotId));
    _;
  }

  function getHighestBallotId () public view returns (uint) {
    return maxBallotId;
  }

  function getAllOpenBallotIds () public view returns (uint[]) {
    return openBallots;
  }

  function getAllBallotIds () public view returns (uint[]) {
    return ballotIds;
  }

  function showBallot (uint _ballotId) public view returns (string _ballotName, bool _ballotOpen, uint _ballotYesVotes, uint _ballotNoVotes) {
    return (ballots[_ballotId].name, ballots[_ballotId].open, ballots[_ballotId].yesVotes, ballots[_ballotId].noVotes);
  }

  function isValidBallot (uint _ballotId) public view returns (bool) {
    return _ballotId != 0 && _ballotId <= maxBallotId;
  }

  modifier validBallot (uint _ballotId) {
    require(isValidBallot(_ballotId));
    _;
  }

  function openBallot (uint _ballotId) public onlyMinter returns (bool) {
    require(isBallotOpen(_ballotId) == false);
    ballots[_ballotId].open = true;
    openBallots.push(_ballotId);
    openBallotIdIndex[_ballotId] = openBallots.length - 1;
    return true;
  }

  function closeBallot (uint _ballotId) public onlyMinter ballotOpen(_ballotId) returns (bool) {
    ballots[_ballotId].open = false;
    if (openBallotIdIndex[_ballotId] != openBallots.length - 1) {
      openBallots[openBallotIdIndex[_ballotId]] = openBallots[openBallots.length-1];
    }
    openBallots.length--;
    return true;
  }

  function castVote (uint _ballotId, bool _yesVote) public whitelistedAddy(msg.sender) ballotOpen(_ballotId) returns (bool) {
    require(_balances[msg.sender] > 0);
    if (ballotAddressVotes[_ballotId][msg.sender].yesVotes > 0) {
      if (_yesVote) {
        if (ballotAddressVotes[_ballotId][msg.sender].yesVotes < _balances[msg.sender]) {
          ballots[_ballotId].yesVotes += _balances[msg.sender] - ballotAddressVotes[_ballotId][msg.sender].yesVotes;
          ballotAddressVotes[_ballotId][msg.sender].yesVotes = _balances[msg.sender];
        }
      }
      else {
        ballots[_ballotId].yesVotes -= ballotAddressVotes[_ballotId][msg.sender].yesVotes;
        delete ballotAddressVotes[_ballotId][msg.sender].yesVotes;
        ballots[_ballotId].noVotes += _balances[msg.sender];
        ballotAddressVotes[_ballotId][msg.sender].noVotes = _balances[msg.sender];
      }
    }
    else if (ballotAddressVotes[_ballotId][msg.sender].noVotes > 0) {
      if (_yesVote) {
        ballots[_ballotId].noVotes -= ballotAddressVotes[_ballotId][msg.sender].noVotes;
        delete ballotAddressVotes[_ballotId][msg.sender].noVotes;
        ballots[_ballotId].yesVotes += _balances[msg.sender];
        ballotAddressVotes[_ballotId][msg.sender].yesVotes = _balances[msg.sender];
      }
      else {
        if (ballotAddressVotes[_ballotId][msg.sender].noVotes < _balances[msg.sender]) {
          ballots[_ballotId].noVotes += _balances[msg.sender] - ballotAddressVotes[_ballotId][msg.sender].noVotes;
          ballotAddressVotes[_ballotId][msg.sender].noVotes = _balances[msg.sender];
        }
      }
    }
    else {
      if (_yesVote) {
        ballots[_ballotId].yesVotes += _balances[msg.sender];
        ballotAddressVotes[_ballotId][msg.sender].yesVotes = _balances[msg.sender];
      }
      else {
        ballots[_ballotId].noVotes += _balances[msg.sender];
        ballotAddressVotes[_ballotId][msg.sender].noVotes = _balances[msg.sender];
      }
    }
    return true;
  }

  /* Transfer function moved here in order to remove cast votes when transferring tokens */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= _balances[msg.sender]);
    require(_to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    for (uint i = 0; i < openBallots.length; i++) {
      if (ballotAddressVotes[openBallots[i]][msg.sender].yesVotes > _balances[msg.sender]) {
        ballots[openBallots[i]].yesVotes -= (ballotAddressVotes[openBallots[i]][msg.sender].yesVotes - _balances[msg.sender]);
        ballotAddressVotes[openBallots[i]][msg.sender].yesVotes = _balances[msg.sender];
      }
      else if (ballotAddressVotes[openBallots[i]][msg.sender].noVotes > _balances[msg.sender]) {
        ballots[openBallots[i]].noVotes -= (ballotAddressVotes[openBallots[i]][msg.sender].noVotes - _balances[msg.sender]);
        ballotAddressVotes[openBallots[i]][msg.sender].noVotes = _balances[msg.sender];
      }
    }
    return true;
  }

  /* transferFrom function moved here in order to remove cast votes when transferring tokens */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= _balances[_from]);
    require(_value <= _allowed[_from][msg.sender]);
    require(_to != address(0));

    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    for (uint i = 0; i < openBallots.length; i++) {
      if (ballotAddressVotes[openBallots[i]][_from].yesVotes > _balances[_from]) {
        ballots[openBallots[i]].yesVotes -= (ballotAddressVotes[openBallots[i]][_from].yesVotes - _balances[_from]);
        ballotAddressVotes[openBallots[i]][_from].yesVotes = _balances[_from];
      }
      else if (ballotAddressVotes[openBallots[i]][_from].noVotes > _balances[_from]) {
        ballots[openBallots[i]].noVotes -= (ballotAddressVotes[openBallots[i]][_from].noVotes - _balances[_from]);
        ballotAddressVotes[openBallots[i]][_from].noVotes = _balances[_from];
      }
    }
    return true;
  }
}
