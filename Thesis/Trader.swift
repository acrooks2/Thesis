//
//  trader.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation
import GameplayKit
import Accelerate


class Trader {
    let traderID: Int
    let traderType: Int
    let cancelProb: Float
    var localBook: [Int:[String:Int]]
    var cancelCollector: [[String:Int]]
    var numQuotes: Int
    var quoteRange: Int
    var position: Int
    var cashFlow: Int
    var cashFlowTimeStamps: [Int]
    var cashFlows: [Int]
    var positions: [Int]
    var quoteCollector: [[String:Int]]
    var orderID: Int
    var maxQuantity: Int
    var buySellProb: Float
    var timeDelta: Int
    var lambda: Double
    var rng: SystemRandomNumberGenerator
    //var testRandomNumbers: [Float]
    //let percentOfWealth: Float
    var wealth: Double
    var dice: GKRandomDistribution
    var wealthString: String
    let generalFileManager = FileManager()
    var maxWealth: Int
    var takerQ: Int
    var takerQDirection: Int
    let makerExchange: Int
    let rebate: Int
    let qS: [Int]
    var lastObservedMarketPrice: Float
    
    init(trader: Int, traderType: Int, numQuotes: Int, quoteRange: Int, cancelProb: Float, maxQuantity: Int, buySellProb: Float, lambda: Double, exchange: Int, rebate: Int) {
        self.traderID = trader
        self.traderType = traderType
        self.localBook = [:]
        self.cancelCollector = []
        self.numQuotes = numQuotes
        self.quoteRange = quoteRange
        self.position = 0
        self.cashFlow = 0
        self.cashFlowTimeStamps = []
        self.cashFlows = []
        self.positions = []
        self.quoteCollector = []
        self.orderID = 0
        self.cancelProb = cancelProb
        self.maxQuantity = maxQuantity
        self.buySellProb = buySellProb
        self.lambda = lambda
        self.timeDelta = 0
        self.rng = SystemRandomNumberGenerator()
        //self.testRandomNumbers = []
        //self.percentOfWealth = percentWealth
        self.wealth = 5000000
        self.maxWealth = Int(wealth * 0.12)
        self.dice = GKRandomDistribution(lowestValue: 1, highestValue: 2)
        self.wealthString = "TraderID,Wealth,TimeStamp,Position\n"
        self.takerQ = Int.random(in: 1...40)
        self.takerQDirection = Int.random(in: 1...2)
        self.makerExchange = exchange
        self.rebate = rebate
        self.lastObservedMarketPrice = 0.0
        self.qS = [1, 5, 10, 25, 50]
    }
    
    // Not used, but kept around in case agent activation worked better as a function of passage of time
    // Produces a random time delta for each agent as an interval between market activity
    func makeTimeDelta(lambda: Double) {
        let rExp = randExp(rate: lambda) + 1.0
        let i = floor(rExp)
        let iq = i * Double(self.maxQuantity)
        let tDelta = Int(iq)
        timeDelta = tDelta
    }
    
    // Part of liquidity provider agent price selection
    // Essentially an implimentation of a random exponential random variable
    func randExp(rate: Double) -> Double {
        return -1.0 / rate * log(Double.random(in: 0...1, using: &rng))
    }
    
    // Produces a dictionary that represents an order to be submitted to the market
    // Common to all traders - can be limit or market order based on price parameter
    func makeAddOrder(time: Int, side: Int, price: Int, quantity: Int) -> [String:Int] {
        orderID += 1
        let addOrder = ["orderID": orderID, "ID": 0, "traderID": traderID, "timeStamp": time, "type": 1, "quantity": quantity, "side": side, "price": price]
        return addOrder
    }
    
    // Produces a dictionary that represents the cancellation of an order resting in the orderbook
    // The existingOrder parameter is the order that is being canclled
    // Only used by market maker agents
    func makeCancelOrder(existingOrder: [String:Int], time: Int) -> [String:Int] {
        let cancelOrder = ["orderID": existingOrder["orderID"]!, "ID": existingOrder["ID"]!, "traderID": traderID, "timeStamp": time, "type": 2, "quantity": existingOrder["quantity"]!, "side": existingOrder["side"]!, "price": existingOrder["price"]!]
        return cancelOrder
    }
    
    // Records the current number of shares held by the trader (positive or negative)
    // Calculates wealth over time
    // Only used by market maker agents
    func cumulateCashFlow(timeStamp: Int, price: Double) {
        cashFlowTimeStamps.append(timeStamp)
        cashFlows.append(cashFlow)
        positions.append(position)
        wealth = Double(cashFlow) + (Double(position) * price)
        let newLine = "\(traderID),\(wealth),\(timeStamp),\(position)\n"
        wealthString.append(contentsOf: newLine)
    }
    
    // When a trade occurs, money and shares are exchanged
    // Orderbook prices and levels need to be updated as well
    // Only used by market maker agents
    func confirmTradeLocal(confirmOrder: [String:Int], price: Double) {
        // Update cashflow and position
        if confirmOrder["side"] == 1 {
            cashFlow -= confirmOrder["price"]! * confirmOrder["quantity"]! + rebate
            position += confirmOrder["quantity"]!
        }
        else {
            cashFlow += confirmOrder["price"]! * confirmOrder["quantity"]! + rebate
            position -= confirmOrder["quantity"]!
        }
        // Modify/remove order from local book
        let localOrder = localBook[confirmOrder["orderID"]!]
        if confirmOrder["quantity"]! == localOrder!["quantity"] {
            localBook.removeValue(forKey: localOrder!["orderID"]!)
        }
        else {
            localBook[localOrder!["orderID"]!]!["quantity"]! -= confirmOrder["quantity"]!
        }
        cumulateCashFlow(timeStamp: confirmOrder["timeStamp"]!, price: price)
    }
    
    // Randomly determine the orders that are still outstanding which will be cancelled
    // Only used by market maker agents
    func bulkCancel(timeStamp: Int) {
        cancelCollector.removeAll()
        for x in localBook.keys {
            if Float.random(in: 0..<1) <= cancelProb {
                cancelCollector.append(makeCancelOrder(existingOrder: localBook[x]!, time: timeStamp))
            }
        }
        for c in cancelCollector {
            localBook.removeValue(forKey: c["orderID"]!)
        }
    }
    
    // Main function for liquidity provider agents to assess the market state and send an order
    func providerProcessSignal(timeStamp: Int, topOfBook: [String:Int], buySellProb: Float) -> [String:Int?] {
        var price: Int
        var side: Int
        let lambda = self.lambda//Double.random(in: 0..<200)
        var order: [String:Int]
        if dice.nextInt() == 1 {
            side = 1
            price = choosePriceFromExp(side: side, insidePrice: topOfBook["bestAsk"]!, lambda: lambda)
        }
        else {
            side = 2
            price = choosePriceFromExp(side: side, insidePrice: topOfBook["bestBid"]!, lambda: lambda)
        }
        order = makeAddOrder(time: timeStamp, side: side, price: price, quantity: 1)
        localBook[order["orderID"]!] = order
        return order
    }
    
    func choosePriceFromExp(side: Int, insidePrice: Int, lambda: Double) -> Int {
        var plug: Int
        var price: Int
        plug = Int(lambda * log(Double.random(in: 0..<1)))
        if side == 1 {
            price = insidePrice - (-plug) - 1
            return price
        }
        else {
            price = insidePrice + (-plug) + 1
            return price
        }
    }
    
    func makeQ() -> Int {
        let q = qS.randomElement()!
        return q
    }
    
    func mmProcessSignal(timeStamp: Int, topOfBook: [String:Int?], buySellProb: Float) -> [[String:Int?]] {
        quoteCollector.removeAll()
        var prices = Array<Int>()
        var side: Int
        /*:
         */
        //////////////////////////////////////////////
        // Start of changes for this branch
        var bidPrices = Array<Int>()
        var askPrices = Array<Int>()
        let spread = Float(topOfBook["bestAsk"]!! - topOfBook["bestBid"]!!)
        let marketPrice = (Float(topOfBook["bestAsk"]!!) + Float(topOfBook["bestBid"]!!)) / 2.0
        if lastObservedMarketPrice == 0.0 {
            lastObservedMarketPrice = marketPrice
        }                                                                              //position sensitivity
        let personalMarketPrice = (marketPrice - ((Float(self.position) / Float(10)) * 10))
        //var positionEffect = Float(position) / Float(10)
        //var mpCoef = Float(10)
        //personalMarketPrice = personalMarketPrice - Float(positionEffect * mpCoef)
        //var maxBidPrice = marketPrice - (spread / 2) + Float(rebate)
        let priceVar = abs(lastObservedMarketPrice - marketPrice) / marketPrice
        var maxBidPrice = personalMarketPrice + Float(rebate)
        maxBidPrice = maxBidPrice * (1 - (priceVar * 1))
        //maxBidPrice = maxBidPrice + abs(lastObservedMarketPrice / marketPrice)
        var minBidPrice = maxBidPrice - Float(quoteRange)
        //var minAskPrice = marketPrice + (spread / 2) - Float(rebate)
        var minAskPrice = personalMarketPrice - Float(rebate)
        minAskPrice = minAskPrice * (1 + (priceVar * 1))
        //minAskPrice = minAskPrice + abs(lastObservedMarketPrice / marketPrice)
        var maxAskPrice = minAskPrice + Float(quoteRange)
        lastObservedMarketPrice = marketPrice
/*:
        if minAskPrice <= maxBidPrice {
            minAskPrice = marketPrice + 2
            maxAskPrice = minAskPrice + Float(quoteRange)
            maxBidPrice = marketPrice - 2
            minBidPrice = maxBidPrice - Float(quoteRange)
        }
 */
        // Make sure that the bid and ask prices don't cross
        if minAskPrice <= marketPrice {
            minAskPrice = marketPrice + 2
            maxAskPrice = minAskPrice + Float(quoteRange)
        }
        if maxBidPrice >= marketPrice {
            maxBidPrice = marketPrice - 2
            minBidPrice = maxBidPrice - Float(quoteRange)
        }
        let newMaxBidPrice = Int(maxBidPrice.rounded(.down))
        let newMinBidPrice = Int(minBidPrice.rounded(.down))
        let newMaxAskPrice = Int(maxAskPrice.rounded(.up))
        let newMinAskPrice = Int(minAskPrice.rounded(.up))

        for _ in 1 ... numQuotes / 2 {
            bidPrices.append(Int.random(in: newMinBidPrice...newMaxBidPrice))
        }
        for _ in 1 ... numQuotes / 2 {
            askPrices.append(Int.random(in: newMinAskPrice...newMaxAskPrice))
        }
        
        for price in bidPrices {
            let order = makeAddOrder(time: timeStamp, side: 1, price: price, quantity: makeQ())
            localBook[order["orderID"]!] = order
            quoteCollector.append(order)
        }
        
        for price in askPrices {
            let order = makeAddOrder(time: timeStamp, side: 2, price: price, quantity: makeQ())
            localBook[order["orderID"]!] = order
            quoteCollector.append(order)
        }
        return quoteCollector
    }
        // End of changes for this branch
        ///////////////////////////////////////////////

/*:

        // This creates a buy order (buySellProb = .5 is equal probability of buy or sell)
        if dice.nextInt() == 1 {
            let maxBidPrice = topOfBook["bestBid"]!
            let minBidPrice = maxBidPrice! - quoteRange
            for _ in 1 ... numQuotes {
                prices.append(Int.random(in: minBidPrice...maxBidPrice!))
            }
            side = 1
        }
        // This creates a sell order
        else {
            let minAskPrice = topOfBook["bestAsk"]!
            let maxAskPrice = minAskPrice! + quoteRange
            for _ in 1 ... Int.random(in: 1...numQuotes) {
                prices.append(Int.random(in: minAskPrice!...maxAskPrice))
            }
            side = 2
        }
        for price in prices {
            let order = makeAddOrder(time: timeStamp, side: side, price: price, quantity: Int.random(in: 1...maxQuantity))
            localBook[order["orderID"]!] = order
            quoteCollector.append(order)
        }
        return quoteCollector
    }

 */
        
    
    func mtProcessSignal(timeStamp: Int, ex1Tob: [String:Int?], ex2Tob: [String:Int?]) -> (order: [String : Int], exchange: Int) {
        
        var order: [String : Int] = [:]
        var exch: Int = 0
        
        if self.takerQ <= 0 {
            self.takerQDirection = Int.random(in: 1...2)
            //self.takerQ = Int(randExp(rate: 0.02))
            self.takerQ = Int.random(in: 1...20)
        }
        
        if self.takerQDirection == 1 {
            // Where is the best ask price (exchange1 or exchange2?)
            if ex1Tob["bestAsk"]!! < ex2Tob["bestAsk"]!! {
                exch = 1
                let askSize = ex1Tob["askSize"]!!
                let randQ = max(Float.random(in: 0...1) * Float(askSize), 1)
                var q = Int(randQ)
                if q > takerQ {
                    q = takerQ
                }
                order = makeAddOrder(time: timeStamp, side: 1, price: 2000000, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
            if ex2Tob["bestAsk"]!! < ex1Tob["bestAsk"]!! {
                exch = 2
                let askSize = ex2Tob["askSize"]!!
                let randQ = max(Float.random(in: 0...1) * Float(askSize), 1)
                var q = Int(randQ)
                if q > takerQ {
                    q = takerQ
                }
                order = makeAddOrder(time: timeStamp, side: 1, price: 2000000, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
            if ex2Tob["bestAsk"]!! == ex1Tob["bestAsk"]!! {
                exch = dice.nextInt()
                var q = 0
                if exch == 1 {
                    let askSize = ex1Tob["askSize"]!!
                    let randQ = max(Float.random(in: 0...1) * Float(askSize), 1)
                    q = Int(randQ)
                    if q > takerQ {
                        q = takerQ
                    }
                }
                if exch == 2 {
                    let askSize = ex2Tob["askSize"]!!
                    let randQ = max(Float.random(in: 0...1) * Float(askSize), 1)
                    q = Int(randQ)
                    if q > takerQ {
                        q = takerQ
                    }
                }
                order = makeAddOrder(time: timeStamp, side: 1, price: 2000000, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
        }
        else {
            if ex1Tob["bestBid"]!! > ex2Tob["bestBid"]!! {
                exch = 1
                let bidSize = ex1Tob["bidSize"]!!
                let randQ = max(Float.random(in: 0...1) * Float(bidSize), 1)
                var q = Int(randQ)
                if q > takerQ {
                    q = takerQ
                }
                order = makeAddOrder(time: timeStamp, side: 2, price: 0, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
            if ex2Tob["bestBid"]!! > ex1Tob["bestBid"]!! {
                exch = 2
                let bidSize = ex2Tob["bidSize"]!!
                let randQ = max(Float.random(in: 0...1) * Float(bidSize), 1)
                var q = Int(randQ)
                if q > takerQ {
                    q = takerQ
                }
                order = makeAddOrder(time: timeStamp, side: 2, price: 0, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
            if ex2Tob["bestBid"]!! == ex1Tob["bestBid"]!! {
                exch = dice.nextInt()
                var q = 0
                if exch == 1 {
                    let bidSize = ex1Tob["bidSize"]!!
                    let randQ = max(Float.random(in: 0...1) * Float(bidSize), 1)
                    q = Int(randQ)
                    if q > takerQ {
                        q = takerQ
                    }
                }
                if exch == 2 {
                    let bidSize = ex2Tob["bidSize"]!!
                    let randQ = max(Float.random(in: 0...1) * Float(bidSize), 1)
                    q = Int(randQ)
                    if q > takerQ {
                        q = takerQ
                    }
                }
                order = makeAddOrder(time: timeStamp, side: 2, price: 0, quantity: q)
                self.takerQ -= q
                //return (order, exch)
            }
        }
        return (order, exch)
    }
    
    func addWealthToCsv(filePath: String) {
        if generalFileManager.fileExists(atPath: filePath) {
            // create file handler
            let fh = FileHandle(forWritingAtPath: filePath)
            // seek to end of file
            fh?.seekToEndOfFile()
            // convert sip string to Data type
            let data = wealthString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            // write to end of file
            fh?.write(data!)
            // close the file handler
            fh?.closeFile()
            wealthString.removeAll()
        }
        else {
            do {
                try wealthString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
                wealthString.removeAll()
            } catch {
                print("Failed to write sip to file.")
                print("\(error)")
            }
        }
    }
}

