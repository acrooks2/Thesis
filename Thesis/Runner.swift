//
//  Runner.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation

class Runner {
    var exchange1: OrderBook
    var exchange2: OrderBook
    let runSteps: Int
    var liquidityProviders: [Int:Trader]
    var liquidityTakers: [Int:Trader]
    let numProviders: Int
    let numMMs: Int
    let numMTs: Int
    var topOfBook: [String:Int?]
    let setupTime: Int
    var providers: [Trader]
    var marketMakers: [Trader]
    var takers: [Trader]
    var traders: [Trader]
    
    init(exchange1: OrderBook, exchange2: OrderBook, runSteps: Int, numProviders: Int, numMMs: Int, numMTs: Int, setupTime: Int) {
        self.exchange1 = exchange1
        self.exchange2 = exchange2
        self.runSteps = runSteps
        self.liquidityProviders = [:]
        self.liquidityTakers = [:]
        self.numProviders = numProviders
        self.numMMs = numMMs
        self.numMTs = numMTs
        self.topOfBook = [:]
        self.setupTime = setupTime
        self.providers = []
        self.marketMakers = []
        self.takers = []
        self.traders = []
    }
    
    func buildProviders(numProviders: Int) -> [Trader] {
        let maxProviderID = 3000 + numProviders - 1
        var providerList: [Trader] = []
        for i in 3000...maxProviderID {
            let trader = Trader(trader: i, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 50, buySellProb: 0.5, lambda: 0.0375)
            trader.makeTimeDelta(lambda: trader.lambda)
            providerList.append(trader)
        }
        for p in providerList {
            liquidityProviders[p.traderID] = p
        }
        return providerList
    }
    
    func buildMarketMakers(numMMS: Int) -> [Trader] {
        let maxMarketMakerID = 1000 + numMMs - 1
        var mmList: [Trader] = []
        for i in 1000...maxMarketMakerID {
            let trader = Trader(trader: i, traderType: 1, numQuotes: 60, quoteRange: 60, cancelProb: 0.025, maxQuantity: 50, buySellProb: 0.5, lambda: 0.0375)
            trader.makeTimeDelta(lambda: trader.lambda)
            mmList.append(trader)
        }
        for mm in mmList {
            liquidityProviders[mm.traderID] = mm
        }
        return mmList
    }
    
    func buildTakers(numTakers: Int) -> [Trader] {
        let maxTakerID = 2000 + numMTs - 1
        var mtList: [Trader] = []
        for i in 2000...maxTakerID {
            let trader = Trader(trader: i, traderType: 2, numQuotes: 1, quoteRange: 0, cancelProb: 0.5, maxQuantity: 50, buySellProb: 0.5, lambda: 0.0175)
            trader.makeTimeDelta(lambda: trader.lambda)
            mtList.append(trader)
        }
        for mt in mtList {
            liquidityTakers[mt.traderID] = mt
        }
        return mtList
    }
    
    // Using "Any" is not ideal, see if you can figure out another way to do it
    func makeAll() -> [Trader] {
        var traderList: [Trader] = []
        providers = buildProviders(numProviders: numProviders)
        marketMakers = buildMarketMakers(numMMS: numMMs)
        takers = buildTakers(numTakers: numMTs)
        traderList.append(contentsOf: providers)
        traderList.append(contentsOf: marketMakers)
        traderList.append(contentsOf: takers)
        traderList.shuffle()
        return traderList
    }
    
    func seedOrderBook() {
        let seedProvider = Trader(trader: 9999, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 50, buySellProb: 0.5, lambda: 0.0375)
        seedProvider.makeTimeDelta(lambda: seedProvider.lambda)
        liquidityProviders[seedProvider.traderID] = seedProvider
        let bestAsk = Int.random(in: 1000005...1002000)
        let bestBid = Int.random(in: 997995...999995)
        let seedAsk = ["orderID": 1, "ID": 0, "traderID": 9999, "timeStamp": 0, "type": 1, "quantity": 1, "side": 2, "price": bestAsk]
        let seedBid = ["orderID": 2, "ID": 0, "traderID": 9999, "timeStamp": 0, "type": 1, "quantity": 1, "side": 1, "price": bestBid]
        seedProvider.localBook[1] = seedAsk
        exchange1.addOrderToBook(order: seedAsk)
        exchange1.addOrderToHistory(order: seedAsk)
        seedProvider.localBook[2] = seedBid
        exchange1.addOrderToBook(order: seedBid)
        exchange1.addOrderToHistory(order: seedBid)
    }
    
    func setup() {
        traders = makeAll()
        seedOrderBook()
        topOfBook = exchange1.reportTopOfBook(nowTime: 1)
        for time in 1...setupTime {
            providers.shuffle()
            for p in providers {
                if Float.random(in: 0..<1) < 0.5 {
                    let order = p.providerProcessSignal(timeStamp: time, topOfBook: topOfBook as! [String : Int], buySellProb: 0.5)
                    exchange1.processOrder(order: order as! [String : Int])
                    topOfBook = exchange1.reportTopOfBook(nowTime: time)
                }
            }
        }
    }
    
    func doCancels(trader: Trader) {
        for c in trader.cancelCollector {
            exchange1.processOrder(order: c)
        }
    }
    
    func confirmTrades() {
        for c in exchange1.confirmTradeCollector {
            let contraSide = liquidityProviders[c["traderID"]!]
            contraSide?.confirmTradeLocal(confirmOrder: c)
        }
    }
    
    func run(prime: Int, writeInterval: Int) {
        topOfBook = exchange1.reportTopOfBook(nowTime: prime)
        for currentTime in prime...runSteps {
            traders.shuffle()
            for t in traders {
                
                if t.traderType == 0 {
                    if Float.random(in: 0..<1) < 0.05 {
                        let order = t.providerProcessSignal(timeStamp: currentTime, topOfBook: topOfBook as! [String : Int], buySellProb: 0.5)
                        exchange1.processOrder(order: order as! [String : Int])
                        topOfBook = exchange1.reportTopOfBook(nowTime: currentTime)
                    }
                }
                
                if t.traderType == 1 {
                    if Float.random(in: 0..<1) < 0.025 {
                        let orders = t.mmProcessSignal(timeStamp: currentTime, topOfBook: topOfBook, buySellProb: 0.5)
                        for order in orders {
                            exchange1.processOrder(order: order as! [String : Int])
                        }
                        topOfBook = exchange1.reportTopOfBook(nowTime: currentTime)
                    }
                    t.bulkCancel(timeStamp: currentTime)
                    if t.cancelCollector.count > 0 {
                        doCancels(trader: t)
                        topOfBook = exchange1.reportTopOfBook(nowTime: currentTime)
                    }
                }
                if t.traderType == 2 {
                    if Float.random(in: 0..<1) < 0.01 {
                        let order = t.mtProcessSignal(timeStamp: currentTime)
                        exchange1.processOrder(order: order)
                        if exchange1.traded {
                            confirmTrades()
                            topOfBook = exchange1.reportTopOfBook(nowTime: currentTime)
                        }
                    }
                }
            }
            if currentTime % writeInterval == 0 {
                exchange1.orderHistoryToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders.csv")
                exchange1.sipToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip.csv")
            }
        }
        print("This might have worked.")
    }
    
    
}
