// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private s_merkleRoot = 0x1070fa89ab909d1672646ba27fa8290385b29f61250037ce8e2839f875e07c1e;
    uint256 private s_amountToTransferToAirdrop = 4 * 25 * 1e18;
    function run() external returns(MerkleAirdrop, BagelToken){
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns(MerkleAirdrop, BagelToken){
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(token)));
        token.mint(token.owner(),s_amountToTransferToAirdrop);
        token.transfer(address(airdrop),s_amountToTransferToAirdrop);
        vm.stopBroadcast();
        return (airdrop,token);
    }
}