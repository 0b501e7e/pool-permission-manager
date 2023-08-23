// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { PoolPermissionManager } from "../../contracts/PoolPermissionManager.sol";

import { TestBase } from "../utils/TestBase.sol";

contract PoolPermissionManagerTestsBase is TestBase {

    address lender = makeAddr("lender");
    address pool   = makeAddr("pool");

    PoolPermissionManager internal poolPermissionManager;

    function setUp() public virtual {
        poolPermissionManager = new PoolPermissionManager();
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
