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
from collections import Counter

lower_bound = 10000
upper_bound = 105000

files = ["/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/wealth.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/sip2.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/orders2.csv",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/e1Trades.json",
         "/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Code/maker_taker/Swift/Thesis/Thesis/e2Trades.json"]

def remove_files(files):
    for file in files:
        os.remove(file)
        
res_PI_TQ_1 = []
res_PI_TQ_2 = []
res_eff_spread_1 = []
res_eff_spread_2 = []
res_logDD_Ask_1 = []
res_logDD_Bid_1 = []
res_logDD_Ask_2 = []
res_logDD_Bid_2 = []
res_price_impact_1 = []
res_price_impact_2 = []
res_r_vol_1 = []
res_r_vol_2 = []
res_real_spread_1 = []
res_real_spread_2 = []
res_time_ba_1 = []
res_time_ba_2 = []
res_time_bb_1 = []
res_time_bb_2 = []
res_twqs_1 = []
res_twqs_2 = []
res_vwqs_1 = []
res_vwqs_2 = []


# Reading data
sip = pd.read_csv("sip.csv")
sip2 = pd.read_csv("sip2.csv")
sip["price"] = (sip.bestBid + sip.bestAsk) / 2
sip["spread"] = sip.bestAsk - sip.bestBid
sip2["price"] = (sip2.bestBid + sip2.bestAsk) / 2
sip2["spread"] = sip2.bestAsk - sip2.bestBid
price_hist = sip.price[lower_bound : upper_bound]
price_hist2 = sip2.price[lower_bound : upper_bound]
sip["returns"] = np.log(sip.price).diff()
sip2["returns"] = np.log(sip2.price).diff()
returns = sip.returns[lower_bound : upper_bound]
returns2 = sip2.returns[lower_bound : upper_bound]

orders = pd.read_csv("orders.csv")
orders2 = pd.read_csv("orders2.csv")

wealth = pd.read_csv("wealth.csv")

e1trades = pd.read_json("e1Trades.json")
e2trades = pd.read_json("e2Trades.json")

def calc_eff_spread(row):
    if row["side"] == 1:
        return (2 * ((row["bestAsk"] - row["price"]) / row["price"]))
    if row["side"] == 2:
        return (-2 * ((row["bestBid"] - row["price"]) / row["price"]))

PRICE_IMPACT_DELTA_T = 5

def calc_price_impact(row):
    if row["side"] == 1:
        return (2 * ((row["priceTDelta"] - row["price"]) / row["price"]))
    if row["side"] == 2:
        return (-2 * ((row["priceTDelta"] - row["price"]) / row["price"]))


def convert_realized_spread(row):
    if row["side"] == 1:
        return row["rs"]
    if row["side"] == 2:
        return row["rs"] * -1


e1trades = e1trades.sort_values(by="incomingTimeStamp")
e1trades = e1trades.reset_index(drop=True)
e1trades = e1trades.rename({"incomingTimeStamp":"timeStamp"}, axis="columns")
e1trades = e1trades.join(sip.set_index("timeStamp"), on="timeStamp")
e1trades["effectiveSpread"] = e1trades.apply(lambda row: calc_eff_spread(row), axis=1)

e2trades = e2trades.sort_values(by="incomingTimeStamp")
e2trades = e2trades.reset_index(drop=True)
e2trades = e2trades.rename({"incomingTimeStamp":"timeStamp"}, axis="columns")
e2trades = e2trades.join(sip.set_index("timeStamp"), on="timeStamp")
e2trades["effectiveSpread"] = e2trades.apply(lambda row: calc_eff_spread(row), axis=1)


sip = sip.join(e1trades.set_index("timeStamp").drop(labels=['bestBid', 'bestAsk', 'bidSize', 'askSize', 'price', 'spread', 'returns'], axis=1), on="timeStamp")
sip["priceTDelta"] = sip.price.shift(-1 * PRICE_IMPACT_DELTA_T)
sip["priceImpact"] = sip.apply(lambda row: calc_price_impact(row), axis=1)
realizedSpread = sip[["side", "bestAsk", "bestBid", "tradePrice", "priceTDelta", "price"]].dropna()
realizedSpread["rs"] = (realizedSpread.tradePrice - realizedSpread.priceTDelta) / realizedSpread.price
realizedSpread.rs = realizedSpread.apply(lambda row: convert_realized_spread(row), axis=1)

sip2 = sip2.join(e2trades.set_index("timeStamp").drop(labels=['bestBid', 'bestAsk', 'bidSize', 'askSize', 'price', 'spread', 'returns'], axis=1), on="timeStamp")
sip2["priceTDelta"] = sip2.price.shift(-1 * PRICE_IMPACT_DELTA_T)
sip2["priceImpact"] = sip2.apply(lambda row: calc_price_impact(row), axis=1)
realizedSpread2 = sip2[["side", "bestAsk", "bestBid", "tradePrice", "priceTDelta", "price"]].dropna()
realizedSpread2["rs"] = (realizedSpread2.tradePrice - realizedSpread2.priceTDelta) / realizedSpread2.price
realizedSpread2.rs = realizedSpread2.apply(lambda row: convert_realized_spread(row), axis=1)


# Plotting data
#fig1 = plt.figure(1)
#fig1.size = (15, 10)
#f1ax1 = fig1.add_subplot(221)
#f1ax1.plot(price_hist)
#f1ax1.plot(price_hist2)
#
#f1ax2 = fig1.add_subplot(222)
#f1ax2.plot(returns)
#
#f1ax3 = fig1.add_subplot(223)
#f1ax3.plot(price_hist2)
#
#f1ax4 = fig1.add_subplot(224)
#f1ax4.plot(returns2)

# Deleting files for next run
        
remove_files(files)

# Line Plots


#pd.plotting.autocorrelation_plot(returns[0:2000])
#pd.plotting.autocorrelation_plot(abs(returns))
#
#pd.plotting.autocorrelation_plot(abs(returns2))
## Histograms
#plt.hist(returns, log=True, bins=20)
#plt.hist(returns, bins=20)
#
#plt.hist(returns2, log=True)

# Scatter Plots
#fig2 = plt.figure(2)
#f2ax1 = fig2.add_subplot(111)
#f2ax1.scatter(x=sip.bestBid, y=sip2.bestBid)
#
#fig3 = plt.figure(3)
#f3ax1 = fig3.add_subplot(111)
#f3ax1.plot(sip.bestBid)
#f3ax1.plot(sip.bestAsk)
#
#fig4 = plt.figure(4)
#f4ax1 = fig4.add_subplot(111)
#f4ax1.plot(sip2.bestBid)
#f4ax1.plot(sip2.bestAsk)

# Metrics
# Cancel to Trade Ratio
cancels = orders[orders.type == 2]
trades = orders[(orders.traderID >= 2000) & (orders.traderID < 3000)]
cancels.size / trades.size

trades.size / cancels.size

cancels2 = orders2[orders2.type == 2]
trades2 = orders2[(orders2.traderID >= 2000) & (orders2.traderID < 3000)]
cancels2.size / trades2.size

trades2.size / cancels2.size


wealth1 = wealth[wealth.TraderID == "1000"]
wealth1.Wealth = pd.to_numeric(wealth1.Wealth)
#wealth1.plot()

wealth2 = wealth[wealth.TraderID == "1001"]
wealth2.Wealth = pd.to_numeric(wealth2.Wealth)
#wealth2.plot()

# Plotting realized spread
#realizedSpread.rs.plot()
#realizedSpread2.rs.plot()

#realizedSpread.rs.hist()
#realizedSpread2.rs.hist()

# Plotting effective spread
#sip.effectiveSpread.plot()
#sip2.effectiveSpread.plot()

# Plotting price impact
#sip.priceImpact.plot()
#sip2.priceImpact.plot()


# Calculating Volume-Weighted Quoted Spread from section 3.4.1
sip["Volume"] = sip.askSize + sip.bidSize
sip["VWQS"] = (sip.spread * sip.Volume) / sip.Volume

sip2["Volume"] = sip2.askSize + sip2.bidSize
sip2["VWQS"] = (sip2.spread * sip2.Volume) / sip2.Volume

# Calculation the time-weighted spread from section 3.4.1
time_at_each_spread = Counter(sip.spread)
tw = []
count = []
for k, v in time_at_each_spread.items():
    tw.append(k * v)
    count.append(v)
TWQS = sum(tw) / sum(count)

time_at_each_spread2 = Counter(sip2.spread)
tw2 = []
count2 = []
for k, v in time_at_each_spread2.items():
    tw2.append(k * v)
    count2.append(v)
TWQS2 = sum(tw2) / sum(count2)

# Calculating log of dollar value at best ask and bid in 3.4.2
sip["logDollarDepthAsk"] = np.log(sip.askSize)
sip.logDollarDepthAsk = sip.logDollarDepthAsk.replace(-np.inf, np.nan)
sip["logDollarDepthBid"] = np.log(sip.bidSize)
sip.logDollarDepthBid = sip.logDollarDepthBid.replace(-np.inf, np.nan)
sip.logDollarDepthAsk.fillna(method="ffill").mean()
sip.logDollarDepthBid.fillna(method="ffill").mean()

sip2["logDollarDepthAsk"] = np.log(sip2.askSize)
sip2.logDollarDepthAsk = sip2.logDollarDepthAsk.replace(-np.inf, np.nan)
sip2["logDollarDepthBid"] = np.log(sip2.bidSize)
sip2.logDollarDepthBid = sip2.logDollarDepthBid.replace(-np.inf, np.nan)
sip2.logDollarDepthAsk.fillna(method="ffill").mean()
sip2.logDollarDepthBid.fillna(method="ffill").mean()

# Calculating average price impact to average trade volume from 3.4.2
sip.priceImpact.mean() / sip.tradeQuantity.mean()

sip2.priceImpact.mean() / sip2.tradeQuantity.mean()

# Calculating the time each exchange spends at the best bid and ask prices from 3.4.2
mostTS = None
if sip.size > sip2.size:
    mostTS = sip
if sip2.size > sip.size:
    mostTS = sip2
if sip.size == sip2.size:
    mostTS = sip

bestAskExchange = None
bestBidExchange = None
bae = None
e1_time_at_best_ask = None
e2_time_at_best_ask = None
e1_time_at_best_bid = None
e2_time_at_best_bid = None

if mostTS.size == sip.size:
    bestAskExchange = sip[["timeStamp", "bestAsk", "bestBid"]]
    bestAskExchange = bestAskExchange.join(sip2[["bestAsk", "bestBid"]], on="timeStamp", rsuffix="2")
    bestAskExchange = bestAskExchange[10000:]
    baTimes = np.where(bestAskExchange.bestAsk < bestAskExchange.bestAsk2, 1, np.where(bestAskExchange.bestAsk2 < bestAskExchange.bestAsk, 2, 0))
    ca = Counter(baTimes)
    bae = ca[1]/ca[2]
    e1_time_at_best_ask = ca[1]/sum(list(ca.values()))
    e2_time_at_best_ask = ca[2]/sum(list(ca.values()))
    
    bbTimes = np.where(bestAskExchange.bestBid < bestAskExchange.bestBid2, 1, np.where(bestAskExchange.bestBid2 < bestAskExchange.bestBid, 2, 0))
    cb = Counter(bbTimes)
    e1_time_at_best_bid = cb[1]/sum(list(cb.values()))
    e2_time_at_best_bid = cb[2]/sum(list(cb.values()))

if mostTS.size == sip2.size:
    bestAskExchange = sip2[["timeStamp", "bestAsk", "bestBid"]]
    bestAskExchange = bestAskExchange.join(sip[["bestAsk", "bestBid"]], on="timeStamp", rsuffix="1")
    bestAskExchange = bestAskExchange[10000:]
    baTimes = np.where(bestAskExchange.bestAsk1 < bestAskExchange.bestAsk, 1, np.where(bestAskExchange.bestAsk < bestAskExchange.bestAsk1, 2, 0))
    c = Counter(baTimes)
    bae = c[1]/c[2]
    e1_time_at_best_ask = c[1]/sum(list(c.values()))
    e2_time_at_best_ask = c[2]/sum(list(c.values()))
    
    bbTimes = np.where(bestAskExchange.bestBid1 < bestAskExchange.bestBid, 1, np.where(bestAskExchange.bestBid < bestAskExchange.bestBid1, 2, 0))
    cb = Counter(bbTimes)
    e1_time_at_best_bid = cb[1]/sum(list(cb.values()))
    e2_time_at_best_bid = cb[2]/sum(list(cb.values()))
    
res_PI_TQ_1.append(sip.priceImpact.mean() / sip.tradeQuantity.mean())
res_PI_TQ_2.append(sip2.priceImpact.mean() / sip2.tradeQuantity.mean())
res_eff_spread_1.append(sip.effectiveSpread.mean())
res_eff_spread_2.append(sip2.effectiveSpread.mean())
res_logDD_Ask_1.append(sip.logDollarDepthAsk.fillna(method="ffill").mean())
res_logDD_Bid_1.append(sip.logDollarDepthBid.fillna(method="ffill").mean())
res_logDD_Ask_2.append(sip2.logDollarDepthAsk.fillna(method="ffill").mean())
res_logDD_Bid_2.append(sip2.logDollarDepthBid.fillna(method="ffill").mean())
res_price_impact_1.append(sip.priceImpact.mean())
res_price_impact_2.append(sip2.priceImpact.mean())
res_r_vol_1.append(sip.returns.std())
res_r_vol_2.append(sip2.returns.std())
res_real_spread_1.append(realizedSpread.rs.mean())
res_real_spread_2.append(realizedSpread2.rs.mean())
res_time_ba_1.append(e1_time_at_best_ask)
res_time_ba_2.append(e2_time_at_best_ask)
res_time_bb_1.append(e1_time_at_best_bid)
res_time_bb_2.append(e2_time_at_best_bid)
res_twqs_1.append(TWQS)
res_twqs_2.append(TWQS2)
res_vwqs_1.append(sip.VWQS.mean())
res_vwqs_2.append(sip2.VWQS.mean())

fig1 = plt.figure(1, figsize=(15,10))
fig1.size = (15, 10)
plt.suptitle("Simultaneous Prices at Each Exchange", fontsize=30)
f1ax1 = fig1.add_subplot(111)
f1ax1.plot(price_hist[13000:15000], "bs-", ms=5, markerfacecolor="none", label="No Rebate Exchange")
f1ax1.plot(price_hist2[13000:15000], "r^-", ms=5, markerfacecolor="none", label="Rebate Exchange")
plt.setp(f1ax1, xticks=np.arange(23000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
plt.setp(f1ax1, yticks=np.arange(1001340, 1001430, 25), yticklabels=np.arange(340, 430, 25))
f1ax1.set_xlabel("Time", fontsize=25)
f1ax1.set_ylabel("Price", fontsize=25)
plt.legend()
fig1.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/PriceMatch.png")

f1ax2 = fig1.add_subplot(222)
f1ax2.plot(returns)

f1ax3 = fig1.add_subplot(223)
f1ax3.plot(price_hist2)

f1ax4 = fig1.add_subplot(224)
f1ax4.plot(returns2)



res_PI_TQ_1.pop()
res_PI_TQ_2.pop()
res_eff_spread_1.pop()
res_eff_spread_2.pop()
res_logDD_Ask_1.pop()
res_logDD_Ask_2.pop()
res_logDD_Bid_1.pop()
res_logDD_Bid_2.pop()
res_price_impact_1.pop()
res_price_impact_2.pop()
res_r_vol_1.pop()
res_r_vol_2.pop()
res_real_spread_1.pop()
res_real_spread_2.pop()
res_vwqs_1.pop()
res_vwqs_2.pop()
res_twqs_1.pop()
res_twqs_2.pop()
res_time_ba_1.pop()
res_time_ba_2.pop()
res_time_bb_1.pop()
res_time_bb_2.pop()


import xlwings as xw

#R = 20
#d = {0:"C", 1:"D", 2:"E", 3:"F", 4:"G", 5:"H", 6:"I", 7:"J", 8:"K", 9:"L", 10:"M", 11:"N", 12:"O", 13:"P", 14:"Q", 15:"R", 16:"S", 17:"T", 18:"U", 19:"V", 20:"W"}
#
#wb = xw.Book("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/Results.xlsx")
#sht = wb.sheets["Sheet1"]
#sht.range(d[R]+"2").value = np.mean(res_eff_spread_1)
#sht.range(d[R]+"3").value = np.mean(res_eff_spread_2)
#sht.range(d[R]+"4").value = np.mean(res_real_spread_1)
#sht.range(d[R]+"5").value = np.mean(res_real_spread_2)
#sht.range(d[R]+"6").value = np.mean(res_price_impact_1)
#sht.range(d[R]+"7").value = np.mean(res_price_impact_2)
#sht.range(d[R]+"8").value = np.mean(res_vwqs_1)
#sht.range(d[R]+"9").value = np.mean(res_vwqs_2)
#sht.range(d[R]+"10").value = np.mean(res_twqs_1)
#sht.range(d[R]+"11").value = np.mean(res_twqs_2)
#sht.range(d[R]+"12").value = np.mean(res_logDD_Ask_1)
#sht.range(d[R]+"13").value = np.mean(res_logDD_Ask_2)
#sht.range(d[R]+"14").value = np.mean(res_logDD_Bid_1)
#sht.range(d[R]+"15").value = np.mean(res_logDD_Bid_2)
#sht.range(d[R]+"16").value = np.mean(res_PI_TQ_1)
#sht.range(d[R]+"17").value = np.mean(res_PI_TQ_2)
#sht.range(d[R]+"18").value = np.mean(sip.returns.std())
#sht.range(d[R]+"19").value = np.mean(sip2.returns.std())

# Results plots (Chapter 4)
import xlwings as xw
import matplotlib.pyplot as plt
import numpy as np
#wb = xw.Book("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/Results.xlsx")
#sht = wb.sheets["Sheet1"]
#effective_spread_1 = sht["C2:W2"].value
#effective_spread_2 = sht["C3:W3"].value
#realized_spread_1 = sht["C4:W4"].value
#realized_spread_2 = sht["C5:W5"].value
#price_impact_1 = sht["C6:W6"].value
#price_impact_2 = sht["C7:W7"].value
#vwqs_1 = sht["C8:W8"].value
#vwqs_2 = sht["C9:W9"].value
#twqs_1 = sht["C10:W10"].value
#twqs_2 = sht["C11:W11"].value
#log_DD_A_1 = sht["C12:W12"].value
#log_DD_A_2 = sht["C13:W13"].value
#log_DD_B_1 = sht["C14:W14"].value
#log_DD_B_2 = sht["C15:W15"].value
#PI_TQ_1 = sht["C16:W16"].value
#PI_TQ_2 = sht["C17:W17"].value
#R_vol_1 = sht["C18:W18"].value
#R_vol_2 = sht["C19:W19"].value

# Plotting effective spread
fig1 = plt.figure(1, figsize=(15,10))
f1ax1 = fig1.add_subplot(111)
fig1.size = (15, 10)
plt.suptitle("Effective Spread as Rebate Increases", fontsize=30)
plt.xlabel("Rebate", fontsize=25)
plt.ylabel("Effective Spread", fontsize=25)
plt.xticks(np.arange(0, 21, 1))
f1ax1.plot(effective_spread_1, "bs-", label="No-Rebate Exchange")
f1ax1.plot(effective_spread_2, "r^-", label="Rebate Exchange")
plt.legend(fontsize=15)
plt.show()
fig1.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/EffectiveSpread.png")

# Plotting volume weighted quoted spread
fig2 = plt.figure(2, figsize=(15,10))
f2ax1 = fig2.add_subplot(111)
plt.suptitle("Volume-Weighted Quoted Spread as Rebate Increases", fontsize=30)
plt.xlabel("Rebate", fontsize=25)
plt.ylabel("Volume-Weighted Spread", fontsize=25)
plt.xticks(np.arange(0, 21, 1))
f2ax1.plot(vwqs_1, "bs-",label="No-Rebate Exchange")
f2ax1.plot(vwqs_2, "r^-", label="Rebate Exchange")
plt.legend(fontsize=15)
plt.show()
fig2.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/VWQS.png")

# Plotting time weighted quoted spread
fig3 = plt.figure(3, figsize=(15,10))
f3ax1 = fig3.add_subplot(111)
plt.suptitle("Time-Weighted Quoted Spread as Rebate Increases", fontsize=30)
plt.xlabel("Rebate", fontsize=25)
plt.ylabel("Time-Weighted Spread", fontsize=25)
plt.xticks(np.arange(0, 21, 1))
f3ax1.plot(twqs_1, "bs-", label="No-Rebate Exchange")
f3ax1.plot(twqs_2, "r^-", label="Rebate Exchange")
plt.legend(fontsize=15)
plt.show()
fig3.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/TWQS.png")

# Plotting log dollar depth
fig4 = plt.figure(4, figsize=(15, 10))
f4ax1 = fig4.add_subplot(111)
plt.suptitle("Log Dollar Depth as Rebate Increases", fontsize=30)
plt.xlabel("Rebate", fontsize=25)
plt.ylabel("Log Dollar Depth", fontsize=25)
plt.xticks(np.arange(0, 21, 1))
f4ax1.plot(log_DD_A_1, "bs-", label="No-Rebate Exchange Ask")
f4ax1.plot(log_DD_A_2, "r^-", label="Rebate Exchange Ask")
f4ax1.plot(log_DD_B_1, "bx-", label="No-Rebate Exchange Bid")
f4ax1.plot(log_DD_B_2, "ro-", label="Rebate Exchange Bid")
plt.legend(fontsize=15)
plt.show()
fig4.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/logDD.png")

# Plotting average PI to average TQ
fig5 = plt.figure(5, figsize=(15, 10))
f5ax1 = fig5.add_subplot(111)
plt.suptitle("Price Impact to Trade Volume as Rebate Increases", fontsize=30)
plt.xlabel("Rebate", fontsize=25)
plt.ylabel("Price Impact to Trade Volume", fontsize=25)
plt.xticks(np.arange(0, 21, 1))
f5ax1.plot(PI_TQ_1, "bs-", label="No-Rebate Exchange")
f5ax1.plot(PI_TQ_2, "r^-", label="Rebate Exchange")
plt.legend(fontsize=15)
plt.show()
fig5.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/PI_TQ.png")

# Plotting Return Characteristics
fig6 = plt.figure(6, figsize=(15, 10))
plt.suptitle("Price Time Series and Returns", fontsize=30)
f6ax1 = fig6.add_subplot(211)
f6ax1.xaxis.label.set
f6ax1.plot(price_hist, "g-")
f6ax1.set_ylabel("Price", fontsize=25)
f6ax2 = fig6.add_subplot(212)
f6ax2.set_ylabel("Log Return", fontsize=25)
f6ax2.set_xlabel("Time", fontsize=25)
f6ax2.plot(returns, "g-")
plt.setp(f6ax1, xticks=np.arange(10000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
plt.setp(f6ax1, yticks=np.arange(999825, 1000026, 25), yticklabels=np.arange(995, 1197, 25))
plt.setp(f6ax2, xticks=np.arange(10000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
fig6.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/NoRebatePrice_Returns.png")

fig7 = plt.figure(7, figsize=(15, 10))
plt.suptitle("Price Time Series and Returns for Rebate Exchange", fontsize=30)
f7ax1 = fig7.add_subplot(211)
f7ax1.plot(price_hist2, "r-")
f7ax1.set_ylabel("Price", fontsize=25)
f7ax2 = fig7.add_subplot(212)
f7ax2.set_ylabel("Return", fontsize=25)
f7ax2.set_xlabel("Time", fontsize=25)
f7ax2.plot(returns, "r-")
plt.setp(f7ax1, xticks=np.arange(10000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
plt.setp(f7ax1, yticks=np.arange(999825, 1000026, 25), yticklabels=np.arange(995, 1197, 25))
plt.setp(f7ax2, xticks=np.arange(10000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
fig7.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/RebatePrice_Returns.png")

# Fractal Nature
fig8, f8ax1 = plt.subplots(figsize=(15, 5))
f8ax1.plot(price_hist, "g-")
plt.suptitle("Fractal Price Pattern", fontsize=30)
f8ax1.set_xlabel("Time", fontsize=25)
f8ax1.set_ylabel("Price", fontsize=25)
plt.setp(f8ax1, xticks=np.arange(10000, 25001, 1000), xticklabels=np.arange(0, 15001, 1000))
plt.setp(f8ax1, yticks=np.arange(999825, 1000026, 25), yticklabels=np.arange(995, 1197, 25))
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes
axins1 = zoomed_inset_axes(f8ax1, 4, loc=3) # zoom-factor: 2.5, location: upper-left
axins1.plot(price_hist, "g-")
x1, x2, y1, y2 = 10600, 11700, 999990, 1000017 # specify the limits
axins1.set_xlim(x1, x2) # apply the x-limits
axins1.set_ylim(y1, y2) # apply the y-limits
plt.yticks(visible=False)
plt.xticks(visible=False)
plt.setp(axins1, xticks=np.arange(10600, 11701, 100))
plt.setp(axins1, yticks=np.arange(999990, 1000018, 100))
from mpl_toolkits.axes_grid1.inset_locator import mark_inset
mark_inset(f8ax1, axins1, loc1=2, loc2=1, fc="none", ec="0.5")
axins2 = zoomed_inset_axes(f8ax1, 8, loc=9)
axins2.plot(price_hist, "g-")
xa, xb, ya, yb = 22400, 22800, 999922, 999935
axins2.set_xlim(xa, xb)
axins2.set_ylim(ya, yb)
plt.xticks(visible=False)
plt.yticks(visible=False)
plt.setp(axins2, xticks=np.arange(22400, 22801, 1000))
plt.setp(axins2, yticks=np.arange(999922, 999936, 25))
mark_inset(f8ax1, axins2, loc1=4, loc2=1, fc="none", ec="0.5")
fig8.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/FractalPrice.png")

# Return distribution
fig9 = plt.figure(9, figsize=(15, 10))
plt.suptitle("Return Distribution", fontsize=30)
f9ax1 = fig9.add_subplot(111)

f9ax1.set_xlabel("Log Return", fontsize=25)
prices = [sip.price.mean()]
for x in range(sip.price.size):
    prices.append(np.random.normal(loc=prices[-1], scale=sip.price.diff().std()))
norm_returns = pd.DataFrame(prices, columns=["prices_sd1"])
norm_returns["returns_sd1"] = np.log(norm_returns["prices_sd1"]).diff()
prices = [sip.price.mean()]
for x in range(sip.price.size):
    prices.append(np.random.normal(loc=prices[-1], scale=sip.price.diff().std() * 2))
norm_returns["prices_sd2"] = prices
norm_returns["returns_sd2"] = np.log(norm_returns.prices_sd2).diff()
prices = [sip.price.mean()]
for x in range(sip.price.size):
    prices.append(np.random.normal(loc=prices[-1], scale=3))
norm_returns["prices_sd3"] = prices
norm_returns["returns_sd3"] = np.log(norm_returns.prices_sd3).diff()
f9ax1.hist(norm_returns.returns_sd1, bins=40, histtype="step", color="b", alpha=0.3, log=True, label="Normal Distribution")
#f9ax1.hist(norm_returns.returns_sd2, bins=30, histtype="step", color="r", alpha=0.3, log=True)
#f9ax1.hist(norm_returns.returns_sd3, bins=30, histtype="step", color="k", alpha=0.3, log=True)
f9ax1.hist(sip.returns, bins=40, histtype="step", color="g", linewidth=2, log=True, label="Return Distribution")
real_stocks = pd.read_csv("/Users/charlie/Downloads/2de0932742e45e03.csv")
real_stocks["returns"] = np.log(real_stocks.PRC).diff()
real_stocks.returns = real_stocks.returns / 5000
r = np.array(real_stocks.returns)
r = np.insert(r, 0, np.zeros(1000))

f9ax1.hist(r, histtype="step", bins=40, color="r", label="MSFT Returns")
plt.legend()
fig9.savefig("/Users/charlie/OneDrive - George Mason University/CSS/Thesis/Paper/ReturnDistribution.png")






