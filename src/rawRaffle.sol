// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";


error Raffle_NotEnoughEthSent();

/**
 * @title A sample Raffle Contract
 * @author Ethan Walker
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2 and Chainlink Automation
 */
contract RawRaffle is VRFConsumerBaseV2 {

    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds, we need a decent amount of time passed(not too short)
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    // Chainlink VRF related variables, divide the `Raffle` variables from the `Chainlink VRF` variables to keep the contract tidy.
    // address immutable i_vrfCoordinator;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    // request 1 word
    uint32 private constant NUM_WORDS = 1;
    

    event EnteredRaffle(address indexed player);
    
    // initiate the VRFConsumerBaseV2 using our constructor VRFConsumerBaseV2(vrfCoordinator) because of inheriting relationship
    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        if(msg.value < i_entranceFee) revert Raffle_NotEnoughEthSent();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);

    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function pickWinner() public {
        // check to see if enough time has passed
        if(block.timestamp - s_lastTimeStamp < i_interval) revert();

        // Getting a random, First we make a request tomthe chainlink VRF contract
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }
    // This will be called by the `vrfCoordinator` when it sends back the requested `randomWords`. This is also where we'll select our winner!
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

    }

    /** Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

}