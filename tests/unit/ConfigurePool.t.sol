// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

contract ConfigurePoolTests is PoolPermissionManagerTestBase {

    function test_configurePool_unauthorized() external {
        globals.__setPoolDelegate(poolManager, false);

        vm.expectRevert("PPM:NOT_PD");
        ppm.configurePool(poolManager, 3, functionIds, bitmaps);
    }

    function test_configurePool_public() external {
        vm.prank(poolDelegate);
        ppm.setPoolPermissionLevel(poolManager, 3);

        vm.prank(poolDelegate);
        vm.expectRevert("PPM:CP:PUBLIC_POOL");
        ppm.configurePool(poolManager, 0, functionIds, bitmaps);
    }

    function test_configurePool_invalid() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PPM:CP:INVALID_LEVEL");
        ppm.configurePool(poolManager, 4, functionIds, bitmaps);
    }

    function test_configurePool_lengthMismatch() external {
        functionIds.push(functionId);

        vm.prank(poolDelegate);
        vm.expectRevert("PPM:CP:LENGTH_MISMATCH");
        ppm.configurePool(poolManager, 2, functionIds, bitmaps);
    }

    function test_configurePool_success() external {
        functionIds.push(functionId);
        bitmaps.push(generateBitmap([0, 2]));

        assertEq(ppm.poolBitmaps(poolManager, functionId), 0);
        assertEq(ppm.poolPermissions(poolManager),         0);

        vm.prank(poolDelegate);
        ppm.configurePool(poolManager, 1, functionIds, bitmaps);

        assertEq(ppm.poolBitmaps(poolManager, functionId), generateBitmap([0, 2]));
        assertEq(ppm.poolPermissions(poolManager),         1);
    }
    
}
