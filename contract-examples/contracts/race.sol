interface IRaceCalculator {
  function getRaceWinner(uint256[] memory birds, uint256[] memory track) external view returns (uint256, uint256);
}

contract raceExample {
  address constant RACE_CALC = 0x0300000000000000000000000000000000000001"

  function testRace(uint256[] memory birds, uint256[] memory trackProperties) public view returns (uint256, uint256) {
    (uint256 score, uint256 index) = IRaceCalculator(RACE_CALC).getRaceWinner(birds, trackProperties);
    return (score, index);
  }
}
