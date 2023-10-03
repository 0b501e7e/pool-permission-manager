// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

contract SetPermissionAdminTests is PoolPermissionManagerTestBase {

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
