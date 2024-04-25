// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenVesting is Ownable{

    IERC20 public token;
    uint256 public startTime; 

    struct UserVesting {
        uint256 totalTokens; 
        uint256 initialUnlockPercentage; 
        uint256 delayAfterStart; 
        uint256 linearVestingDuration; 
        uint256 claimedTokens; 
    }

    mapping(address => UserVesting) public vestingSchedules;

    constructor() {}


    function init (address _token, uint256 _startTime)  external onlyOwner{
        token = IERC20(_token);
        startTime = _startTime;
    }
     function setStartTime ( uint256 _startTime)   external onlyOwner{
        startTime = _startTime;
    }

    function setMultipleUserVesting(
            address[] calldata _users,
            uint256[] calldata _totalTokens,
            uint256[] calldata _initialUnlockPercentages,
            uint256[] calldata _delaysAfterStart,
            uint256[] calldata _linearVestingDurations,
            uint256[] calldata _claimedTokens
        ) external onlyOwner {
            require(
                _users.length == _totalTokens.length &&
                _users.length == _initialUnlockPercentages.length
                && _users.length == _delaysAfterStart.length 
                && _users.length == _linearVestingDurations.length,
                "Array lengths must be equal"
                );

        for (uint256 i = 0; i < _users.length; i++) {
            setUserVesting( _users[i],  _totalTokens[i],  _initialUnlockPercentages[i], 
             _delaysAfterStart[i],  _linearVestingDurations[i],_claimedTokens[i]);
        }
    }

    function setUserVesting(address _user, uint256 _totalTokens, uint256 _initialUnlockPercentage,
     uint256 _delayAfterStart, uint256 _linearVestingDuration,uint256 _claimedTokens) public onlyOwner {
        vestingSchedules[_user] = UserVesting({
            totalTokens: _totalTokens,
            initialUnlockPercentage: _initialUnlockPercentage,
            delayAfterStart: _delayAfterStart,
            linearVestingDuration: _linearVestingDuration,
            claimedTokens: _claimedTokens
        });
    }
     
    
    function calculateClaimableTokens(address _user) public view returns (uint256) {
        UserVesting storage vesting = vestingSchedules[_user];
        if (block.timestamp < startTime) {
            return 0; 
        }

        uint256 timeElapsed = block.timestamp - startTime;
        uint256 initUnlockClaimable = 0;
        uint256 linearClaimable = 0;

        if (timeElapsed >= 0) {
            initUnlockClaimable = (vesting.totalTokens * vesting.initialUnlockPercentage) / 1000;
        }

        if (timeElapsed > vesting.delayAfterStart) {
            uint256 timeSinceStartOfLinearVesting = timeElapsed - (vesting.delayAfterStart );
            uint256 linearVestingPeriodInSeconds = vesting.linearVestingDuration ;
            uint256 totalLinearVestingTokens = vesting.totalTokens - initUnlockClaimable; 
            uint256 canClaimable = (totalLinearVestingTokens * timeSinceStartOfLinearVesting) / linearVestingPeriodInSeconds;
            linearClaimable = canClaimable > totalLinearVestingTokens ? totalLinearVestingTokens : canClaimable;
        }

        return initUnlockClaimable + linearClaimable - vesting.claimedTokens;
    }
    
    function claimTokens() external {
        uint256 claimable = calculateClaimableTokens(msg.sender);
        require(claimable > 0, "No claimable tokens");

        vestingSchedules[msg.sender].claimedTokens += claimable;
        require(token.transfer(msg.sender, claimable), "Token transfer failed");
        
    }

    function withdrawTokens(address _token,uint256 amount)  external onlyOwner {
        uint256 contractBalance = IERC20(_token).balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient balance in contract");

        require(IERC20(_token).transfer(msg.sender, amount), "Token transfer failed");
    }

}