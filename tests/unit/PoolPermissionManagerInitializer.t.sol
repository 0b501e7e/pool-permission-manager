// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { PoolPermissionManager }            from "../../contracts/PoolPermissionManager.sol";
import { PoolPermissionManagerInitializer } from "../../contracts/PoolPermissionManagerInitializer.sol";

import { GlobalsMock } from "../utils/Mocks.sol";
import { TestBase }    from "../utils/TestBase.sol";

contract PoolPermissionManagerInitializerTests is TestBase {

    event Initialized(address implementation, address globals);

    address admin  = makeAddr("admin");
    address lender = makeAddr("lender");
    address pool   = makeAddr("pool");

    address implementation;
    address initializer;

    GlobalsMock           globals;
    PoolPermissionManager poolPermissionManager;

    function setUp() public {
        globals        = new GlobalsMock();
        implementation = address(new PoolPermissionManager());
        initializer    = address(new PoolPermissionManagerInitializer());

        poolPermissionManager = PoolPermissionManager(address(new NonTransparentProxy(admin, address(initializer))));
    }

    function test_initializer_notGovernor() external {
        vm.expectRevert("PPMI:I:NOT_GOVERNOR");
        PoolPermissionManagerInitializer(address(poolPermissionManager)).initialize(implementation, address(globals));
    }

    function test_initializer_success() external {
        vm.expectEmit(address(poolPermissionManager));
        emit Initialized(implementation, address(globals));

        vm.prank(admin);
        PoolPermissionManagerInitializer(address(poolPermissionManager)).initialize(implementation, address(globals));

        assertEq(poolPermissionManager.admin(),          address(admin));
        assertEq(poolPermissionManager.globals(),        address(globals));
        assertEq(poolPermissionManager.implementation(), address(implementation));
    }

}
