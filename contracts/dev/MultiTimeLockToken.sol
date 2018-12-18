pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract MultiTimeLockToken is  Ownable {
    using SafeMath for uint256;

    struct TransferInfo {
        uint256 amount;
        uint256 time;
    }

    struct TimeLockInfo {
        uint256 currentAmount;
        uint256 transferAmount;
        uint256 receivedAmount;
        uint256 totalAmount;
        uint currentCount;
        uint totalCount;
        uint256 startTime;
        uint256 endTime;
        uint depositCount;
        uint256 lastDepositTime;
        uint intervalDays;
        TransferInfo[] depositHistory;
        TransferInfo[] withdrawHistory;
        bool forceRelease;
        bool isReleased;
        bool isRevoked;
    }

    address[] members;
    mapping(address => TimeLockInfo) public timeLockTokenInfo;

    modifier isReleased() {
        TimeLockInfo storage lInfo = timeLockTokenInfo[msg.sender];
        require(block.timestamp >= lInfo.endTime
            || lInfo.isReleased
            || lInfo.forceRelease );
        _;
    }

    modifier isReleasedTo(address _to) {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        require(block.timestamp >= lInfo.endTime
            || lInfo.isReleased
            || lInfo.forceRelease );
        _;
    }

    modifier isNotReleasedTo(address _to) {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        require(block.timestamp < lInfo.endTime
                && !lInfo.isReleased
                && !lInfo.forceRelease );
        _;
    }

    modifier isRevokedTo(address _to) {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        require(lInfo.isRevoked);
        _;
    }

    modifier isNotRevokedTo(address _to) {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        require(!lInfo.isRevoked);
        _;
    }

    function setLockInfo(address _to, uint256 _totalAmount, uint _splitCount, uint256 _startTime, uint _intervalDays) onlyOwner internal {
        require(_to != 0x0);
        require(timeLockTokenInfo[_to].startTime < 1);
        require(_totalAmount > 0);
        require(_splitCount > 0);
        require(_startTime > block.timestamp);
        require(_intervalDays >= 1);

        members.push(_to);

        timeLockTokenInfo[_to].currentAmount = 0;
        timeLockTokenInfo[_to].transferAmount = 0;
        timeLockTokenInfo[_to].receivedAmount = 0;
        timeLockTokenInfo[_to].totalAmount = _totalAmount;
        timeLockTokenInfo[_to].depositCount = 0;
        timeLockTokenInfo[_to].currentCount = 0;
        timeLockTokenInfo[_to].totalCount = _splitCount;
        timeLockTokenInfo[_to].startTime = _startTime;
        timeLockTokenInfo[_to].endTime = _startTime + ((_intervalDays * _splitCount) * 1 days);
        timeLockTokenInfo[_to].lastDepositTime = 0;
        timeLockTokenInfo[_to].intervalDays = _intervalDays;
        timeLockTokenInfo[_to].forceRelease = false;
        timeLockTokenInfo[_to].isReleased = false;
        timeLockTokenInfo[_to].isRevoked = false;

    }

    function depositTo(address _to, uint256 _amount) internal {
        require(_to != address(0));
        require(_amount > 0);

        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        require(_amount+lInfo.receivedAmount <= lInfo.totalAmount);

        lInfo.receivedAmount = lInfo.receivedAmount.add(_amount);
        lInfo.currentAmount = lInfo.currentAmount.add(_amount);
        lInfo.depositCount = lInfo.depositCount.add(1);
        lInfo.currentCount = lInfo.receivedAmount.div(lInfo.totalAmount).mul(lInfo.totalCount);
        lInfo.lastDepositTime = block.timestamp;

        TransferInfo memory depositInfo = TransferInfo(_amount, lInfo.lastDepositTime);

        lInfo.depositHistory.push(depositInfo);
    }

    function withdrawFrom(address _from, uint256 _amount) internal {
        require(_from != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_from];
        require(lInfo.currentAmount >= _amount);

        lInfo.transferAmount = lInfo.transferAmount.add(_amount);
        lInfo.currentAmount = lInfo.currentAmount.sub(_amount);

        TransferInfo memory withdrawHistory = TransferInfo(_amount, block.timestamp);

        lInfo.withdrawHistory.push(withdrawHistory);
    }

    function setForceReleaseTo(address _to) onlyOwner isNotRevokedTo(_to) internal {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        lInfo.forceRelease = true;
    }

    function setReleaseTo(address _to) isNotRevokedTo(_to) internal {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        lInfo.forceRelease = true;
        lInfo.isReleased = true;
    }

    function setRevokeTo(address _to) isNotReleasedTo(_to) isNotRevokedTo(_to) internal {
        require(_to != address(0));
        TimeLockInfo storage lInfo = timeLockTokenInfo[_to];
        lInfo.isRevoked = true;
    }

    function timeLockTokenTotalCurrentAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < members.length ; i++) {
            amount = amount.add(timeLockTokenInfo[members[i]].currentAmount);
        }
        return (amount);
    }

    function timeLockTokenTotalReceivedAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < members.length ; i++) {
            amount = amount.add(timeLockTokenInfo[members[i]].receivedAmount);
        }
        return (amount);
    }

    function timeLockTokenTotalAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < members.length ; i++) {
            amount = amount.add(timeLockTokenInfo[members[i]].totalAmount);
        }
        return (amount);
    }

}
