#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 27 11:01:07 2019

@author: charlie
"""

import pandas as pd
import os
import numpy as np
import matplotlib.pyplot as plt

lower_bound = 10000
upper_bound = 105000

files = ["/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/wealth.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip2.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders2.csv"]

def remove_files(files):
    for file in files:
        os.remove(file)

# Reading data
sip = pd.read_csv("sip.csv")
sip2 = pd.read_csv("sip2.csv")
sip["price"] = (sip.bestBid + sip.bestAsk) / 2
sip2["price"] = (sip.bestBid + sip.bestAsk) / 2
price_hist = sip.price[lower_bound : upper_bound]
price_hist2 = sip2.price[lower_bound : upper_bound]
sip["returns"] = np.log(sip.price).diff()
sip2["returns"] = np.log(sip2.price).diff()
returns = sip.returns[lower_bound : upper_bound]
returns2 = sip2.returns[lower_bound : upper_bound]

orders = pd.read_csv("orders.csv")
orders2 = pd.read_csv("orders2.csv")

wealth = pd.read_csv("wealth.csv")

# Plotting data
fig1 = plt.figure(1)
fig1.size = (15, 10)
f1ax1 = fig1.add_subplot(221)
f1ax1.plot(price_hist)

f1ax2 = fig1.add_subplot(222)
f1ax2.plot(returns)

f1ax3 = fig1.add_subplot(223)
f1ax3.plot(price_hist2)

f1ax4 = fig1.add_subplot(224)
f1ax4.plot(returns2)

# Deleting files for next run
        
remove_files(files)

# Line Plots


pd.plotting.autocorrelation_plot(returns[0:2000])
pd.plotting.autocorrelation_plot(abs(returns))

# Histograms
plt.hist(returns, log=True, bins=50)
plt.hist(returns, bins=20)

# Scatter Plots
fig2 = plt.figure(2)
f2ax1 = fig2.add_subplot(111)
f2ax1.scatter(x=sip.bestBid, y=sip2.bestBid)

fig3 = plt.figure(3)
f3ax1 = fig3.add_subplot(111)
f3ax1.plot(sip.bestBid)
f3ax1.plot(sip.bestAsk)

fig4 = plt.figure(4)
f4ax1 = fig4.add_subplot(111)
f4ax1.plot(sip2.bestBid)
f4ax1.plot(sip2.bestAsk)

# Metrics
# Cancel to Trade Ratio
cancels = orders[orders.type == 2]
trades = orders[(orders.traderID >= 2000) & (orders.traderID < 3000)]
cancels.size / trades.size

cancels2 = orders2[orders2.type == 2]
trades2 = orders2[(orders2.traderID >= 2000) & (orders2.traderID < 3000)]
cancels2.size / trades2.size




