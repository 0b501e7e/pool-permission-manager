// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

contract SetPermissionAdminTests is PoolPermissionManagerTestBase {

    function test_setPermissionAdmin_unauthorized() external {
        vm.expectRevert("PPM:NOT_GOV_OR_OA");
        ppm.setPermissionAdmin(address(1), true);
    }

    function test_setPermissionAdmin_success() external {
        assertEq(ppm.permissionAdmins(address(1)), false);

        vm.prank(governor);
        ppm.setPermissionAdmin(address(1), true);

        assertEq(ppm.permissionAdmins(address(1)), true);
    }

    function test_setPermissionAdmin_success_operationalAdmin() external {
        assertEq(ppm.permissionAdmins(address(1)), false);

        vm.prank(operationalAdmin);
        ppm.setPermissionAdmin(address(1), true);

        assertEq(ppm.permissionAdmins(address(1)), true);
    }

}
