//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // This will make that the address can be picked from any chain and we dont have to hardcode the addresses.
    NetworkConfig public activeNetworkConfig; // this is a struct that we will create later in the contract and it will be used to store the price feed address.

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 3000e8;

    struct NetworkConfig {
        // This is a struct, it is a way to group data together.
        address priceFeed; // this is the address of the price feed
    }

    constructor() {
        // this is the constructor, it runs when the contract is deployed
        if (block.chainid == 11155111) {
            // we can obtain the chainid from the site: chainid.org
            activeNetworkConfig = getSepoliaEthConfig(); // this is how we call a function that returns a struct
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // pure is a way to tell solidity that this function will not modify the state of the contract
        NetworkConfig memory sepoliaConfig = NetworkConfig({ // this is how we create a new struct
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
        // memory is a way to tell solidity that this is a temporary variable and it will be deleted after the function is done.
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            // this is how we compare an address to 0, it means if the address is different to 0 we have a price feed
            return activeNetworkConfig;
        }
        // pure is a way to tell solidity that this function will not modify the state of the contract
        // For anvil we need to use a mock, because we dont have a price feed for anvil. mocks are used for testing, are like fake contracts.
        // when we use vm. we need to take away the "pure" from the function.
        // we need to change the contract to "contract HelperConfig is Script", so we can use vm. to run the function.
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
