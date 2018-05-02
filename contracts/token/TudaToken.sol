pragma solidity ^0.4.21;

import 'openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol';
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract TudaToken is ERC827Token, Pausable {

    string constant public name = "TudaToken"; // solium-disable-line uppercase
    string constant public symbol = "TUDA"; // solium-disable-line uppercase
    uint8 constant public decimals = 8; // solium-disable-line uppercase

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address _who, bool frozen);
    event Burn(address indexed burner, uint256 value);


    modifier checkFrozenAccountTo(address _to) {
        require(!frozenAccount[msg.sender]);           // Check if sender is frozen
        require(!frozenAccount[_to]);                  // Check if recipient is frozen
        _;
    }
    modifier checkFrozenAccountFromTo(address _from, address _to) {
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        _;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function TudaToken(uint256 _initSupply) public {
        require(_initSupply < 0);

        totalSupply_ = _initSupply * (10 ** uint256(decimals));
        if (totalSupply_ > 0) {
            balances[msg.sender] = totalSupply_;
            emit Transfer(0x0, msg.sender, totalSupply_);
        }
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
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

    /**
     * @dev pausable transfers.
     **/

    function transfer(address _to, uint256 _value) public whenNotPaused checkFrozenAccountTo(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused checkFrozenAccountFromTo(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    // spender = 출금계좌
    function approve(address _spender, uint256 _value) public whenNotPaused checkFrozenAccountTo(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused checkFrozenAccountTo(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused checkFrozenAccountTo(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}
