// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner(); // error declaration, we use the name of the contract with two underscores and the name of the error

contract FundMe {
    using PriceConverter for uint256; // using is like importing a library, but for a function

    // State Variables
    mapping(address => uint256) private s_addressToAmountFunded; // mapping is like a dictionary, it maps an address to a uint256
    address[] private s_funders; // array of addresses
    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner; // we use "i_" for immutable. Immutable is like constant, but it can be set in the constructor
    uint256 public constant MINIMUM_USD = 5e18; // we use CAPS for constants
    AggregatorV3Interface private s_priceFeed; // We use "s_" for private variables(or also called state variables), we use private for variables that we dont want to be accessed from outside the contract

    constructor(address priceFeed) {
        // constructor is a special function that runs once when the contract is deployed
        i_owner = msg.sender; // msg.sender is the person who deployed the contract
        s_priceFeed = AggregatorV3Interface(priceFeed); // we need to pass the address of the price feed to the constructor
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // Modifiers in Solidity are special functions that modify the behavior of other functions. They allow developers to add extra conditions or functionality without having to rewrite the entire function.
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // this is a special character that means that the code will continue to run after the modifier is done running
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; // this way me make it cheaper to run the for loop, because it will only run once and read fundersLength from memory instead of storage
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex]; // we get the address of the funder
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /*
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
