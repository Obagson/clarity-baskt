Clarinet.test({
  name: "Can perform batch updates and validates inputs",
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
    
    // Batch update items
    let batchBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'batch-update-items', [
        listId,
        types.list([
          types.tuple({
            name: types.ascii("Milk"),
            quantity: types.uint(2),
            price: types.uint(399),
            category: types.ascii("Dairy")
          }),
          types.tuple({
            name: types.ascii("Bread"),
            quantity: types.uint(1),
            price: types.uint(299),
            category: types.ascii("Bakery")
          })
        ])
      ], wallet1.address)
    ]);
    
    assertEquals(batchBlock.receipts[0].result.expectOk(), true);
    
    // Test invalid price
    let invalidBlock = chain.mineBlock([
      Tx.contractCall('baskt', 'update-list-item', [
        listId,
        types.uint(0),
        types.ascii("Invalid"),
        types.uint(0),
        types.uint(0),
        types.ascii("Test")
      ], wallet1.address)
    ]);
    
    assertEquals(invalidBlock.receipts[0].result.isErr(), true);
  },
});

// [Previous tests remain unchanged...]
