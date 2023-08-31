// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

contract PoolPermissionManagerStorage {
    
    /**************************************************************************************************************************************/
    /*** Structs                                                                                                                        ***/
    /**************************************************************************************************************************************/

    struct PoolConfig {
        bool isGlobalAllowList;
        bool isFunctionAllowList;
    }

    /**************************************************************************************************************************************/
    /*** Storage                                                                                                                        ***/
    /**************************************************************************************************************************************/

    address public globals;

    mapping(address => bool) public permissionsAdmins;

    mapping(address => uint256) public lenderBitmaps;
    mapping(address => uint256) public poolBitmaps;

    mapping(address => PoolConfig) public poolConfigs;

    mapping(address => mapping(address => bool)) public poolAllowList;

    mapping(address => mapping(bytes32 => uint256)) public poolFunctionBitmaps;
    
}
