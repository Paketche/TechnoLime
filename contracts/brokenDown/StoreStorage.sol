// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StoreStorage {
    struct Product {
        uint id;
        string name;
        uint quantity;
        uint cost;
    }
    Product[] public products; 
    mapping(string => bool) productNameExists;

    event ItemAdded(uint productId, uint initialQuantity);
    event Restocked(uint productId, uint quantity);

    modifier productExists(uint id){
        require(products.length > id, "product does not exist");
        _;
    }

    modifier nonZeroQuantity(uint quantity){
        require(quantity > 0, "quantity cannot be 0");
        _;
    }

    modifier productEnoughtQuanitity(uint productId, uint quantity) {
         require(products[productId].quantity >= quantity, "not enough stock");
        _;
    }

    modifier productPayedExactly(uint productId, uint quantity) {
        require((products[productId].cost * quantity) == msg.value, "amount sent is not exactly equal to cost");
        _;
    }

    function addNewProduct(string calldata productName, uint cost, uint initQuantity) public virtual nonZeroQuantity(initQuantity) {
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

    function restock(uint productId, uint quantity) public virtual productExists(productId) nonZeroQuantity(quantity){
        products[productId].quantity += quantity;
        emit Restocked(productId, quantity);
    }

    function getProducts() external view returns (Product[] memory){
        return products;
    }

    function decreateQuantity(uint productId, uint quantity) internal productExists(productId){
        products[productId].quantity -= quantity; 
    }
}