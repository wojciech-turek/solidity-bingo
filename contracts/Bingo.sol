// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Bingo game contract
/// @author @wojciechturek.eth
/// @notice This contract is a simple implementation of a bingo game
/// @dev Some assumptions were made to simplify the implementation
/// 1. Players are online to claim a winning board
/// 2. Players are online to shout bingo
/// 3. Each game number may be between 0 and 255, inclusive (a byte)
/// 4. Boards may have duplicate numbers that can be marked by one drawn number
/// 5. Duplicate numbers may be drawn, but have no effect on the game
/// 6. Random numbers are generated with blockhash(block.number - 1)
/// 7. Bingo board markings are done on the frontend
contract Bingo is Ownable {
    using SafeERC20 for IERC20;

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

    // duration of the join phase
    uint256 public joinDuration;
    // duration of a turn, also the time between draws
    uint256 public turnDuration;
    // entry fee for a game in wei
    uint256 public entryFee;
    // token used for entry fee
    IERC20 public betToken;

    struct Game {
        uint256 gameId;
        address creator;
        uint256 entryFee;
        uint256 joinDuration;
        uint256 turnDuration;
        uint256 lastDrawTime;
        uint256 startTime;
        uint256 endTime;
        uint256 pot;
        address winner;
    }

    // gameId => playerAddress => board
    mapping(uint256 => mapping(address => uint8[5][5])) public playerBoards;
    // gameId =>  number => bool
    mapping(uint256 => mapping(uint256 => bool)) public drawnNumbers;
    // game id => address => bool
    mapping(uint256 => mapping(address => bool)) public players;

    // number of games created
    uint256 public gameCount = 0;
    // gameId => Game
    mapping(uint256 => Game) public games;

    /// @notice Constructor for the contract
    /// @dev Sets the join and turn durations, entry fee and bet token, can be changed later
    constructor(
        uint256 _joinDuration,
        uint256 _turnDuration,
        IERC20 _betToken,
        uint256 _entryFee
    ) {
        joinDuration = _joinDuration;
        turnDuration = _turnDuration;
        entryFee = _entryFee;
        betToken = _betToken;
    }

    /// @dev throws if called by any account other than the game creator
    modifier onlyGameCreator(uint256 gameId) {
        require(
            games[gameId].creator == msg.sender,
            "Only the game creator can call this function"
        );
        _;
    }

    /// @dev throws when called for a game that has not started yet or has already ended
    modifier onlyActiveGame(uint256 gameId) {
        require(
            games[gameId].startTime != 0 && games[gameId].endTime == 0,
            "Game is not active"
        );
        _;
    }

    /// @dev throws when non-player calls game related functions
    modifier onlyPlayer(uint256 gameId) {
        require(
            players[gameId][msg.sender] == true,
            "Only players can call this function"
        );
        _;
    }

    /// @notice Creates a game
    /// @dev Creates a game with the specified parameters, transfers entry fee to the contract
    function createGame() public {
        gameCount++;
        games[gameCount] = Game(
            gameCount,
            msg.sender,
            entryFee,
            joinDuration,
            turnDuration,
            block.timestamp,
            block.timestamp,
            0,
            0,
            address(0)
        );
        betToken.safeTransferFrom(msg.sender, address(this), entryFee);
        games[gameCount].pot += entryFee;
        playerBoards[gameCount][msg.sender] = generateBoard(msg.sender);
        players[gameCount][msg.sender] = true;
        emit GameCreated(
            gameCount,
            msg.sender,
            entryFee,
            joinDuration,
            turnDuration,
            block.timestamp
        );
    }

    /// @notice Allows players to join a game
    /// @dev Players can only join a game once and they need to pay the entry fee
    /// @param gameId The id of the game
    function joinGame(uint256 gameId) public onlyActiveGame(gameId) {
        require(
            games[gameId].startTime + games[gameId].joinDuration >
                block.timestamp,
            "Game is not open for joining"
        );
        require(
            players[gameId][msg.sender] == false,
            "You have already joined this game"
        );
        betToken.safeTransferFrom(
            msg.sender,
            address(this),
            games[gameId].entryFee
        );
        playerBoards[gameId][msg.sender] = generateBoard(msg.sender);
        games[gameId].pot += games[gameId].entryFee;
        players[gameId][msg.sender] = true;
        emit PlayerJoined(gameId, msg.sender);
    }

    /**  
    @notice Cancels a game noone has not joined after the join duration
    @param gameId The id of the game to cancel
    */
    function cancelGame(uint256 gameId) public onlyGameCreator(gameId) {
        if (
            games[gameId].pot % games[gameId].entryFee == 0 &&
            games[gameId].startTime + games[gameId].joinDuration <
            block.timestamp
        ) {
            betToken.safeTransfer(
                games[gameId].creator,
                games[gameId].entryFee
            );
            delete games[gameId];
            emit GameCancelled(gameId);
        }
    }

    /// @notice Draws a number for a pending game
    /// @dev Only the game creator can call this function, the game must be active and the turn duration must have passed
    /// @param gameId The id of the game
    function drawNumber(uint256 gameId)
        public
        onlyGameCreator(gameId)
        onlyActiveGame(gameId)
    {
        require(
            games[gameId].lastDrawTime + games[gameId].turnDuration <
                block.timestamp,
            "It is not time to draw a number yet"
        );
        games[gameId].lastDrawTime = block.timestamp;
        uint8 number = generateRandomNumber();
        drawnNumbers[gameId][number] = true;
        emit NumberDrawn(gameId, number);
    }

    /// @notice Allows user to claim the prize if they have won
    /// @dev We iterate over the rows, if any number in a row is not found we invalidate the row
    /// @dev and also invalidate the column to which that number belongs.
    /// @dev If any number in a diagonal is found false we know that the diagonal is invalid as well
    /// @param gameId The id of the game
    function shoutBingo(uint256 gameId)
        public
        onlyActiveGame(gameId)
        onlyPlayer(gameId)
    {
        bool[5] memory columnDeprecated;
        bool[2] memory diagonalDeprecated;
        bool isWinner = true;
        // iterate over rows
        for (uint8 i = 0; i < 5; i++) {
            isWinner = true;
            for (uint8 j = 0; j < 5; j++) {
                if (
                    !drawnNumbers[gameId][
                        playerBoards[gameId][msg.sender][i][j]
                    ]
                ) {
                    if (i != 2 && i == j) diagonalDeprecated[0] = true;
                    if (i != 2 && i == 4 - j) diagonalDeprecated[1] = true;
                    columnDeprecated[j] = true;
                    isWinner = false;
                }
            }
            if (isWinner) {
                wrapUpGame(gameId, msg.sender);
                return;
            }
        }
        // iterate over columns
        for (uint8 k = 0; k < 5; k++) {
            if (!columnDeprecated[k]) {
                wrapUpGame(gameId, msg.sender);
                return;
            }
        }
        if (!diagonalDeprecated[0] || !diagonalDeprecated[1]) {
            wrapUpGame(gameId, msg.sender);
        }
    }

    /// @notice Returns the board of a player by gameId and player address
    /// @param gameId The id of the game
    /// @param playerAddress The address of the player
    function getPlayerBoard(uint256 gameId, address playerAddress)
        external
        view
        returns (uint8[5][5] memory)
    {
        return playerBoards[gameId][playerAddress];
    }

    /// @notice Paginated function to get all games
    /// @param _resultsPerPage The number of results per page
    /// @param _page The page number
    function getGames(uint256 _resultsPerPage, uint256 _page)
        external
        view
        returns (Game[] memory)
    {
        uint256 start = _resultsPerPage * _page;
        uint256 end = start + _resultsPerPage;
        if (end > gameCount) {
            end = gameCount;
        }
        if (start > end) {
            return new Game[](0);
        }
        Game[] memory results = new Game[](end - start);
        for (uint256 i = start; i < end; i++) {
            results[i - start] = games[i];
        }
        return results;
    }

    // Admin functions

    /// @notice Changes the entry fee
    /// @param _entryFee The new entry fee
    function changeEntryFee(uint256 _entryFee) public onlyOwner {
        entryFee = _entryFee;
    }

    /// @notice Changes the join duration
    /// @param _joinDuration The new join duration
    function changeJoinDuration(uint256 _joinDuration) public onlyOwner {
        joinDuration = _joinDuration;
    }

    /// @notice Changes the turn duration
    /// @param _turnDuration The new turn duration
    function changeTurnDuration(uint256 _turnDuration) public onlyOwner {
        turnDuration = _turnDuration;
    }

    /// @notice Finishes the game and transfers the pot to the winner
    /// @param gameId The id of the game
    /// @param playerAddress The address of the winner
    function wrapUpGame(uint256 gameId, address playerAddress) private {
        games[gameId].endTime = block.timestamp;
        games[gameId].winner = playerAddress;
        betToken.safeTransfer(playerAddress, games[gameId].pot);
        emit GameEnded(gameId, playerAddress);
    }

    /// @notice Generates a random number
    function generateRandomNumber() private view returns (uint8) {
        return uint8(uint256(blockhash(block.number - 1)) % 255);
    }

    /// @notice Generates a board for a player
    /// @param playerAddress The address of the player used to make sure if two players call this function in the same block they get different numbers
    function generateBoard(address playerAddress)
        private
        view
        returns (uint8[5][5] memory)
    {
        uint8[5][5] memory board;
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = 0; j < 5; j++) {
                board[i][j] = uint8(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                i,
                                j,
                                playerAddress
                            )
                        )
                    ) % 255
                );
            }
        }
        return board;
    }
}
