// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.2;

import "forge-std/Test.sol";
import "../../../contracts/core/access/SecureOwnable.sol";
import "../../../contracts/lib/MultiPhaseSecureOperation.sol";
import "../../../certora/harness/SecureOwnableHarness.sol";
import "../../../certora/harness/MultiPhaseSecureOperationHarness.sol";

/**
 * @title SecureOwnableTest
 * @dev Comprehensive test suite for SecureOwnable and MultiPhaseSecureOperation
 */
contract SecureOwnableTest is Test {
    // Test contracts
    SecureOwnableHarness private secureOwnableContract;
    MultiPhaseSecureOperationHarness private libraryHarness;
    
    // Test accounts
    address private owner = address(0x1);
    address private broadcaster = address(0x2);
    address private recovery = address(0x3);
    address private newOwner = address(0x4);
    address private newBroadcaster = address(0x5);
    address private newRecovery = address(0x6);
    address private attacker = address(0x7);
    
    // Constants
    uint256 private timeLockPeriodInMinutes = 60; // 1 hour
    bytes32 private constant OWNERSHIP_TRANSFER = keccak256("OWNERSHIP_TRANSFER");
    bytes32 private constant BROADCASTER_UPDATE = keccak256("BROADCASTER_UPDATE");
    bytes32 private constant RECOVERY_UPDATE = keccak256("RECOVERY_UPDATE");
    bytes32 private constant TIMELOCK_UPDATE = keccak256("TIMELOCK_UPDATE");
    
    function setUp() public {
        // Setup SecureOwnableHarness
        secureOwnableContract = new SecureOwnableHarness(
            owner,
            broadcaster, 
            recovery,
            timeLockPeriodInMinutes
        );
        
        // Setup MultiPhaseSecureOperationHarness
        libraryHarness = new MultiPhaseSecureOperationHarness(
            owner,
            broadcaster,
            recovery,
            timeLockPeriodInMinutes
        );
        
        // Add standard operation types to library harness
        libraryHarness.addOperationType(
            MultiPhaseSecureOperation.ReadableOperationType({
                operationType: OWNERSHIP_TRANSFER,
                name: "OWNERSHIP_TRANSFER"
            })
        );
        
        libraryHarness.addOperationType(
            MultiPhaseSecureOperation.ReadableOperationType({
                operationType: BROADCASTER_UPDATE,
                name: "BROADCASTER_UPDATE"
            })
        );
        
        libraryHarness.addOperationType(
            MultiPhaseSecureOperation.ReadableOperationType({
                operationType: RECOVERY_UPDATE,
                name: "RECOVERY_UPDATE"
            })
        );
        
        libraryHarness.addOperationType(
            MultiPhaseSecureOperation.ReadableOperationType({
                operationType: TIMELOCK_UPDATE,
                name: "TIMELOCK_UPDATE"
            })
        );
    }
    
    /*********************************
     * SecureOwnable Contract Tests  *
     *********************************/
    
    function testInitialState() public {
        // Verify initial state
        assertEq(secureOwnableContract.owner(), owner, "Owner should be correctly set");
        assertEq(secureOwnableContract.getBroadcaster(), broadcaster, "Broadcaster should be correctly set");
        assertEq(secureOwnableContract.getRecoveryAddress(), recovery, "Recovery address should be correctly set");
        assertEq(secureOwnableContract.getTimeLockPeriodInMinutes(), timeLockPeriodInMinutes, "Time lock period should be correctly set");
        
        // Check roles
        assertEq(secureOwnableContract.getRoleAddress(secureOwnableContract.OWNER_ROLE()), owner, "Owner role not set correctly");
        assertEq(secureOwnableContract.getRoleAddress(secureOwnableContract.BROADCASTER_ROLE()), broadcaster, "Broadcaster role not set correctly");
        assertEq(secureOwnableContract.getRoleAddress(secureOwnableContract.RECOVERY_ROLE()), recovery, "Recovery role not set correctly");
    }
    
    function testDisabledDirectOwnershipTransfer() public {
        // Attempt direct ownership transfer
        vm.prank(owner);
        vm.expectRevert("Direct ownership transfer disabled");
        secureOwnableContract.transferOwnership(newOwner);
    }
    
    function testDisabledOwnershipRenouncement() public {
        // Attempt to renounce ownership
        vm.prank(owner);
        vm.expectRevert("Ownership renouncement disabled");
        secureOwnableContract.renounceOwnership();
    }
    
    function testOwnershipTransferProcess() public {
        // 1. Request ownership transfer from recovery account
        vm.prank(recovery);
        MultiPhaseSecureOperation.TxRecord memory txRecord = secureOwnableContract.transferOwnershipRequest();
        
        // Verify request was recorded
        assertEq(uint8(txRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.PENDING), "Transaction should be pending");
        assertEq(txRecord.params.operationType, OWNERSHIP_TRANSFER, "Operation type should be ownership transfer");
        assertTrue(secureOwnableContract.hasOpenOwnershipRequest(), "Should have open ownership request");
        
        // 2. Skip forward in time to bypass timelock
        vm.warp(block.timestamp + timeLockPeriodInMinutes * 60);
        
        // 3. Approve ownership transfer by owner
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory approvedRecord = secureOwnableContract.transferOwnershipDelayedApproval(txRecord.txId);
        
        // 4. Verify ownership was transferred
        assertEq(secureOwnableContract.owner(), recovery, "Owner should be updated to recovery address");
        assertEq(uint8(approvedRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.COMPLETED), "Transaction should be completed");
        assertFalse(secureOwnableContract.hasOpenOwnershipRequest(), "Should not have open ownership request");
        
        // 5. Verify role was updated
        assertEq(secureOwnableContract.getRoleAddress(secureOwnableContract.OWNER_ROLE()), recovery, "Owner role should be updated");
    }
    
    function testOwnershipTransferCancellation() public {
        // 1. Request ownership transfer from recovery account
        vm.prank(recovery);
        MultiPhaseSecureOperation.TxRecord memory txRecord = secureOwnableContract.transferOwnershipRequest();
        
        // 2. Cancel ownership transfer request
        vm.prank(recovery);
        MultiPhaseSecureOperation.TxRecord memory cancelledRecord = secureOwnableContract.transferOwnershipCancellation(txRecord.txId);
        
        // 3. Verify request was cancelled
        assertEq(uint8(cancelledRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.CANCELLED), "Transaction should be cancelled");
        assertFalse(secureOwnableContract.hasOpenOwnershipRequest(), "Should not have open ownership request");
        
        // 4. Verify ownership was not transferred
        assertEq(secureOwnableContract.owner(), owner, "Owner should not change");
    }
    
    function testBroadcasterUpdateProcess() public {
        // 1. Request broadcaster update
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory txRecord = secureOwnableContract.updateBroadcasterRequest(newBroadcaster);
        
        // Verify request was recorded
        assertEq(uint8(txRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.PENDING), "Transaction should be pending");
        assertEq(txRecord.params.operationType, BROADCASTER_UPDATE, "Operation type should be broadcaster update");
        assertTrue(secureOwnableContract.hasOpenBroadcasterRequest(), "Should have open broadcaster request");
        
        // 2. Skip forward in time to bypass timelock
        vm.warp(block.timestamp + timeLockPeriodInMinutes * 60);
        
        // 3. Approve broadcaster update
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory approvedRecord = secureOwnableContract.updateBroadcasterDelayedApproval(txRecord.txId);
        
        // 4. Verify broadcaster was updated
        assertEq(secureOwnableContract.getBroadcaster(), newBroadcaster, "Broadcaster should be updated");
        assertEq(uint8(approvedRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.COMPLETED), "Transaction should be completed");
        assertFalse(secureOwnableContract.hasOpenBroadcasterRequest(), "Should not have open broadcaster request");
        
        // 5. Verify role was updated
        assertEq(secureOwnableContract.getRoleAddress(secureOwnableContract.BROADCASTER_ROLE()), newBroadcaster, "Broadcaster role should be updated");
    }
    
    function testBroadcasterUpdateCancellation() public {
        // 1. Request broadcaster update
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory txRecord = secureOwnableContract.updateBroadcasterRequest(newBroadcaster);
        
        // 2. Cancel broadcaster update request
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory cancelledRecord = secureOwnableContract.updateBroadcasterCancellation(txRecord.txId);
        
        // 3. Verify request was cancelled
        assertEq(uint8(cancelledRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.CANCELLED), "Transaction should be cancelled");
        assertFalse(secureOwnableContract.hasOpenBroadcasterRequest(), "Should not have open broadcaster request");
        
        // 4. Verify broadcaster was not updated
        assertEq(secureOwnableContract.getBroadcaster(), broadcaster, "Broadcaster should not change");
    }
    
    function testValidationFunctions() public {
        // Test non-zero address validation
        vm.expectRevert("Invalid address");
        secureOwnableContract.validateNotZeroAddress(address(0));
        
        // Test operation type validation
        vm.expectRevert("Invalid operation type");
        secureOwnableContract.validateOperationType(bytes32(0), OWNERSHIP_TRANSFER);
        
        // Test handler selector validation
        bytes4 selector1 = bytes4(keccak256("test1()"));
        bytes4 selector2 = bytes4(keccak256("test2()"));
        vm.expectRevert("Invalid handler selector");
        secureOwnableContract.validateHandlerSelector(selector1, selector2);
        
        // Test new address validation
        address currentAddr = address(0x123);
        vm.expectRevert("Not new address");
        secureOwnableContract.validateNewAddress(currentAddr, currentAddr);
    }
    
    /********************************************
     * MultiPhaseSecureOperation Library Tests  *
     ********************************************/
    
    function testLibraryInitialState() public {
        // Verify initial state of library
        assertEq(libraryHarness.getOwner(), owner, "Owner should be set");
        assertEq(libraryHarness.getTimeLockPeriod(), timeLockPeriodInMinutes, "TimeLock should be set");
        assertEq(libraryHarness.getCurrentTxId(), 0, "Initial tx counter should be 0");
        assertEq(libraryHarness.getNonce(), 0, "Initial nonce should be 0");
        
        // Check supported operation types
        assertTrue(libraryHarness.isOperationTypeSupported(OWNERSHIP_TRANSFER), "Ownership transfer operation should be supported");
        assertTrue(libraryHarness.isOperationTypeSupported(BROADCASTER_UPDATE), "Broadcaster update operation should be supported");
        assertTrue(libraryHarness.isOperationTypeSupported(RECOVERY_UPDATE), "Recovery update operation should be supported");
        assertTrue(libraryHarness.isOperationTypeSupported(TIMELOCK_UPDATE), "Timelock update operation should be supported");
    }
    
    function testRoleManagement() public {
        // Verify role assignments
        assertTrue(libraryHarness.hasRole(libraryHarness.OWNER_ROLE(), owner), "Owner role should be assigned");
        assertTrue(libraryHarness.hasRole(libraryHarness.BROADCASTER_ROLE(), broadcaster), "Broadcaster role should be assigned");
        assertTrue(libraryHarness.hasRole(libraryHarness.RECOVERY_ROLE(), recovery), "Recovery role should be assigned");
        
        // Verify other accounts don't have roles
        assertFalse(libraryHarness.hasRole(libraryHarness.OWNER_ROLE(), attacker), "Attacker should not have owner role");
        assertFalse(libraryHarness.hasRole(libraryHarness.BROADCASTER_ROLE(), attacker), "Attacker should not have broadcaster role");
        assertFalse(libraryHarness.hasRole(libraryHarness.RECOVERY_ROLE(), attacker), "Attacker should not have recovery role");
    }
    
    function testTransactionLifecycle() public {
        // 1. Create tx request
        vm.prank(owner);
        bytes memory execOptions = libraryHarness.createStandardExecutionOptions(bytes4(keccak256("test()")), abi.encode(uint256(123)));
        
        MultiPhaseSecureOperation.TxRecord memory txRecord = libraryHarness.txRequest(
            owner,
            address(this),
            0,
            1000000,
            OWNERSHIP_TRANSFER,
            MultiPhaseSecureOperation.ExecutionType.STANDARD,
            execOptions
        );
        
        // Verify request data
        assertEq(txRecord.txId, 1, "Transaction ID should be 1");
        assertEq(txRecord.releaseTime, block.timestamp + (timeLockPeriodInMinutes * 60), "Release time should be set correctly");
        assertEq(uint8(txRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.PENDING), "Status should be PENDING");
        
        // 2. Skip time and approve transaction
        vm.warp(block.timestamp + timeLockPeriodInMinutes * 60);
        vm.prank(owner);
        
        // This will fail because the target contract doesn't implement the function, which is expected in a test
        MultiPhaseSecureOperation.TxRecord memory approvedRecord = libraryHarness.txDelayedApproval(txRecord.txId);
        
        // Status will be FAILED because the called function doesn't exist
        assertEq(uint8(approvedRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.FAILED), "Status should be FAILED");
    }
    
    function testTransactionCancellation() public {
        // 1. Create tx request
        vm.prank(owner);
        bytes memory execOptions = libraryHarness.createStandardExecutionOptions(bytes4(keccak256("test()")), abi.encode(uint256(123)));
        
        MultiPhaseSecureOperation.TxRecord memory txRecord = libraryHarness.txRequest(
            owner,
            address(this),
            0,
            1000000,
            OWNERSHIP_TRANSFER,
            MultiPhaseSecureOperation.ExecutionType.STANDARD,
            execOptions
        );
        
        // 2. Cancel transaction
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory cancelledRecord = libraryHarness.txCancellation(txRecord.txId);
        
        // Verify cancellation
        assertEq(uint8(cancelledRecord.status), uint8(MultiPhaseSecureOperation.TxStatus.CANCELLED), "Status should be CANCELLED");
    }
    
    function testOperationTypesManagement() public {
        // Get all supported operation types
        MultiPhaseSecureOperation.ReadableOperationType[] memory types = libraryHarness.getSupportedOperationTypes();
        
        // Verify all types are present
        assertEq(types.length, 4, "Should have 4 operation types");
        
        // Test type names
        bool foundOwnershipTransfer = false;
        bool foundBroadcasterUpdate = false;
        bool foundRecoveryUpdate = false;
        bool foundTimelockUpdate = false;
        
        for (uint i = 0; i < types.length; i++) {
            if (types[i].operationType == OWNERSHIP_TRANSFER && 
                keccak256(bytes(types[i].name)) == keccak256(bytes("OWNERSHIP_TRANSFER"))) {
                foundOwnershipTransfer = true;
            }
            else if (types[i].operationType == BROADCASTER_UPDATE && 
                    keccak256(bytes(types[i].name)) == keccak256(bytes("BROADCASTER_UPDATE"))) {
                foundBroadcasterUpdate = true;
            }
            else if (types[i].operationType == RECOVERY_UPDATE && 
                    keccak256(bytes(types[i].name)) == keccak256(bytes("RECOVERY_UPDATE"))) {
                foundRecoveryUpdate = true;
            }
            else if (types[i].operationType == TIMELOCK_UPDATE && 
                    keccak256(bytes(types[i].name)) == keccak256(bytes("TIMELOCK_UPDATE"))) {
                foundTimelockUpdate = true;
            }
        }
        
        assertTrue(foundOwnershipTransfer, "Should have ownership transfer type");
        assertTrue(foundBroadcasterUpdate, "Should have broadcaster update type");
        assertTrue(foundRecoveryUpdate, "Should have recovery update type");
        assertTrue(foundTimelockUpdate, "Should have timelock update type");
    }
    
    /***************************
     * Security & Edge Cases   *
     ***************************/
    
    function testUnauthorizedAccess() public {
        // Try to call owner-only functions as non-owner
        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
        secureOwnableContract.updateBroadcasterRequest(newBroadcaster);
        
        // Try to call broadcaster-only functions as non-broadcaster
        vm.prank(attacker);
        vm.expectRevert("Restricted to Broadcaster");
        secureOwnableContract.transferOwnershipApprovalWithMetaTx(
            MultiPhaseSecureOperation.MetaTransaction({
                txRecord: MultiPhaseSecureOperation.TxRecord({
                    txId: 0,
                    releaseTime: 0,
                    status: MultiPhaseSecureOperation.TxStatus.PENDING,
                    params: MultiPhaseSecureOperation.TxParams({
                        requester: address(0),
                        target: address(0),
                        value: 0,
                        gasLimit: 0,
                        operationType: bytes32(0),
                        executionType: MultiPhaseSecureOperation.ExecutionType.NONE,
                        executionOptions: new bytes(0)
                    }),
                    message: bytes32(0),
                    result: new bytes(0),
                    payment: MultiPhaseSecureOperation.PaymentDetails({
                        recipient: address(0),
                        nativeTokenAmount: 0,
                        erc20TokenAddress: address(0),
                        erc20TokenAmount: 0
                    })
                }),
                params: MultiPhaseSecureOperation.MetaTxParams({
                    chainId: 0,
                    nonce: 0,
                    handlerContract: address(0),
                    handlerSelector: bytes4(0),
                    deadline: 0,
                    maxGasPrice: 0,
                    signer: address(0)
                }),
                message: bytes32(0),
                signature: new bytes(0),
                data: new bytes(0)
            })
        );
        
        // Try to call recovery-only functions as non-recovery
        vm.prank(attacker);
        vm.expectRevert("Restricted to recovery");
        secureOwnableContract.transferOwnershipRequest();
    }
    
    function testInvalidTimelock() public {
        // Attempt to approve before timelock period
        
        // 1. Request broadcaster update
        vm.prank(owner);
        MultiPhaseSecureOperation.TxRecord memory txRecord = secureOwnableContract.updateBroadcasterRequest(newBroadcaster);
        
        // 2. Attempt to approve immediately (before timelock expires)
        vm.prank(owner);
        vm.expectRevert("Current time is before release time");
        secureOwnableContract.updateBroadcasterDelayedApproval(txRecord.txId);
    }
    
    function testZeroAddressRejection() public {
        // Attempt to update broadcaster to zero address
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        secureOwnableContract.updateBroadcasterRequest(address(0));
    }
    
    function testExternalSelector() public {
        // Test execution of internal functions from external contracts
        vm.prank(address(0));
        vm.expectRevert("Only callable by contract itself");
        secureOwnableContract.executeTransferOwnership(newOwner);
    }
} 