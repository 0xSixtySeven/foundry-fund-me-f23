// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./helperconfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); // we create this new contract so we save some gas because it wont deploy to the chain
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // we get the address of the price feed from the helperConfig contract
        // function run() is a special function that runs when we call the contract

        //mock
        // Anything before startBroadcast will run in a virtual enviroment
        // Anything after startBroadcast will run in the real enviroment(real transaction)
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
