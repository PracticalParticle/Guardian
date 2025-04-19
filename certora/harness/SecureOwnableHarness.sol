// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.2;

import "../../contracts/core/access/SecureOwnable.sol";

/**
 * @title SecureOwnableHarness
 * @dev Harness contract to test SecureOwnable's internal state and functions
 */
contract SecureOwnableHarness is SecureOwnable {
    // Events for harness testing
    event HarnessOperationAdded(uint256 txId, bytes32 operationType);
    event HarnessOperationFinalized(uint256 txId, MultiPhaseSecureOperation.TxStatus status);
    
    // For harness tracking of state that is private in the parent contract
    bool private _hasPendingOwnershipRequest;
    bool private _hasPendingBroadcasterRequest;
    
    constructor(
        address initialOwner,
        address broadcaster,
        address recovery,
        uint256 timeLockPeriodInMinutes
    ) SecureOwnable(
        initialOwner,
        broadcaster,
        recovery,
        timeLockPeriodInMinutes
    ) {
        _hasPendingOwnershipRequest = false;
        _hasPendingBroadcasterRequest = false;
    }
    
    // Return state variables separately to avoid issues with complex storage structures
    function getSecureStateCounters() public view returns (uint256 txCounter, uint256 metaTxNonce, uint256 timelock) {
        MultiPhaseSecureOperation.SecureOperationState storage state = _getSecureState();
        return (state.txCounter, state.metaTxNonce, state.timeLockPeriodInMinutes);
    }
    
    // Get role address by role identifier
    function getRoleAddress(bytes32 role) public view returns (address) {
        return _getSecureState().roles[role];
    }
    
    function OWNER_ROLE() public pure returns (bytes32) {
        return MultiPhaseSecureOperation.OWNER_ROLE;
    }
    
    function BROADCASTER_ROLE() public pure returns (bytes32) {
        return MultiPhaseSecureOperation.BROADCASTER_ROLE;
    }
    
    function RECOVERY_ROLE() public pure returns (bytes32) {
        return MultiPhaseSecureOperation.RECOVERY_ROLE;
    }
    
    // Function to manually execute ownership transfer (for testing)
    function manualTransferOwnership(address newOwner) public {
        _transferOwnership(newOwner);
    }
    
    // Function to manually update broadcaster (for testing)
    function manualUpdateBroadcaster(address newBroadcaster) public {
        _updateBroadcaster(newBroadcaster);
    }
    
    // Function to manually update recovery (for testing)
    function manualUpdateRecoveryAddress(address newRecoveryAddress) public {
        _updateRecoveryAddress(newRecoveryAddress);
    }
    
    // Function to manually update timelock (for testing)
    function manualUpdateTimeLockPeriod(uint256 newTimeLockPeriodInMinutes) public {
        _updateTimeLockPeriod(newTimeLockPeriodInMinutes);
    }
    
    // Expose the getOperation function from SecureOwnable to get a specific transaction
    function getSecureOperation(uint256 txId) public view returns (MultiPhaseSecureOperation.TxRecord memory) {
        return getOperation(txId);
    }
    
    // Helper to get the number of operations in SecureOwnable
    function getSecureOperationCount() public view returns (uint256) {
        // Get the transaction count directly from the structure state
        (uint256 txCounter, , ) = getSecureStateCounters();
        return txCounter;
    }
    
    // Get all operation history with a specific status
    function getOperationHistoryWithStatus(MultiPhaseSecureOperation.TxStatus status) public view returns (MultiPhaseSecureOperation.TxRecord[] memory) {
        // Use the parent's getOperationHistory and filter
        MultiPhaseSecureOperation.TxRecord[] memory allRecords = getOperationHistory();
        
        // Count records with matching status
        uint256 matchingCount = 0;
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (allRecords[i].status == status) {
                matchingCount++;
            }
        }
        
        // Create array of matching size
        MultiPhaseSecureOperation.TxRecord[] memory filteredHistory = new MultiPhaseSecureOperation.TxRecord[](matchingCount);
        
        // Fill the array
        uint256 index = 0;
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (allRecords[i].status == status) {
                filteredHistory[index] = allRecords[i];
                index++;
            }
        }
        
        return filteredHistory;
    }
    
    // Find operations by type
    function getOperationsByType(bytes32 operationType) public view returns (MultiPhaseSecureOperation.TxRecord[] memory) {
        // Use the parent's getOperationHistory and filter
        MultiPhaseSecureOperation.TxRecord[] memory allRecords = getOperationHistory();
        
        // Count records with matching type
        uint256 matchingCount = 0;
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (allRecords[i].params.operationType == operationType) {
                matchingCount++;
            }
        }
        
        // Create array of matching size
        MultiPhaseSecureOperation.TxRecord[] memory filteredHistory = new MultiPhaseSecureOperation.TxRecord[](matchingCount);
        
        // Fill the array
        uint256 index = 0;
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (allRecords[i].params.operationType == operationType) {
                filteredHistory[index] = allRecords[i];
                index++;
            }
        }
        
        return filteredHistory;
    }
    
    // Override to intercept for testing
    function addOperation(MultiPhaseSecureOperation.TxRecord memory txRecord) internal override {
        // Call original implementation
        super.addOperation(txRecord);
        
        // Update our tracking
        if (txRecord.params.operationType == OWNERSHIP_TRANSFER) {
            _hasPendingOwnershipRequest = true;
        } else if (txRecord.params.operationType == BROADCASTER_UPDATE) {
            _hasPendingBroadcasterRequest = true;
        }
        
        // Emit event for testing
        emit HarnessOperationAdded(txRecord.txId, txRecord.params.operationType);
    }
    
    // Override to intercept for testing
    function finalizeOperation(MultiPhaseSecureOperation.TxRecord memory opData) internal override {
        // Call original implementation
        super.finalizeOperation(opData);
        
        // Update our tracking
        if (opData.params.operationType == OWNERSHIP_TRANSFER) {
            _hasPendingOwnershipRequest = false;
        } else if (opData.params.operationType == BROADCASTER_UPDATE) {
            _hasPendingBroadcasterRequest = false;
        }
        
        // Emit event for testing
        emit HarnessOperationFinalized(opData.txId, opData.status);
    }
    
    // Function to expose internal validation checks
    function validateNotZeroAddress(address addr) public pure {
        _validateNotZeroAddress(addr);
    }
    
    // Function to expose internal validation checks
    function validateOperationType(bytes32 actualType, bytes32 expectedType) public pure {
        _validateOperationType(actualType, expectedType);
    }
    
    // Function to expose internal validation checks
    function validateHandlerSelector(bytes4 actualSelector, bytes4 expectedSelector) public pure {
        _validateHandlerSelector(actualSelector, expectedSelector);
    }
    
    // Function to expose internal validation checks
    function validateNewAddress(address newAddress, address currentAddress) public pure {
        _validateNewAddress(newAddress, currentAddress);
    }
    
    // Check if an open ownership request exists
    function hasOpenOwnershipRequest() public view returns (bool) {
        return _hasPendingOwnershipRequest;
    }
    
    // Check if an open broadcaster request exists
    function hasOpenBroadcasterRequest() public view returns (bool) {
        return _hasPendingBroadcasterRequest;
    }
    
    // Test meta-transaction generation with simulated signer
    function testGenerateAndSignMetaTx(
        address requester,
        address target,
        bytes32 operationType,
        bytes memory executionOptions,
        uint256 deadline
    ) public view returns (MultiPhaseSecureOperation.MetaTransaction memory) {
        address signer = owner();
        
        MultiPhaseSecureOperation.TxParams memory txParams = MultiPhaseSecureOperation.TxParams({
            requester: requester,
            target: target,
            value: 0,
            gasLimit: 1000000,
            operationType: operationType,
            executionType: MultiPhaseSecureOperation.ExecutionType.STANDARD,
            executionOptions: executionOptions
        });
        
        MultiPhaseSecureOperation.MetaTxParams memory metaTxParams = createMetaTxParams(
            address(this),
            bytes4(keccak256("executeTest()")),
            deadline,
            0,
            signer
        );
        
        return generateUnsignedMetaTransactionForNew(
            requester,
            target,
            0,
            1000000,
            operationType,
            MultiPhaseSecureOperation.ExecutionType.STANDARD,
            executionOptions,
            metaTxParams
        );
    }
    
    // Test function to verify permission checks
    function checkRolePermission(bytes4 selector) public view returns (bool) {
        try this.getSecureOperation(1) {
            // This is just a dummy check to handle the try-catch syntax
            // The actual logic is to redirect to the simpler approach below
            return checkPermissionDirectly(selector);
        } catch {
            return checkPermissionDirectly(selector);
        }
    }
    
    // Helper function to check permissions directly through the access control logic
    function checkPermissionDirectly(bytes4 selector) public view returns (bool) {
        // Check if caller is owner
        if (msg.sender == owner()) {
            return true;
        }
        
        // Check if caller is broadcaster
        if (msg.sender == getBroadcaster()) {
            return true;
        }
        
        // Check if caller is recovery
        if (msg.sender == getRecoveryAddress()) {
            return true;
        }
        
        return false;
    }
} 