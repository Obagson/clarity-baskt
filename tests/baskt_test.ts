// [Previous test content remains unchanged...]

Clarinet.test({
  name: "Can update and delete shopping list items",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create shopping list
    let block = chain.mineBlock([
      Tx.contractCall('baskt', 'create-shopping-list', [
        types.ascii("Groceries"),
        types.ascii("SuperStore")
      ], wallet1.address)
    ]);
    
    const listId = block.receipts[0].result.expectOk();
    
    // Update item
    let updateBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'update-list-item', [
        listId,
        types.uint(0),
        types.ascii("Milk"),
        types.uint(2),
        types.uint(399),
        types.ascii("Dairy")
      ], wallet1.address)
    ]);
    
    assertEquals(updateBlock.receipts[0].result.expectOk(), true);
    
    // Delete item
    let deleteBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'delete-list-item', [
        listId,
        types.uint(0)
      ], wallet1.address)
    ]);
    
    assertEquals(deleteBlock.receipts[0].result.expectOk(), true);
  },
});
