// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Destore is ERC1155, Ownable {
    enum Category{
        MobilePhones,
        MobileAccessories,
        Laptops,
        Desktops,
        Television,
        ComputerAccessories,
        Groceries,
        Vegetables,
        Fruits,
        FancyItems,
        Gifts,
        Appliances
    }

    struct Product{
        string productName;
        Category category;
        address sellerAddress;
        uint expiryDate;
        uint priceForUnit;
        uint qty;
        string productImageUrl;
    }

    struct Seller{
        string sellerName;
        string gstNumber;
        string sellerAddress;
        bool isSeller;
    }

    struct Buyer{
        string buyername;
        string panNumber;
        string buyerAddress;
        bool isBuyer;
    }

    mapping(uint => Product) public products;
    mapping(address => Buyer) public buyers;
    mapping(address => Seller) public sellers;

    uint nextProductId;
    IERC20 paymentToken;

    modifier onlyBuyer(){
        require(buyers[msg.sender].isBuyer, "please register as a buyer");
        _; 
    }

    modifier onlySeller(){
        require(sellers[msg.sender].isSeller, "please register as a seller");
        _; 
    }

    modifier isNotExpired(uint expiryTime) {
        require(expiryTime > block.timestamp, "product is expired");
        _;
    }

    modifier isProductNotExpired(uint productId) {
        Product memory product = products[productId];
        require(product.expiryDate > block.timestamp, "product is expired");
        _;
    }

    modifier checkQtyAndPrice(uint _qty, uint _price){
        require(_qty > 0,"qty should be greater than zero");
        require(_price > 0,"price should be greater than zero");
        _;
    }

    modifier checkQty(uint productId, uint qty){
        Product memory product = products[productId];
        require(qty<product.qty,"qty is not available");
        _;
    }

    modifier debit(uint productId, uint qty){
        Product memory product = products[productId];
        uint price = qty * product.priceForUnit;
        require(paymentToken.transfer(product.sellerAddress, price), "Payment Failed");
        product.qty -= qty;
        products[productId] = product;
        _;
    }


    event NewBuyer(address indexed buyerAddress, string buyerName);
    event NewSeller(address indexed sellerAddress, string sellerName);
    event NewProduct(uint indexed ProductId, string ProductName, address indexed sellerAddress, uint quantity, uint price);
    event ProductSold(uint indexed ProductId, address indexed sellerId, address indexed buyerId, uint quantity, uint price);


    constructor(address initialOwner, IERC20 _paymentToken) ERC1155("") Ownable(initialOwner) {
        paymentToken = _paymentToken;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function registerBuyer(
        string memory _name,
        string memory _panNumber,
        string memory _address) external{
        Buyer memory newBuyer = Buyer(_name, _panNumber, _address, true);
        buyers[msg.sender] = newBuyer;
        emit NewBuyer(msg.sender, _name);
    }

     function registerSeller(
        string memory _name,
        string memory _gstNumber,
        string memory _address) external{
        Seller memory newSeller = Seller(_name, _gstNumber, _address, true);
        sellers[msg.sender] = newSeller;
        emit NewSeller(msg.sender, _name);
    }

    function newSellOrder(
        string memory _productName,
        Category _category,
        uint _price,
        uint _expiryTime,
        uint _qty,
        string memory _productImageUrl) external onlySeller() checkQtyAndPrice(_qty,_price) isNotExpired(_expiryTime){
        Product memory newProduct = Product(_productName, _category, msg.sender, _expiryTime, _price, _qty, _productImageUrl);
        uint productId = nextProductId;
        products[productId] = newProduct;
        _mint(msg.sender, productId, _qty, "");
        nextProductId += 1;
        emit NewProduct(productId, _productName, msg.sender, _price, _qty);
    }

    function buy(
            uint _productId,
            uint _qty
    ) external onlyBuyer() isProductNotExpired(_productId) checkQty(_productId,_qty) debit(_productId,_qty){
        Product memory product = products[_productId];
        _safeTransferFrom(product.sellerAddress, msg.sender, _productId, _qty, "");
        emit ProductSold(_productId, product.sellerAddress, msg.sender, _qty, product.priceForUnit);
    }

}