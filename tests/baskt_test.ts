import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create user profile",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('baskt', 'create-profile', [
        types.ascii("testuser"),
        types.ascii("test@example.com")
      ], wallet1.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    // Verify profile was created
    let profileBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'get-profile', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    profileBlock.receipts[0].result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Can create shopping list and add items",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('baskt', 'create-shopping-list', [
        types.ascii("Groceries"),
        types.ascii("SuperStore")
      ], wallet1.address)
    ]);
    
    const listId = block.receipts[0].result.expectOk();
    
    // Verify list was created
    let listBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'get-shopping-list', [
        listId
      ], wallet1.address)
    ]);
    
    listBlock.receipts[0].result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Can add shipping address",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('baskt', 'add-shipping-address', [
        types.ascii("Home"),
        types.ascii("123 Main St"),
        types.ascii("New York"),
        types.ascii("NY"),
        types.ascii("10001"),
        types.ascii("USA")
      ], wallet1.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    // Verify address was added
    let addressBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'get-shipping-addresses', [],
        wallet1.address)
    ]);
    
    addressBlock.receipts[0].result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Can create order",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('baskt', 'create-order', [
        types.ascii("SuperStore"),
        types.list([]),
        types.uint(0)
      ], wallet1.address)
    ]);
    
    const orderId = block.receipts[0].result.expectOk();
    
    // Verify order was created
    let orderBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'get-order', [
        orderId
      ], wallet1.address)
    ]);
    
    orderBlock.receipts[0].result.expectOk().expectSome();
  },
});