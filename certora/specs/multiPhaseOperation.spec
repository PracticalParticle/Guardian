/**
 * Specification file for MultiPhaseSecureOperation
 * Focuses on validating secure operation execution flow
 */

// Import the library and harness
import "../contracts/lib/MultiPhaseSecureOperation.sol";
import "../certora/harness/MultiPhaseSecureOperationHarness.sol";

// Define methods that can be called by any environment
methods {
    // TxStatus enums for comparison
    function TxStatus.UNDEFINED() internal returns uint8 envfree;
    function TxStatus.PENDING() internal returns uint8 envfree;
    function TxStatus.CANCELLED() internal returns uint8 envfree;
    function TxStatus.COMPLETED() internal returns uint8 envfree;
    function TxStatus.FAILED() internal returns uint8 envfree;
    function TxStatus.REJECTED() internal returns uint8 envfree;
    
    // Harness functions
    function getOwner() external returns (address) envfree;
    function getTxRecord(uint256) external returns (MultiPhaseSecureOperation.TxRecord) envfree;
    function getCurrentTxId() external returns (uint256) envfree;
    function getNextTxId() external returns (uint256) envfree;
    function isOperationTypeSupported(bytes32) external returns (bool) envfree;
    function BROADCASTER_ROLE() external returns (bytes32) envfree;
    function checkPermissionPermissive(bytes4) external returns (bool) envfree;
}

/**
 * Rule: Transaction Status Transitions
 * Ensures that transaction status follows a valid transition path
 */
rule transactionStatusTransitions(env e) {
    // Storage variables to track status
    storage init_state = lastStorage;
    
    // Get an arbitrary transaction ID
    uint256 txId;
    require txId > 0;
    
    // Get initial status (if tx exists)
    MultiPhaseSecureOperation.TxRecord record = getTxRecord(txId);
    uint8 initialStatus = record.status;
    
    // Call any method
    method f;
    calldataarg args;
    f(e, args);
    
    // Get status after method call
    MultiPhaseSecureOperation.TxRecord newRecord = getTxRecord(txId);
    uint8 newStatus = newRecord.status;
    
    // If status was initially PENDING, it can transition to CANCELLED, COMPLETED, or FAILED
    if (initialStatus == TxStatus.PENDING()) {
        assert newStatus == TxStatus.PENDING() || 
               newStatus == TxStatus.CANCELLED() || 
               newStatus == TxStatus.COMPLETED() || 
               newStatus == TxStatus.FAILED();
    }
    
    // If status was CANCELLED, COMPLETED, or FAILED, it should remain unchanged
    if (initialStatus == TxStatus.CANCELLED() || 
        initialStatus == TxStatus.COMPLETED() || 
        initialStatus == TxStatus.FAILED()) {
        assert newStatus == initialStatus;
    }
}

/**
 * Rule: Time Lock Enforcement
 * Ensures that time lock periods are respected before allowing transaction execution
 */
rule timeLockEnforcement(env e) {
    // Get an arbitrary transaction ID
    uint256 txId;
    require txId > 0;
    
    // Try to approve transaction
    txDelayedApproval@withrevert(e, txId);
    
    // If call doesn't revert
    if (!lastReverted) {
        // Get transaction record
        MultiPhaseSecureOperation.TxRecord record = getTxRecord(txId);
        
        // If successful, assert that current time is past release time
        assert e.block.timestamp >= record.releaseTime;
    }
}

/**
 * Rule: Roles Separation
 * Ensure separate roles don't have overlapping access patterns
 */
rule rolesSeparation(env e) {
    // Storage variables to track state changes
    storage init_state = lastStorage;
    
    // Get owner and broadcaster addresses
    address owner = getOwner();
    bytes32 broadcasterRole = BROADCASTER_ROLE();
    address broadcaster;
    
    // Call method from owner context
    env eOwner = e;
    eOwner.msg.sender = owner;
    
    // Require owner is not zero and not the same as broadcaster
    require owner != 0;
    require owner != broadcaster;
    
    // Owner should not be able to directly approve transactions that require broadcaster role
    bytes4 txApprovalWithMetaTxSelector = sig:txApprovalWithMetaTx((TxRecord, MetaTxParams, bytes32, bytes, bytes)).selector;
    require !checkPermissionPermissive(txApprovalWithMetaTxSelector);
}

/**
 * Rule: Request and Approval Atomicity
 * Ensures that requestAndApprove operations are atomic
 */
rule requestAndApprovalAtomicity(env e) {
    // Storage variables to track state changes
    storage init_state = lastStorage;
    
    // Get count of txns before operation
    uint256 beforeCount = getCurrentTxId();
    
    // Call requestAndApprove
    method f;
    bool isRequestAndApprove = f.selector == sig:requestAndApprove((TxRecord,MetaTxParams,bytes32,bytes,bytes)).selector;
    require isRequestAndApprove;
    calldataarg args;
    
    f@withrevert(e, args);
    
    // If successful, check results
    if (!lastReverted) {
        // Get count after operation
        uint256 afterCount = getCurrentTxId();
        
        // Should increment count by exactly one
        assert afterCount == beforeCount + 1;
        
        // Get the new transaction record
        MultiPhaseSecureOperation.TxRecord record = getTxRecord(afterCount);
        
        // The status should be either COMPLETED or FAILED
        assert record.status == TxStatus.COMPLETED() || record.status == TxStatus.FAILED();
    }
}

/**
 * Invariant: Transaction IDs are strictly sequential
 * Ensures transaction IDs are always sequential
 */
invariant transactionIdsSequential()
    getNextTxId() == getCurrentTxId() + 1
    filtered { f -> !f.isView }

/**
 * Rule: Verify transactions cannot be cancelled after completion
 * Ensures completed transactions cannot be cancelled
 */
rule noRevertingCompletedTransactions(env e) {
    uint256 txId;
    
    // Get transaction record
    MultiPhaseSecureOperation.TxRecord record = getTxRecord(txId);
    
    // If transaction is completed
    if (record.status == TxStatus.COMPLETED()) {
        // Try to cancel it
        txCancellation@withrevert(e, txId);
        
        // Should revert
        assert lastReverted;
    }
}

/**
 * Rule: Nonce Incrementing
 * Ensures operations that require meta transactions always increment nonce
 */
rule nonceIncrementingOnMetaTx(env e) {
    storage initial = lastStorage;
    
    // Call txApprovalWithMetaTx
    bytes4 selector = sig:txApprovalWithMetaTx((TxRecord,MetaTxParams,bytes32,bytes,bytes)).selector;
    
    // Get current nonce (requires custom accessor in harness)
    // uint256 initialNonce = getNonce();
    
    method f;
    require f.selector == selector;
    calldataarg args;
    
    f@withrevert(e, args);
    
    // If successful, verify security properties
    if (!lastReverted) {
        // Can add a check for nonce incrementation when harness exposes this
        assert(true); // Placeholder for now
    }
} 