// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IGlobalsLike }           from "./interfaces/Interfaces.sol";
import { IPoolPermissionManager } from "./interfaces/IPoolPermissionManager.sol";

import { PoolPermissionManagerStorage } from "./PoolPermissionManagerStorage.sol";

contract PoolPermissionManager is IPoolPermissionManager, PoolPermissionManagerStorage, NonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Permission Levels                                                                                                              ***/
    /**************************************************************************************************************************************/

    uint256 constant PRIVATE        = 0;  // Allow only when on the allowlist (default).
    uint256 constant FUNCTION_LEVEL = 1;  // Allow when function-specific pool bitmaps match.
    uint256 constant POOL_LEVEL     = 2;  // Allow when pool bitmaps match.
    uint256 constant PUBLIC         = 3;  // Allow always.

    /**************************************************************************************************************************************/
    /*** Access Control Modifiers                                                                                                       ***/
    /**************************************************************************************************************************************/

    modifier onlyGovernor() {
        require(msg.sender == admin(), "PPM:NOT_GOVERNOR");

        _;
    }

    modifier onlyPermissionAdmin() {
        require(permissionAdmins[msg.sender], "PPM:NOT_PPM_ADMIN");

        _;
    }

    // TODO: Add operation admin modifier.
    modifier onlyPoolDelegate(address poolManager_) {
        ( address ownedPoolManager_, bool isPoolDelegate_ ) = IGlobalsLike(globals).poolDelegates(msg.sender);

        require(isPoolDelegate_ && ownedPoolManager_ == poolManager_, "PPM:NOT_PD");

        _;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function setLenderBitmaps(address[] calldata lenders_, uint256[] calldata bitmaps_) external override onlyPermissionAdmin {
        require(lenders_.length > 0,                "PPM:SLB:NO_LENDERS");
        require(lenders_.length == bitmaps_.length, "PPM:SLB:LENGTH_MISMATCH");

        for (uint256 i; i < lenders_.length; ++i) {
            lenderBitmaps[lenders_[i]] = bitmaps_[i];
        }

        emit LenderBitmapsSet(lenders_, bitmaps_);
    }

    function setPermissionAdmin(address account_, bool isPermissionAdmin_) external override onlyGovernor {
        permissionAdmins[account_] = isPermissionAdmin_;

        emit PermissionAdminSet(account_, isPermissionAdmin_);
    }

    /**************************************************************************************************************************************/
    /*** Pool Configuration Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function configurePool(
        address            poolManager_,
        uint256            permissionLevel_,
        bytes32[] calldata functionIds_,
        uint256[] calldata poolBitmaps_
    )
        external override onlyPoolDelegate(poolManager_)
    {
        require(poolPermissions[poolManager_] != PUBLIC,    "PPM:CP:PUBLIC_POOL");
        require(permissionLevel_ <= PUBLIC,                 "PPM:CP:INVALID_LEVEL");
        require(functionIds_.length == poolBitmaps_.length, "PPM:CP:LENGTH_MISMATCH");

        for (uint256 i; i < functionIds_.length; ++i) {
            poolBitmaps[poolManager_][functionIds_[i]] = poolBitmaps_[i];
        }

        poolPermissions[poolManager_] = permissionLevel_;

        emit PoolPermissionLevelSet(poolManager_, permissionLevel_);
        emit PoolBitmapsSet(poolManager_, functionIds_, poolBitmaps_);
    }

    function setLenderAllowlist(
        address            poolManager_,
        address[] calldata lenders_,
        bool[]    calldata booleans_
    )
        external override onlyPoolDelegate(poolManager_)
    {
        require(lenders_.length > 0,                 "PPM:SLA:NO_LENDERS");
        require(lenders_.length == booleans_.length, "PPM:SLA:LENGTH_MISMATCH");

        for (uint256 i; i < lenders_.length; ++i) {
            lenderAllowlist[poolManager_][lenders_[i]] = booleans_[i];
        }

        emit LenderAllowlistSet(poolManager_, lenders_, booleans_);
    }

    function setPoolBitmaps(
        address            poolManager_,
        bytes32[] calldata functionIds_,
        uint256[] calldata bitmaps_
    )
        external override onlyPoolDelegate(poolManager_)
    {
        require(functionIds_.length > 0,                "PPM:SPB:NO_FUNCTIONS");
        require(functionIds_.length == bitmaps_.length, "PPM:SPB:LENGTH_MISMATCH");

        for (uint256 i; i < functionIds_.length; ++i) {
            poolBitmaps[poolManager_][functionIds_[i]] = bitmaps_[i];
        }

        emit PoolBitmapsSet(poolManager_, functionIds_, bitmaps_);
    }

    function setPoolPermissionLevel(address poolManager_, uint256 permissionLevel_) external override onlyPoolDelegate(poolManager_) {
        require(poolPermissions[poolManager_] != PUBLIC, "PPM:SPPL:PUBLIC_POOL");
        require(permissionLevel_ <= PUBLIC,              "PPM:SPPL:INVALID_LEVEL");

        poolPermissions[poolManager_] = permissionLevel_;

        emit PoolPermissionLevelSet(poolManager_, permissionLevel_);
    }

    /**************************************************************************************************************************************/
    /*** Permission-related Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function hasPermission(
        address poolManager_,
        address lender_,
        bytes32 functionId_
    )
        external override view returns (bool hasPermission_)
    {
        uint256 permissionLevel_ = poolPermissions[poolManager_];

        // Allow only if the bitmaps match.
        hasPermission_ = _hasPermission(poolManager_, lender_, permissionLevel_, functionId_);
    }

    // TODO: Optimize poolBitmaps SLOADS.
    function hasPermission(
        address            poolManager_,
        address[] calldata lenders_,
        bytes32            functionId_
    )
        external override view returns (bool hasPermission_)
    {
        uint256 permissionLevel_ = poolPermissions[poolManager_];

        for (uint256 i; i < lenders_.length; ++i) {
            if (!_hasPermission(poolManager_, lenders_[i], permissionLevel_, functionId_)) {
                return false;
            }
        }

        hasPermission_ = true;
    }

    function _hasPermission(
        address poolManager_,
        address lender_,
        uint256 permissionLevel_,
        bytes32 functionId_
    )
        internal view returns (bool hasPermission_)
    {
        // Always allow if the pool is public.
        if (permissionLevel_ == PUBLIC) return true;

        // Always allow if the lender is on the allow list.
        if (lenderAllowlist[poolManager_][lender_]) return true;

        // Always deny if the pool is private and the lender is not on the allow list.
        if (permissionLevel_ == PRIVATE) return false;

        // Ignore the function identifier if using pool-level bitmaps.
        if (permissionLevel_ == POOL_LEVEL) functionId_ = bytes32(0);

        uint256 poolBitmap = poolBitmaps[poolManager_][functionId_];

        // Always deny if the pool bitmap has not been set.
        // @AUDIT: Do we also need to check if the lender bitmap is zero?
        if (poolBitmap == 0) return false;

        // Allow only if the bitmaps match.
        hasPermission_ = (poolBitmap & lenderBitmaps[lender_]) == poolBitmap;
    }

}
