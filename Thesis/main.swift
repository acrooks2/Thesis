//
//  unitTests.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation
import Accelerate


var bb1 = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab1 = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb1 = TradeBook(trades: [:])
var bb2 = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab2 = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb2 = TradeBook(trades: [:])
var ob1 = OrderBook(bidbook: bb1, askbook: ab1, tradebook: tb1)
var ob2 = OrderBook(bidbook: bb2, askbook: ab2, tradebook: tb2)



var market1 = Runner(exchange1: ob1, exchange2: ob2, runSteps: 25000, numProviders: 20, numMMs: 1, numMTs: 50, setupTime: 20)
market1.setup()
market1.run(prime: market1.setupTime, writeInterval: 500)
