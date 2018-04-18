pragma solidity ^0.4.16;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface token { function transfer(address receiver, uint amount) external; }

contract Crowdsale is usingOraclize {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    uint ethUsd;			// usd price per ether
    uint discountRate;
    uint premiumRate;

    // 투자자 목록
    struct investorInfo {
        uint amount;			// total token amount
        uint sendCount;			// send token count (last count is four...)
        uint discountRate;
        uint premiumRate;
        uint investDate;
    }
    mapping (address => investorInfo) investors;
    address[] investorAddress;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
    * Constrctor function
    *
    * Setup the owner
    */
    function Crowdsale (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint tokenCostOfEachEther,
        address addressOfTokenUsedAsReward,
        uint ethDiscountRate,
        uint tokenPremiumRate
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = tokenCostOfEachEther * 10;					// 10 token per ether
        tokenReward = token(addressOfTokenUsedAsReward);
        discountRate = tokenDiscountRate;
        premiumRate = tokenPremiumRate;
    }

    /**
    * Fallback function
    *
    * The function without name is the default function that is called whenever anyone sends funds to a contract
    */
    function () payable public {
        require(!crowdsaleClosed);

        uint amount = msg.value;

        // amount by discountRate
        uint256 cashbagEthAmount = amount * (discountRate / 100);
        uint256 investAmount = amount - cashbagEthAmount;

        balanceOf[msg.sender] += investAmount;
        amountRaised += investAmount;

        // 투자자 목록 저장
        investorInfo ii = investorInfo(investAmount, 0, discountRate, premiumRate, now);
        investors[msg.sender] = ii;
        investorAddress.push(msg.sender);

        // transfer eth from msg.sender to owner
        emit FundTransfer(msg.sender, investAmount, true);

        // cashbag eth from owner to msg.sender by discountRate
        emit Transfer(0, this, cashbagEthAmount);
        emit Transfer(this, msg.sender, cashbagEthAmount);
    }

    modifier afterDeadline() {
        if (now >= deadline)
        _;
    }

    /**
    * Check if goal was reached
    *
    * Checks if the goal or time limit has been reached and ends the campaign
    */
    function checkGoalReached() afterDeadline onlyOwner public {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
    * Withdraw the funds
    *
    * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
    * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
    * the amount they contributed.
    */
    function safeWithdrawal() afterDeadline onlyOwner public {
        if (!fundingGoalReached) {
            // return eth to investor
            uint len = investorAddress.length;
            for (uint8 i=0; i<len; i++){
                uint ethAmount = balanceOf[investorAddress[i]];
                balanceOf[investorAddress[i]] = 0;
                if (ethAmount > 0) {
                    if (investorAddress[i].send(ethAmount)) {
                        emit FundTransfer(investorAddress[i], ethAmount, false);
                    } else {
                        balanceOf[investorAddress[i]] = amount;
                    }
                }
            }
        }

        if (fundingGoalReached) {
            oraclize_query("WolframAlpha", "1 eth to usd");
        }
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) {
            revert();
        }

        // usd per ether
        ethUsd = result;

        if (beneficiary.send(amountRaised)) {
            // token transfer to investor's address
            uint len = investorAddress.length;
            for (uint8 i=0; i<len; i++){
                investorInfo investor = investors[investorAddress[i]];
                uint totalEthAmount = investor.amount;
                uint sendCount = investor.sendCount;
                uint tokenPremiumRate = investor.premiumRate;
                uint tokenInvestDate = investor.investDate;

                // check send token date
                if (now >= (tokenInvestDate + ((sendCount + 1) * 30 days)) {
                    // send 25% amount
                    uint ethAmount = totalEthAmount / 4;

                    if (investor.sendCount < 4) {
                        uint256 tokenAmount = (ethAmount * price * ethUsd) * (1 + (tokenPremiumRate / 100));
                        tokenReward.transfer(investorAddress[i], tokenAmount);

                        investor.sendCount += 1;
                    }
                }
            }

            // eth transfer to beneficiary
            emit FundTransfer(beneficiary, amountRaised, false);
        } else {
            //If we fail to send the funds to beneficiary, unlock funders balance
            fundingGoalReached = false;
        }
    }

    /// @notice Kill contract by myself
    function kill() onlyOwner public {
        require(owner == msg.sender);

        selfdestruct(owner);
    }
}
