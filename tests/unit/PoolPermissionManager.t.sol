// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManager } from "../../contracts/PoolPermissionManager.sol";

import { TestBase } from "../utils/TestBase.sol";

contract PoolPermissionManagerTestsBase is TestBase {

    address admin  = makeAddr("admin");
    address lender = makeAddr("lender");
    address pool   = makeAddr("pool");

    address implementation;

    PoolPermissionManager internal poolPermissionManager;

    function setUp() public virtual {
        implementation        = address(new PoolPermissionManager());
        poolPermissionManager = PoolPermissionManager(address(new NonTransparentProxy(admin, implementation)));
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

    function test_setIsGlobalAllowList() public {
        poolPermissionManager.setIsGlobalAllowList(pool, true);

        ( bool isGlobalAllowList, ) = poolPermissionManager.poolConfigs(pool);

        assertTrue(isGlobalAllowList);
    }

}

contract SetIsPoolFunctionOnlyTests is PoolPermissionManagerTestsBase {

    function test_setIsPoolFunctionAllowList() public {
        poolPermissionManager.setIsPoolFunctionAllowList(pool, true);

        ( , bool isFunctionOnly ) = poolPermissionManager.poolConfigs(pool);

        assertTrue(isFunctionOnly);
    }

}

contract SetPoolAllowListTests is PoolPermissionManagerTestsBase {

    function test_setPoolAllowList() public {
        poolPermissionManager.setPoolAllowList(pool, lender, true);

        assertTrue(poolPermissionManager.poolAllowList(pool, lender));
    }

}

contract SetPoolBitmapTests is PoolPermissionManagerTestsBase {

    function test_setPoolBitmap() public {
        poolPermissionManager.setPoolBitmap(pool, 1);

        assertEq(poolPermissionManager.poolBitmaps(pool), 1);
    }

}

contract SetPoolFunctionBitmapTests is PoolPermissionManagerTestsBase {

    function test_setPoolFunctionBitmap() public {
        bytes32 functionSig = "P:deposit";

        poolPermissionManager.setPoolFunctionBitmap(pool, functionSig, 1);

        assertEq(poolPermissionManager.poolFunctionBitmaps(pool, functionSig), 1);
    }

}

contract SetLenderBitmapTests is PoolPermissionManagerTestsBase {

    function test_setLenderBitmap() public {
        poolPermissionManager.setLenderBitmap(lender, 1);

        assertEq(poolPermissionManager.lenderBitmaps(lender), 1);
    }

}
