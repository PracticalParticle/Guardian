import { Address, PublicClient, WalletClient, Chain, Hex } from 'viem';
import DynamicRBACABIJson from '../../../abi/DynamicRBAC.abi.json';
import { TransactionOptions, TransactionResult } from '../interfaces/base.index';
import { IDynamicRBAC } from '../interfaces/core.access.index';
import { TxAction } from '../types/lib.index';
// import { DYNAMIC_RBAC_FUNCTION_SELECTORS } from '../types/core.access.index';
import { BaseStateMachine } from './BaseStateMachine';

/**
 * @title DynamicRBAC
 * @notice TypeScript wrapper for DynamicRBAC smart contract
 */
export class DynamicRBAC extends BaseStateMachine implements IDynamicRBAC {
  constructor(
    client: PublicClient,
    walletClient: WalletClient | undefined,
    contractAddress: Address,
    chain: Chain
  ) {
    super(client, walletClient, contractAddress, chain, DynamicRBACABIJson);
  }

  // Role Management Functions
  async createRole(roleName: string, maxWallets: bigint, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('createRole', [roleName, maxWallets], options);
  }

  async updateRole(roleHash: Hex, newRoleName: string, newMaxWallets: bigint, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('updateRole', [roleHash, newRoleName, newMaxWallets], options);
  }

  async deleteRole(roleHash: Hex, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('deleteRole', [roleHash], options);
  }

  // Wallet Management Functions
  async addWalletToRole(roleHash: Hex, wallet: Address, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('addWalletToRole', [roleHash, wallet], options);
  }

  async revokeWallet(roleHash: Hex, wallet: Address, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('revokeWallet', [roleHash, wallet], options);
  }

  async replaceWalletInRole(roleHash: Hex, newWallet: Address, oldWallet: Address, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('replaceWalletInRole', [roleHash, newWallet, oldWallet], options);
  }

  // Permission Management Functions
  async addFunctionPermissionToRole(roleHash: Hex, functionSelector: Hex, action: TxAction, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('addFunctionPermissionToRole', [roleHash, functionSelector, action], options);
  }

  async removeFunctionPermissionFromRole(roleHash: Hex, functionSelector: Hex, options: TransactionOptions): Promise<TransactionResult> {
    return this.executeWriteContract('removeFunctionPermissionFromRole', [roleHash, functionSelector], options);
  }

  // Query Functions
  async getDynamicRoles(): Promise<Hex[]> {
    return this.executeReadContract<Hex[]>('getDynamicRoles');
  }

  async getAllRoles(): Promise<Hex[]> {
    return this.executeReadContract<Hex[]>('getAllRoles');
  }

  async getRoleInfo(roleHash: Hex): Promise<{
    roleName: string;
    roleHashReturn: Hex;
    maxWallets: bigint;
    walletCount: bigint;
    isProtected: boolean;
    authorizedWallets: Address[];
    functionPermissions: any[];
  }> {
    // Get basic role info from BaseStateMachine
    const roleInfo = await this.getRole(roleHash);
    
    // Get authorized wallets list
    const authorizedWallets = await this.getWalletsInRole(roleHash);
    
    // Get function permissions for the role
    const functionPermissions = await this.getRolePermission(roleHash);
    
    return {
      roleName: roleInfo.roleName,
      roleHashReturn: roleInfo.roleHashReturn,
      maxWallets: roleInfo.maxWallets,
      walletCount: roleInfo.walletCount,
      isProtected: roleInfo.isProtected,
      authorizedWallets,
      functionPermissions
    };
  }

  // DynamicRBAC-specific methods

  async getWalletsInRole(roleHash: Hex): Promise<Address[]> {
    return this.executeReadContract<Address[]>('getWalletsInRole', [roleHash]);
  }

  async getRolePermissions(roleHash: Hex): Promise<{
    functionSelectors: Hex[];
    actions: TxAction[];
  }> {
    return this.executeReadContract<{
      functionSelectors: Hex[];
      actions: TxAction[];
    }>('getRolePermissions', [roleHash]);
  }

  async roleExists(roleHash: Hex): Promise<boolean> {
    return this.executeReadContract<boolean>('roleExists', [roleHash]);
  }

  async isRoleProtected(roleHash: Hex): Promise<boolean> {
    return this.executeReadContract<boolean>('isRoleProtected', [roleHash]);
  }

  async getRoleWalletCount(roleHash: Hex): Promise<bigint> {
    return this.executeReadContract<bigint>('getRoleWalletCount', [roleHash]);
  }

  async isRoleAtCapacity(roleHash: Hex): Promise<boolean> {
    return this.executeReadContract<boolean>('isRoleAtCapacity', [roleHash]);
  }
}

export default DynamicRBAC;
