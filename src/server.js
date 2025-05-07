require('dotenv').config();
const express = require('express');
const axios = require('axios');
const { ethers } = require('ethers');

const app = express();
const port = process.env.PORT || 3000;

// Minimal ABI for the smart contract (assumes a function: setWeather(uint256 temperature))
const contractAbi = [
    "function setWeather(uint256 temperature) public"
];

// Create provider and signer using environment variables
const provider = new ethers.providers.JsonRpcProvider(process.env.PROVIDER_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contractAddress = process.env.CONTRACT_ADDRESS; // Set in your .env file
const weatherContract = new ethers.Contract(contractAddress, contractAbi, signer);

app.get('/weather', async (req, res) => {
    try {
        // get lat and lon from query parameters
        const { lat, lon } = req.query;
        if (!lat || !lon) {
            return res.status(400).json({ error: "Missing latitude or longitude query parameters" });
        }
        
        // Fetch weather data from OpenWeatherMap API
        const apiKey = process.env.WEATHER_API_KEY; // Set your OpenWeatherMap API key in your .env file
        const weatherUrl = `http://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&appid=${apiKey}`;
        const response = await axios.get(weatherUrl);
        const temperature = response.data.main.temp;
        
        // Call the smart contract function to set the weather temperature
        const tx = await weatherContract.setWeather(Math.floor(temperature)); 
        await tx.wait(); // Wait for transaction to be mined

        // Return the temperature in the response
        res.json({ temperature: `${temperature}°C`, transactionHash: tx.hash });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "An error occurred while fetching weather data or setting the contract." });
    }
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});