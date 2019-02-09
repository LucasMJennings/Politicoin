pragma solidity 0.4.24;

import "./libraries/erc20/ERC20Mintable.sol";
import "./libraries/erc165/CheckERC165.sol";

contract Politicoin is ERC20Mintable, CheckERC165 {
  using SafeMath for uint256;

  mapping (address => bool) private whitelist;

  uint private maxBallotId;

  struct Ballot {
    bool open;
    uint32 yesVotes;
    uint32 noVotes;
    bytes23 name;
  }

  mapping (uint => Ballot) public ballots;
  uint[] private ballotIds;
  uint[] private openBallots;
  mapping (uint => uint) private openBallotIdIndex;
  /* Stores the index at which a given ballotId exists in openBallots array */

  struct CastVote {
    uint128 yesVotes;
    uint128 noVotes;
  }

  mapping (uint => mapping (address => CastVote)) private ballotAddressVotes;
  /* Used to store current votes on a given ballotId for an address.  Index position 0 is yesVotes and position 1 is no votes.  Only one of these can be a non-zero value */

  constructor() public CheckERC165() {
    supportedInterfaces[
        this.totalSupply.selector ^
        this.balanceOf.selector ^
        this.allowance.selector ^
        this.approve.selector ^
        bytes4(keccak256("transfer(address,uint256"))^
        this.transferFrom.selector
    ] = true;
  }

  function distribute (address[] _addresses, uint[] _amounts) public onlyMinter returns (bool[]) {
    for (uint i = 0; i < _addresses.length; i++) {
      mint(_addresses[i], _amounts[i]);
      _totalSupply.add(_amounts[i]);
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

  function createBallot (bytes32 _ballotName) public onlyMinter returns (uint ballotId)  {
    maxBallotId++;
    ballots[maxBallotId] = Ballot(false, 0, 0, bytes23(_ballotName));
    ballotIds.push(maxBallotId);
    emit BallotCreated(_ballotName, maxBallotId);
    return maxBallotId;
  }

  event BallotCreated(
    bytes32 ballotName,
    uint indexed ballotId
  );

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

  function showBallot (uint _ballotId) public view returns (bytes32 _ballotName, bool _ballotOpen, uint _ballotYesVotes, uint _ballotNoVotes) {
    return (bytes32(ballots[_ballotId].name), ballots[_ballotId].open, ballots[_ballotId].yesVotes, ballots[_ballotId].noVotes);
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
    emit BallotOpened(_ballotId);
    return true;
  }

  event BallotOpened(
    uint indexed ballotId
  );

  function closeBallot (uint _ballotId) public onlyMinter ballotOpen(_ballotId) returns (bool) {
    ballots[_ballotId].open = false;
    if (openBallotIdIndex[_ballotId] != openBallots.length - 1) {
      openBallots[openBallotIdIndex[_ballotId]] = openBallots[openBallots.length-1];
    }
    openBallots.length--;
    emit BallotClosed(_ballotId);
    return true;
  }

  event BallotClosed(
    uint indexed ballotId
  );

  function getVotesByBallotByAddress (uint _ballotId, address _address) public view validBallot(_ballotId) returns (uint _yesVotes, uint _noVotes) {
    _yesVotes = ballotAddressVotes[_ballotId][_address].yesVotes;
    _noVotes = ballotAddressVotes[_ballotId][_address].noVotes;
  }

  function castVote (uint _ballotId, bool _yesVote) public whitelistedAddy(msg.sender) ballotOpen(_ballotId) returns (bool) {
    require(_balances[msg.sender] > 0);
    if (ballotAddressVotes[_ballotId][msg.sender].yesVotes > 0) {
      if (_yesVote) {
        if (ballotAddressVotes[_ballotId][msg.sender].yesVotes < _balances[msg.sender]) {
          ballots[_ballotId].yesVotes += uint32(_balances[msg.sender]) - uint32(ballotAddressVotes[_ballotId][msg.sender].yesVotes);
          ballotAddressVotes[_ballotId][msg.sender].yesVotes = uint128(_balances[msg.sender]);
        }
      }
      else {
        ballots[_ballotId].yesVotes -= uint32(ballotAddressVotes[_ballotId][msg.sender].yesVotes);
        delete ballotAddressVotes[_ballotId][msg.sender].yesVotes;
        ballots[_ballotId].noVotes += uint32(_balances[msg.sender]);
        ballotAddressVotes[_ballotId][msg.sender].noVotes = uint128(_balances[msg.sender]);
      }
    }
    else if (ballotAddressVotes[_ballotId][msg.sender].noVotes > 0) {
      if (_yesVote) {
        ballots[_ballotId].noVotes -= uint32(ballotAddressVotes[_ballotId][msg.sender].noVotes);
        delete ballotAddressVotes[_ballotId][msg.sender].noVotes;
        ballots[_ballotId].yesVotes += uint32(_balances[msg.sender]);
        ballotAddressVotes[_ballotId][msg.sender].yesVotes = uint128(_balances[msg.sender]);
      }
      else {
        if (ballotAddressVotes[_ballotId][msg.sender].noVotes < _balances[msg.sender]) {
          ballots[_ballotId].noVotes += uint32(_balances[msg.sender]) - uint32(ballotAddressVotes[_ballotId][msg.sender].noVotes);
          ballotAddressVotes[_ballotId][msg.sender].noVotes = uint128(_balances[msg.sender]);
        }
      }
    }
    else {
      if (_yesVote) {
        ballots[_ballotId].yesVotes += uint32(_balances[msg.sender]);
        ballotAddressVotes[_ballotId][msg.sender].yesVotes = uint128(_balances[msg.sender]);
      }
      else {
        ballots[_ballotId].noVotes += uint32(_balances[msg.sender]);
        ballotAddressVotes[_ballotId][msg.sender].noVotes = uint128(_balances[msg.sender]);
      }
    }
    emit VoteCast(msg.sender, _ballotId, _yesVote, _balances[msg.sender]);
    return true;
  }

  event VoteCast(
    address indexed voter,
    uint indexed ballotId,
    bool yesVote,
    uint amount
  );

  /* Transfer function moved here in order to remove cast votes when transferring tokens */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= _balances[msg.sender]);
    require(_to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    for (uint i = 0; i < openBallots.length; i++) {
      if (ballotAddressVotes[openBallots[i]][msg.sender].yesVotes > _balances[msg.sender]) {
        ballots[openBallots[i]].yesVotes -= (uint32(ballotAddressVotes[openBallots[i]][msg.sender].yesVotes) - uint32(_balances[msg.sender]));
        ballotAddressVotes[openBallots[i]][msg.sender].yesVotes = uint128(_balances[msg.sender]);
      }
      else if (ballotAddressVotes[openBallots[i]][msg.sender].noVotes > _balances[msg.sender]) {
        ballots[openBallots[i]].noVotes -= (uint32(ballotAddressVotes[openBallots[i]][msg.sender].noVotes) - uint32(_balances[msg.sender]));
        ballotAddressVotes[openBallots[i]][msg.sender].noVotes = uint128(_balances[msg.sender]);
      }
    }
    emit Transfer(msg.sender, _to, _value);
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
        ballots[openBallots[i]].yesVotes -= (uint32(ballotAddressVotes[openBallots[i]][_from].yesVotes) - uint32(_balances[_from]));
        ballotAddressVotes[openBallots[i]][_from].yesVotes = uint128(_balances[_from]);
      }
      else if (ballotAddressVotes[openBallots[i]][_from].noVotes > _balances[_from]) {
        ballots[openBallots[i]].noVotes -= (uint32(ballotAddressVotes[openBallots[i]][_from].noVotes) - uint32(_balances[_from]));
        ballotAddressVotes[openBallots[i]][_from].noVotes = uint128(_balances[_from]);
      }
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

}
