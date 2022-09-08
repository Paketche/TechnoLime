// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract BalanceHolder is Ownable {

    function getBalance() external view onlyOwner returns (uint){
        return address(this).balance;
    }

    function withdrawFunds(uint amount) external onlyOwner {
        require(this.getBalance() >= amount, "Insufficient Funds");
        payable(msg.sender).transfer(amount);
    }
}