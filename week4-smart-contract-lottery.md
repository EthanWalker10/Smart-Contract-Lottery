# Foundry Fundamentals -- Section 4: Smart Contract Lottery

## 1. Introduction
1. Amazing: This project will be a valuable addition to your portfolio, as we'll develop a **Verifiably Random Lottery Smart Contract** that contains a lot of best coding practices.
2. we will cover **events**, **true random numbers**, **modules**, and **automation**.
3. There are detailed comments corresponding to NAT spec(recording comments of smart contract using structure method) in the sol files of the project, such as:
```
/**
// the title of smart contract
 * @title A sample Raffle Contract

 // a concise interpretation decribing the main function and purpose of the contarct targets users.
 * @notice This contract is for creating a sample raffle contract

 // a comment of the developer with more detailed info targets developers
 * @dev This implements the Chainlink VRF Version 2
 */
 ```

## 2. Smart contract lottery - Project setup
1. We are going to learn in consequent lessons(waiting for supplementing it):
   * Events;
   * On-chain randomness (done the proper way);
   * Chainlink automation
   * And many more!
2. steps to setup the project:
```
forge init // git repo appears after this step

```
3. a way to extend:
   1. the prices of the tickets are dynamic, the higher price the ticket is, the higher possibility user gain. In addition, the relationship of possibility(y) and price(x) is like `y=ln(x+1)`. Obviously, y can not be 1, we should set a limitation for it.
4. Every time we introduce a new variable we need to think about what type and visibility of variable we need to use. Here we set `immutable` so that everytime deploying a new contract we can simply pass a new value to the constructor. Af for visibility, `private` is ok, and we need to write a `getter` for it.



## 3. Solidity style guide
Solidity style:
```
// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions

// external & public view & pure functions
```


## 4. Creating custom errors
1. We changed the visibility from `public` to `external`. `External` is more gas efficient, and we won't call the `enterRaffle` function internally.
2. The `require` statement is used to enforce certain conditions at runtime. If the condition specified in the `require` statement evaluates to `false`, the transaction is reverted, and any changes made to the state within that transaction are undone.
3. **Custom errors**: a new and more gas-efficient way introduced in Solidity 0.8.4, provide a way to define and use specific error types that can be used to revert transactions with more efficient and gas-saving mechanisms compared to the `require` statements with string messages. click [here](https://soliditylang.org/blog/2021/04/21/custom-errors/) to know why.



## 5. Smart contracts events
1. Choose a storage structure to keep track of all registered users:
   1. Mapping: Mappings in Solidity are powerful but come with the limitation that you cannot iterate through them directly. If you need to loop through the entries(items) in a mapping, you must maintain an additional data structure, like an array, to keep track of the keys.
   2. Array is fine, Especially in this condition where all prices of tickets are equal.
   3. **The order of Data Type, Visibility Specifier, and Modifier**: 
      1. It is Data Type --> Visibility Specifier --> and Modifier
      2. the special case is 'payable', which modify the Data type(address) itself but variable or visibility. So it has to follow the Data Type.
      3. The custom of naming variables is 
         1. immutable -> i_
         2. state -> s_
         3. constant -> UPPER_UNDERSCORE
2. **Events**: a way for smart contracts to communicate with the outside world, primarily with the front-end applications that interact with these contracts. Events are logs that the Ethereum Virtual Machine (EVM) stores in a special data structure known as the blockchain log. These logs can be efficiently accessed and filtered by external applications, such as dApps (decentralized applications) or off-chain services. The logs can also be accessed from the blockchain nodes. Each emitted event is tied up to the smart contract that emitted it.
   1. Evnet: An event is a special type of function in Solidity that allows you to log data to the blockchain. When you define an event in your contract, you specify the data you want to include in the log.
   2. Emit: To trigger an event, you use the emit keyword followed by the event name and the necessary parameters. This action logs the data specified in the event to the blockchain.
   3. Indexed: The indexed keyword allows up to three parameters in an event to be indexed, making them searchable in the logs. This means you can filter and search for specific events based on the indexed parameters. Simply, we create an index on this variable.



## 6. Random numbers - Block Timestamp
1. Set a decent amount of time using block timestamps



## 7. Random numbers - Introduction to Chainlink VRF(Verifiable Random Function)
Summary: the principle of using Chainlink VRF for generating random numbers in blockchain applications.
1. Chainlink VRF provides randomness in 3 steps:
   1. Requesting Randomness: A smart contract makes a request for randomness by calling the `requestRandomness` function provided by the Chainlink VRF. This involves sending a request to the Chainlink oracle along with the necessary fees.

   2. Generating Randomness: The Chainlink oracle node generates a random number off-chain using a secure cryptographic method. The oracle also generates a proof that this number was generated in a verifiable manner.

   3. Returning the Result: The oracle returns the random number along with the cryptographic proof to the smart contract. The smart contract can then use the random number, and any external observer can verify the proof to confirm the authenticity and integrity of the randomness.
2. **I have to find a way to get some Sepolia Eth**:
   1. mining [here](https://sepolia-faucet.pk910.de/)
   2. get 0.001 ETH on the mainnet.
3. steps to introduce a chainlink VRF
   1. Create a subscription with my wallet address
   2. send a transaction
   3. sign the request from `vrf.chain.link`, the content of the request is:
   ```
   Message

   Welcome to Chainlink VRF!
   We require a signature in order to ensure you are the owner of the subscription.
   Wallet address:
   0x67612f0d87a3a6bbc13074bf54c0500dba12f4d4
   VRF Coordinator address:
   0x9ddfaca8183c41ad55329bdeed9f6a8d53168b1b
   Subscription ID:
   94372659827754995745485973588981096746673275253965000816464276966814827436584
   ```
   4. Fund subscription
   5. Add consumer: our smart contract and Chainlink VRF need to be aware of each other, which means that Chainlink needs to know the address that will consume the LINK we provided in our subscription and the smart contract needs to know the Subscription ID. **Question**: my subscription ID doesn't work in remix, why? Don't mind now, the lession doesn't tell me to deploy in Remix. Just grasp the notions.
   6. These are the gas lanes available on Ethereum mainnet, you can find out info about all available gas lanes [here](https://docs.chain.link/vrf/v2/subscription/supported-networks).The `keyHash` variable represents the gas lane we want to use. Think of those as the maximum gas price you are willing to pay for a request in WEI. It functions as an ID of the off-chain VRF job that runs in response to requests. The same page contains information about `Max Gas Limit` and `Minimum Confirmations`. Our contract specifies those in `callbackGasLimit` and `requestConfirmations`.
   7. `callbackGasLimit` and `requestConfirmations`.
      1.  `callbackGasLimit` needs to be adjusted depending on the number of random words you request and the logic you are employing in the callback function.
      2. `requestConfirmations` specifies the number of block confirmations required before the Chainlink VRF node responds to a randomness request. This parameter plays a crucial role in ensuring the security and reliability of the randomness provided. A higher number of block confirmations reduces the risk of chain reorganizations affecting the randomness request. Chain reorganizations (or reorgs) occur when the blockchain reorganizes due to the discovery of a longer chain, which can potentially alter the order of transactions.
   8. Another extremely important aspect related to Chainlink VRF is understanding its `Security Considerations`. Please read them [here](https://docs.chain.link/vrf/v2-5/security#use-requestid-to-match-randomness-requests-with-their-fulfillment-in-order)






## 8. Implement the Chainlink VRF
Summary: Tutorial on deploying and integrating Chainlink VRF in smart contracts for **random number generation**.
1. a command to set remappings: `forge remappings>remappings.txt`   Of course we may mend it sometimes.
2. In Solidity, when a contract inherits from a base contract that has a constructor with parameters, the derived contract must pass the appropriate arguments to the base constructor when it is instantiated. If the derived contract does not do this, the compiler will raise an error.



## 9. Implementing Vrf Fulfil
Summary: A comprehensive guide to implementing Chainlink VRF Fulfill......From here, the lesson scripts is diffrent from the code in video and repo. 
1. abstract contract can contain both defining and undefining functions. Undefining functions are modified by `virtual`, waiting for us to complete it using `override`
2. There are several type declarations in solidity. We can use these types defined by ourselves to declare variables. eg:
   1. enum, allow us to define a set of named values:
   ```
   enum RaffleState {
    OPEN,
    CALCULATING
   }

   // now we can declare variables of this type, and the values of the variables are constrained in a certain scope.
   ```
   2. struct
3. quick go back: manage -> keyboradshortcuts -> search -> 'go back/front' -> `ctrl + alt + '-'`
4. **Question:** 
   1. Why are params commented out?



## 10. The modulo operation
1. use `%` to choose the winner randomly.




## 11. Implementing the lottery state - Enum
1. why we use a Enum? --Security! [here](https://docs.chain.link/vrf/v2-5/security) is Security Consideration from Chainlink VRF.
   1. Use requestId to match randomness requests with their fulfillment in order. ---- Blockchain miners/validators can control the order in which your requests appear onchain. For example, if you made randomness requests A, B, C in short succession, there is no guarantee that the associated randomness fulfillments will also be in order A, B, C. The randomness fulfillments might just as well arrive at your contract in order C, A, B or any other order.
   2. Choose a safe block confirmation time, which will vary between blockchains. ---- Confirmation time is how many blocks the VRF service waits before writing a fulfillment to the chain to make potential rewrite attacks unprofitable in the context of your application and its value-at-risk.
   3. Do not allow re-requesting or cancellation of randomness. ---- Any re-request or cancellation of randomness is an incorrect use of VRF v2.5. dApps that implement the ability to cancel or re-request randomness for specific commitments must consider the additional attack vectors created by this capability. For example, you must prevent the ability for any party to discard unfavorable randomness.
   4. **Don't accept bids/bets/inputs after you have made a randomness request.** ---- Generally speaking, whenever an outcome in your contract depends on some user-supplied inputs and randomness, the contract should not accept any additional user-supplied inputs after it submits the randomness request. Otherwise, the cryptoeconomic security properties may be violated by an attacker that can rewrite the chain. In our case this translates to `Don't let people buy tickets while we calculate the final winner`. 
   5. The fulfillRandomWords function must not revert.
   6. Use VRFConsumerBaseV2Plus in your contract to interact with the VRF service.
2. **what is the order of the procedure?**


## 14. The CEI method - Checks, Effects,m Interactions
1. **who is msg?** 
   1. When we deploy a contract, the msg.sender is our address if deploying by scripts or `test contract` if deploying in test. 
2. How does user interact with smart contract directly instead of via another contract.
3. review the `FundMe` contract deployed on Sepolia, the Transaction Hash is `0x579cfe4ee5e8b21a5b96ebe37ec6b5b8519c561db123ea52bc0f31397e79915c`, maybe we will use it.
4. CEI pattern, a safe and gas-efficient way to code:
   * Checks: Validate inputs and conditions to ensure the function can execute safely. This includes checking permissions, input validity, and contract state prerequisites.
   * Effects: Modify the state of our contract based on the validated inputs. This phase ensures that all **internal** state changes occur before any external interactions. **When the contract fails to update its state before sending funds, the attacker can continuously call the withdraw function to drain the contract’s funds.** `receive()` Function will exec auto after the `Attacker` contruct received the balance from `VulnerableBank` contruct and trigger the `withdraw()` Function again.
   * Interactions: Perform external calls to other contracts or accounts. This is the last step to prevent reentrancy attacks, where an external call could potentially call back into the original function before it completes, leading to unexpected behavior. (More about reentrancy attacks on a later date)



## 15. Introduction to Chainlink Automation
1. The task is: automatically pick a winner
2. The steps to Chainlink Automation / UpkeepL:
   1. deploy a contract on one net, get the address and ABI(or verify it on the net by publishing the source code)
   2. register a new Upkeep and follow the guideline(choose time-based)
   3. then it can call the function we choosed in the time-based way, we can check it in the `History` section.
3. In our contract, we need to override 2 functions(checkUpKeep() and performUpKeep()) to implement an interface `AutomationCompatibleInterface` so that our contract can be compatible to the Automation.
4. **function signature:** 
   ```
   // the following items are function signatures, just like declarations.
   interface MyInterface {
      function setValue(uint256 _value) external;
      function getValue() external view returns (uint256);
   }
   ```
5. Contrac, Interface, Library:
   | **Type**       | **Features**                                     | **Usage**                                   | **State Storage** |
   | -------------- | -------------------------------------------- | ------------------------------------------ | ----------------- |
   | **Contract**   | Main unit of Solidity, includes functions, state variables, inheritance, events | Deployed to the blockchain, defines specific business logic | Has state storage  |
   | **Interface**  | Contains only function signatures without implementation | Used to define interaction standards between contracts (e.g., ERC-20) | No state storage   |
   | **Library**    | A set of reusable functions for contracts        | Provides utility functions, reduces code duplication | No state storage   |
 

## 16. Implementing Chainlink Automation
1. 2 functions
   1. checkUpKeep(): 
      1. If a function expects an input, but we are not going to use it we can comment it out like this: /* checkData */. 
      2. `checkUpkeep()` can use onchain data and a specified `checkData` parameter to perform complex calculations offchain and then send the result to `performUpkeep()` as `performData`.




## 18. Mid section recap
What did we do: 
* We implemented Chainlink VRF to get a random number;
* We defined a couple of variables that we need both for Raffle operation and for Chainlink VRF interaction;
* We have a not-so-small constructor;
* We've created a method for the willing participants to enter the Raffle;
* Then made the necessary integrations with Chainlink Automation to automatically draw a winner when the time is right.
* When the time is right and after the Chainlink nodes perform the call then Chainlink VRF will provide the requested randomness inside `fulfillRandomWords`;
* The randomness is used to find out who won, the prize is sent, raffle is reset.

