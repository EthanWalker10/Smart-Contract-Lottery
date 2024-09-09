// SPDX-License-Identifier: MIT
// This specifies the license type, in this case, MIT, which is a common open-source license.

pragma solidity 0.8.19;
// The version of Solidity being used, which is `0.8.19`.

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
// These are imports from Chainlink contracts and libraries, which provide the VRF (Verifiable Random Function) and Automation (Keepers) functionality.
// `VRFConsumerBaseV2Plus` is the base contract that handles the interaction with the VRF Coordinator for randomness.
// `AutomationCompatibleInterface` is used for Chainlink Keepers functionality to automate certain contract functions.

// The contract declaration begins here
/**
 * @title A sample Raffle Contract
 * @author Ethan Walker
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Errors */
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    // Custom errors defined to make the contract more gas-efficient. 
    // These errors are thrown in certain conditions like when upkeep isn't needed, a transfer fails, or the player doesn't send enough funds to enter the raffle.

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    // Enum declaration to represent the state of the raffle. 
    // The raffle can either be in the `OPEN` state, where new players can enter, or in the `CALCULATING` state, where a winner is being determined.

    /* State variables */
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    // These variables store configuration details for interacting with Chainlink VRF.
    // `i_subscriptionId`: ID of the Chainlink VRF subscription.
    // `i_gasLane`: The maximum gas price you're willing to pay for VRF.
    // `i_callbackGasLimit`: The gas limit for the callback function to process the random number.
    // `REQUEST_CONFIRMATIONS`: Number of confirmations before VRF provides randomness.
    // `NUM_WORDS`: Number of random words you want from VRF, in this case, just one.

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;
    // `i_interval`: How much time must pass before another raffle can happen.
    // `i_entranceFee`: The amount of ETH required to enter the raffle.
    // `s_lastTimeStamp`: Timestamp of the last time the raffle was run.
    // `s_recentWinner`: The most recent winner of the raffle.
    // `s_players`: Dynamic array to store addresses of players who enter the raffle.
    // `s_raffleState`: Tracks the current state of the raffle (OPEN or CALCULATING).

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);
    // These events are emitted when specific actions take place in the contract.
    // `RequestedRaffleWinner`: Emitted when a request for randomness (VRF) is made.
    // `RaffleEnter`: Emitted when a new player enters the raffle.
    // `WinnerPicked`: Emitted when a random winner is chosen.

    /* Functions */
    // cause Raffle inherits VRFConsumerBaseV2Plus, we need to pass corresponding params to the constructor of it
    // param `vrfCoordinator` is the address of VRFCoordinator contract
    constructor(
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        // Constructor for initializing the contract.
        // It sets the values for the Chainlink VRF configuration and raffle settings.
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        // Players enter the raffle by sending ETH.
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle(); 
            // Reverts if the player sends less ETH than the entrance fee.
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
            // Reverts if the raffle is not in the OPEN state.
        }
        s_players.push(payable(msg.sender));
        // The player's address is added to the list of participants.
        emit RaffleEnter(msg.sender);
        // Emits the `RaffleEnter` event to log the new participant.
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
        // This function checks if the conditions for running the raffle are met.
        // It checks if enough time has passed, if the raffle is open, if there are players, and if the contract has a balance.
        // If all conditions are true, `upkeepNeeded` will be true, allowing the raffle to proceed.
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
            // Reverts if upkeep is not needed.
        }

        s_raffleState = RaffleState.CALCULATING;
        // Changes the raffle state to CALCULATING to indicate that a winner is being determined.

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
        // Requests a random number from Chainlink VRF and emits the `RequestedRaffleWinner` event.
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable ; // Resets the players array after a winner is picked.
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
            // Sends the contract balance to the winner, reverting if the transfer fails.
        }
    }

    /**
     * Getter Functions
     */
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
    // Returns the current state of the raffle.

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }
    // Returns the constant number of words used for randomness (1).

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
    // Returns the constant number of confirmations required for the VRF request (3).

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
    // Returns the address of the most recent winner.

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
    // Returns the address of a player at a specific index in the `s_players` array.

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
    // Returns the timestamp of the last time the raffle was run.

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
    // Returns the time interval for running the raffle.

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
    // Returns the entrance fee to participate in the raffle.

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
    // Returns the number of players currently entered in the raffle.
}
