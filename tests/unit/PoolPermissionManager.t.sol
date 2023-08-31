// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManager }            from "../../contracts/PoolPermissionManager.sol";
import { PoolPermissionManagerInitializer } from "../../contracts/PoolPermissionManagerInitializer.sol";

import { GlobalsMock } from "../utils/Mocks.sol";
import { TestBase }    from "../utils/TestBase.sol";

contract PoolPermissionManagerTestsBase is TestBase {

    address admin            = makeAddr("admin");
    address lender           = makeAddr("lender");
    address poolManager      = makeAddr("poolManager");
    address permissionsAdmin = makeAddr("permissionsAdmin");

    address implementation;
    address initializer;

    GlobalsMock           globals;
    PoolPermissionManager poolPermissionManager;

    function setUp() public virtual {
        globals        = new GlobalsMock();
        implementation = address(new PoolPermissionManager());
        initializer    = address(new PoolPermissionManagerInitializer());

        poolPermissionManager = PoolPermissionManager(address(new NonTransparentProxy(admin, address(initializer))));

        globals.__setGovernor(admin);
        globals.__setPoolDelegate(poolManager, true);

        vm.startPrank(admin);
        PoolPermissionManagerInitializer(address(poolPermissionManager)).initialize(implementation, address(globals));
        poolPermissionManager.setPermissionsAdmin(permissionsAdmin, true);
        vm.stopPrank();
    }

}

contract SetImplementationTests is PoolPermissionManagerTestsBase {

    event ImplementationSet(address indexed implementation);

    function test_setImplementation_notAdmin() external {
        vm.expectRevert("NTP:SI:NOT_ADMIN");
        NonTransparentProxy(address(poolPermissionManager)).setImplementation(address(0x1));
    }

    function test_setImplementation_success() external {
        address newImplementation = address(new PoolPermissionManager());

        vm.expectEmit();
        emit ImplementationSet(newImplementation);

        vm.prank(admin);
        NonTransparentProxy(address(poolPermissionManager)).setImplementation(newImplementation);

        assertEq(poolPermissionManager.implementation(), newImplementation);
    }

}

contract FallbackTests is PoolPermissionManagerTestsBase {

    function test_fallback_noCodeOnImplementation() external {
        address newImplementation = makeAddr("notContract");

        vm.prank(admin);
        NonTransparentProxy(address(poolPermissionManager)).setImplementation(newImplementation);

        vm.expectRevert("NTP:F:NO_CODE_ON_IMPLEMENTATION");
        poolPermissionManager.implementation();
    }

}

contract SetIsGlobalAllowListTests is PoolPermissionManagerTestsBase {

    function test_setGlobalAllowList_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setIsGlobalAllowList(poolManager, true);
    }

    function test_setGlobalAllowList_wrongPoolDelegate() public {
        address otherPoolManager = makeAddr("otherPoolManager");

        globals.__setPoolDelegate(otherPoolManager, true);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setIsGlobalAllowList(poolManager, true);
    }

    function test_setIsGlobalAllowList() public {
        poolPermissionManager.setIsGlobalAllowList(poolManager, true);

        ( bool isGlobalAllowList, ) = poolPermissionManager.poolConfigs(poolManager);

        assertTrue(isGlobalAllowList);

        poolPermissionManager.setIsGlobalAllowList(poolManager, false);

        ( isGlobalAllowList, ) = poolPermissionManager.poolConfigs(poolManager);

        assertTrue(!isGlobalAllowList);
    }

}

contract SetIsPoolFunctionOnlyTests is PoolPermissionManagerTestsBase {

    function test_setIsPoolFunctionAllowList_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setIsPoolFunctionAllowList(poolManager, true);
    }

    function test_setIsPoolFunctionAllowList_wrongPoolDelegate() public {
        address otherPoolManager = makeAddr("otherPoolManager");

        globals.__setPoolDelegate(otherPoolManager, true);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setIsPoolFunctionAllowList(poolManager, true);
    }

    function test_setIsPoolFunctionAllowList() public {
        poolPermissionManager.setIsPoolFunctionAllowList(poolManager, true);

        ( , bool isFunctionOnly ) = poolPermissionManager.poolConfigs(poolManager);

        assertTrue(isFunctionOnly);

        poolPermissionManager.setIsPoolFunctionAllowList(poolManager, false);

        ( , isFunctionOnly ) = poolPermissionManager.poolConfigs(poolManager);

        assertTrue(!isFunctionOnly);
    }

}

contract SetPermissionsAdminTests is PoolPermissionManagerTestsBase {

    function test_setPermissionsAdmin_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_GOV");
        poolPermissionManager.setPermissionsAdmin(permissionsAdmin, true);
    }

    function test_setPermissionsAdmin() public {
        address newPermissionsAdmin = makeAddr("newPermissionsAdmin");

        vm.prank(admin);
        poolPermissionManager.setPermissionsAdmin(newPermissionsAdmin, true);

        assertTrue(poolPermissionManager.permissionsAdmins(newPermissionsAdmin));

        vm.prank(admin);
        poolPermissionManager.setPermissionsAdmin(newPermissionsAdmin, false);

        assertTrue(!poolPermissionManager.permissionsAdmins(newPermissionsAdmin));
    }

}

contract SetPoolAllowListTests is PoolPermissionManagerTestsBase {

    function test_setPoolAllowList_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolAllowList(poolManager, lender, true);
    }

    function test_setPoolAllowList_wrongPoolDelegate() public {
        address otherPoolManager = makeAddr("otherPoolManager");

        globals.__setPoolDelegate(otherPoolManager, true);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolAllowList(poolManager, lender, true);
    }

    function test_setPoolAllowList() public {
        poolPermissionManager.setPoolAllowList(poolManager, lender, true);

        assertTrue(poolPermissionManager.poolAllowList(poolManager, lender));

        poolPermissionManager.setPoolAllowList(poolManager, lender, false);

        assertTrue(!poolPermissionManager.poolAllowList(poolManager, lender));
    }

}

contract SetPoolBitmapTests is PoolPermissionManagerTestsBase {

    function test_setPoolBitmap_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolBitmap(poolManager, 1);
    }

    function test_setPoolBitmap_wrongPoolDelegate() public {
        address otherPoolManager = makeAddr("otherPoolManager");

        globals.__setPoolDelegate(otherPoolManager, true);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolBitmap(poolManager, 1);
    }

    function test_setPoolBitmap() public {
        poolPermissionManager.setPoolBitmap(poolManager, 1);

        assertEq(poolPermissionManager.poolBitmaps(poolManager), 1);

        poolPermissionManager.setPoolBitmap(poolManager, 0);

        assertEq(poolPermissionManager.poolBitmaps(poolManager), 0);
    }

}

contract SetPoolFunctionBitmapTests is PoolPermissionManagerTestsBase {

    bytes32 functionSig = "P:deposit";

    function test_setPoolFunctionBitmap_notPoolDelegate() public {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolFunctionBitmap(poolManager, functionSig, 1);
    }

    function test_setPoolFunctionBitmap_wrongPoolDelegate() public {
        address otherPoolManager = makeAddr("otherPoolManager");

        globals.__setPoolDelegate(otherPoolManager, true);

        vm.expectRevert("PPM:NOT_PD");
        poolPermissionManager.setPoolFunctionBitmap(poolManager, functionSig, 1);
    }

    function test_setPoolFunctionBitmap() public {

        poolPermissionManager.setPoolFunctionBitmap(poolManager, functionSig, 1);

        assertEq(poolPermissionManager.poolFunctionBitmaps(poolManager, functionSig), 1);

        poolPermissionManager.setPoolFunctionBitmap(poolManager, functionSig, 0);

        assertEq(poolPermissionManager.poolFunctionBitmaps(poolManager, functionSig), 0);
    }

}

contract SetLenderBitmapTests is PoolPermissionManagerTestsBase {

    function test_setLenderBitmap_notPermissionsAdmin() public {
        vm.expectRevert("PPM:NOT_PPM_ADMIN");
        poolPermissionManager.setLenderBitmap(lender, 1);
    }

    function test_setLenderBitmap() public {
        vm.prank(permissionsAdmin);
        poolPermissionManager.setLenderBitmap(lender, 1);

        assertEq(poolPermissionManager.lenderBitmaps(lender), 1);

        vm.prank(permissionsAdmin);
        poolPermissionManager.setLenderBitmap(lender, 0);

        assertEq(poolPermissionManager.lenderBitmaps(lender), 0);
    }

}
