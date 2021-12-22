//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Dunia {

    using SafeMath for uint256;

    address public owner;
    uint256 public noOracles;
    uint256 public noGames;
    uint256 public noGameOutcomes;
    uint256 public noBets;
    uint256 public noPunters;
    uint256 public totalOwnerCommissions;
    uint256 public availableOwnerCommissions;

    struct Oracle {
        address payable account;
        bool status;
        uint256 noOfGames;
        uint256 totalCommissions;
        uint256 availableCommissions;        
    }

    struct Game {    
        string description;
        uint256 oracleID;
        uint256 noGameOutcome;
        uint256 totalValue;
        bool finalised;
        uint256 selectedGameOutcome;
    }

    struct GameOutcome {
        string description;
        uint256 gameID;
        uint256 totalValue;
        uint256 noBets;  
        uint256[] gameOutcomeBets;       
    }

    struct Bet {
        uint256 gameID;
        uint256 gameOutcomeID;
        uint256 punterID;
        uint256 betValue;
    }

    struct Punter {
        address payable account;
        uint256 totalBets;
        uint256 totalWins;
        uint256 availableWins;
    }

    
    mapping(uint256 => Oracle) oracles;
    mapping(uint256 => Game) games;
    mapping(uint256 => GameOutcome) gameOutcomes;
    mapping(uint256 => Bet) bets;
    mapping(uint256 => Punter) punters;

    event OracleRegistered(
        address indexed _oracleAddress,
        uint256 indexed _oracleID
    );

    event OracleToogled(
        uint256 indexed _oracleID,
        bool oldStatus,
        bool newStatus
    );    

    event GameCreated(
        uint256 indexed _gameID,
        string _description,
        uint256 indexed _oracleID
    );

    event PunterCreated(
        uint256 indexed _punterID,
        address indexed _walletAddress
    );


    event BetCreated(
        uint256 indexed _gameID,
        uint256 indexed _gameOutcomeID,
        uint256 indexed _punterID,
        uint256 betValue
    );

    event GameFinalised(
        uint256 indexed _gameID,
        uint256 _selectedOutcome,
        uint256 totalWins,
        uint256 totalBets
    );

    event PunterWithdrawCoin(
        uint256 indexed _punterID,
        address walletAddress,
        uint256 withdrawalAmount
    );

    event OracleWithdrawCoin(
        uint256 indexed _oracleID,
        address walletAddress,
        uint256 withdrawalAmount        
    );

    event OwnerWithdrawCoin(
        uint256 withdrawalAmount
    );

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor() {        
        owner = msg.sender;
        noOracles = 0;
        noGames = 0;
        noGameOutcomes = 0;
        noBets = 0;
        noPunters = 0;
        totalOwnerCommissions = 0;
        availableOwnerCommissions = 0;
        console.log("Deploying Contract with owner:", msg.sender);
    }    

    function registerOracle(address payable _oracleAddress) public onlyOwner returns (uint256 oracleID) {
        oracleID = noOracles++;
        Oracle storage oracle = oracles[oracleID];
        oracle.account = payable(_oracleAddress);
        oracle.status = true;
        oracle.noOfGames = 0;
        oracle.totalCommissions = 0;
        oracle.availableCommissions = 0;
        
        emit OracleRegistered(_oracleAddress, oracleID);
    }

    function toggleOracle(uint256 _oracleID) public onlyOwner {
        Oracle storage oracle = oracles[_oracleID];
        bool oldStatus = oracle.status;
        bool newStatus = !oracle.status;
        oracle.status = newStatus;

        emit OracleToogled(_oracleID, oldStatus, newStatus);
    }


    function createGame(string memory _description, uint256 _oracleID) public returns (uint256 gameID) {
        gameID = noGames++;
        Game storage game = games[gameID];
        game.description = _description;
        game.oracleID = _oracleID;
        game.noGameOutcome = 0;
        game.totalValue = 0;
        game.finalised = false;
        game.selectedGameOutcome = 0;

        emit GameCreated(gameID, _description, _oracleID);
    }

    function createGameOutcome(string memory _description, uint256 _gameID) public returns (uint256 gameOutcomeID) {
        gameOutcomeID = noGameOutcomes++;
        GameOutcome storage gameOutcome = gameOutcomes[gameOutcomeID];
        gameOutcome.description = _description;
        gameOutcome.totalValue = 0;        
        gameOutcome.noBets = 0;
        gameOutcome.gameID = _gameID;
    }

    function createPunter () public returns (uint256 punterID) {
        punterID = noPunters++;
        Punter storage punter = punters[punterID];
        address payable _walletAddress = payable(msg.sender);
        punter.account = _walletAddress;
        punter.totalBets = 0;
        punter.totalWins = 0;
        punter.availableWins = 0;       

        emit PunterCreated(punterID, _walletAddress);
    }

    function createBet(uint256 _gameOutcomeID, uint256 _punterID) public payable returns (uint256 betID) {   

        uint256 betValue = msg.value;
        betID = noBets++;
        Bet storage bet = bets[betID];        

        GameOutcome storage gameOutcome = gameOutcomes[_gameOutcomeID];
        gameOutcome.gameOutcomeBets.push(betID);
        gameOutcome.totalValue.tryAdd(betValue);

        uint256 gameID = gameOutcome.gameID;

        Game storage game = games[gameID];
        game.totalValue.tryAdd(betValue);

        bet.gameID = gameID;
        bet.gameOutcomeID = _gameOutcomeID;
        bet.punterID = _punterID;
        bet.betValue = betValue;

        Punter storage punter = punters[_punterID];
        punter.totalBets++;

        emit BetCreated(gameID, _gameOutcomeID, _punterID, betValue);
    }

    function finaliseGame(uint256 _gameID, uint256 _selectedOutcome) public  {

        uint256 gameOutcomeID = _selectedOutcome;

        Game storage game = games[_gameID];
        game.finalised = true;
        game.selectedGameOutcome = gameOutcomeID;  

        uint256 commissionToOracle = game.totalValue;
        commissionToOracle.tryMul(3);
        commissionToOracle.tryDiv(100);

        uint256 commissionToOwner = game.totalValue;
        commissionToOwner.tryMul(7);
        commissionToOwner.tryDiv(100);   
        totalOwnerCommissions.tryAdd(commissionToOwner);
        availableOwnerCommissions.tryAdd(commissionToOwner);

        uint256 oracleID = game.oracleID;
        
        Oracle storage oracle = oracles[oracleID];
        oracle.totalCommissions.tryAdd(commissionToOracle);
        oracle.availableCommissions.tryAdd(commissionToOracle);

        GameOutcome storage gameOutcome = gameOutcomes[gameOutcomeID];
        uint256 arrayLength = gameOutcome.gameOutcomeBets.length;

        uint256 betTotalWins = game.totalValue;
        uint256 betTotalPool = gameOutcome.totalValue;
        betTotalWins.tryMul(90);
        betTotalWins.tryDiv(100);        

        for (uint i = 0; i < arrayLength; i++) {

            uint256 betID = gameOutcome.gameOutcomeBets[i];

            Bet storage bet = bets[betID];  

            uint256 punterID = bet.punterID;
            uint256 betValue = bet.betValue;
            uint256 betWinningRatio = betValue;
            betWinningRatio.tryMul(betTotalWins);
            betWinningRatio.tryDiv(betTotalPool);

            Punter storage punter = punters[punterID];
            punter.totalWins.tryAdd(betWinningRatio);
            punter.availableWins.tryAdd(betWinningRatio);

        }        

        emit GameFinalised(_gameID, gameOutcomeID, game.totalValue, arrayLength);  
    }

    function punterWithdrawCoin(uint256 _punterID, uint256 _withdrawalAmount) public {
        Punter storage punter = punters[_punterID];
        uint256 availableWins = punter.availableWins;
        address payable walletAddress = punter.account;
        
        require(msg.sender == walletAddress, 'Caller is not the punter');
        require(_withdrawalAmount <= availableWins, 'Withdrawal amount cannot exceed available wins');

        walletAddress.transfer(_withdrawalAmount);
        punter.availableWins.trySub(_withdrawalAmount);

        emit PunterWithdrawCoin(_punterID, walletAddress, _withdrawalAmount);
    }   

    function oracleWithdrawCoin(uint256 _oracleID, uint256 _withdrawalAmount) public  {
        Oracle storage oracle = oracles[_oracleID];
        uint256 availableCommissions = oracle.availableCommissions;
        address payable walletAddress = oracle.account;
        
        require(msg.sender == walletAddress, 'Caller is not the oracle');
        require(_withdrawalAmount <= availableCommissions, 'Withdrawal amount cannot exceed available commissions');

        walletAddress.transfer(_withdrawalAmount);   
        oracle.availableCommissions.trySub(_withdrawalAmount); 

        emit OracleWithdrawCoin(_oracleID, walletAddress, _withdrawalAmount); 
    } 

    function ownerWithdrawCoin(uint256 _withdrawalAmount) public onlyOwner {
        require(_withdrawalAmount <= availableOwnerCommissions, 'Withdrawal amount cannot exceed available commissions');
        
        address payable ownerWallet = payable(owner);
        ownerWallet.transfer(_withdrawalAmount);
        availableOwnerCommissions.trySub(_withdrawalAmount);

        emit OwnerWithdrawCoin(_withdrawalAmount);
    }  

}
