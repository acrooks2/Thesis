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

struct BidBook {
    //always sorted array of bid prices
    var prices: SortedArray<Int>
    //orders is a dictionary with prices as keys and a list of orders at each value
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    var exIDs: [Int:[Int]]
    
}

struct AskBook {
    //always sorted array of ask prices
    var prices: SortedArray<Int>
    //orders is a dictionary with prices as keys and a list of orders at each value
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    var exIDs: [Int:[Int]]
}

class OrderBook {
    var orderHistory: [Int:Order]
    var bidBook: BidBook
    var askBook: AskBook
    var orderIndex: Int
    var exIndex: Int
    
    init(bidBook: BidBook, askBook: AskBook) {
        self.orderHistory = [:]
        self.bidBook = bidBook
        self.askBook = askBook
        self.orderIndex = 0
        self.exIndex = 0
    }
    
    func addOrderToHistory(order: Order) {
        orderIndex += 1
        orderHistory[orderIndex] = order
    }
    
    func addOrderToBook(order: Order) {
        exIndex += 1
        if order.side == 1 {
            if bidBook.prices.contains(order.price) {
                bidBook.numOrders[order.price] += 1
                bidBook.priceSize[order.price] += order.quantity
                bidBook.exIDs[order.price]?.append(exIndex)
                bidBook.orders[exIndex] = order
            }
            else {
                bidBook.prices.insert(order.price)
                bidBook.numOrders[order.price] = 1
                bidBook.priceSize[order.price] = order.quantity
                bidBook.exIDs[order.price]?.append(exIndex)
                bidBook.orders[exIndex] = order
        
            }
        }
        else {
            if askBook.prices.contains(order.price) {
                askBook.numOrders[order.price] += 1
                askBook.priceSize[order.price] += order.quantity
                askBook.exIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
            else {
                askBook.prices.insert(order.price)
                askBook.numOrders[order.price] = 1
                askBook.priceSize[order.price] = order.quantity
                askBook.exIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
        }
    }
}

var bb = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], exIDs: [:])
var ab = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], exIDs: [:])
var ob = OrderBook(bidBook: bb, askBook: ab)

print(ob.askBook)
