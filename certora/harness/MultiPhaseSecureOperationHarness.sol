// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.2;

import "../../contracts/lib/MultiPhaseSecureOperation.sol";

/**
 * @title MultiPhaseSecureOperationHarness
 * @dev Harness contract to test MultiPhaseSecureOperation library functions in isolation
 */
contract MultiPhaseSecureOperationHarness {
    using MultiPhaseSecureOperation for MultiPhaseSecureOperation.SecureOperationState;

    MultiPhaseSecureOperation.SecureOperationState private _secureState;
    
    // Constructor to initialize the state
    constructor(address owner, address broadcaster, address recovery, uint256 timeLockPeriodInMinutes) {
        _secureState.initialize(owner, broadcaster, recovery, timeLockPeriodInMinutes);
    }
    
    // Expose library functions through the harness
    
    function initialize(address owner, address broadcaster, address recovery, uint256 timeLockPeriodInMinutes) public {
        _secureState.initialize(owner, broadcaster, recovery, timeLockPeriodInMinutes);
    }
    
    function getOwner() public view returns (address) {
        return _secureState.getOwner();
    }
    
    function getTxRecord(uint256 txId) public view returns (MultiPhaseSecureOperation.TxRecord memory) {
        return _secureState.getTxRecord(txId);
    }
    
    function txRequest(
        address requester,
        address target,
        uint256 value,
        uint256 gasLimit,
        bytes32 operationType,
        MultiPhaseSecureOperation.ExecutionType executionType,
        bytes memory executionOptions
    ) public returns (MultiPhaseSecureOperation.TxRecord memory) {
        return _secureState.txRequest(requester, target, value, gasLimit, operationType, executionType, executionOptions);
    }
    
    function txDelayedApproval(uint256 txId) public returns (MultiPhaseSecureOperation.TxRecord memory) {
        return _secureState.txDelayedApproval(txId);
    }
    
    function txCancellation(uint256 txId) public returns (MultiPhaseSecureOperation.TxRecord memory) {
        return _secureState.txCancellation(txId);
    }
    
    function getCurrentTxId() public view returns (uint256) {
        return _secureState.getCurrentTxId();
    }
    
    function getNextTxId() public view returns (uint256) {
        return _secureState.getNextTxId();
    }
    
    function addOperationType(MultiPhaseSecureOperation.ReadableOperationType memory readableType) public {
        _secureState.addOperationType(readableType);
    }
    
    function isOperationTypeSupported(bytes32 operationType) public view returns (bool) {
        return _secureState.isOperationTypeSupported(operationType);
    }
    
    function BROADCASTER_ROLE() public pure returns (bytes32) {
        return MultiPhaseSecureOperation.BROADCASTER_ROLE;
    }
    
    function checkPermissionPermissive(bytes4 functionSelector) public view returns (bool) {
        return _secureState.checkPermissionPermissive(functionSelector);
    }
} 