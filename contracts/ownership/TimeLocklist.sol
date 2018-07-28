pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TimeLocklist is Ownable {

    mapping(address => uint256) public unlockTimelist;
    mapping(address => uint256) public originalTimelist;

    /* This generates a public event on the blockchain that will notify clients */
    event SetUnLockedTime(address _who, uint256 _unlockTime);
    event UnLockAccount(address _who);

    modifier onlyOverTimeTo(address _to) {
        require(block.timestamp > unlockTimelist[_to]);
        _;
    }

    modifier onlyOverTime() {
        require(block.timestamp > unlockTimelist[msg.sender]);
        _;
    }

    modifier onlyUnderTimeTo(address _to) {
        require(block.timestamp <= unlockTimelist[_to]);
        _;
    }

    modifier onlyUnderTime() {
        require(block.timestamp <= unlockTimelist[msg.sender]);
        _;
    }

    function setUnLockTimeAccount(address _to, uint256 _unlocktime) onlyOwner public {
        require(_to != 0x0);

        unlockTimelist[_to] = _unlocktime;
        originalTimelist[_to] = _unlocktime;

        emit SetUnLockedTime(_to, _unlocktime);
    }

    function setUnLockAccount(address _to) onlyOwner onlyUnderTimeTo(_to) public {
        require(_to != 0x0);

        unlockTimelist[_to] = block.timestamp;

        emit UnLockAccount(_to);
    }

    function checkUnlockTimeTo(address _to) public view returns (uint256, uint256) {
        return (unlockTimelist[_to], originalTimelist[_to]);
    }

    function checkUnlockTime() public view returns (uint256, uint256) {
        return (unlockTimelist[msg.sender], originalTimelist[msg.sender]);
    }

}
