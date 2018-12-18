pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../trait/MultiTimeLockTokenSplit.sol";

contract MultiTimeLockTokenSplitContract is MultiTimeLockTokenSplit {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;

    event revokeContract(address _from, address _to, uint256 TokenAmount);
    event releaseContract(address _to, uint256 TokenAmount);

    constructor(ERC20 _token) public {
        require(_token != address(0));
        token = _token;
    }

    function makeTimeLockTokenContract(address _to, uint256 _totalAmount, uint _splitCount, uint256 _startTime, uint _intervalDays) public {
        require(_to != address(0));
        require(_totalAmount > 0);
        require(_splitCount > 0);
        require(_startTime > block.timestamp);
        require(_intervalDays >= 1);

        setLockInfo(_to, _totalAmount, _splitCount, _startTime, _intervalDays);
    }

    function transferTokenToContract(address _to, uint256 _amount) onlyOwner public {
        require(_to != address(0));
        require(timeLockTokenInfo[_to].startTime <= block.timestamp);

        token.safeTransferFrom(msg.sender, address(this), _amount);


        depositTo(_to, _amount);
    }

    function releaseTo(address _to) isReleasedTo(_to) isNotRevokedTo(_to) public {
        _releaseTo(_to);
    }

    function forceReleaseTo(address _to) onlyOwner isNotRevokedTo(_to) public {
        setForceReleaseTo(_to);
        _releaseTo(_to);
    }

    function forceTransferContractTokenTo(address _to, uint256 _amount) onlyOwner isNotRevokedTo(_to) public {
        _transferToken(_to, _amount);
    }

    function _releaseTo(address _to) isReleasedTo(_to) private {
        require(_to != 0x0);
        require(address(this) != 0x0);
        require(msg.sender != 0x0);

        uint256 amount = timeLockTokenInfo[_to].currentAmount;

        token.safeTransfer(_to, amount);
        withdrawFrom(_to, amount);

        emit releaseContract(_to, amount);
    }

    function _transferToken(address _to, uint256 _amount) private {
        require(_to != 0x0);
        require(address(this) != 0x0);
        require(msg.sender != 0x0);
        uint256 amount = timeLockTokenInfo[_to].currentAmount;
        require(amount >= _amount);

        token.safeTransfer(_to, _amount);
        withdrawFrom(_to, amount);

        emit releaseContract(_to, _amount);
    }

    function revokeTo(address _to) onlyOwner isNotRevokedTo(_to) isNotReleasedTo(_to) public {
        require(_to != 0x0);
        require(msg.sender != 0x0);

        uint256 amount = timeLockTokenInfo[_to].currentAmount;

        token.safeTransfer(msg.sender, amount);
        withdrawFrom(_to, amount);

        emit revokeContract(msg.sender, _to, amount);
    }

    function revokeToAmount(address _to, uint256 _amount) onlyOwner isNotReleasedTo(_to) public {
        require(_to != 0x0);
        require(msg.sender != 0x0);
        uint256 amount = timeLockTokenInfo[_to].currentAmount;
        require(amount >= _amount);

        token.safeTransfer(msg.sender, amount);
        withdrawFrom(_to, amount);

    }

    function checkReleased() isReleased public view returns (bool){
        return true;
    }

    function viewTimeLockTokenSummary() onlyOwner public view returns(uint256, uint256, uint256) {
        uint256 current = timeLockTokenTotalCurrentAmount();
        uint256 received = timeLockTokenTotalReceivedAmount();
        uint256 total = timeLockTokenTotalAmount();
        return (current, received, total);
    }

}
