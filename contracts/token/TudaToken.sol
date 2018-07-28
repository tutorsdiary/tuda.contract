pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol";
import 'openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol';
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./Frozenlist.sol";

contract TudaToken is Pausable, ERC827Token, Frozenlist, StandardBurnableToken {

    string constant public name = "TudaToken"; // solium-disable-line uppercase
    string constant public symbol = "TUDA"; // solium-disable-line uppercase
    uint8 constant public decimals = 8; // solium-disable-line uppercase

    uint256 public constant INITIAL_SUPPLY = 600000000 * (10 ** uint256(decimals));

    /**
     * Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Force Burns a specific amount of tokens from the target address and decrements allowance
     * @param _from address The address which you want to send tokens from
     * @param _value uint256 The amount of token to be burned
     */
    function burnFromForce(address _from, uint256 _value) onlyOwner public {
        _burn(_from, _value);
    }

    /**
     * pausable transfers.
     **/

    function transfer(address _to, uint256 _value) public whenNotPaused checkFrozenAccount(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused checkFrozenAccountFromTo(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}
