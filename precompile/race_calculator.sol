interface RaceCalculator {
    function getRaceWinner(uint256[] memory birds, uint256[] memory track)
        external
        view
        returns (uint256, uint256);
}
