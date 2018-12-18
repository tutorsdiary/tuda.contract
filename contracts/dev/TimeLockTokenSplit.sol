pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract TimeLockTokenSplit is Ownable {
    using SafeMath for uint256;

    struct TransferInfo {
        uint256 amount;
        uint256 time;
    }

    struct TimeLockInfo {
        address wallet;
        uint256 currentAmount;
        uint256 transferAmount;
        uint256 receivedAmount;
        uint256 totalAmount;
        uint currentCount;
        uint totalCount;
        uint256 startTime;
        uint256 lastTime;
        uint256 endTime;
        uint intervalDays;
        TransferInfo[] depositHistory;
        TransferInfo[] withdrawHistory;
        bool forceRelease;
        bool isReleased;
        bool isRevoked;
    }

    TimeLockInfo lockedInfo;

    /* This generates a public event on the blockchain that will notify clients */

    modifier isReleased() {
        require(lockedInfo.isReleased
            || lockedInfo.forceRelease
            || block.timestamp >= lockedInfo.endTime);
        _;
    }

    modifier isNotReleased() {
        require(!lockedInfo.isReleased
            && !lockedInfo.forceRelease
            && block.timestamp < lockedInfo.endTime);
        _;
    }

    modifier isRevoked() {
        require(lockedInfo.isRevoked);
        _;
    }

    modifier isNotRevoked() {
        require(!lockedInfo.isRevoked);
        _;
    }

    modifier onlyOverTime() {
        require(block.timestamp > lockedInfo.endTime);
        _;
    }

    modifier onlyUnderTime() {
        require(block.timestamp <= lockedInfo.endTime);
        _;
    }

    function setLockInfo(address _to, uint256 _totalAmount, uint _splitCount, uint256 _startTime, uint _intervalDays) onlyOwner internal {
        require(_to != 0x0);
        require(_totalAmount > 0);
        require(_splitCount > 0);
        require(_startTime > block.timestamp);
        require(_intervalDays >= 1);

        lockedInfo.wallet = _to;
        lockedInfo.currentAmount = 0;
        lockedInfo.transferAmount = 0;
        lockedInfo.receivedAmount = 0;
        lockedInfo.totalAmount = _totalAmount;
        lockedInfo.currentCount = 0;
        lockedInfo.totalCount = _splitCount;
        lockedInfo.startTime = _startTime;
        lockedInfo.lastTime = _startTime;
        lockedInfo.endTime = _startTime + (1 days * _intervalDays);
        lockedInfo.intervalDays = _intervalDays;
        lockedInfo.forceRelease = false;
        lockedInfo.isReleased = false;
        lockedInfo.isRevoked = false;

    }

    function depositTo(uint256 _amount) internal {
        require(_amount > 0);

        lockedInfo.currentAmount = lockedInfo.currentAmount.add(_amount);
        lockedInfo.depositHistory.push(TransferInfo(_amount, block.timestamp));
    }

    function withdraw(uint256 _amount) isNotRevoked internal {
        require(_amount > 0);

        lockedInfo.transferAmount = lockedInfo.transferAmount.add(_amount);
        lockedInfo.currentAmount = lockedInfo.currentAmount.sub(_amount);
        lockedInfo.withdrawHistory.push(TransferInfo(_amount, block.timestamp));
    }

    function setForceRelease() onlyOwner isNotRevoked public {
        lockedInfo.forceRelease = true;
    }

    function setRelease() isNotRevoked internal {
        lockedInfo.forceRelease = true;
    }

    function setRevoke() isNotReleased isNotRevoked internal {
        lockedInfo.isRevoked = true;
    }

}
