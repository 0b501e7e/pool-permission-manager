// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManager }            from "../../contracts/PoolPermissionManager.sol";
import { PoolPermissionManagerInitializer } from "../../contracts/PoolPermissionManagerInitializer.sol";

import { GlobalsMock } from "../utils/Mocks.sol";
import { TestBase }    from "../utils/TestBase.sol";

// TODO: Add checks for emitted events.
contract PoolPermissionManagerTestBase is TestBase {

    address governor        = makeAddr("governor");
    address lender          = makeAddr("lender");
    address permissionAdmin = makeAddr("permissionAdmin");
    address poolDelegate    = makeAddr("poolDelegate");
    address poolManager     = makeAddr("poolManager");

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
        globals.__setPoolDelegate(poolManager, true);

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

contract SetImplementationTests is PoolPermissionManagerTestBase {

    function test_setImplementation_unauthorized() external {
        vm.expectRevert("NTP:SI:NOT_ADMIN");
        NonTransparentProxy(address(ppm)).setImplementation(address(0x1));
    }

    function test_setImplementation_success() external {
        address newImplementation = address(new PoolPermissionManager());

        assertEq(ppm.implementation(), implementation);

        vm.prank(governor);
        NonTransparentProxy(address(ppm)).setImplementation(newImplementation);

        assertEq(ppm.implementation(), newImplementation);
    }

}

contract FallbackTests is PoolPermissionManagerTestBase {

    function test_fallback_noCode() external {
        address newImplementation = makeAddr("notContract");

        vm.prank(governor);
        NonTransparentProxy(address(ppm)).setImplementation(newImplementation);

        vm.expectRevert("NTP:F:NO_CODE_ON_IMPLEMENTATION");
        ppm.implementation();
    }

}

contract SetLenderBitmapsTests is PoolPermissionManagerTestBase {

    function test_setLenderBitmaps_unauthorized() external {
        vm.expectRevert("PPM:NOT_PPM_ADMIN");
        ppm.setLenderBitmaps(lenders, bitmaps);
    }

    function test_setLenderBitmaps_empty() external {
        vm.prank(permissionAdmin);
        vm.expectRevert("PPM:SLB:NO_LENDERS");
        ppm.setLenderBitmaps(lenders, bitmaps);
    }

    function test_setLenderBitmaps_mismatch() external {
        lenders.push(lender);

        vm.prank(permissionAdmin);
        vm.expectRevert("PPM:SLB:LENGTH_MISMATCH");
        ppm.setLenderBitmaps(lenders, bitmaps);
    }

    function test_setLenderBitmaps_success() external {
        lenders.push(lender);
        bitmaps.push(generateBitmap([0, 2]));

        assertEq(ppm.lenderBitmaps(lender), 0);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        assertEq(ppm.lenderBitmaps(lender), generateBitmap([0, 2]));
    }

    function test_setLenderBitmaps_batch() external {
        lenders.push(address(1));
        lenders.push(address(2));
        lenders.push(address(3));

        bitmaps.push(generateBitmap([0, 1]));
        bitmaps.push(generateBitmap([1, 4]));
        bitmaps.push(generateBitmap([0, 1, 2]));

        assertEq(ppm.lenderBitmaps(address(1)), 0);
        assertEq(ppm.lenderBitmaps(address(2)), 0);
        assertEq(ppm.lenderBitmaps(address(3)), 0);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        assertEq(ppm.lenderBitmaps(address(1)), generateBitmap([0, 1]));
        assertEq(ppm.lenderBitmaps(address(2)), generateBitmap([1, 4]));
        assertEq(ppm.lenderBitmaps(address(3)), generateBitmap([0, 1, 2]));
    }

}

contract SetPermisionAdminTests is PoolPermissionManagerTestBase {

    function test_setPermissionAdmin_unauthorized() external {
        vm.expectRevert("PPM:NOT_GOVERNOR");
        ppm.setPermissionAdmin(address(1), true);
    }

    function test_setPermissionAdmin_success() external {
        assertEq(ppm.permissionAdmins(address(1)), false);

        vm.prank(governor);
        ppm.setPermissionAdmin(address(1), true);

        assertEq(ppm.permissionAdmins(address(1)), true);
    }

}

contract SetLenderAllowlistTests is PoolPermissionManagerTestBase {

    function test_setLenderAllowlist_unauthorized() external {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        ppm.setLenderAllowlist(poolManager, lenders, booleans);
    }

    function test_setLenderAllowlist_empty() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SLA:NO_LENDERS");
        ppm.setLenderAllowlist(poolManager, lenders, booleans);
    }

    function test_setLenderAllowlist_mismatch() external {
        lenders.push(lender);

        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SLA:LENGTH_MISMATCH");
        ppm.setLenderAllowlist(poolManager, lenders, booleans);
    }

    function test_setLenderAllowlist_success() external {
        lenders.push(lender);
        booleans.push(true);

        assertFalse(ppm.lenderAllowlist(poolManager, lender));

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        assertTrue(ppm.lenderAllowlist(poolManager, lender));
    }

    function test_setLenderAllowlist_batch() external {
        lenders.push(address(1));
        lenders.push(address(2));
        lenders.push(address(3));

        booleans.push(true);
        booleans.push(false);
        booleans.push(true);

        assertEq(ppm.lenderAllowlist(poolManager, address(1)), false);
        assertEq(ppm.lenderAllowlist(poolManager, address(2)), false);
        assertEq(ppm.lenderAllowlist(poolManager, address(3)), false);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        assertEq(ppm.lenderAllowlist(poolManager, address(1)), true);
        assertEq(ppm.lenderAllowlist(poolManager, address(2)), false);
        assertEq(ppm.lenderAllowlist(poolManager, address(3)), true);
    }

}

contract SetPoolBitmapsTests is PoolPermissionManagerTestBase {

    function test_setPoolBitmaps_unauthorized() external {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);
    }

    function test_setPoolBitmaps_empty() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SPB:NO_FUNCTIONS");
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);
    }

    function test_setPoolBitmaps_mismatch() external {
        functionIds.push(functionId);

        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SPB:LENGTH_MISMATCH");
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);
    }

    function test_setPoolBitmaps_success() external {
        functionIds.push(functionId);
        bitmaps.push(generateBitmap([0, 2]));

        assertEq(ppm.poolBitmaps(poolManager, functionId), 0);

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        assertEq(ppm.poolBitmaps(poolManager, functionId), generateBitmap([0, 2]));
    }

    function test_setPoolBitmaps_batch() external {
        functionIds.push("P:deposit");
        functionIds.push("P:mint");
        functionIds.push("P:withdraw");
        functionIds.push("P:redeem");

        bitmaps.push(generateBitmap([0, 1]));
        bitmaps.push(generateBitmap([0, 2]));
        bitmaps.push(generateBitmap([2, 3, 4]));
        bitmaps.push(generateBitmap([1, 2, 3]));

        assertEq(ppm.poolBitmaps(poolManager, "P:deposit"),  0);
        assertEq(ppm.poolBitmaps(poolManager, "P:mint"),     0);
        assertEq(ppm.poolBitmaps(poolManager, "P:withdraw"), 0);
        assertEq(ppm.poolBitmaps(poolManager, "P:redeem"),   0);

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        assertEq(ppm.poolBitmaps(poolManager, "P:deposit"),  generateBitmap([0, 1]));
        assertEq(ppm.poolBitmaps(poolManager, "P:mint"),     generateBitmap([0, 2]));
        assertEq(ppm.poolBitmaps(poolManager, "P:withdraw"), generateBitmap([2, 3, 4]));
        assertEq(ppm.poolBitmaps(poolManager, "P:redeem"),   generateBitmap([1, 2, 3]));
    }

}

contract SetPoolPermissionLevelTests is PoolPermissionManagerTestBase {

    function test_setPoolPermissionLevel_unauthorized() external {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        ppm.setPoolPermissionLevel(poolManager, 3);
    }

    function test_setPoolPermissionLevel_public() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 3);

        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SPPL:PUBLIC_POOL");
        ppm.setPoolPermissionLevel(poolManager, 0);
    }

    function test_setPoolPermissionLevel_invalid() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PPM:SPPL:INVALID_LEVEL");
        ppm.setPoolPermissionLevel(poolManager, 4);
    }

    function test_setPoolPermissionLevel_success() external {
        assertEq(ppm.poolPermissions(poolManager), 0);

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        assertEq(ppm.poolPermissions(poolManager), 1);
    }

    function testFuzz_setPoolPermissionLevel(uint256 oldPermissionLevel, uint256 newPermissionLevel) external {
        oldPermissionLevel = bound(oldPermissionLevel, 0, 3);
        newPermissionLevel = bound(newPermissionLevel, 0, 3);

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, oldPermissionLevel);

        if (oldPermissionLevel == 3) {
            vm.expectRevert("PPM:SPPL:PUBLIC_POOL");
        }

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, newPermissionLevel);

        assertEq(ppm.poolPermissions(poolManager), oldPermissionLevel == 3 ? oldPermissionLevel : newPermissionLevel);
    }

}

contract HasPermissionTests is PoolPermissionManagerTestBase {

    /**************************************************************************************************************************************/
    /*** Private Permission Level                                                                                                       ***/
    /**************************************************************************************************************************************/

    function test_hasPermission_private_unauthorized() external {
        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_private_whitelisted() external {
        lenders.push(lender);
        booleans.push(true);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertTrue(hasPermission);
    }

    function testFuzz_hasPermission_private_whitelisted(address poolManager_, address lender_, bytes32 functionId_) external {
        globals.__setPoolDelegate(poolManager_, true);

        lenders.push(lender_);
        booleans.push(true);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager_, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager_, lender_, functionId_);

        assertTrue(hasPermission);
    }

    function testFuzz_hasPermission_multiLender_private_whitelisted(
        address poolManager_,
        address[] calldata lenders_,
        bytes32 functionId_
    )
        external
    {
        vm.assume(lenders_.length > 1);

        globals.__setPoolDelegate(poolManager_, true);

        lenders = lenders_;

        // Set all lenders, except last one to true
        for (uint256 i; i < lenders.length - 1; ++i) {
            booleans.push(true);
        }
        booleans.push(false);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager_, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager_, lenders_, functionId_);

        // Since there's at least one lender without permission, the check should fail.
        assertFalse(hasPermission);

        booleans[booleans.length - 1] = true;

        // Authorize last lender
        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager_, lenders, booleans);

        hasPermission = ppm.hasPermission(poolManager_, lenders_, functionId_);

        // Permission now is allowed.
        assertTrue(hasPermission);
    }

    function testFuzz_hasPermission_private_unauthorized(address poolManager_, address lender_, bytes32 functionId_) external {
        bool hasPermission = ppm.hasPermission(poolManager_, lender_, functionId_);

        assertFalse(hasPermission);
    }

    /**************************************************************************************************************************************/
    /*** Function Permission Level                                                                                                      ***/
    /**************************************************************************************************************************************/

    function test_hasPermission_functionLevel_whitelisted() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        lenders.push(lender);
        booleans.push(true);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertTrue(hasPermission);
    }

    function testFuzz_hasPermission_functionLevel_multiLender_whitelisted(address[] calldata lenders_) external {
        vm.assume(lenders_.length > 1);

        lenders = lenders_;

        // Set all lenders, except last one to true
        for (uint256 i; i < lenders.length - 1; ++i) {
            booleans.push(true);
        }

        booleans.push(false);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager, lenders_, functionId);

        // Since there's at least one lender without permission, the check should fail.
        assertFalse(hasPermission);

        booleans[booleans.length - 1] = true;

        // Authorize last lender
        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        hasPermission = ppm.hasPermission(poolManager, lenders_, functionId);

        // Permission now is allowed.
        assertTrue(hasPermission);
    }

    function test_hasPermission_functionLevel_zeroPoolBitmap() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_functionLevel_zeroLenderBitmap() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        functionIds.push(functionId);
        bitmaps.push(generateBitmap([0, 1]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_functionLevel_mismatch() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        functionIds.push(functionId);
        bitmaps.push(generateBitmap([0, 1]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        lenders.push(lender);
        bitmaps[0] = generateBitmap([0, 2, 3]);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_functionLevel_match() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        functionIds.push(functionId);
        bitmaps.push(generateBitmap([0, 1]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        lenders.push(lender);
        bitmaps[0] = generateBitmap([0, 1, 3]);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertTrue(hasPermission);
    }

    function test_hasPermission_multiLender_functionLevel(address[] calldata lenders_) external {
        vm.assume(lenders_.length > 1);

        lenders = lenders_;

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        uint256 functionBitmap = generateBitmap([1, 2]);

        functionIds.push(functionId);
        bitmaps.push(functionBitmap);

        // Set pool bitmap
        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        bitmaps = new uint256[](lenders.length);

        // Set all lenders, except last one to matching bitmaps
        for (uint256 i; i < lenders.length - 1; ++i) {
            bitmaps[i] = functionBitmap;
        }

        bitmaps[lenders.length - 1] = generateBitmap([0, 1, 3]);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lenders, functionId);

        assertFalse(hasPermission);

        // Set the last lender to matching bitmap
        bitmaps[lenders.length - 1] = functionBitmap;

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        hasPermission = ppm.hasPermission(poolManager, lenders, functionId);

        assertTrue(hasPermission);
    }

    /**************************************************************************************************************************************/
    /*** Pool Permission Level                                                                                                          ***/
    /**************************************************************************************************************************************/

    function test_hasPermission_poolLevel_whitelisted() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 2);

        lenders.push(lender);
        booleans.push(true);

        vm.prank(poolDelegate);
        ppm.setLenderAllowlist(poolManager, lenders, booleans);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertTrue(hasPermission);
    }

    function test_hasPermission_poolLevel_zeroPoolBitmap() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 2);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_poolLevel_zeroLenderBitmap() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 1);

        functionIds.push(bytes32(0));
        bitmaps.push(generateBitmap([1, 2]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_poolLevel_mismatch() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 2);

        functionIds.push(bytes32(0));
        bitmaps.push(generateBitmap([1, 2]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        lenders.push(lender);
        bitmaps[0] = generateBitmap([0, 2, 3]);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertFalse(hasPermission);
    }

    function test_hasPermission_poolLevel_multiLender_mismatch() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 2);

        functionIds.push(bytes32(0));
        bitmaps.push(generateBitmap([1, 2]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        lenders.push(lender);
        bitmaps[0] = generateBitmap([0, 2, 3]);

        lenders.push(makeAddr("newLender"));
        bitmaps.push(generateBitmap([1, 2]));

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        // One of the lenders doesn't have the correct permission so the check returns false.
        assertFalse(hasPermission);
    }

    function test_hasPermission_poolLevel_match() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 2);

        functionIds.push(bytes32(0));
        bitmaps.push(generateBitmap([1, 2]));

        vm.prank(poolDelegate);
        ppm.setPoolBitmaps(poolManager, functionIds, bitmaps);

        lenders.push(lender);
        bitmaps[0] = generateBitmap([0, 1, 2]);

        vm.prank(permissionAdmin);
        ppm.setLenderBitmaps(lenders, bitmaps);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertTrue(hasPermission);
    }

    /**************************************************************************************************************************************/
    /*** Public Permission Level                                                                                                        ***/
    /**************************************************************************************************************************************/

    function test_hasPermission_public_success() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 3);

        bool hasPermission = ppm.hasPermission(poolManager, lender, functionId);

        assertEq(hasPermission, true);
    }

    function testFuzz_hasPermission_public(address poolManager_, address lender_, bytes32 functionId_) external {
        globals.__setPoolDelegate(poolManager_, true);

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager_, 3);

        bool hasPermission = ppm.hasPermission(poolManager_, lender_, functionId_);

        assertEq(hasPermission, true);
    }

    function testFuzz_hasPermission_multiLender_public_(address poolManager_, address[] calldata lenders_, bytes32 functionId_) external {
        vm.assume(lenders_.length > 1);

        globals.__setPoolDelegate(poolManager_, true);

        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager_, 3);

        bool hasPermission = ppm.hasPermission(poolManager_, lenders_, functionId_);

        assertEq(hasPermission, true);
    }

}
