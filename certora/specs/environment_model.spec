/**
 * Environment Model Specification
 * 
 * This file defines environment constraints and behaviors for Certora verification
 * It can be included in other specification files to standardize environment assumptions
 */

// TxStatus enum values as constants for easier reference
methods {
    // TxStatus enum values
    function TxStatus.UNDEFINED() internal returns uint8 envfree;
    function TxStatus.PENDING() internal returns uint8 envfree;
    function TxStatus.CANCELLED() internal returns uint8 envfree;
    function TxStatus.COMPLETED() internal returns uint8 envfree;
    function TxStatus.FAILED() internal returns uint8 envfree;
    function TxStatus.REJECTED() internal returns uint8 envfree;
    
    // ExecutionType enum values
    function ExecutionType.NONE() internal returns uint8 envfree;
    function ExecutionType.STANDARD() internal returns uint8 envfree;
    function ExecutionType.RAW() internal returns uint8 envfree;
    
    // Role constants
    function OWNER_ROLE() external returns (bytes32) envfree;
    function BROADCASTER_ROLE() external returns (bytes32) envfree;
    function RECOVERY_ROLE() external returns (bytes32) envfree;
}

// Common environment constraints and assumptions

/**
 * Defines standard assumptions about msg sender for testing RBAC functions
 * Creates environments that represent owner, broadcaster, and recovery roles
 */
function env_for_roles() returns (env e_owner, env e_broadcaster, env e_recovery, env e_other) {
    // Basic environment
    e_owner = havoc_env();
    e_broadcaster = havoc_env();
    e_recovery = havoc_env();
    e_other = havoc_env();
    
    // Different actors should have different addresses
    require e_owner.msg.sender != e_broadcaster.msg.sender;
    require e_owner.msg.sender != e_recovery.msg.sender;
    require e_broadcaster.msg.sender != e_recovery.msg.sender;
    
    // Other sender is not any of the three privileged roles
    require e_other.msg.sender != e_owner.msg.sender;
    require e_other.msg.sender != e_broadcaster.msg.sender;
    require e_other.msg.sender != e_recovery.msg.sender;
    
    // None of the addresses should be zero
    require e_owner.msg.sender != 0;
    require e_broadcaster.msg.sender != 0;
    require e_recovery.msg.sender != 0;
    require e_other.msg.sender != 0;
    
    // Same block/tx parameters
    require e_owner.block.timestamp == e_broadcaster.block.timestamp;
    require e_owner.block.timestamp == e_recovery.block.timestamp;
    require e_owner.block.timestamp == e_other.block.timestamp;
}

/**
 * Defines standard assumptions about time for time-based operations
 * Creates environments for "before timelock" and "after timelock"
 */
function env_for_timelock(uint256 releaseTime) returns (env e_before, env e_after) {
    // Create two environments
    e_before = havoc_env();
    e_after = havoc_env();
    
    // Constrain timestamps relative to release time
    require e_before.block.timestamp < releaseTime;
    require e_after.block.timestamp >= releaseTime;
    
    // Same sender to isolate time effect
    require e_before.msg.sender == e_after.msg.sender;
}

/**
 * Defines a common set of valid input values and constraints
 * to standardize inputs across specifications
 */
ghost uint256 MIN_VALID_TIMELOCK_PERIOD() returns uint256 { return 1; }
ghost uint256 MAX_VALID_TIMELOCK_PERIOD() returns uint256 { return 60 * 24 * 365 * 10; } // 10 years in minutes
ghost uint256 MAX_REASONABLE_TXN_ID() returns uint256 { return 1000; }
ghost address ZERO_ADDRESS() returns address { return 0; }

/**
 * Filter definitions for common use cases
 */
definition nonViewFilter(method f) returns bool = !f.isView;
definition noConstructorFilter(method f) returns bool = !f.isConstructor; 