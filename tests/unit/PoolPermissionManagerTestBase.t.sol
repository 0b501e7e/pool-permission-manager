// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManager }            from "../../contracts/PoolPermissionManager.sol";
import { PoolPermissionManagerInitializer } from "../../contracts/PoolPermissionManagerInitializer.sol";

import { GlobalsMock } from "../utils/Mocks.sol";
import { TestBase }    from "../utils/TestBase.sol";

// TODO: Add checks for emitted events.
contract PoolPermissionManagerTestBase is TestBase {

    address governor         = makeAddr("governor");
    address lender           = makeAddr("lender");
    address operationalAdmin = makeAddr("operationalAdmin");
    address permissionAdmin  = makeAddr("permissionAdmin");
    address poolDelegate     = makeAddr("poolDelegate");
    address poolManager      = makeAddr("poolManager");

    address implementation = address(new PoolPermissionManager());
    address initializer    = address(new PoolPermissionManagerInitializer());

    bytes32 functionId = "P:deposit";

    address[] lenders;
    uint256[] bitmaps;
    bool   [] booleans;
    bytes32[] functionIds;

    GlobalsMock           globals;
    PoolPermissionManager ppm;

    function setUp() public virtual {
        globals = new GlobalsMock();

        globals.__setGovernor(governor);
        globals.__setOperationalAdmin(operationalAdmin);
        globals.__setOwnedPoolManager(poolDelegate, poolManager, true);

        ppm = PoolPermissionManager(address(new NonTransparentProxy(governor, address(initializer))));

        vm.startPrank(governor);
        PoolPermissionManagerInitializer(address(ppm)).initialize(implementation, address(globals));
        ppm.setPermissionAdmin(permissionAdmin, true);
        vm.stopPrank();
    }

    function generateBitmap(uint8[2] memory indices_) internal pure returns (uint256 bitmap_) {
        for (uint8 i = 0; i < indices_.length; i++) {
            bitmap_ |= (1 << indices_[i]);
        }
    }

    function generateBitmap(uint8[3] memory indices_) internal pure returns (uint256 bitmap_) {
        for (uint8 i = 0; i < indices_.length; i++) {
            bitmap_ |= (1 << indices_[i]);
        }
    }

}
