//
//  trader.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation


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
    
    init(trader: Int, traderType: Int, numQuotes: Int, quoteRange: Int, cancelProb: Float, maxQuantity: Int, buySellProb: Float, lambda: Double) {
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
    }
    
    func makeTimeDelta(lambda: Double) {
        let rExp = randExp(rate: lambda) + 1.0
        let i = floor(rExp)
        let iq = i * Double(self.maxQuantity)
        let tDelta = Int(iq)
        timeDelta = tDelta
    }
    
    func randExp(rate: Double) -> Double {
        return -1.0 / rate * log(Double.random(in: 0...1))
    }
    
    func makeAddOrder(time: Int, side: Int, price: Int, quantity: Int) -> [String:Int] {
        orderID += 1
        let addOrder = ["orderID": orderID, "ID": 0, "traderID": traderID, "timeStamp": time, "type": 1, "quantity": quantity, "side": side, "price": price]
        return addOrder
    }
    
    func makeCancelOrder(existingOrder: [String:Int], time: Int) -> [String:Int] {
        let cancelOrder = ["orderID": existingOrder["orderID"]!, "ID": existingOrder["ID"]!, "traderID": traderID, "timeStamp": time, "type": 2, "quantity": existingOrder["quantity"]!, "side": existingOrder["side"]!, "price": existingOrder["price"]!]
        return cancelOrder
    }
    
    func cumulateCashFlow(timeStamp: Int) {
        cashFlowTimeStamps.append(timeStamp)
        cashFlows.append(cashFlow)
        positions.append(position)
    }
    
    func confirmTradeLocal(confirmOrder: [String:Int]) {
        // Update cashflow and position
        if confirmOrder["side"] == 1 {
            cashFlow -= confirmOrder["price"]! * confirmOrder["quantity"]!
            position += confirmOrder["quantity"]!
        }
        else {
            cashFlow += confirmOrder["price"]! * confirmOrder["quantity"]!
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
        cumulateCashFlow(timeStamp: confirmOrder["timeStamp"]!)
    }
    
    func bulkCancel(timeStamp: Int) {
        cancelCollector.removeAll()
        for x in localBook.keys {
            if Float.random(in: 0..<1) < cancelProb {
                cancelCollector.append(makeCancelOrder(existingOrder: localBook[x]!, time: timeStamp))
            }
        }
        for c in cancelCollector {
            localBook.removeValue(forKey: c["orderID"]!)
        }
    }
    
    func providerProcessSignal(timeStamp: Int, topOfBook: [String:Int], buySellProb: Float) -> [String:Int?] {
        var price: Int
        var side: Int
        let lambda = Double.random(in: 0..<1)
        var order: [String:Int]
        if Float.random(in: 0..<1) < buySellProb {
            side = 1
            price = choosePriceFromExp(side: side, insidePrice: topOfBook["bestAsk"]!, lambda: lambda)
        }
        else {
            side = 2
            price = choosePriceFromExp(side: side, insidePrice: topOfBook["bestBid"]!, lambda: lambda)
        }
        order = makeAddOrder(time: timeStamp, side: side, price: price, quantity: Int.random(in: 1...maxQuantity))
        localBook[order["orderID"]!] = order
        return order
    }
    
    func choosePriceFromExp(side: Int, insidePrice: Int, lambda: Double) -> Int {
        var plug: Int
        var price: Int
        plug = Int(lambda * log(Double.random(in: 0..<1)))
        if side == 1 {
            price = insidePrice - plug - 1
            return price
        }
        else {
            price = insidePrice + plug + 1
            return price
        }
    }
    
    func mmProcessSignal(timeStamp: Int, topOfBook: [String:Int?], buySellProb: Float) -> [String:Int?] {
        quoteCollector.removeAll()
        var prices = Array<Int>()
        var side: Int
        // This creates a buy order (buySellProb = .5 is equal probability of buy or sell)
        if Float.random(in: 0..<1) < buySellProb {
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
        return quoteCollector[0]
    }
    
    func mtProcessSignal(timeStamp: Int) -> [String:Int] {
        if Float.random(in: 0..<1) < buySellProb {
            let order = makeAddOrder(time: timeStamp, side: 1, price: 200000, quantity: Int.random(in: 1...maxQuantity))
            return order
        }
        else {
            let order = makeAddOrder(time: timeStamp, side: 2, price: 0, quantity: Int.random(in: 1...maxQuantity))
            return order
        }
    }
}

