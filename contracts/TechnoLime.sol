// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BalanceHolder.sol";

/**
    requirement mapping: 
       1. The administrator (owner) of the store should be able to add new products and the quantity of them. -> function addNewProduct;
       2. The administrator should not be able to add the same product twice, -> first line of addNewProduct 
                just quantity. -> function restock
       3. Buyers (clients) should be able to see the available products -> function getProducts;
            and buy them by their id. -> function purchase
       4. Buyers should be able to return products if they are not satisfied (within a certain period in blocktime: 100 blocks). -> function refund
       5. A client cannot buy the same product more than one time. -> third line of function purchase
       6. The clients should not be able to buy a product more times than the quantity in the store -> second line of function purchase
            unless 
                a product is returned or -> function refund call internal _restock
                added by the administrator (owner) -> external function restock callable only by owner
       7. Everyone should be able to see the addresses of all clients that have ever bought a given product. -> function getProductsPurchasers               
*/
contract TechnoLime is BalanceHolder {
    struct Product {
        uint id;
        string name;
        uint quantity;
        uint cost;
    }
    Product[] public products; 
    mapping(string => bool) productNameExists;

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
    mapping(address => mapping(uint => bool)) clientToProductPurchaseMap;
    mapping(uint => address[]) productToPurchasersMap;

    event ItemAdded(uint productId, uint initialQuantity);
    event Purchased(uint purchaseId, uint productId, address client, uint quantity);
    event Refunded(uint purchseId, uint productId, address client, uint quantity);
    event Restocked(uint productId, uint quantity);

    modifier productExists(uint id){
        require(products.length > id, "product does not exist");
        _;
    }

    modifier nonZeroQuantity(uint quantity){
        require(quantity > 0, "quantity cannot be 0");
        _;
    }

    function addNewProduct(string calldata productName, uint cost, uint initQuantity) external onlyOwner nonZeroQuantity(initQuantity){
        require(!productNameExists[productName], "product already exists");
        
        uint productId = products.length;
        products.push(Product({
            id: productId,
            name: productName,
            quantity: initQuantity,
            cost: cost
        }));
        productNameExists[productName] = true;
        
        emit ItemAdded(productId, initQuantity);
    }

    function restock(uint productId, uint quantity) external onlyOwner {
        _restock(productId, quantity);
    }

    function _restock(uint productId, uint quantity) internal productExists(productId) nonZeroQuantity(quantity) {
        products[productId].quantity += quantity;
        emit Restocked(productId, quantity);
    }

    function getProducts() external view returns (Product[] memory){
        return products;
    }

    function getPurchases() external view returns (Purchase[] memory){
        return purchases;
    }

    function getProductsPurchasers(uint productId) external view productExists(productId) returns(address[] memory){
        return productToPurchasersMap[productId];
    }

    function purchase(uint productId, uint quantity) external payable productExists(productId) nonZeroQuantity(quantity) {
        Product memory product = products[productId];
        require(product.quantity >= quantity, "not enough stock");
        require(!clientToProductPurchaseMap[msg.sender][productId], "Already Purchased by client");
        require((product.cost * quantity) == msg.value, "amount sent is not exactly equal to cost");

        products[productId].quantity -= quantity;

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

    function refund(uint purchaseId) external {
        require(purchases.length > purchaseId, "Purchase does not exists");
        Purchase storage purchaseToRefund = purchases[purchaseId];
        
        require(purchaseToRefund.client == msg.sender, "Sender is not on purchase");
        require(!purchaseToRefund.isReturned, "Purchase already refunded");
        require(block.number - purchaseToRefund.blockNumber <= 100, "Refund not within 100 blocks");
        require(address(this).balance >= purchaseToRefund.payed, "Not enough balance to refund");
        
        purchaseToRefund.isReturned = true;
        payable(msg.sender).transfer(purchaseToRefund.payed);
        _restock(purchaseToRefund.productId, purchaseToRefund.quantity);
        
        emit Refunded(purchaseId, purchaseToRefund.productId, msg.sender, purchaseToRefund.quantity);
    }
}