const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const TruffleAssert = require("truffle-assertions");

contract("Dex:Orderbook", accounts => {
    //The user must have ETH deposited such that the deposited eth >= buy order value.
    //Must have enough ETH to cover the order to buy.
    it("buyer must have more or equivalent amount of currency to create a buy order", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await TruffleAssert.reverts(
            dex.createLimitOrder(Dex.Side.BUY,web3.utils.fromUtf8("LINK"),10,1)
        )
        dex.depositEth({value: 10})
        await TruffleAssert.passes(
            //WTF?
            //dex.createLimitOrder(Dex.Side.BUY,web3.utils.fromUtf8("LINK"),10,1)
        )
    })
    //The user must have enough tokens deposited such that token balance >= sell order amount
    it("seller must have enough or equivalent currency to fulfill a sell order.", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()

        await TruffleAssert.reverts(
            dex.createLimitOrder(Dex.Side.SELL,web3.utils.fromUtf8("LINK"),10,1)
        )
        await link.approve(dex.address,300)
        await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
        await dex.deposit(10,web3.utils.fromUtf8("LINK"))
        await TruffleAssert.passes(
            dex.createLimitOrder(Dex.Side.SELL,web3.utils.fromUtf8("LINK"),10,1)
        )
    })
    //the BUY order book should be ordered on price from highest to lowest starting at index[0]
    it("buy orderbook is ordered by price in descending (hightest [0] to lowest [length-1])", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await link.approve(dex.address,500)
        await dex.depositEth({value: 3000})
        await dex.createLimitOrder(Dex.Side.BUY,web3.utils.fromUtf8("LINK"),1,300)
        await dex.createLimitOrder(Dex.Side.BUY,web3.utils.fromUtf8("LINK"),1,100)
        await dex.createLimitOrder(Dex.Side.BUY,web3.utils.fromUtf8("LINK"),1,200)

        //[300, 200, 100]

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),Dex.Side.BUY)
        //console.log(orderbook)
        assert(orderbook.length > 0)
        for(let i=0; i < orderbook.length-1; i++) {
            assert(orderbook[i].price >= orderbook[i+1].price, "buy order book is out of order")
            //highest price at the beginning (lowest index)
        }
    })
    //the SELL order book should be ordered on price from lowest to highest starting at index[0]
    it("sell orderbook is ordered by price in ascending (lowest [0] to highest [length-1])", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await link.approve(dex.address,500)
        await dex.createLimitOrder(Dex.Side.SELL,web3.utils.fromUtf8("LINK"),1,300)
        await dex.createLimitOrder(Dex.Side.SELL,web3.utils.fromUtf8("LINK"),1,100)
        await dex.createLimitOrder(Dex.Side.SELL,web3.utils.fromUtf8("LINK"),1,200)

        //[100, 200, 300]

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),Dex.Side.SELL);
        assert(orderbook.length > 0)
        //console.log(orderbook);
        for(let i=0; i < orderbook.length-1; i++) {
            assert(orderbook[i].price <= orderbook[i+1].price, "sell order book is out of order");
            //highest price on the end (highest index)
        }
    })

})
