// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract MerkleAirdrop is EIP712 { 
    using SafeERC20 for IERC20;
    // What it will do
    // Hold a list of addresses
    // Allow an address in the list to claim ERC-20 tokens
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AirdropAlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    uint256 private amount;
    mapping (address claimer => bool claimed ) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address account, uint256 amount);

    constructor(bytes32 _merkleRoot,IERC20 _airdropToken/* , address[] memory _addresses, uint256 _amount */) EIP712(/* name */ "MerkleAirdrop", /* version */ "1"){
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
/*         claimers =_addresses;
        amount =_amount; */

    }
    // Merkle Proofs   
    function claim(address _account, uint256 _amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
       // CEI - Checks, Effects, Interactions
       // Check
       if(s_hasClaimed[_account]){
        revert MerkleAirdrop__AirdropAlreadyClaimed();
       }
       // Verify signature
       if(!_isValidSignature(_account, getMessageHash(_account, _amount), v, r, s)) {
        revert MerkleAirdrop__InvalidSignature();
       }
       // Calculate using account and amount the hash -> which is a leaf node in the tree
       bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot,leaf)){
            revert MerkleAirdrop__InvalidProof();
        }
        // need a way to determine if address has claimed or not to prevent duplicate claims
        s_hasClaimed[_account] = true;
        emit Claim(_account, _amount);
        i_airdropToken.safeTransfer(_account,_amount);
    }

    function _isValidSignature(address _account, bytes32 _messageDigest, uint8 _v, bytes32 _r,bytes32 _s) internal pure returns(bool){ 
        (address actualSigner, ,) = ECDSA.tryRecover(_messageDigest,_v,_r,_s);
        return actualSigner == _account;
    }
    function getMessageHash(address _account, uint256 _amount) public view returns( bytes32){
        return _hashTypedDataV4(
            keccak256(
                abi.encode(MESSAGE_TYPEHASH,AirdropClaim({account: _account, amount: _amount}))
            )
        );
    }
    function getMerkleRoot() external view returns(bytes32){
        return i_merkleRoot;
    }
    function getAirdropToken() external view returns(IERC20){
        return i_airdropToken; 
    }
}