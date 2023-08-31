// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

contract GlobalsMock {

    struct PoolDelegate {
        address ownedPoolManager;
        bool    isPoolDelegate;
    }

    address public governor;

    PoolDelegate poolDelegate_; 

    function poolDelegates(address ) external view returns (address, bool) {
        return (poolDelegate_.ownedPoolManager, poolDelegate_.isPoolDelegate);
    }

    function __setGovernor(address governor_) external {
        governor = governor_;
    }

    function __setPoolDelegate(address ownedPoolManager_, bool isPoolDelegate_) external {
        poolDelegate_.ownedPoolManager = ownedPoolManager_;
        poolDelegate_.isPoolDelegate = isPoolDelegate_;
    }
    
}
