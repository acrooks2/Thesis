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
    var liquidityProviders: [Int:MarketMaker]
    var liquidityTakers: [Int:Taker]
    let numMMs: Int
    let numMTs: Int
    var topOfBook: [String:Int?]
    let setupTime: Int
    var providers: [MarketMaker]
    var takers: [Taker]
    var traders: [Any]
    
    init(exchange1: OrderBook, exchange2: OrderBook, runSteps: Int, numMMs: Int, numMTs: Int, setupTime: Int) {
        self.exchange1 = exchange1
        self.exchange2 = exchange2
        self.runSteps = runSteps
        self.liquidityProviders = [:]
        self.liquidityTakers = [:]
        self.numMMs = numMMs
        self.numMTs = numMTs
        self.topOfBook = [:]
        self.setupTime = setupTime
        self.providers = []
        self.takers = []
        self.traders = []
    }
    
    func buildProviders(numMMS: Int) -> [MarketMaker] {
        let maxProviderID = 1000 + numMMs - 1
        var mmList: [MarketMaker] = []
        for i in 1000...maxProviderID {
            mmList.append(MarketMaker(trader: i, numQuotes: 12, quoteRange: 60, cancelProb: 0.025))
        }
        for mm in mmList {
            liquidityProviders[mm.traderID] = mm
        }
        return mmList
    }
    
    func buildTakers(numTakers: Int) -> [Taker] {
        let maxTakerID = 2000 + numMTs - 1
        var mtList: [Taker] = []
        for i in 2000...maxTakerID {
            mtList.append(Taker(traderID: i, maxQuantity: 1, buySellProb: 0.5))
        }
        for mt in mtList {
            liquidityTakers[mt.traderID] = mt
        }
        return mtList
    }
    
    // Using "Any" is not ideal, see if you can figure out another way to do it
    func makeAll() -> [Any] {
        var traderList: [Any] = []
        providers = buildProviders(numMMS: numMMs)
        takers = buildTakers(numTakers: numMTs)
        traderList.append(contentsOf: providers)
        traderList.append(contentsOf: takers)
        traderList.shuffle()
        return traderList
    }
    
    func seedOrderBook() {
        let seedProvider = MarketMaker(trader: 9999, numQuotes: 1, quoteRange: 60, cancelProb: 0.025)
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
        topOfBook = exchange1.reportTopOfBook(nowTime: 1)
        for time in 1...setupTime {
            providers.shuffle()
            for p in providers {
                if Float.random(in: 0..<1) < 0.5 {
                    let order = 1
                }
            }
        }
    }
}
