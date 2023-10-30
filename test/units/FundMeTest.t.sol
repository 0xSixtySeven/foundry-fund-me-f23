// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol"; // FundMe.sol is in the parent directory
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // DeployFundMe.s.sol is in the parent directory

contract FundMeTest is Test {
    FundMe fundMe;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    address USER = makeAddr("user"); // this is how we create a new address, so we can later in our code assign a user to make an specific tx
    uint256 constant SEND_VALUE = 0.1 ether;
    // up until here we have created a USER with a value that that use will be sending, th problem is that we havent assign any ether to this user/address, so thats what we are going to do next
    uint256 constant STARTING_BALANCE = 100e8 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // setUp is a special function that runs before each test
        // fundMe = new FundMe(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // deploy a new FundMe contract
        DeployFundMe deployFundMe = new DeployFundMe(); // deploy a new DeployFundMe contract
        fundMe = deployFundMe.run();
        // run the DeployFundMe contract and assign the result to fundMe
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        // test functions must be public
        // test functions must start with "test"
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // ask question in github tomorrow...........!!!!!!!!!

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
        // this is the address of the person who deployed FundMeTest
        // console.log(fundMe.i_owner());
        // console.log(address(this));
        // assertEq(fundMe.i_owner(), msg.sender); // this gives an error because we are calling FundMeTest, and FundMeTest is the one calling FundMe. So the owner is FundMeTest, not the person who deployed FundMeTest. thats why theres a dicrepancy between the two addresses.
        // to fix this we need to change msg.sender to the address of the person who deployed FundMeTest.
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4); //  4 englobes all the versions of the price feed
    }

    function testFundFailsWithNotEnoughETH() public {
        vm.expectRevert(); // this is how we tell the test that we expect the transaction to revert
        // fundMe.fund(); // this will revert because we are not sending enough ETH
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // this is how we tell the test that we want to pretend to be a different user
        fundMe.fund{value: SEND_VALUE}(); // fund with 6 ETH

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); // get the amount funded by USER
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testIsOnlyOwnerTheOneWithdrowing() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrowWithASingleFunder() public funded {
        // When we do a test we need to mentaly think about this structure with 3 components:
        // Arrange: setup the test enviroment
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act: execute the code we want to test
        uint256 gasStart = gasleft(); // this is how we get the amount of gas we have left after the transaction is done
        vm.txGasPrice(GAS_PRICE); // this is how we tell the test that we want to use 0 gas price (we dont want to spend gas
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // this is how we call a function from a contract, should have spent gas?

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // this is how we calculate the amount of gas we used
        console.log(gasUsed);

        // Assert: check that the code we executed did what we expected it to do
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        // ARRANGE

        // if we want to create addresses we use uint160, because addresses are 20 bytes long, and 20 * 8 = 160
        uint160 numberOfFunders = 10; // we are going to fund 10 times
        uint160 startingFundersIndex = 1; // its better to always start the indexes with 1 because usually when we put 0 as the first index we are refering to the whole array, and it can revert
        // this means that 1++ will add 1 continuously until it reaches 10
        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            // we are going to fund 10 times starting from 2 because the first two are already funded by the previous test
            // vm.prank new address
            // vm.deal new address
            // address
            // instead of using all this code we can use "hoax", this will englobe vm.prank and vm.deal in one function call
            hoax(address(i), SEND_VALUE); // this is how we fund a new address
            fundMe.fund{value: SEND_VALUE}();
        }

        // ACT
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // this is how we start a prank
        fundMe.withdraw();
        vm.stopPrank(); // this is how we stop a prank

        // ASSERT

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    // we are coping the code from the previous test, but we are going to make it cheaper by using a for loop

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // ARRANGE

        // if we want to create addresses we use uint160, because addresses are 20 bytes long, and 20 * 8 = 160
        uint160 numberOfFunders = 10; // we are going to fund 10 times
        uint160 startingFundersIndex = 1; // its better to always start the indexes with 1 because usually when we put 0 as the first index we are refering to the whole array, and it can revert
        // this means that 1++ will add 1 continuously until it reaches 10
        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            // we are going to fund 10 times starting from 2 because the first two are already funded by the previous test
            // vm.prank new address
            // vm.deal new address
            // address
            // instead of using all this code we can use "hoax", this will englobe vm.prank and vm.deal in one function call
            hoax(address(i), SEND_VALUE); // this is how we fund a new address
            fundMe.fund{value: SEND_VALUE}();
        }

        // ACT
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // this is how we start a prank
        fundMe.cheaperWithdraw();
        vm.stopPrank(); // this is how we stop a prank

        // ASSERT

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
