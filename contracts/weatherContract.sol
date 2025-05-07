// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WeatherContract {
    uint256 private temperature; // Temperature in degree Celsius

    event WeatherUpdated(uint256 newTemperature);

    // Setter for the temperature
    function setWeather(uint256 _temperature) public {
        temperature = _temperature;
        emit WeatherUpdated(_temperature);
    }

    // Getter for the temperature
    function getWeather() public view returns (uint256) {
        return temperature;
    }
}