// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StoreAccounting {

    struct Purchase {
        uint id;
        uint productId;
        address client;
        uint quantity;
        uint blockNumber;
        bool isReturned;
        uint payed;
    }

    Purchase[] public purchases;
    
    mapping(uint => address[]) productToPurchasersMap;
    mapping(address => mapping(uint => bool)) clientToProductPurchaseMap;

    event Purchased(uint purchaseId, uint productId, address client, uint quantity);
    event Refunded(uint purchseId, uint productId, address client, uint quantity);

    function getPurchases() external view returns (Purchase[] memory){
        return purchases;
    }

    function getProductsPurchasers(uint productId) external view returns (address[] memory){
        return productToPurchasersMap[productId];
    }

    function addNewPurchase(uint productId, uint quantity) internal {
        uint purchaseId = purchases.length;

        purchases.push(Purchase({
            id: purchaseId,
            productId: productId,
            client: msg.sender,
            quantity: quantity,
            blockNumber: block.number,
            isReturned: false,
            payed: msg.value
        }));

        clientToProductPurchaseMap[msg.sender][productId] = true;
        productToPurchasersMap[productId].push(msg.sender);

        emit Purchased(purchaseId, productId, msg.sender, quantity);
    }

    modifier clientHasNotPurchasedProduct(uint productId) {
        require(!clientToProductPurchaseMap[msg.sender][productId], "Already Purchased by client");        
        _;
    }

    function refund(uint purchaseId) public virtual {
        require(purchases.length > purchaseId, "Purchase does not exists");
 
        Purchase memory purchaseToRefund = purchases[purchaseId];
        
        require(purchaseToRefund.client == msg.sender, "Sender is not on purchase");
        require(!purchaseToRefund.isReturned, "Purchase already refunded");
        require(block.number - purchaseToRefund.blockNumber <= 100, "Refund not within 100 blocks");
        require(address(this).balance >= purchaseToRefund.payed, "Not enough balance to refund");

        purchases[purchaseId].isReturned = true;
        payable(msg.sender).transfer(purchaseToRefund.payed);

        emit Refunded(purchaseId, purchaseToRefund.productId, msg.sender, purchaseToRefund.quantity);
    }
}