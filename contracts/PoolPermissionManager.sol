// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IGlobalsLike } from "./interfaces/Interfaces.sol";

import { PoolPermissionManagerStorage } from "./PoolPermissionManagerStorage.sol";

// TODO: Interface / Natspec
contract PoolPermissionManager is NonTransparentProxied, PoolPermissionManagerStorage {

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyGovernor() {
        require(msg.sender == admin(), "PPM:NOT_GOV");
        _;
    }

    modifier onlyPermissionsAdmin() {
        require(permissionsAdmins[msg.sender], "PPM:NOT_PPM_ADMIN");
        _;
    }

    // TODO: Add operation admin in the future.
    modifier onlyPoolDelegate(address poolManager) {
        ( address ownedPoolManager, bool isPoolDelegate ) = IGlobalsLike(globals).poolDelegates(msg.sender);

        require(isPoolDelegate && ownedPoolManager == poolManager, "PPM:NOT_PD");
        _;
    }

    /**************************************************************************************************************************************/
    /*** Setters                                                                                                                        ***/
    /**************************************************************************************************************************************/

    function setIsGlobalAllowList(address poolManager_, bool isGlobalAllowList_) external onlyPoolDelegate(poolManager_) {
        poolConfigs[poolManager_].isGlobalAllowList = isGlobalAllowList_;
    }

    function setIsPoolFunctionAllowList(address poolManager_, bool isFunctionAllowList_) external onlyPoolDelegate(poolManager_) {
        // TODO: Require Global allow list to be set first / should we combine ?
        poolConfigs[poolManager_].isFunctionAllowList = isFunctionAllowList_;
    }

    function setPermissionsAdmin(address permissionAdmin_, bool isPermissionsAdmin_) external onlyGovernor {
        permissionsAdmins[permissionAdmin_] = isPermissionsAdmin_;
    }

    function setPoolAllowList(address poolManager_, address user_, bool isAllowed_) external onlyPoolDelegate(poolManager_) {
        // TODO: What validation should be done?
        poolAllowList[poolManager_][user_] = isAllowed_;
    }

    function setPoolBitmap(address poolManager_, uint256 bitmap_) external onlyPoolDelegate(poolManager_) {
        // TODO: What validation should be done?
        poolBitmaps[poolManager_] = bitmap_;
    }

    function setPoolFunctionBitmap(address poolManager_, bytes32 functionSig_, uint256 bitmap_) external onlyPoolDelegate(poolManager_) {
        // TODO: What validation should be done?
        poolFunctionBitmaps[poolManager_][functionSig_] = bitmap_;
    }

    function setLenderBitmap(address lender_, uint256 bitmap_) external onlyPermissionsAdmin {
        // TODO: What validation should be done?
        // TODO: Should de governor be able to call it directly too?
        lenderBitmaps[lender_] = bitmap_;
    }

}
