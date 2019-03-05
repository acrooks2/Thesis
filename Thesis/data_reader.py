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

# Plotting data
fig1 = plt.figure(1)
fig1.size = (15, 10)
f1ax1 = fig1.add_subplot(121)
f1ax1.plot(price_hist)

f1ax2 = fig1.add_subplot(122)
f1ax2.plot(price_hist2)
# Line Plots
price_hist.plot()
returns.plot()
pd.plotting.autocorrelation_plot(returns)
pd.plotting.autocorrelation_plot(abs(returns))

# Histograms
plt.hist(returns, log=True, bins=100)

# Deleting files for next run
os.remove("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip.csv")
os.remove("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders.csv")
os.remove("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/wealth.csv")
os.remove("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip2.csv")
os.remove("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders2.csv")



