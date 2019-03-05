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
    var ex1TopOfBook: [String:Int?]
    var ex2TopOfBook: [String : Int?]
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
        self.ex1TopOfBook = [:]
        self.ex2TopOfBook = [:]
        self.setupTime = setupTime
        self.providers = []
        self.marketMakers = []
        self.takers = []
        self.traders = []
    }
    
    func buildProviders(numProviders: Int) -> [Trader] {
        let maxProviderID = 3000 + (numProviders * 2) - 1
        var providerList: [Trader] = []
        for i in stride(from: 3000, to: maxProviderID, by: 2) {
            // Build a provider for exchange1
            let provider1 = Trader(trader: i, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 1)
            provider1.makeTimeDelta(lambda: provider1.lambda)
            providerList.append(provider1)
            // Build a provider for exchange2
            let provider2 = Trader(trader: i + 1, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 2)
            provider2.makeTimeDelta(lambda: provider2.lambda)
            providerList.append(provider2)
        }
        for p in providerList {
            liquidityProviders[p.traderID] = p
        }
        return providerList
    }
    
    func buildMarketMakers(numMMS: Int) -> [Trader] {
        let maxMarketMakerID = 1000 + (numMMs * 2) - 1
        var mmList: [Trader] = []
        for i in stride(from: 1000, to: maxMarketMakerID, by: 2) {
            // Build a market maker for exchange1
            let mm1 = Trader(trader: i, traderType: 1, numQuotes: 12, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 1)
            mm1.makeTimeDelta(lambda: mm1.lambda)
            mmList.append(mm1)
            // Build a market maker for exchange2
            let mm2 = Trader(trader: i + 1, traderType: 1, numQuotes: 12, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 2)
            mm2.makeTimeDelta(lambda: mm2.lambda)
            mmList.append(mm2)
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
            let trader = Trader(trader: i, traderType: 2, numQuotes: 1, quoteRange: 1, cancelProb: 0.5, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0175, exchange: 1)
            trader.makeTimeDelta(lambda: trader.lambda)
            mtList.append(trader)
        }
        for mt in mtList {
            liquidityTakers[mt.traderID] = mt
        }
        return mtList
    }
    
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
        let seedProvider1 = Trader(trader: 9999, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 1)
        seedProvider1.makeTimeDelta(lambda: seedProvider1.lambda)
        let seedProvider2 = Trader(trader: 9998, traderType: 0, numQuotes: 1, quoteRange: 60, cancelProb: 0.025, maxQuantity: 1, buySellProb: 0.5, lambda: 0.0375, exchange: 2)
        seedProvider2.makeTimeDelta(lambda: seedProvider2.lambda)
        liquidityProviders[seedProvider1.traderID] = seedProvider1
        liquidityProviders[seedProvider2.traderID] = seedProvider2
        // Set the initial reference bid and ask prices
        let bestAsk = Int.random(in: 1000005...1002000)
        let bestBid = Int.random(in: 997995...999995)
        let seedAsk = ["orderID": 1, "ID": 0, "traderID": 9999, "timeStamp": 0, "type": 1, "quantity": 1, "side": 2, "price": bestAsk]
        let seedBid = ["orderID": 2, "ID": 0, "traderID": 9999, "timeStamp": 0, "type": 1, "quantity": 1, "side": 1, "price": bestBid]
        // Place the orders in provider's local book and then into the exchanges
        // Seed exchange1 first
        seedProvider1.localBook[1] = seedAsk
        exchange1.addOrderToBook(order: seedAsk)
        exchange1.addOrderToHistory(order: seedAsk)
        seedProvider1.localBook[2] = seedBid
        exchange1.addOrderToBook(order: seedBid)
        exchange1.addOrderToHistory(order: seedBid)
        // Now seed exchange2
        seedProvider2.localBook[1] = seedAsk
        exchange2.addOrderToBook(order: seedAsk)
        exchange2.addOrderToHistory(order: seedAsk)
        seedProvider2.localBook[2] = seedBid
        exchange2.addOrderToBook(order: seedBid)
        exchange2.addOrderToHistory(order: seedBid)
    }
    
    func setup() {
        traders = makeAll()
        seedOrderBook()
        let vAndT1 = exchange1.reportTopOfBook(nowTime: 1)
        let vAndT2 = exchange2.reportTopOfBook(nowTime: 1)
        ex1TopOfBook = vAndT1.tob
        ex2TopOfBook = vAndT2.tob
        for time in 1...setupTime {
            providers.shuffle()
            for p in providers {
                if Float.random(in: 0...1) <= 0.5 {
                    if p.makerExchange == 1 {
                        let order = p.providerProcessSignal(timeStamp: time, topOfBook: ex1TopOfBook as! [String : Int], buySellProb: 0.5)
                        exchange1.processOrder(order: order as! [String : Int])
                        let vAndT = exchange1.reportTopOfBook(nowTime: time)
                        ex1TopOfBook = vAndT.tob
                    }
                    else {
                        let order = p.providerProcessSignal(timeStamp: time, topOfBook: ex2TopOfBook as! [String : Int], buySellProb: 0.5)
                        exchange2.processOrder(order: order as! [String : Int])
                        let vAndT = exchange2.reportTopOfBook(nowTime: time)
                        ex2TopOfBook = vAndT.tob
                    }
                }
            }
        }
        let price1 = exchange1.priceHistory.last
        exchange1.priceHistory = Array(repeating: price1!, count: 1000)
        let price2 = exchange2.priceHistory.last
        exchange2.priceHistory = Array(repeating: price2!, count: 1000)
    }
    
    func doCancels(trader: Trader) {
        if trader.makerExchange == 1 {
            for c in trader.cancelCollector {
                exchange1.processOrder(order: c)
            }
        }
        else {
            for c in trader.cancelCollector {
                exchange2.processOrder(order: c)
            }
        }
    }
    
    func confirmTrades() {
        // need to track exchange1 and exchange2 positions probably
        for c in exchange1.confirmTradeCollector {
            let contraSide = liquidityProviders[c["traderID"]!]
            contraSide?.confirmTradeLocal(confirmOrder: c, price: exchange1.priceHistory.last!)
        }
    }
    
    func wealthToCsv() {
        for trader in marketMakers {
            trader.addWealthToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/wealth.csv")
        }
    }
    
    func run(prime: Int, writeInterval: Int) {
        let vAndT1 = exchange1.reportTopOfBook(nowTime: prime)
        let vAndT2 = exchange2.reportTopOfBook(nowTime: prime)
        ex1TopOfBook = vAndT1.tob
        ex2TopOfBook = vAndT2.tob
        for currentTime in prime...runSteps {
            traders.shuffle()
            for t in traders {
                // Trader is provider
                if t.traderType == 0 {
                    if Float.random(in: 0...1) <= 0.005 {
                        // Which exchange is the provider going to post to?
                        if t.makerExchange == 1 {
                            let order = t.providerProcessSignal(timeStamp: currentTime, topOfBook: ex1TopOfBook as! [String : Int], buySellProb: 0.5)
                            exchange1.processOrder(order: order as! [String : Int])
                            let vAndT = exchange1.reportTopOfBook(nowTime: currentTime)
                            ex1TopOfBook = vAndT.tob
                        }
                        else {
                            let order = t.providerProcessSignal(timeStamp: currentTime, topOfBook: ex2TopOfBook as! [String : Int], buySellProb: 0.5)
                            exchange2.processOrder(order: order as! [String : Int])
                            let vAndT = exchange2.reportTopOfBook(nowTime: currentTime)
                            ex2TopOfBook = vAndT.tob
                        }
                    }
                }
                // Trader is market maker
                if t.traderType == 1 {
                    if Float.random(in: 0...1) <= 0.05 {
                        // Which exchange is the mm going to post to?
                        if t.makerExchange == 1 {
                            let orders = t.mmProcessSignal(timeStamp: currentTime, topOfBook: ex1TopOfBook, buySellProb: 0.5)
                            for order in orders {
                                exchange1.processOrder(order: order as! [String : Int])
                            }
                            let vAndT = exchange1.reportTopOfBook(nowTime: currentTime)
                            ex1TopOfBook = vAndT.tob
                        }
                        else {
                            let orders = t.mmProcessSignal(timeStamp: currentTime, topOfBook: ex2TopOfBook, buySellProb: 0.5)
                            for order in orders {
                                exchange2.processOrder(order: order as! [String : Int])
                            }
                            let vAndT = exchange2.reportTopOfBook(nowTime: currentTime)
                            ex2TopOfBook = vAndT.tob
                        }
                    }
                    t.bulkCancel(timeStamp: currentTime)
                    if t.cancelCollector.count > 0 {
                        doCancels(trader: t)
                        if t.makerExchange == 1 {
                            let vAndT = exchange1.reportTopOfBook(nowTime: currentTime)
                            ex1TopOfBook = vAndT.tob
                        }
                        else {
                            let vAndT = exchange2.reportTopOfBook(nowTime: currentTime)
                            ex2TopOfBook = vAndT.tob
                        }
                    }
                }
                // Trader is market taker
                if t.traderType == 2 {
                    if Float.random(in: 0...1) <= 0.0035 {
                        let order = t.mtProcessSignal(timeStamp: currentTime, ex1Tob: ex1TopOfBook, ex2Tob: ex2TopOfBook)
                        if order.exchange == 1 {
                            exchange1.processOrder(order: order.order)
                            if exchange1.traded {
                                confirmTrades()
                                let vAndT = exchange1.reportTopOfBook(nowTime: currentTime)
                                ex1TopOfBook = vAndT.tob
                            }
                        }
                        else {
                            exchange2.processOrder(order: order.order)
                            if exchange2.traded {
                                confirmTrades()
                                let vAndT = exchange2.reportTopOfBook(nowTime: currentTime)
                                ex2TopOfBook = vAndT.tob
                            }
                        }
                    }
                }
                let _ = exchange1.tobTime(nowTime: currentTime)
                // If there are any weird data things in visualization consider this part of the code
                let _ = exchange2.tobTime(nowTime: currentTime)
            }
            if currentTime % writeInterval == 0 {
                exchange1.orderHistoryToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders.csv")
                exchange1.sipToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip.csv")
                exchange2.orderHistoryToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders2.csv")
                exchange2.sipToCsv(filePath: "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip2.csv")
                wealthToCsv()
            }
        }
        print("This might have worked.")
        print(market1.exchange1.volatility)
    }
    
    
}
