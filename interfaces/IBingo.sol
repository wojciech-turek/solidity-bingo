// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Interface that should implement your Bingo contract
/// The constructor should have the ERC20 token address, join and turn durations and entryFee as arguments
interface IBingo {
    /// @notice Event when a game is created
    /// @param gameId Game's id based on a counter (starting from 1)
    /// @param creator Creator of the game (sender)
    /// @param entryFee Entry fee for the game in wei
    /// @param joinDuration Duration of the join phase
    /// @param turnDuration Duration of a turn
    /// @param startTime Timestamp of the start of the game
    event GameCreated(
        uint256 indexed gameId,
        address indexed creator,
        uint256 entryFee,
        uint256 joinDuration,
        uint256 turnDuration,
        uint256 startTime
    );

    /// @notice Event when game ends
    /// @param gameId Game's id
    /// @param winner Winner of the game
    event GameEnded(uint256 gameId, address winner);

    /// @notice Event when game is cancelled
    /// @param gameId Game's id
    event GameCancelled(uint256 gameId);

    /// @notice Event when a player joins a game
    /// @param gameId Game's id
    /// @param player Player's address
    event PlayerJoined(uint256 gameId, address player);

    /// @notice Event when a number for a game is drawn
    /// @param gameId Game's id
    /// @param number Number drawn
    event NumberDrawn(uint256 gameId, uint8 number);

    /// @notice Object representing a game
    struct Game {
        // Game's id
        uint256 gameId;
        // Creator of game
        address creator;
        // Entry fee for the game in wei
        uint256 entryFee;
        // Duration of the join phase
        uint256 joinDuration;
        // Duration of a turn
        uint256 turnDuration;
        // Timestamp of the last draw
        uint256 lastDrawTime;
        // Timestamp of the start of the game
        uint256 startTime;
        // Timestamp of the end of the game
        uint256 endTime;
        // Total amount of tokens in the pot
        uint256 pot;
        // Winner of the game
        address winner;
    }

    // ~~~! Game Management !~~~

    /// @notice Create a game
    function createGame() external;

    /// @notice Join a game
    /// @param gameId Game's id
    function joinGame(uint256 gameId) external;

    /// @notice Cancel a game
    /// @param gameId Game's id
    function cancelGame(uint256 gameId) external;

    /// @notice Draw a number for a game
    /// @param gameId Game's id
    function drawNumber(uint256 gameId) external;

    /// @notice Shout bingo for a game to claim the prize
    /// @param gameId Game's id
    function shoutBingo(uint256 gameId) external;

    // ~~~! Getters !~~~

    /// @notice Get player's board for a game
    /// @param gameId Game's id
    /// @param playerAddress Player's address
    function getPlayerBoard(uint256 gameId, address playerAddress)
        external
        view
        returns (uint8[5][5] memory);

    /// @notice Get all games paginated
    /// @param _resultsPerPage Number of results per page
    /// @param _page Page number
    function getGames(uint256 _resultsPerPage, uint256 _page)
        external
        view
        returns (Game[] memory);

    // ~~~! Admin functions !~~~

    ///@notice Admin function to change the entry fee
    ///@param _entryFee New entry fee
    function changeEntryFee(uint256 _entryFee) external;

    ///@notice Admin function to change the join duration
    ///@param _joinDuration New join duration
    function changeJoinDuration(uint256 _joinDuration) external;

    ///@notice Admin function to change the turn duration
    ///@param _turnDuration New turn duration
    function changeTurnDuration(uint256 _turnDuration) external;
}
