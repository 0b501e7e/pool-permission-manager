// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

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
