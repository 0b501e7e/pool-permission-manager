// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { PoolPermissionManagerStorage } from "./PoolPermissionManagerStorage.sol";

contract PoolPermissionManagerInitializer is NonTransparentProxied, PoolPermissionManagerStorage {
    
    function initialize(address implementation_, address globals_) external {
        require(msg.sender == admin(), "PPMI:I:NOT_ADMIN");

        globals = globals_; 

        _setAddress(IMPLEMENTATION_SLOT, implementation_);
    }

    function _setAddress(bytes32 slot_, address value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}
