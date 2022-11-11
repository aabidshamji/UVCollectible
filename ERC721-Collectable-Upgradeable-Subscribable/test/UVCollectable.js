const { expect } = require('chai');
const { ethers, upgrades } = require("hardhat");

// Start test block
describe('UVCollectable', function () {
    before(async function () {
        this.factory = await ethers.getContractFactory('UVCollectable');
        // deploy the contract
        this.nonFunToken = await upgrades.deployProxy(this.factory, [
            "CRT1",
            "Creator 1 x Ultraviolet"
        ], {
            kind: 'uups',
            initializer: "initialize"
        })

        await this.nonFunToken.deployed();

        // Get the contractOwner and collector address
        const signers = await ethers.getSigners();
        this.contractOwner = signers[0].address;

        // Get the collector contract for signing transaction with collector key
        this.collectorContract = this.nonFunToken.connect(this.contractOwner);

        // Mint an initial set of NFTs from this collection
        this.initialMintCount = 20;
        this.initialMint = [];
        for (let i = 1; i <= this.initialMintCount; i++) { // tokenId to start at 1
            await this.nonFunToken.mintToken(0, this.contractOwner, false, 0);
            this.initialMint.push(i.toString());
        }
    });

    beforeEach(async function () {

    });

    // Test cases
    it('Creates a token collection with a name', async function () {
        expect(await this.nonFunToken.name()).to.exist;
        // expect(await this.nonFunToken.name()).to.equal('NonFunToken');
    });

    // it('Creates a token collection with a symbol', async function () {
    //     expect(await this.nonFunToken.symbol()).to.exist;
    //     // expect(await this.nonFunToken.symbol()).to.equal('NONFUN');
    // });

    // it('Mints initial set of NFTs from collection to contractOwner', async function () {
    //     for (let i = 0; i < this.initialMint.length; i++) {
    //         expect(await this.nonFunToken.ownerOf(this.initialMint[i])).to.equal(this.contractOwner);
    //     }
    // });

    // it('Is able to query the NFT balances of an address', async function () {
    //     expect(await this.nonFunToken.balanceOf(this.contractOwner)).to.equal(this.initialMint.length);
    // });

    // it('Emits a transfer event for newly minted NFTs', async function () {
    //     let tokenId = (this.initialMint.length + 1).toString();
    //     await expect(this.nonFunToken.mintToken(0, this.contractOwner, false, 0))
    //         .to.emit(this.nonFunToken, "Transfer")
    //         .withArgs("0x0000000000000000000000000000000000000000", this.contractOwner, tokenId); //NFTs are minted from zero address
    // });

});