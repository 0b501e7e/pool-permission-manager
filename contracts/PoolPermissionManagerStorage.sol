// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { IPoolPermissionManagerStorage } from "./interfaces/IPoolPermissionManagerStorage.sol";

contract PoolPermissionManagerStorage is IPoolPermissionManagerStorage {

    address public override globals;

    mapping(address => bool) public override permissionAdmins;

    mapping(address => uint256) public override lenderBitmaps;

    mapping(address => uint256) public override poolPermissions;

    mapping(address => mapping(address => bool)) public override lenderAllowlist;

    mapping(address => mapping(bytes32 => uint256)) public override poolBitmaps;

}
