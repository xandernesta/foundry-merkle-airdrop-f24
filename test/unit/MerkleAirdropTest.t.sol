// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;

    bytes32 public merkleRoot = 0x1070fa89ab909d1672646ba27fa8290385b29f61250037ce8e2839f875e07c1e;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32 proofThree = 0x1e15681a1536a349c86a6d15e159eb0176b83923b384a8b224904dbdbf7d80b1;
    bytes32[] proof = [proofOne, proofTwo, proofThree];
    address user;
    uint256 userPrivKey;
    address public gasPayer;
    uint256 gasPayerPrivKey;

    uint256 constant AMOUNT_TO_CLAIM = 25 ether;
    uint256 constant AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;

    function setUp() public {
        if (!isZkSyncChain()) {
            // deploy with a script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.run();
        } else {   
            token = new BagelToken();
            airdrop = new MerkleAirdrop(merkleRoot, token);
        }
        vm.prank(token.owner());
        token.mint(address(airdrop), AMOUNT_TO_MINT);
        (user, userPrivKey) = makeAddrAndKey("user");
        (gasPayer , gasPayerPrivKey) = makeAddrAndKey("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        //grab message digest
        bytes32 messageDigest = airdrop.getMessageHash(address(user), AMOUNT_TO_CLAIM);

        // sign message - cheatcode sign, takes a wallet private key and a message digest and returns v, r, and s
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, messageDigest);

        // gasPayer calls claim using the signed message
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
        console.log("starting user balance: %s", startingBalance);
        console.log("ending user balance: %s", endingBalance);
    }

    function testClaimRevertsIfWrongUserSigns() public {
        bytes32 messageDigest = airdrop.getMessageHash(address(user), AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(gasPayerPrivKey, messageDigest);

        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
    }
}
