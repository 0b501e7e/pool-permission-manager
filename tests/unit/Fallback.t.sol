// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManagerTestBase } from "./PoolPermissionManagerTestBase.t.sol";

contract FallbackTests is PoolPermissionManagerTestBase {

    function test_fallback_noCode() external {
        address newImplementation = makeAddr("notContract");

        vm.prank(governor);
        NonTransparentProxy(address(ppm)).setImplementation(newImplementation);

        vm.expectRevert("NTP:F:NO_CODE_ON_IMPLEMENTATION");
        ppm.implementation();
    }

}
