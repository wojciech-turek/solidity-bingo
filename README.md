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


Gas usage on a sample game where `shoutBingo` is called after every number drawn:

```
·----------------------------|---------------------------|-------------|-----------------------------·
|    Solc version: 0.8.17    ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····························|···························|·············|······························
|  Methods                                                                                           │
··············|··············|·············|·············|·············|···············|··············
|  Contract   ·  Method      ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
··············|··············|·············|·············|·············|···············|··············
|  Bingo      ·  createGame  ·     456862  ·     491062  ·     476405  ·            7  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  Bingo      ·  drawNumber  ·      39419  ·      59319  ·      55882  ·          220  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  Bingo      ·  joinGame    ·          -  ·          -  ·     275508  ·            4  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  Bingo      ·  shoutBingo  ·     111561  ·     122251  ·     112877  ·          218  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  MockERC20  ·  approve     ·          -  ·          -  ·      46272  ·            3  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  MockERC20  ·  mint        ·      51137  ·      51149  ·      51143  ·            2  ·          -  │
··············|··············|·············|·············|·············|···············|··············
|  Deployments               ·                                         ·  % of limit   ·             │
·····························|·············|·············|·············|···············|··············
|  Bingo                     ·          -  ·          -  ·    1760702  ·        5.9 %  ·          -  │
·····························|·············|·············|·············|···············|··············
|  MockERC20                 ·          -  ·          -  ·     673039  ·        2.2 %  ·          -  │
·----------------------------|-------------|-------------|-------------|---------------|-------------·
```
