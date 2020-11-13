pragma solidity 0.6.6;

import "./vrf/VRFConsumerBase.sol";
import {lottery_interface} from "./interfaces/lottery_interface.sol";
import {governance_interface} from "./interfaces/governance_interface.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping (uint => uint) public randomNumber; 
    mapping (bytes32 => uint) public requestIds;
    governance_interface public governance;
    uint256 public most_recent_random;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Ropsten
     * Chainlink VRF Coordinator address: 0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb
     * LINK token address:                0x20fE562d797A42Dcb3399062AE9546cd06f63280
     * Key Hash: 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205
     */
    constructor(address _governance) 
        // TODO how does this work?? 
        VRFConsumerBase(
            0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb, // VRF Coordinator  
            0x20fE562d797A42Dcb3399062AE9546cd06f63280  // LINK Token       
            // TODO how to pay link tokens on conflux network? a market website on conflux? 
            //if not, how can we call an oracle node on conflux?
        ) public
    {
        keyHash = 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205; // TODO what's keyHash, how to use it, where to get it?
        fee = 0.1 * 10 ** 18; // 0.1 LINK 
        governance = governance_interface(_governance);
    }

    /** 
     * Requests randomness from a user-provided seed
     */
     
    function getRandom(uint256 userProvidedSeed, uint256 lotteryId) public {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet"); // TODO do we need to deposite toekns to randomness and lottery contract?
        bytes32 _requestId = requestRandomness(keyHash, fee, userProvidedSeed); //TODO defination of requestRandomness, read Chainlink doc
        requestIds[_requestId] = lotteryId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external override { // TODO what's bytes32? array and string in frontend javascript
        require(msg.sender == vrfCoordinator, "Fulillment only permitted by Coordinator");
        most_recent_random = randomness;
        uint lotteryId = requestIds[requestId];
        randomNumber[lotteryId] = randomness;
        lottery_interface(governance.lottery()).fulfill_random(randomness);
    }
}


