// // SPDX-License-Identifier: MIT
// not for this project 
// pragma solidity ^0.8.0;

// import "./Verifier.sol"; // Import the Verifier contract

// contract BidContractWithVerifier is Verifier {
//     struct Bid {
//         bytes32 commitment;
//         address bidder;
//         bool verified;
//     }

//     mapping(address => Bid) public bids;
//     address[] public bidders;

//     event BidSubmitted(address indexed bidder, bytes32 commitment);
//     event BidVerified(address indexed bidder, bool status);

//     // Submit a bid with a Pedersen commitment
//     function submitBid(bytes32 _commitment) public {
//         require(bids[msg.sender].bidder == address(0), "Bid already submitted");
//         bids[msg.sender] = Bid(_commitment, msg.sender, false);
//         bidders.push(msg.sender);
//         emit BidSubmitted(msg.sender, _commitment);
//     }

//     // Verify zk-SNARK proof for a bid
//     function verifyBid(
//         bytes memory _proof,
//         uint[1] memory _input // Adjust input size based on zk-SNARK circuit
//     ) public returns (bool) {
//         require(bids[msg.sender].bidder != address(0), "No bid submitted");
//         require(!bids[msg.sender].verified, "Bid already verified");

//         bool result = verifyTx(_proof, _input);
//         if (result) {
//             bids[msg.sender].verified = true;
//         }
//         emit BidVerified(msg.sender, result);
//         return result;
//     }

//     // Retrieve all verified bids
//     function getVerifiedBids() public view returns (address[] memory) {
//         address[] memory verifiedBidders = new address[](bidders.length);
//         uint index = 0;

//         for (uint i = 0; i < bidders.length; i++) {
//             if (bids[bidders[i]].verified) {
//                 verifiedBidders[index] = bidders[i];
//                 index++;
//             }
//         }
//         return verifiedBidders;
//     }
// }
