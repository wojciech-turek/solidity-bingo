# Bingo Game

This solidity Bingo game that allows players to create their own bingo game where the creator is also a player, other players can join by paying a fee and the host draws numbers until any of the players get a bingo.
Players can call function `shoutBingo` when they get a match which is equivalent of standing up in the bingo game room and shouting Bingo!, little less embarassing if you don't have a bingo though.
The frontend would listen to events emitted by the smart contract to show numbers to players.

Historical games can be retrieved to show when they started, what the pot and who was the winner.

To run a sample game (test) locally use below commands in your terminal in the project directory.

```shell
npm install
npx hardhat test
```
