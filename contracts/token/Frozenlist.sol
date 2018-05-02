pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Frozenlist is Ownable {

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address _who, bool frozen);

    modifier checkFrozenAccount(address _to) {
        require(!frozenAccount[msg.sender]);                // Check if spender is frozen
        require(!frozenAccount[_to]);                  // Check if recipient is frozen
        _;
    }

    modifier checkFrozenAccountFromTo(address _from, address _to) {
        require(!frozenAccount[_from]);                // Check if spender is frozen
        require(!frozenAccount[_to]);                  // Check if recipient is frozen
        _;
    }

    /*
     * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
     * @param target Address to be frozen
     * @param freeze either to freeze it or not
     */
    function freezeAccount(address _who, bool freeze) onlyOwner public {
        require (_who != 0x0);

        frozenAccount[_who] = freeze;
        emit FrozenFunds(_who, freeze);
    }

}
