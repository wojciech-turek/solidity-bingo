import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const deployBingoFixture = async () => {
  const MockToken = await ethers.getContractFactory("MockERC20");
  const mockToken = await MockToken.deploy(
    "MockERC20",
    "MTK",
    "1000000000000000000000000"
  );

  const [owner, otherAccount, player2] = await ethers.getSigners();
  // mint some tokens for otherAccount
  await mockToken.mint(otherAccount.address, "1000000000000000000000000");
  await mockToken.mint(player2.address, "1000000000000000000000000");
  const Bingo = await ethers.getContractFactory("Bingo");
  const bingo = await Bingo.deploy(
    60, // 1 minute
    60, // 1 minute
    mockToken.address,
    "1000000000000000000"
  );

  // approve bingo contract to spend tokens on behalf of owner
  await mockToken.approve(bingo.address, "1000000000000000000000000", {
    from: owner.address,
  });

  await mockToken
    .connect(otherAccount)
    .approve(bingo.address, "1000000000000000000000000");

  await mockToken
    .connect(player2)
    .approve(bingo.address, "1000000000000000000000000");

  return { bingo, owner, otherAccount, mockToken, player2 };
};

describe("Bingo", async function () {
  describe("Game", async function () {
    this.beforeAll(async function () {
      const { bingo, owner, otherAccount, player2 } = await loadFixture(
        deployBingoFixture
      );
      this.bingo = bingo;
      this.owner = owner;
      this.otherAccount = otherAccount;
      this.player2 = player2;
    });
    it("should allow anyone can create a new game", async function () {
      const tx = await this.bingo.createGame();
      const receipt = await tx.wait();
      expect(receipt.status).to.equal(1);
      expect((await this.bingo.games(1)).startTime).to.be.greaterThan(0);
      const tx2 = await this.bingo.connect(this.otherAccount).createGame();
      const receipt2 = await tx2.wait();
      expect(receipt2.status).to.equal(1);
      expect((await this.bingo.games(2)).startTime).to.be.greaterThan(0);
    });
    it("should allow players can join a game", async function () {
      const tx = await this.bingo.connect(this.otherAccount).joinGame(1);
      const receipt = await tx.wait();
      expect(receipt.status).to.equal(1);
      expect((await this.bingo.games(1)).pot).to.equal("2000000000000000000");
    });
    it("should not allow players to join a game that does not exist", async function () {
      await expect(
        this.bingo.connect(this.otherAccount).joinGame(3)
      ).to.be.revertedWith("Game is not active");
    });
    it("should not allow to draw number if game has not started", async function () {
      await expect(this.bingo.drawNumber(1)).to.be.revertedWith(
        "It is not time to draw a number yet"
      );
    });
    it("should be able to draw a number", async function () {
      // wait for 1 minute
      await ethers.provider.send("evm_increaseTime", [60]);
      const tx = await this.bingo.connect(this.owner).drawNumber(1);
      const receipt = await tx.wait();
      // ready data from event
      const { args } = receipt.events[0];
      // returns correct game id
      expect(args[0]).to.equal(1);
      // returns a number between 0 and 255
      expect(args[1]).to.be.greaterThanOrEqual(0);
      expect(args[1]).to.be.lessThanOrEqual(255);
    });
    it("should not allow players to join a game that has already started", async function () {
      await expect(
        this.bingo.connect(this.player2).joinGame(1)
      ).to.be.revertedWith("Game is not open for joining");
    });
  });
  describe("Test Game (up to 300 draws)", async function () {
    this.beforeAll(async function () {
      const { bingo, owner, otherAccount } = await loadFixture(
        deployBingoFixture
      );
      this.bingo = bingo;
      this.owner = owner;
      this.otherAccount = otherAccount;
      this.game = await this.bingo.createGame();

      // join game
      await this.bingo.connect(this.otherAccount).joinGame(1);
    });
    it("should be able to determine winner", async function () {
      for (let i = 0; i < 300; i++) {
        await ethers.provider.send("evm_increaseTime", [80]);
        const tx = await this.bingo.connect(this.owner).drawNumber(1);
        await tx.wait();

        try {
          await this.bingo.connect(this.owner).shoutBingo(1);
        } catch (e: any) {}
        try {
          await this.bingo.connect(this.otherAccount).shoutBingo(1);
        } catch (e: any) {}

        const winnerAddress = (await this.bingo.games(1)).winner;
        if (winnerAddress !== ethers.constants.AddressZero) {
          if (winnerAddress === this.owner.address) {
            console.log("The player number one won");
          } else if (winnerAddress === this.otherAccount.address) {
            console.log("The player number two won");
          } else {
            console.log("No winner");
          }
          console.log("The game took ", i + 1, " draws.");
          break;
        }
      }
    });
  });
  describe("Game getters", async function () {
    this.beforeAll(async function () {
      const { bingo, owner, otherAccount } = await loadFixture(
        deployBingoFixture
      );
      this.bingo = bingo;
      this.owner = owner;
      this.otherAccount = otherAccount;
      this.game = await this.bingo.createGame();
      await this.bingo.connect(this.otherAccount).joinGame(1);
      await this.bingo.createGame();
    });
    it("should allow to get players board", async function () {
      const board = await this.bingo.getPlayerBoard(1, this.owner.address);
      expect(board).to.be.an("array").and.to.have.lengthOf(5);
    });
    it("should allow to get paginated games", async function () {
      const games = await this.bingo.getGames(10, 0);
      expect(games).to.be.an("array").and.to.have.lengthOf(2);
    });
  });
});
