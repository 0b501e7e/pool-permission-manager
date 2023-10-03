// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

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
