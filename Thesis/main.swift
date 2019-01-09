//
//  unitTests.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation


var bb1 = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab1 = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb1 = TradeBook(trades: [:])
var bb2 = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab2 = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb2 = TradeBook(trades: [:])
var ob1 = OrderBook(bidbook: bb1, askbook: ab1, tradebook: tb1)
var ob2 = OrderBook(bidbook: bb2, askbook: ab2, tradebook: tb2)

/*
let initialOrder1 = ["orderID": 0, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 100, "side": 1, "price": 500]
let initialOrder2 = ["orderID": 1, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 100, "side": 1, "price": 499]
let initialOrder3 = ["orderID": 2, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 200, "side": 1, "price": 500]
let initialOrder4 = ["orderID": 3, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 100, "side": 2, "price": 505]
let initialOrder5 = ["orderID": 4, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 200, "side": 2, "price": 506]
let initialOrder6 = ["orderID": 5, "ID": 0, "traderID": 9999, "timeStamp": 1, "type": 1, "quantity": 100, "side": 2, "price": 505]
let newOrder1 = ["orderID": 1, "ID": 0, "traderID": 1000, "timeStamp": 1, "type": 1, "quantity": 100, "side": 1, "price": 500]
let newOrder2 = ["orderID": 1, "ID": 0, "traderID": 1001, "timeStamp": 2, "type": 1, "quantity": 100, "side": 1, "price": 500]
let newOrder3 = ["orderID": 1, "ID": 0, "traderID": 1002, "timeStamp": 2, "type": 1, "quantity": 100, "side": 1, "price": 498]
let newOrder4 = ["orderID": 1, "ID": 0, "traderID": 1003, "timeStamp": 3, "type": 1, "quantity": 50, "side": 2, "price": 0]
let removeOrder1 = ["orderID": 0, "ID": 1, "traderID": 9999, "timeStamp": 4, "type": 2, "quantity": 100, "side": 1, "price": 500]
let removeOrder2 = ["orderID": 3, "ID": 4, "traderID": 9999, "timeStamp": 5, "type": 2, "quantity": 100, "side": 2, "price": 505]
let modifyOrder1 = ["orderID": 2, "ID": 3, "traderID": 9999, "timeStamp": 6, "type": 3, "quantity": 20, "side": 1, "price": 500]

ob.addOrderToBook(order: initialOrder1)
ob.addOrderToBook(order: initialOrder2)
ob.addOrderToBook(order: initialOrder3)
ob.addOrderToBook(order: initialOrder4)
ob.addOrderToBook(order: initialOrder5)
ob.addOrderToBook(order: initialOrder6)
ob.processOrder(order: newOrder1)
ob.processOrder(order: newOrder2)
ob.processOrder(order: newOrder3)
ob.processOrder(order: newOrder4)
ob.processOrder(order: removeOrder1)
ob.processOrder(order: removeOrder2)
ob.processOrder(order: modifyOrder1)

print(ob.askBook)
print(ob.bidBook)
*/


var market1 = Runner(exchange1: ob1, exchange2: ob2, runSteps: 500, numMMs: 40, numMTs: 25, setupTime: 20)
market1.setup()
market1.run(prime: market1.setupTime, writeInterval: 5000)
