//
//  main.swift
//  Thesis
//
//  Created by Charlie on 1/5/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation


struct Trade {
    var restingTraderID: Int
    var restingOrderID: Int
    var restingTimeStamp: Int
    var incomingTraderID: Int
    var incomingOrderID: Int
    var incomingTimeStamp: Int
    var tradePrice: Int
    var tradeQuantity: Int
    var side: Int
}

struct BidBook {
    //always sorted array of bid prices
    var prices: SortedArray<Int>
    //orders is a dictionary with exIDs as keys and the associated order (as dicitonary) as values
    var orders: [Int:[String:Int]]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists of exIDs as values
    var orderIDs: [Int:[Int]]
    
}

struct AskBook {
    //always sorted array of ask prices
    var prices: SortedArray<Int>
    //orders is a dictionary with exIDs as keys and the associated order (as dictionary) as values
    var orders: [Int:[String:Int]]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists exIDs as values
    var orderIDs: [Int:[Int]]
}

struct TradeBook {
    // A dictionary to store all trades with trade ID as key and trades as values
    var trades: [Int:Trade]
}

class OrderBook {
    var orderHistory: [Int:[String:Int]]
    // initial string of order history data to be written to csv file at write intervals (this is the header row, it will be cleared after the first file write)
    var orderHistoryString = "exID,orderID,traderID,timeStamp,type,quantity,side,price"
    // initial string of sip to be written to csv file at write intervals (this is the header row, it will be cleared after the first file write)
    var sipString = "timeStamp,bestBid,bestAsk,bidSize,bidSize,askSize"
    var bidBook: BidBook
    var askBook: AskBook
    var orderIndex: Int
    var exIndex: Int
    var traded: Bool
    var confirmTradeCollector: [[String:Int]]
    var confirmTradeCollectorTimeStamps: [Int]
    var tradeBook: TradeBook
    var tradeIndex: Int
    var lookUp: [Int:[Int:[String:Int]]]
    var sipCollector: [[String:Int?]]
    
    init(bidbook: BidBook, askbook: AskBook, tradebook: TradeBook) {
        self.orderHistory = [:]
        self.bidBook = bidbook
        self.askBook = askbook
        /* Order index is simply to identify orders in sequence in order history - this is different from the order ID in order objects */
        self.orderIndex = 0
        // ex index is for identifying limit orders that will be hit in process order
        self.exIndex = 0
        self.traded = false
        self.confirmTradeCollector = []
        self.confirmTradeCollectorTimeStamps = []
        self.tradeBook = tradebook
        self.tradeIndex = 0
        self.lookUp = [:]
        self.sipCollector = []
    }
    
    func addOrderToHistory(order: [String:Int]) {
        orderIndex += 1
        orderHistory[orderIndex] = order
    }
    
    func addOrderToLookUp(order: [String:Int]) {
        if lookUp.keys.contains(order["traderID"]!) {
            lookUp[order["traderID"]!]![order["orderID"]!] = order
        }
        else {
            lookUp[order["traderID"]!] = ([order["orderID"]:order] as! [Int : [String : Int]])
        }
    }
    
    func addOrderToBook(order: [String:Int]) {
        exIndex += 1
        // Add an order to the buy side
        if order["side"] == 1 {
            if bidBook.prices.contains(order["price"]!) {
                bidBook.numOrders[order["price"]!]! += 1
                bidBook.priceSize[order["price"]!]! += order["quantity"]!
                bidBook.orderIDs[order["price"]!]!.append(exIndex)
                bidBook.orders[exIndex] = order
                bidBook.orders[exIndex]!["ID"] = exIndex
            }
            else {
                bidBook.prices.insert(order["price"]!)
                bidBook.numOrders[order["price"]!] = 1
                bidBook.priceSize[order["price"]!] = order["quantity"]
                if bidBook.orderIDs[order["price"]!] == nil {
                    bidBook.orderIDs[order["price"]!] = [exIndex]
                }
                else {
                    bidBook.orderIDs[order["price"]!]!.append(exIndex)
                }
                bidBook.orders[exIndex] = order
                bidBook.orders[exIndex]!["ID"] = exIndex
            }
        }
        // Add an order to the sell side
        else {
            if askBook.prices.contains(order["price"]!) {
                askBook.numOrders[order["price"]!]! += 1
                askBook.priceSize[order["price"]!]! += order["quantity"]!
                askBook.orderIDs[order["price"]!]!.append(exIndex)
                askBook.orders[exIndex] = order
                askBook.orders[exIndex]!["ID"] = exIndex
            }
            else {
                askBook.prices.insert(order["price"]!)
                askBook.numOrders[order["price"]!] = 1
                askBook.priceSize[order["price"]!] = order["quantity"]
                if askBook.orderIDs[order["price"]!] == nil {
                    askBook.orderIDs[order["price"]!] = [exIndex]
                }
                else {
                    askBook.orderIDs[order["price"]!]!.append(exIndex)
                }
                askBook.orders[exIndex] = order
                askBook.orders[exIndex]!["ID"] = exIndex
            }
        }
        if order["side"] == 1 {
            let lookupOrder = bidBook.orders[exIndex]!
            addOrderToLookUp(order: lookupOrder)
        }
        else {
            let lookupOrder = askBook.orders[exIndex]!
            addOrderToLookUp(order: lookupOrder)
        }
    }
    
    func confirmTrade(bookOrder: [String:Int], order: [String:Int]) {
        confirmTradeCollector.append(bookOrder)
        confirmTradeCollectorTimeStamps.append(order["timeStamp"]!)
    }
    
    func addTradeToBook(trade: Trade) {
        tradeBook.trades[tradeIndex] = trade
    }
    
    func removeOrder(order: [String:Int]) {
        if order["side"] == 1 {
            bidBook.numOrders[order["price"]!]! -= 1
            bidBook.priceSize[order["price"]!]! -= order["quantity"]!
            bidBook.orderIDs[order["price"]!]! = bidBook.orderIDs[order["price"]!]!.filter {$0 != order["ID"]}
            bidBook.orders.removeValue(forKey: order["ID"]!)
            if bidBook.numOrders[order["price"]!]! == 0 {
                bidBook.prices.remove(order["price"]!)
            }
        }
        else {
            askBook.numOrders[order["price"]!]! -= 1
            askBook.priceSize[order["price"]!]! -= order["quantity"]!
            askBook.orderIDs[order["price"]!]! = askBook.orderIDs[order["price"]!]!.filter {$0 != order["ID"]}
            askBook.orders.removeValue(forKey: order["ID"]!)
            if askBook.numOrders[order["price"]!]! == 0 {
                askBook.prices.remove(order["price"]!)
            }
        }
        lookUp[order["traderID"]!]!.removeValue(forKey: order["orderID"]!)
    }
    
    func modifyOrder(order: [String:Int], less: Int) {
        if order["side"] == 1 {
            if less < bidBook.orders[order["ID"]!]!["quantity"]! {
                bidBook.priceSize[order["price"]!]! -= less
                bidBook.orders[order["ID"]!]!["quantity"]! -= less
            }
            else {
                removeOrder(order: order)
            }
        }
        else {
            if less < askBook.orders[order["ID"]!]!["quantity"]! {
                askBook.priceSize[order["price"]!]! -= less
                askBook.orders[order["ID"]!]!["quantity"]! -= less
            }
            else {
                removeOrder(order: order)
            }
        }
    }
    
    func matchTrade(order: [String:Int]) {
        traded = true
        confirmTradeCollector.removeAll()
        confirmTradeCollectorTimeStamps.removeAll()
        // If order side is "buy"
        var remainder = order["quantity"]
        if order["side"] == 1 {
            while remainder! > 0 {
                let price = askBook.prices[0]
                if order["price"]! >= price {
                    let bookOrderExID = askBook.orderIDs[order["price"]!]![0]
                    let bookOrder = askBook.orders[bookOrderExID]
                    if remainder! >= bookOrder!["quantity"]! {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        //TODO consider chaninging orderID to ID for resting and incoming order
                        let trade = Trade(restingTraderID: (bookOrder?["traderID"])!, restingOrderID: (bookOrder?["orderID"])!, restingTimeStamp: (bookOrder?["timeStamp"])!, incomingTraderID: order["traderID"]!, incomingOrderID: order["orderID"]!, incomingTimeStamp: order["timeStamp"]!, tradePrice: (bookOrder?["price"])!, tradeQuantity: (bookOrder?["quantity"])!, side: order["side"]!)
                        addTradeToBook(trade: trade)
                        removeOrder(order: bookOrder!)
                        remainder! -= bookOrder!["quantity"]!
                    }
                    // Remainder less than book order
                    else {
                        var modifiedBookOrder = bookOrder!
                        modifiedBookOrder["quantity"]! -= remainder!
                        confirmTrade(bookOrder: modifiedBookOrder, order: order)
                        let trade = Trade(restingTraderID: (bookOrder?["traderID"])!, restingOrderID: (bookOrder?["orderID"])!, restingTimeStamp: (bookOrder?["timeStamp"])!, incomingTraderID: order["traderID"]!, incomingOrderID: order["orderID"]!, incomingTimeStamp: order["timeStamp"]!, tradePrice: (bookOrder?["price"])!, tradeQuantity: (bookOrder?["quantity"])!, side: order["side"]!)
                        addTradeToBook(trade: trade)
                        modifyOrder(order: bookOrder!, less: remainder!)
                        break
                    }
                }
                else {
                    // have to make order a var or else it errors because it is "let constant"
                    var newBookOrder = order
                    newBookOrder["quantity"] = remainder
                    addOrderToBook(order: newBookOrder)
                    break
                }
            }
        }
        // order is "sell"
        else {
            while remainder! > 0 {
                let price = bidBook.prices.last!
                if order["price"]! <= price {
                    let orderID = bidBook.orderIDs[price]![0]
                    let bookOrder = bidBook.orders[orderID]
                    if remainder! >= bookOrder!["quantity"]! {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        let trade = Trade(restingTraderID: (bookOrder?["traderID"])!, restingOrderID: (bookOrder?["orderID"])!, restingTimeStamp: (bookOrder?["timeStamp"])!, incomingTraderID: order["traderID"]!, incomingOrderID: order["orderID"]!, incomingTimeStamp: order["timeStamp"]!, tradePrice: (bookOrder?["price"])!, tradeQuantity: (bookOrder?["quantity"])!, side: order["side"]!)
                        addTradeToBook(trade: trade)
                        removeOrder(order: bookOrder!)
                        remainder! -= bookOrder!["quantity"]!
                    }
                    // Remainder less than book order
                    else {
                        var modifiedBookOrder = bookOrder!
                        modifiedBookOrder["quantity"]! -= remainder!
                        confirmTrade(bookOrder: modifiedBookOrder, order: order)
                        let trade = Trade(restingTraderID: (bookOrder?["traderID"])!, restingOrderID: (bookOrder?["orderID"])!, restingTimeStamp: (bookOrder?["timeStamp"])!, incomingTraderID: order["traderID"]!, incomingOrderID: order["orderID"]!, incomingTimeStamp: order["timeStamp"]!, tradePrice: (bookOrder?["price"])!, tradeQuantity: (bookOrder?["quantity"])!, side: order["side"]!)
                        addTradeToBook(trade: trade)
                        modifyOrder(order: bookOrder!, less: remainder!)
                        break
                    }
                }
                else {
                    // have to make order a var or else it errors because it is "let constant"
                    var newBookOrder = order
                    newBookOrder["quantity"] = remainder
                    addOrderToBook(order: newBookOrder)
                    break
                }
            }
        }
    }
    
    func processOrder(order: [String:Int]) {
        traded = false
        addOrderToHistory(order: order)
        // If order type is "add"
        if order["type"] == 1 {
            // If order side is "buy"
            if order["side"] == 1 {
                // If price is greater than or equal to lowest ask book price (i.e. is marketable)
                if order["price"]! >= askBook.prices[0] {
                    matchTrade(order: order)
                }
                else {
                    addOrderToBook(order: order)
                }
            }
            // Order is "sell"
            else {
                if order["price"]! <= bidBook.prices.last! {
                    matchTrade(order: order)
                }
                else {
                    addOrderToBook(order: order)
                }
            }
        }
        // order is "cancel" or "modify"
        else {
            // order is "cancel"
            if order["type"] == 2 {
                let orderToCancel = lookUp[order["traderID"]!]![order["orderID"]!]
                removeOrder(order: orderToCancel!)
            }
            // order is "modify"
            else {
                let orderToModify = lookUp[order["traderID"]!]![order["orderID"]!]
                modifyOrder(order: orderToModify!, less: order["quantity"]!)
            }
        }
    }
    
    func orderHistoryToCsv(filePath: String, data: String) {
        do {
            try data.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to write order history to file.")
            print("\(error)")
        }
    }
    
    func sipToCsv(filePath: String, data: String) {
        do {
            try data.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to write sip to file.")
            print("\(error)")
        }
    }
    
    func reportTopOfBook(nowTime: Int) -> [String:Int?] {
        let bestBidPrice = bidBook.prices.last
        let bestBidSize = bidBook.priceSize[bestBidPrice!]
        let bestAskPrice = askBook.prices[0]
        let bestAskSize = askBook.priceSize[bestAskPrice]
        let tob = ["timeStamp": nowTime, "bestBid": bestBidPrice, "bestAsk": bestAskPrice, "bidSize": bestBidSize, "askSize": bestAskSize]
        sipCollector.append(tob)
        let sipData = "\(tob["timeStamp"]!!),\(tob["bestBid"]!!),\(tob["bestAsk"]!!),\(tob["bidSize"]!!),\(tob["bidSize"]!!),\(tob["askSize"]!!)"
        sipString.append(contentsOf: sipData)
        return tob
    }
}








