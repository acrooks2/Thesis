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
sip["price"] = (sip.bestBid + sip.bestAsk) / 2
price_hist = sip.price[lower_bound : upper_bound]
sip["returns"] = np.log(sip.price).diff()
returns = sip.returns[lower_bound : upper_bound]

# Plotting data

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


