// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title BagelToken
 * @author Xander Nesta
 * @notice ERC-20 Token for use with MerkleAirdrop Contract
 * 
 */
contract BagelToken is ERC20, Ownable{
    // What it will do
    // Token to be claimed by addresses in MerkleAirdrop contract list of addresses
    // 
    constructor() ERC20("Bagel", "BAGEL") Ownable(msg.sender) {
        
    }
    function mint(address _to, uint256 _amount) external onlyOwner /* returns (bool) */ {
        _mint(_to,_amount);
    }
}