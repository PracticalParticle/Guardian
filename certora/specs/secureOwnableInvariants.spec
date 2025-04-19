/**
 * Invariants specification file for SecureOwnable
 * Focuses on core security invariants that should always hold
 */

// Import the contract definitions
import "../contracts/core/access/SecureOwnable.sol";
import "../contracts/lib/MultiPhaseSecureOperation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Invariant: Role Integrity 
 * Ensures that the role addresses are always non-zero
 */
invariant roleAddressesNotZero()
    owner() != 0 && getBroadcaster() != 0 && getRecoveryAddress() != 0
    filtered { f -> !f.isView }

/**
 * Invariant: Owner should have owner role
 * Ensures that the owner address is always registered as OWNER_ROLE
 */
invariant ownerHasOwnerRole(env e)
    owner() == getSecureState().roles[OWNER_ROLE()]
    filtered { f -> !f.isView }

/**
 * Invariant: Broadcaster should have broadcaster role
 * Ensures that the broadcaster address is always registered as BROADCASTER_ROLE
 */
invariant broadcasterHasBroadcasterRole(env e)
    getBroadcaster() == getSecureState().roles[BROADCASTER_ROLE()]
    filtered { f -> !f.isView }

/**
 * Invariant: Recovery should have recovery role
 * Ensures that the recovery address is always registered as RECOVERY_ROLE
 */
invariant recoveryHasRecoveryRole(env e)
    getRecoveryAddress() == getSecureState().roles[RECOVERY_ROLE()]
    filtered { f -> !f.isView }

/**
 * Invariant: Support for Interface
 * Ensures that the contract always supports the ISecureOwnable interface
 */
invariant interfaceSupport()
    supportsInterface(0x01ffc9a7) && // ERC165
    supportsInterface(type(ISecureOwnable).interfaceId)
    filtered { f -> !f.isView }

/**
 * Invariant: Transaction counter consistency
 * Ensures that the transaction counter is always consistent with the number of records
 */
invariant txCounterConsistency(env e)
    forall uint256 txId. txId > getCurrentTxId() => 
        getTxRecord(txId).txId == 0
    filtered { f -> !f.isView } 