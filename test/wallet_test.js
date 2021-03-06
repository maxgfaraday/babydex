const Dex =  artifacts.require("Dex");
const Link = artifacts.require("Link");
const TruffleAssert = require("truffle-assertions");

contract("Dex", accounts => {
    it("should only be possible for owner to add tokens", async () => {
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await TruffleAssert.passes(
            dex.addToken(web3.utils.fromUtf8("LINK"),link.address, {from: accounts[0]})
        )
        await TruffleAssert.reverts(
            dex.addToken(web3.utils.fromUtf8("LINK"),link.address, {from: accounts[1]})
        )
    })
    it("should handle deposits correctly", async () => {
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await link.approve(dex.address, 500);
        dex.addToken(web3.utils.fromUtf8("LINK"),link.address);
        await dex.deposit(100, web3.utils.fromUtf8("LINK"));
        let balanceOfLink = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));
        assert.equal(balanceOfLink.toNumber(),100);
    })
    it("should handle correct withdrawals correctly", async () => {
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await TruffleAssert.passes(dex.withdraw(100, web3.utils.fromUtf8("LINK")));
    })
    it("should handle faulty withdrawals correctly", async () => {
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await TruffleAssert.reverts(dex.withdraw(101, web3.utils.fromUtf8("LINK")));
    })
})
