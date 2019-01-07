//
//  main.swift
//  Thesis
//
//  Created by Charlie on 1/5/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation


struct Order {
    var orderID: Int
    var traderID: Int
    var timeStamp: Int
    var type: Int
    var quantity: Int
    var side: Int
    var price: Int
}

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
    //orders is a dictionary with exIDs as keys and the associated order as values
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists of order ids as values
    var orderIDs: [Int:[Int]]
    
}

struct AskBook {
    //always sorted array of ask prices
    var prices: SortedArray<Int>
    //orders is a dictionary with exIDs as keys and the associated order as values
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists of order ids as values
    var orderIDs: [Int:[Int]]
}

struct TradeBook {
    // A dictionary to store all trades with trade ID as key and trades as values
    var trades: [Int:Trade]
}

class OrderBook {
    var orderHistory: [Int:Order]
    var bidBook: BidBook
    var askBook: AskBook
    var orderIndex: Int
    var exIndex: Int
    var traded: Bool
    var confirmTradeCollector: [Order]
    var tradeBook: TradeBook
    var tradeIndex: Int
    var lookUp: [Int:[Int:Order]]
    
    init(bidbook: BidBook, askbook: AskBook, tradebook: TradeBook) {
        self.orderHistory = [:]
        self.bidBook = bidbook
        self.askBook = askbook
        // Order index is simply to identify orders in sequence in order history
        self.orderIndex = 0
        // ex index is for identifying limit orders will hit in process order
        self.exIndex = 0
        self.traded = false
        self.confirmTradeCollector = []
        self.tradeBook = tradebook
        self.tradeIndex = 0
        self.lookUp = [:]
    }
    
    func addOrderToHistory(order: Order) {
        orderIndex += 1
        orderHistory[orderIndex] = order
    }
    
    func addOrderToLookUp(order: Order) {
        if lookUp.keys.contains(order.traderID) {
            lookUp[order.traderID]![order.orderID]! = order
        }
        else {
            lookUp[order.traderID]! = [order.orderID:order]
        }
    }
    
    func addOrderToBook(order: Order) {
        exIndex += 1
        // Add an order to the buy side
        if order.side == 1 {
            if bidBook.prices.contains(order.price) {
                bidBook.numOrders[order.price]! += 1
                bidBook.priceSize[order.price]! += order.quantity
                bidBook.orderIDs[order.price]!.append(exIndex)
                bidBook.orders[exIndex] = order
            }
            else {
                bidBook.prices.insert(order.price)
                bidBook.numOrders[order.price] = 1
                bidBook.priceSize[order.price] = order.quantity
                bidBook.orderIDs[order.price]!.append(exIndex)
                bidBook.orders[exIndex] = order
        
            }
        }
        // Add an order to the sell side
        else {
            if askBook.prices.contains(order.price) {
                askBook.numOrders[order.price]! += 1
                askBook.priceSize[order.price]! += order.quantity
                askBook.orderIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
            else {
                askBook.prices.insert(order.price)
                askBook.numOrders[order.price] = 1
                askBook.priceSize[order.price] = order.quantity
                askBook.orderIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
        }
    }
    
    func confirmTrade(order: Order) {
        confirmTradeCollector.append(order)
    }
    
    func addTradeToBook(trade: Trade) {
        tradeBook.trades[tradeIndex] = trade
    }
    
    func removeOrder(order: Order) {
        if order.side == 1 {
            bidBook.numOrders[order.price]! -= 1
            bidBook.priceSize[order.price]! -= order.quantity
            bidBook.orderIDs[order.price]!.removeLast()
            if bidBook.numOrders[order.price]! == 0 {
                bidBook.prices.remove(order.price)
            }
        }
    }
    
    func matchTrade(order: Order) {
        traded = true
        confirmTradeCollector.removeAll()
        // If order side is "buy"
        var remainder = order.quantity
        if order.side == 1 {
            while remainder > 0 {
                var price = askBook.prices[0]
                if order.price >= price {
                    var orderID = askBook.orderIDs[order.price]![0]
                    var bookOrder = askBook.orders[orderID]
                    if remainder >= bookOrder!.quantity {
                        confirmTrade(order: order)
                        var trade = Trade(restingTraderID: (bookOrder?.traderID)!, restingOrderID: (bookOrder?.orderID)!, restingTimeStamp: (bookOrder?.timeStamp)!, incomingTraderID: order.traderID, incomingOrderID: order.orderID, incomingTimeStamp: order.timeStamp, tradePrice: (bookOrder?.price)!, tradeQuantity: (bookOrder?.quantity)!, side: order.side)
                        addTradeToBook(trade: trade)
                        //remove order func
                    }
                }
            }
            
        }
    }
    
    func processOrder(order: Order) {
        traded = false
        addOrderToHistory(order: order)
        // If order type is "add"
        if order.type == 1 {
            // If order side is "buy"
            if order.side == 1 {
                // If price is greater than or equal to lowest ask book price (i.e. is marketable)
                if order.price >= askBook.prices[0] {
                    // match trade func
                }
            }
        }
    }
}

var bb = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb = TradeBook(trades: [:])
var ob = OrderBook(bidbook: bb, askbook: ab, tradebook: tb)

print(ob.askBook)
