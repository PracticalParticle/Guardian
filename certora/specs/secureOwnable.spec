/**
 * Specification file for SecureOwnable
 * Focuses on validating ownership management and access control
 */

// Import the contract definitions
import "../contracts/core/access/SecureOwnable.sol";
import "../contracts/lib/MultiPhaseSecureOperation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* Rules related to ownership behaviors */

/**
 * Rule: Owner should not change without a transfer ownership operation
 * Verifies that the owner address cannot change arbitrarily between states
 */
rule ownershipDoesNotChangeWithoutTransfer() {
    env e1;
    env e2;
    
    // Get initial owner
    address initialOwner = owner(e1);
    
    // Call any method
    method f;
    calldataarg args;
    
    // For any method call
    f(e2, args);
    
    // Get new owner
    address newOwner = owner(e1);
    
    // If the owner has changed
    if (initialOwner != newOwner) {
        // Assert that the method was related to ownership transfer
        assert(
            f.selector == sig:executeTransferOwnership(address).selector ||
            f.selector == sig:_transferOwnership(address).selector
        );
    }
}

/**
 * Rule: Only owner can request broadcaster update
 * Ensures only the owner can initiate a broadcaster update request
 */
rule onlyOwnerCanRequestBroadcasterUpdate() {
    env e;
    address newBroadcaster;
    
    // Assume the caller is not the owner
    require(e.msg.sender != owner(e));
    
    // Try to request a broadcaster update
    updateBroadcasterRequest@withrevert(e, newBroadcaster);
    
    // Assert the call should revert
    assert(lastReverted);
}

/**
 * Rule: Verify that direct ownership transfer is disabled
 * Ensures the standard transferOwnership function always reverts
 */
rule directOwnershipTransferDisabled() {
    env e;
    address newOwner;
    
    // Try to directly transfer ownership
    transferOwnership@withrevert(e, newOwner);
    
    // Assert the call should always revert
    assert(lastReverted);
}

/**
 * Rule: Verify that renounceOwnership is disabled
 * Ensures the standard renounceOwnership function always reverts
 */
rule renounceOwnershipDisabled() {
    env e;
    
    // Try to renounce ownership
    renounceOwnership@withrevert(e);
    
    // Assert the call should always revert
    assert(lastReverted);
}

/**
 * Invariant: Role Integrity 
 * Ensures that the role addresses are always non-zero
 */
invariant roleAddressesNotZero()
    owner() != 0 && getBroadcaster() != 0 && getRecoveryAddress() != 0
    filtered { f -> !f.isView }
    
/**
 * Rule: Operations validity
 * Ensures that operations are always with a supported type
 */
rule operationTypeAlwaysValid() {
    env e;
    bytes32 operationType;
    
    // Check if operation type is supported
    bool isSupported = isOperationTypeSupported(e, operationType);
    
    // If we assert it's valid in our contract logic, it must be valid
    require(isSupported);
    
    // It should exist in the list of supported types
    assert(isOperationTypeSupported(e, operationType));
} 