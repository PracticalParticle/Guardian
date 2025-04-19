// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.2;

import "../../contracts/core/access/SecureOwnable.sol";

/**
 * @title SecureOwnableHarness
 * @dev Harness contract to test SecureOwnable's internal state and functions
 */
contract SecureOwnableHarness is SecureOwnable {
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
    ) {}
    
    // Expose protected and internal functions
    
    function getSecureState() public view returns (MultiPhaseSecureOperation.SecureOperationState storage) {
        return _getSecureState();
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
    
    // Get all operation history with a specific status
    function getOperationHistoryWithStatus(MultiPhaseSecureOperation.TxStatus status) public view returns (MultiPhaseSecureOperation.TxRecord[] memory) {
        uint256 totalTransactions = _getSecureState().getCurrentTxId();
        uint256 matchingCount = 0;
        
        // First count matching records
        for (uint256 i = 1; i <= totalTransactions; i++) {
            if (_getSecureState().getTxRecord(i).status == status) {
                matchingCount++;
            }
        }
        
        // Create array of matching size
        MultiPhaseSecureOperation.TxRecord[] memory filteredHistory = new MultiPhaseSecureOperation.TxRecord[](matchingCount);
        
        // Fill the array
        uint256 index = 0;
        for (uint256 i = 1; i <= totalTransactions; i++) {
            MultiPhaseSecureOperation.TxRecord memory record = _getSecureState().getTxRecord(i);
            if (record.status == status) {
                filteredHistory[index] = record;
                index++;
            }
        }
        
        return filteredHistory;
    }
    
    // Override to intercept for testing
    function addOperation(MultiPhaseSecureOperation.TxRecord memory txRecord) internal override {
        // Call original implementation
        super.addOperation(txRecord);
        // Additional logic for testing can be added here
    }
    
    // Override to intercept for testing
    function finalizeOperation(MultiPhaseSecureOperation.TxRecord memory opData) internal override {
        // Call original implementation
        super.finalizeOperation(opData);
        // Additional logic for testing can be added here
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
        return _hasOpenOwnershipRequest;
    }
    
    // Check if an open broadcaster request exists
    function hasOpenBroadcasterRequest() public view returns (bool) {
        return _hasOpenBroadcasterRequest;
    }
} 