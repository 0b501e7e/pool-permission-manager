// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

contract GlobalsMock {

    struct PoolDelegate {
        address ownedPoolManager;
        bool    isPoolDelegate;
    }

    address public governor;
    address public operationalAdmin;

    mapping(address =>PoolDelegate) _poolDelegates;

    function poolDelegates(address poolDelegate_) external view returns (address, bool) {
        return (_poolDelegates[poolDelegate_].ownedPoolManager, _poolDelegates[poolDelegate_].isPoolDelegate);
    }

    function __setGovernor(address governor_) external {
        governor = governor_;
    }

    function __setOperationalAdmin(address operationalAdmin_) external {
        operationalAdmin = operationalAdmin_;
    }

    function __setOwnedPoolManager(address poolDelegate_, address ownedPoolManager_, bool isPoolDelegate_) external {
        _poolDelegates[poolDelegate_].ownedPoolManager = ownedPoolManager_;
        _poolDelegates[poolDelegate_].isPoolDelegate = isPoolDelegate_;
    }

}
