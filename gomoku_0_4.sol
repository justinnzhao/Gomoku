// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Gomoku {
    uint8 constant BOARD_SIZE = 15;
    uint8 constant EMPTY = 0;
    uint8 constant BLACK = 1;
    uint8 constant WHITE = 2;
    uint8 constant BLOCK_LIMIT = 10;
    
    struct Player {
        address addr;
        uint16 wins;
        uint16 losses;
    }
    
    struct Room {
        uint256 roomId;
        address blackPlayer;
        address whitePlayer;
        uint8 currentPlayer;
        uint8[BOARD_SIZE][BOARD_SIZE] board;
        bool gameStarted;
        bool gameEnded;
        uint8 moveCount;
        uint256 lastMoveBlock;
    }
    
    mapping(address => Player) public players;
    mapping(uint256 => Room) public rooms;
    uint256 public nextRoomId;
    
    event GameStarted(uint256 roomId, address blackPlayer, address whitePlayer);
    event MoveMade(uint256 roomId, address player, uint8 x, uint8 y);
    event GameEnded(uint256 roomId, address winner);
    event GameReset(uint256 roomId);
    event PlayerJoined(uint256 roomId, address player);
    event PlayerLeft(uint256 roomId, address player);
    
    modifier onlyPlayers(uint256 roomId) {
        require(msg.sender == rooms[roomId].blackPlayer || msg.sender == rooms[roomId].whitePlayer, "Only players can make a move");
        _;
    }
    
    modifier onlyCurrentPlayer(uint256 roomId) {
        require((rooms[roomId].currentPlayer == BLACK && msg.sender == rooms[roomId].blackPlayer) || (rooms[roomId].currentPlayer == WHITE && msg.sender == rooms[roomId].whitePlayer), "It's not your turn");
        _;
    }
    
    modifier validMove(uint256 roomId, uint8 x, uint8 y) {
        require(x < BOARD_SIZE && y < BOARD_SIZE, "Invalid move");
        require(rooms[roomId].board[x][y] == EMPTY, "Cell is already occupied");
        _;
    }
    
    modifier checkBlockLimit(uint256 roomId) {
        require(block.number - rooms[roomId].lastMoveBlock <= BLOCK_LIMIT, "Exceeded block limit");
        _;
    }
    
    function createRoom() public returns (uint256) {
        uint256 roomId = nextRoomId++;
        rooms[roomId].roomId = roomId;
        return roomId;
    }
    
    function joinRoom(uint256 roomId) public {
        require(!rooms[roomId].gameStarted, "Game already started");
        require(rooms[roomId].blackPlayer == address(0) || rooms[roomId].whitePlayer == address(0), "Room is full");
        
        if (rooms[roomId].blackPlayer == address(0)) {
            rooms[roomId].blackPlayer = msg.sender;
            emit PlayerJoined(roomId, msg.sender);
        } else if (rooms[roomId].whitePlayer == address(0)) {
            rooms[roomId].whitePlayer = msg.sender;
            emit PlayerJoined(roomId, msg.sender);
            rooms[roomId].currentPlayer = (uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))) % 2 == 0) ? BLACK : WHITE; // Randomly select the first player
            rooms[roomId].gameStarted = true;
            rooms[roomId].gameEnded = false;
            rooms[roomId].moveCount = 0;
            rooms[roomId].lastMoveBlock = block.number;
            emit GameStarted(roomId, rooms[roomId].blackPlayer, rooms[roomId].whitePlayer);
        }
        
        if (players[msg.sender].addr == address(0)) {
            players[msg.sender].addr = msg.sender;
        }
    }
    
    // ... (其他函数保持不变)
}
