// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

// TODO: Warden actors need adding
// TODO: Should we have a separate proxy storage contract?
// TODO: Interface / Natspec
contract PoolPermissionManager is NonTransparentProxied {

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

    mapping(address => uint256) public lenderBitmaps;
    mapping(address => uint256) public poolBitmaps;

    mapping(address => PoolConfig) public poolConfigs;

    mapping(address => mapping(address => bool)) public poolAllowList;

    mapping(address => mapping(bytes32 => uint256)) public poolFunctionBitmaps;

    /**************************************************************************************************************************************/
    /*** Setters                                                                                                                        ***/
    /**************************************************************************************************************************************/

    function setIsGlobalAllowList(address pool_, bool isGlobalAllowList_) external {
        // TODO: Check caller ACL (Pool Delegate)
        poolConfigs[pool_].isGlobalAllowList = isGlobalAllowList_;
    }

    function setIsPoolFunctionAllowList(address pool_, bool isFunctionAllowList_) external {
        // TODO: Check caller ACL (Pool Delegate)
        // TODO: Require Global allow list to be set first / should we combine ?
        poolConfigs[pool_].isFunctionAllowList = isFunctionAllowList_;
    }

    function setPoolAllowList(address pool_, address user_, bool isAllowed_) external {
        // TODO: Check caller ACL (Pool Delegate)
        // TODO: What validation should be done?
        poolAllowList[pool_][user_] = isAllowed_;
    }

    function setPoolBitmap(address pool_, uint256 bitmap_) external {
        // TODO: Check caller ACL (Pool Delegate)
        // TODO: What validation should be done?
        poolBitmaps[pool_] = bitmap_;
    }

    function setPoolFunctionBitmap(address pool_, bytes32 functionSig_, uint256 bitmap_) external {
        // TODO: Check caller ACL (Pool Delegate)
        // TODO: What validation should be done?
        poolFunctionBitmaps[pool_][functionSig_] = bitmap_;
    }

    function setLenderBitmap(address lender_, uint256 bitmap_) external {
        // TODO: Check caller ACL (PPM Admin)
        // TODO: What validation should be done?
        lenderBitmaps[lender_] = bitmap_;
    }

}
