pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ownership/SendTokenTimeLocklist.sol";
import "../token/TudaToken.sol";

contract SendLockedTokenContract is SendTokenTimeLockedlist {
    using SafeMath for uint256;

    TudaToken public token;

    event MadeTimeLockContract(address indexed _from, address indexed _to, uint256 sendTokenAmount, uint256 unlockTime);
    event DestructedContract(address indexed _from, address indexed _to, uint256 TokenAmount);
    event CompletedContract(address indexed _to, uint256 TokenAmount);

    constructor(TudaToken _token) public {
        require(_token != address(0));

        token = _token;
    }

    function () external payable {
        require(msg.sender == owner);
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function makeTimeLockContract(address _to, uint256 _amount, uint256 _unlockTime) onlyOwner public {
        require(_to != address(0));
        require(_amount > 0);
        require(_unlockTime > 0);

        setSendTokenAmount(_to, _amount);
        setUnLockTimeAccount(_to, _unlockTime);

        token.transfer(address(this), _amount);

        emit MadeTimeLockContract(msg.sender, _to, _amount, _unlockTime);
    }

    function destructContractFrom(address _from) onlyOwner onlyUnderTimeTo(_from) public {
        require(address(this) != 0x0);
        require(msg.sender != 0x0);
        require(_from != 0x0);

        uint256 amount = lockedTokenAmount[_from];
        token.transferFrom(address(this), msg.sender, amount);

        setUnLockTimeAccount(_from, 0);
        getToken(_from, amount);

        emit DestructedContract(msg.sender, _from, amount);
    }

    function runContractTo(address _to) onlyOwner onlyOverTimeTo(_to) hasLockedTokenAmountTo(_to) public {
        require(address(this) != 0x0);
        require(_to != 0x0);

        uint256 amount = lockedTokenAmount[_to];

        token.transferFrom(address(this), _to, amount);
        getToken(_to, amount);

        emit CompletedContract(_to, amount);
    }

    function runMyContract() public onlyOverTime hasLockedTokenAmount {
        require(address(this) != 0x0);
        require(msg.sender != 0x0);

        uint256 amount = lockedTokenAmount[msg.sender];

        token.transferFrom(address(this), msg.sender, amount);
        getToken(msg.sender, amount);

        emit CompletedContract(msg.sender, amount);
    }

}
