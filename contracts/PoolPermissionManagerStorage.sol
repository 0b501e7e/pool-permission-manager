// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

contract PoolPermissionManagerStorage {

    address public globals;

    mapping(address => bool) public permissionAdmins;

    mapping(address => uint256) public lenderBitmaps;

    mapping(address => uint256) public poolPermissions;

    mapping(address => mapping(address => bool)) public lenderAllowlist;

    mapping(address => mapping(bytes32 => uint256)) public poolBitmaps;

}
