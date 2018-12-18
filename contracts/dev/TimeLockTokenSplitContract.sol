pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../trait/TimeLockTokenSplit.sol";

contract TimeLockTokenSplitContract is TimeLockTokenSplit {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;

    event revokeContract(address _from, address _to, uint256 TokenAmount);
    event releaseContract(address _to, uint256 TokenAmount);

    constructor(address _to, uint256 _totalAmount, uint _splitCount, uint256 _startTime, uint _intervalDays, ERC20 _token) public {
        require(_to != address(0));
        require(_totalAmount > 0);
        require(_splitCount > 0);
        require(_startTime > block.timestamp);
        require(_intervalDays >= 1);
        require(_token != address(0));

        token = _token;

        setLockInfo(_to, _totalAmount, _splitCount, _startTime, _intervalDays);

    }

    function () public onlyOwner payable {

        lockedInfo.currentAmount = lockedInfo.currentAmount.add(msg.value);
        lockedInfo.receivedAmount = lockedInfo.receivedAmount.add(msg.value);
        lockedInfo.currentCount = lockedInfo.currentCount.add(1);
        lockedInfo.lastTime = block.timestamp;

//        uint cnt = lockedInfo.currentCount;
//
//        lockedInfo.transferInfo[cnt].amount = msg.value;
//        lockedInfo.transferInfo[cnt].time = lockedInfo.lastTime;

    }

    function release() isReleased isNotRevoked public {
        _release();
    }

    function forceRelease() onlyOwner public {
        setForceRelease();
        _release();
    }

    function forceTransferToken(uint256 _amount) onlyOwner public {
        _transferAmount(_amount);
    }

    function _release() isReleased private {

        uint256 amount = token.balanceOf(this);

        _transferAmount(amount);
        withdraw(amount);
        setRelease();

        emit releaseContract(lockedInfo.wallet, amount);
    }

    function _transferAmount(uint256 _amount) private {
        uint256 amount = token.balanceOf(this);
        require(amount >= _amount);

        token.safeTransfer(lockedInfo.wallet, _amount);
        withdraw(_amount);

        emit releaseContract(lockedInfo.wallet, _amount);
    }

    function revoke() onlyOwner isNotRevoked isNotReleased public {
        require(address(this) != 0x0);
        require(msg.sender != 0x0);

        uint256 amount = token.balanceOf(this);

        token.safeTransfer(msg.sender, amount);
        withdraw(amount);
        setRevoke();

        emit revokeContract(msg.sender, lockedInfo.wallet, amount);
    }

}
