// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BalanceHolder.sol";
import "./StoreAccounting.sol";
import "./StoreStorage.sol";


contract TechnoLimeStoreFront is BalanceHolder, StoreAccounting, StoreStorage {

    function addNewProduct(string calldata productName, uint cost, uint initQuantity) public override(StoreStorage) onlyOwner {
        super.addNewProduct(productName, cost, initQuantity);
    }

    function restock(uint productId, uint quantity) public override(StoreStorage) onlyOwner { 
        super.restock(productId, quantity);
    }

    function purchase(uint productId, uint quantity) external payable 
        productExists(productId) 
        nonZeroQuantity(quantity)
        productEnoughtQuanitity(productId, quantity) 
        productPayedExactly(productId, quantity)
        clientHasNotPurchasedProduct(productId) {

        decreateQuantity(productId, quantity);
        addNewPurchase(productId, quantity);
    }

    function refund(uint purchaseId) public override(StoreAccounting) {
        super.refund(purchaseId);
        super.restock(purchases[purchaseId].productId, purchases[purchaseId].quantity);
    }
    
}