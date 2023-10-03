// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

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
