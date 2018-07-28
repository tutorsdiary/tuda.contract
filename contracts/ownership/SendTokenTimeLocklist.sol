pragma solidity ^0.4.21;

import "./TimeLocklist.sol";

contract SendTokenTimeLockedlist is TimeLocklist {

    mapping(address => uint256) public lockedTokenAmount;
    mapping(address => uint256) public originalTokenAmount;

    /* This generates a public event on the blockchain that will notify clients */
    event sendTokenAmount(address indexed _to, uint256 sendTokenAmount);

    modifier hasLockedTokenAmountTo(address _to) {
        require(lockedTokenAmount[_to] > 0);
        _;
    }

    modifier hasLockedTokenAmount() {
        require(lockedTokenAmount[msg.sender] > 0);
        _;
    }

    function setSendTokenAmount(address _to, uint256 _tokenAmount) onlyOwner public {
        require(_to != 0x0);
        require(_tokenAmount > 0);

        originalTokenAmount[_to] = originalTokenAmount[_to] + _tokenAmount;
        lockedTokenAmount[_to] = lockedTokenAmount[_to] + _tokenAmount;

        emit sendTokenAmount(_to, _tokenAmount);
    }

    function getToken(address _to, uint256 _tokenAmount) hasLockedTokenAmountTo(_to) internal {
        require(_to != 0x0);
        require(_tokenAmount > 0);
        require(lockedTokenAmount[_to] >= _tokenAmount);

        lockedTokenAmount[_to] = lockedTokenAmount[_to] - _tokenAmount;
        emit sendTokenAmount(_to, _tokenAmount);
    }

    function checkHasTokenTo(address _to) public view returns (uint256, uint256, uint256) {
        return (unlockTimelist[_to], lockedTokenAmount[_to], originalTokenAmount[_to]);
    }

    function checkHasToken() public view returns (uint256, uint256, uint256) {
        return (unlockTimelist[msg.sender], lockedTokenAmount[msg.sender], originalTokenAmount[msg.sender]);
    }


}
