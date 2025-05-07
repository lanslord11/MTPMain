// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ReputationManager {
    struct Reputation {
        uint256 alphaQuality;
        uint256 betaQuality;
        uint256 alphaPackaging;
        uint256 betaPackaging;
        uint256 alphaTimeliness;
        uint256 betaTimeliness;
        uint256 alphaSustainability;
        uint256 betaSustainability;
        uint256 alphaTransparency;
        uint256 betaTransparency;
        uint256 alphaResilience;
        uint256 betaResilience;
    }

    mapping(address => Reputation) public reputations;

    // Weights for each dimension (in percentage points)
    uint256 public weightQuality = 20;
    uint256 public weightPackaging = 20;
    uint256 public weightTimeliness = 20;
    uint256 public weightSustainability = 20;
    uint256 public weightTransparency = 10;
    uint256 public weightResilience = 10; // initial weight for resiliency

    // Total weight should remain 100.
    // The resilience weight will be adjusted dynamically based on weather conditions.

    // Weather oracle to fetch adverse weather conditions.
    AggregatorV3Interface internal weatherOracle;

    // Event for logging weight changes.
    event ResilienceWeightUpdated(uint256 newWeight);

    constructor(address _weatherOracleAddress) {
        weatherOracle = AggregatorV3Interface(_weatherOracleAddress);
    }

    /// @notice Updates the weight for the resilience dimension based on current weather conditions.
    ///         Assumes lower weatherData values indicate adverse weather.
    function updateResilienceWeight() public {
        // Fetch the latest weather condition data from the oracle.
        (, int256 weatherData, , , ) = weatherOracle.latestRoundData();

        // For example, if weatherData < 50, we consider it adverse.
        uint256 newWeight;
        if (weatherData < 35) {
            newWeight = 30; // Increase resilience weight under adverse conditions
        } else {
            newWeight = 10; // Normal conditions: lower resilience weight
        }

        // Compute the current sum of non-resilience weights.
        uint256 currentSum = weightQuality +
            weightPackaging +
            weightTimeliness +
            weightSustainability +
            weightTransparency;
        // The new total available weight for non-resilience dimensions.
        uint256 newSum = 100 - newWeight;

        // Redistribute the available weight proportionally across all non-resilience dimensions.
        weightQuality = (weightQuality * newSum) / currentSum;
        weightPackaging = (weightPackaging * newSum) / currentSum;
        weightTimeliness = (weightTimeliness * newSum) / currentSum;
        weightSustainability = (weightSustainability * newSum) / currentSum;
        weightTransparency = (weightTransparency * newSum) / currentSum;

        weightResilience = newWeight;
        emit ResilienceWeightUpdated(newWeight);
    }

    function updateReputation(
        address actor,
        uint8 dimension,
        bool positive,
        uint256 score
    ) public {
        // For simplicity, we assume 'score' is between 0 and 100.
        Reputation storage rep = reputations[actor];
        // Define increment and decrement values
        uint256 increment = score; // proportional increment for positive reviews
        uint256 decrement = 100 - score; // complementary decrement for negative reviews

        if (dimension == 1) {
            if (positive) {
                rep.alphaQuality += increment;
            } else {
                rep.betaQuality += decrement;
            }
        } else if (dimension == 2) {
            if (positive) {
                rep.alphaPackaging += increment;
            } else {
                rep.betaPackaging += decrement;
            }
        } else if (dimension == 3) {
            if (positive) {
                rep.alphaTimeliness += increment;
            } else {
                rep.betaTimeliness += decrement;
            }
        } else if (dimension == 4) {
            if (positive) {
                rep.alphaSustainability += increment;
            } else {
                rep.betaSustainability += decrement;
            }
        } else if (dimension == 5) {
            if (positive) {
                rep.alphaTransparency += increment;
            } else {
                rep.betaTransparency += decrement;
            }
        } else if (dimension == 6) {
            if (positive) {
                rep.alphaResilience += increment;
            } else {
                rep.betaResilience += decrement;
            }
        }
    }

    /// @notice Computes the composite reputation score for an actor using weighted Bayesian scores.
    /// @param actor The address of the actor.
    /// @return composite The composite reputation score.
    function getCompositeReputation(
        address actor
    ) public returns (uint256 composite) {
        Reputation storage rep = reputations[actor];
        // Calculate Bayesian scores for each dimension.
        // Adding 1 to the denominator to prevent division by zero.
        updateResilienceWeight();
        uint256 scoreQuality = (rep.alphaQuality * 100) /
            (rep.alphaQuality + rep.betaQuality + 1);
        uint256 scorePackaging = (rep.alphaPackaging * 100) /
            (rep.alphaPackaging + rep.betaPackaging + 1);
        uint256 scoreTimeliness = (rep.alphaTimeliness * 100) /
            (rep.alphaTimeliness + rep.betaTimeliness + 1);
        uint256 scoreSustainability = (rep.alphaSustainability * 100) /
            (rep.alphaSustainability + rep.betaSustainability + 1);
        uint256 scoreTransparency = (rep.alphaTransparency * 100) /
            (rep.alphaTransparency + rep.betaTransparency + 1);
        uint256 scoreResilience = (rep.alphaResilience * 100) /
            (rep.alphaResilience + rep.betaResilience + 1);

        // Compute the composite score using the weights (assumed total = 100)
        composite =
            (scoreQuality *
                weightQuality +
                scorePackaging *
                weightPackaging +
                scoreTimeliness *
                weightTimeliness +
                scoreSustainability *
                weightSustainability +
                scoreTransparency *
                weightTransparency +
                scoreResilience *
                weightResilience) /
            100;
    }
}
