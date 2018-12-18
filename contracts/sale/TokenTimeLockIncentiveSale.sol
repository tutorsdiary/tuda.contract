pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";

contract TokenTimeLockIncentiveSale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    address[] buyers;

    uint incentiveRate;

    uint256 principalReleaseTime;
    uint256 incentiveReleaseTime;

    struct TimeLockInfo {
        uint256 wallet;
        uint256 ethAmount;
        uint256 principalTokenAmount;
        uint256 incentiveTokenAmount;
    }

    mapping(address => TimeLockInfo) public tokenTimeLockInfo;

    modifier isPrincipalReleasedTo(address _to) {
        require(block.timestamp >= tokenTimeLockInfo[_to].principalReleaseTime);
        _;
    }

    modifier isIncentiveReleasedTo(address _to) {
        require(block.timestamp >= tokenTimeLockInfo[_to].incentiveReleaseTime);
        _;
    }

    modifier isNotPrincipalReleasedTo(address _to) {
        require(_to != address(0));
        require(block.timestamp < tokenTimeLockInfo[_to].principalReleaseTime);
        _;
    }

    modifier isNotIncentiveReleasedTo(address _to) {
        require(_to != address(0));
        require(block.timestamp < tokenTimeLockInfo[_to].principalReleaseTime);
        _;
    }

    constructor(uint256 _incentiveRate) public {
        // solium-disable-next-line security/no-block-members
        require(_incentiveRate >= 0);
        require(_incentiveRate != 0 && _incentiveRate != 15 && _incentiveRate != 25);

        incentiveRate = _incentiveRate;

    }

    function _ETH2TOKEN(uint256 _weiAmount ) internal view onlyWhileOpen returns (uint256){
        require(_weiAmount > 0);

        uint256 oneUSD2Wei = 20000000000000;
        require(oneUSD2Wei > 0);
        return _weiAmount / oneUSD2Wei;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase( address _beneficiary, uint256 _weiAmount ) internal onlyWhileOpen {

        if (incentiveRate == 0) {
            principalReleaseTime = ((closingTime) * 90 days);
            incentiveReleaseTime = ((closingTime) * 999 years);
        } else if (incentiveRate == 15) {
            principalReleaseTime = ((closingTime) * 90 days);
            incentiveReleaseTime = ((closingTime) * 999 years);
        } else if (incentiveRate == 25) {

        }

        super._preValidatePurchase(_beneficiary, _weiAmount);
    }






















    function _setLockInfo(address _to, uint256 _totalAmount, uint _splitCount, uint256 _startTime, uint _intervalDays) onlyOwner internal {
        require(_to != 0x0);
        require(tokenTimeLockInfo[_to].startTime < 1);
        require(_totalAmount > 0);
        require(_splitCount > 0);
        require(_startTime > block.timestamp);
        require(_intervalDays >= 1);

        buyers.push(_to);

        tokenTimeLockInfo[_to].currentAmount = 0;
        tokenTimeLockInfo[_to].transferAmount = 0;
        tokenTimeLockInfo[_to].receivedAmount = 0;
        tokenTimeLockInfo[_to].totalAmount = _totalAmount;
        tokenTimeLockInfo[_to].depositCount = 0;
        tokenTimeLockInfo[_to].currentCount = 0;
        tokenTimeLockInfo[_to].totalCount = _splitCount;
        tokenTimeLockInfo[_to].startTime = _startTime;
        tokenTimeLockInfo[_to].endTime = _startTime + ((_intervalDays * _splitCount) * 1 days);
        tokenTimeLockInfo[_to].lastDepositTime = 0;
        tokenTimeLockInfo[_to].intervalDays = _intervalDays;
        tokenTimeLockInfo[_to].forceRelease = false;
        tokenTimeLockInfo[_to].isReleased = false;
        tokenTimeLockInfo[_to].isRevoked = false;

    }

    function setForceReleaseTo(address _to) onlyOwner isNotRevokedTo(_to) internal {
        require(_to != address(0));
        tokenTimeLockInfo[_to].forceRelease = true;
    }

    function setReleaseTo(address _to) isNotRevokedTo(_to) internal {
        require(_to != address(0));
        tokenTimeLockInfo[_to].forceRelease = true;
        tokenTimeLockInfo[_to].isReleased = true;
    }

    function setRevokeTo(address _to) isNotReleasedTo(_to) isNotRevokedTo(_to) internal {
        require(_to != address(0));
        tokenTimeLockInfo[_to].isRevoked = true;
    }

    function timeLockTokenTotalCurrentAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < buyers.length ; i++) {
            amount = amount.add(tokenTimeLockInfo[buyers[i]].currentAmount);
        }
        return (amount);
    }

    function timeLockTokenTotalReceivedAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < buyers.length ; i++) {
            amount = amount.add(tokenTimeLockInfo[buyers[i]].receivedAmount);
        }
        return (amount);
    }

    function timeLockTokenTotalAmount() internal view returns(uint256) {
        uint256 amount = 0;
        for(uint i=0 ; i < buyers.length ; i++) {
            amount = amount.add(tokenTimeLockInfo[buyers[i]].totalAmount);
        }
        return (amount);
    }

}
