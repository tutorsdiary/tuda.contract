pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract TudaToken is ERC827Token, Pausable {

    string public constant name = "TudaToken"; // solium-disable-line uppercase
    string public constant symbol = "TUDA"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    uint256 public maxSupply_;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        require(totalSupply_.add(_amount) <= maxSupply_);
        _;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function TudaToken(string _name, string _symbol, uint8 _decimals, uint256 _initSupply, uint256 maxSupply) public {
        require(_initSupply > 0 && maxSupply > 0 && _initSupply <= maxSupply);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply_ = _initSupply * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        maxSupply_ = maxSupply;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
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
