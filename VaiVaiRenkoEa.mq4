//+------------------------------------------------------------------+
//|                                                     EA Renko.mq4 |
//|                                   Copyright 2023, Tradecube Ltd. |
//|                                        https://www.tradecube.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Tradecube Ltd."
#property link "https://www.tradecube.net"
#property version "1.00"
#property strict

#import "user32.dll"
int RegisterWindowMessageW(string MessageName);
int PostMessageW(int hwnd, int msg, int wparam, uchar &Name[]);
#import

#define INDICATOR_NAME "renko"
#define INDICATOR_NAME2 "RenkoRSI"

enum LOTTYPE
{
    lt0 = 0, // Fixed
    lt1 = 1, // % Equity based lotsize
};

input string p00 = "****** EA SETTINGS *******"; //******** EA SETTINGS *********
input LOTTYPE lotmode = 0;                       // Lot calculation mode
input double m_lot = 0.01;                       // Fixed lotsize
input double m_risk = 1;                         // % lotsize
input int m_magic = 9811;                        // Magic no.
input bool showIndicator = true;                 // Show indicators on chart
input int bars = 3;                              // No. of bars to confirm valid entry(RSI-MA)
input bool closeWithRenko = true;                // Close with opposite renko

input string p01 = "****** RENKO INDICATOR *******"; //******** RENKO INDICATOR *********
extern int brick = 100;                              // Brick size
input int MA_per = 11;                               // MA period
input bool useTrim = true;                           // Use rounded decimals

input string p02 = "**** RENKO-RSI INDICATOR *****"; //******** RENKO INDICATOR *********
input int rsi_per = 7;                               // RSI period
input int MA_per1 = 20;                              // MA period
extern int brick1 = 100;                             // Brick size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double renko(int sh) { return (iCustom(_Symbol, _Period, "renko", brick, MA_per, useTrim, 0, sh)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double renkoMA(int sh) { return (iCustom(_Symbol, _Period, "renko", brick, MA_per, useTrim, 4, sh)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double renko_rs(int sh) { return (iCustom(_Symbol, _Period, "RenkoRSI", rsi_per, MA_per1, brick1, 0, sh)); }
double renko_ma(int sh) { return (iCustom(_Symbol, _Period, "RenkoRSI", rsi_per, MA_per1, brick1, 1, sh)); }

//+------------------------------------------------------------------+
//| To load the indicators when added to chart                       |
//+------------------------------------------------------------------+
void StartCustomIndicator(int hWnd, string IndicatorName, bool AutomaticallyAcceptDefaults = true)
{
    uchar name2[];
    StringToCharArray(IndicatorName, name2, 0, StringLen(IndicatorName));

    int MessageNumber = RegisterWindowMessageW("MetaTrader4_Internal_Message");
    int r = PostMessageW(hWnd, MessageNumber, 15, name2);
    Sleep(100);
}

//+------------------------------------------------------------------+
//| Checking if indicator is already loaded                          |
//+------------------------------------------------------------------+
bool isThere(string indi)
{
    int j = ChartWindowFind(ChartID(), indi);
    if (j == -1)
        return false;
    return true;
}

datetime t0 = 0, tt = 0;
double ren_op = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Comment("Loading..");
    if (IsTesting() && Period() != PERIOD_M1)
    {
        Comment("Use M1 timeframe for strategy tester!");
        Alert("Use M1 timeframe for strategy tester!");
        return INIT_FAILED;
    }
    //---
    if (showIndicator)
    {
        int hWnd = WindowHandle(Symbol(), 0);
        //--if indicator 1 is not loaded, load it
        if (!isThere(INDICATOR_NAME))
        {
            StartCustomIndicator(hWnd, INDICATOR_NAME);
            int cc = 0;
            while (!isThere(INDICATOR_NAME))
            {
                Sleep(1000);
                cc++;
                if (cc > 60)
                    break;
            }
        }
        //--if indicator 2 is not loaded, load it
        if (!isThere(INDICATOR_NAME2))
            StartCustomIndicator(hWnd, INDICATOR_NAME2);
    }
    Comment("");
    ChartSetInteger(0, CHART_HEIGHT_IN_PIXELS, 1, 0);
    ren_op = renko(0);
    //---
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
}
datetime dt = 0;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CloseBricks();
    // BE();
    /*Comment("Renko 0->"+DoubleToString(renko(1))+"\n"+
            "Renko m->"+DoubleToString(renkoMA(1))+"\n"+
            "Renko rs->"+DoubleToString(renko_rs(1))+"\n"+
            "Renko ma->"+DoubleToString(renko_ma(1))+"\n"+
            "<-------->");*/
    //--Getting trading signal
    int sig = signal();
    int sig2 = signal2();
    if ((sig == -1 || sig2 == -1))
        Comment(sig, " vs ", sig2);
    //---
    if (dt != iTime(_Symbol, PERIOD_M1, 0))
    {
        dt = iTime(_Symbol, PERIOD_M1, 0);
        if (ren_op != renko(0))
        {
            //--closing trades on exit signal
            if (closeWithRenko)
            {
                if (renko(0) > renko(1))
                {
                    CloseAllOrders(OP_SELL);
                }
                if (renko(0) < renko(1))
                {
                    CloseAllOrders(OP_BUY);
                }
            }
            else
            {
                if (renko_rs(0) > renko_ma(1))
                {
                    CloseAllOrders(OP_SELL);
                }
                if (renko_rs(0) < renko_ma(1))
                {
                    CloseAllOrders(OP_BUY);
                }
            }
            ren_op = renko(0);
            if (OrdCount() == 0 && (sig == 1 || sig2 == 1) && tt != Time[0])
            {
                tt = Time[0];
                lastdirr = 1;
                double lots = getLot(Ask, Ask + (brick * _Point));
                OpenTrade(OP_BUY, lots, 0, 0, "");
            }
            if (OrdCount() == 0 && (sig == -1 || sig2 == -1) && tt != Time[0])
            {
                tt = Time[0];
                lastdirr = -1;
                double lots = getLot(Bid, Bid + (brick * _Point));
                OpenTrade(OP_SELL, lots, 0, 0, "");
            }
        }
    }
}

//+------------------------------------------------------------------+
//|  RSI calculations                                                |
//+------------------------------------------------------------------+
double getRSI(int RSIperiod, int shift)
{
    double vSumUp = 0, vSumDown = 0, vDiff = 0;

    // Need to get the RSI on the very first bar,
    int iStartBar = Bars - RSIperiod - 1;
    for (int iFirstCalc = iStartBar; iFirstCalc < iStartBar + RSIperiod; iFirstCalc++)
    {
        vDiff = Close[iFirstCalc] - Close[iFirstCalc + 1];
        if (vDiff > 0)
        {
            vSumUp += vDiff;
        }
        else
        {
            vSumDown += MathAbs(vDiff);
        }
    }
    double vAvgUp = vSumUp / RSIperiod;
    double vAvgDown = vSumDown / RSIperiod;

    // And now, we have to calculate the smoothed RSI value for
    // each subsequent bar until we get to the one requested
    for (int iRepeat = iStartBar - 1; iRepeat >= shift; iRepeat--)
    {
        vDiff = Close[iRepeat] - Close[iRepeat + 1];

        if (vDiff > 0)
        {
            vAvgUp = ((vAvgUp * (RSIperiod - 1)) + vDiff) / RSIperiod;
            vAvgDown = ((vAvgDown * (RSIperiod - 1))) / RSIperiod;
        }
        else
        {
            vAvgUp = ((vAvgUp * (RSIperiod - 1))) / RSIperiod;
            vAvgDown = ((vAvgDown * (RSIperiod - 1)) + MathAbs(vDiff)) / RSIperiod;
        }
    }

    if (vAvgDown == 0)
        return 0;
    else
        return (100.0 - 100.0 / (1 + (vAvgUp / vAvgDown)));
}

//+------------------------------------------------------------------+
//| Lotsize calculations                                             |
//+------------------------------------------------------------------+
double getLot(double price1, double price2)
{
    if (lotmode == 0)
        return m_lot;
    double res = 0;
    double amount = m_lot * 0.08 * AccountEquity();
    double pts = (MathAbs(price1 - price2) / _Point) / (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) / _Point);
    double pf = pts * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    res = amount / pf;
    return NormalizeDouble(res, 2);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int signal()
{
    int res = 0;
    //--buy 1
    if (renko(1) <= renkoMA(1) && renko(0) > renkoMA(0) && renko_rs(0) > renko_ma(0) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        for (int i = 1; i < i + bars; i++)
        {
            if (renko_rs(i) < renko_ma(i))
            {
                res = 1;
                return res;
            }
        }
    }
    //--buy 2
    if (renko(0) > renkoMA(0) && renko_rs(0) > renko_ma(0) && renko_rs(1) <= renko_ma(1) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        for (int i = 1; i < i + bars; i++)
        {
            if (renko(i) < renkoMA(i))
            {
                res = 1;
                return res;
            }
        }
    }

    //--sell 1
    if (renko(1) >= renkoMA(1) && renko(0) < renkoMA(0) && renko_rs(0) < renko_ma(0) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        for (int i = 1; i < bars + 1; i++)
        {
            if (renko_rs(i) > renko_ma(i))
            {
                res = -1;
                return res;
            }
        }
    }
    //--sell 2
    if (renko(0) < renkoMA(0) && renko_rs(0) < renko_ma(0) && renko_rs(1) >= renko_ma(1) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        for (int i = 1; i < bars + 1; i++)
        {
            if (renko(i) > renkoMA(i))
            {
                res = -1;
                return res;
            }
        }
    }
    return res;
}

int lastdirr = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int signal2()
{
    int res = 0;
    if (lastdirr == 1 && renko(0) < renkoMA(0))
        lastdirr = 0;
    if (lastdirr == -1 && renko(0) > renkoMA(0))
        lastdirr = 0;
    //--buy 2
    if (lastdirr == 1 && renko_rs(0) > renko_ma(0) && renko_rs(1) <= renko_ma(1) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        return 1;
    }

    //--sell 2
    if (lastdirr == -1 && renko_rs(0) < renko_ma(0) && renko_rs(1) >= renko_ma(1) && renko_ma(1) > 0 && renko_ma(1) != EMPTY_VALUE)
    {
        return -1;
    }

    return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenTrade(int type, double lot, int sl = 0, int tp = 0, string cm = "")
{
    double price = 0;
    double ssl = 0;
    double ttp = 0;
    color clr = clrNONE;

    if (type == OP_BUY)
    {
        price = Ask;
        if (sl > 0)
            ssl = price - sl * _Point;
        if (tp > 0)
            ttp = price + tp * _Point;
        clr = clrBlue;
    }
    if (type == OP_SELL)
    {
        price = Bid;
        if (sl > 0)
            ssl = price + sl;
        if (tp > 0)
            ttp = price - tp;
        clr = clrRed;
    }
    int k = OrderSend(_Symbol, type, lot, price, 10, ssl, ttp, MQLInfoString(MQL_PROGRAM_NAME), m_magic, 0, clr);
    if (k == -1)
        Print("Failed to place orderType ", type, " with errorcode #", GetLastError());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders(int type = -1)
{
    for (int i = OrdersTotal(); i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS))
            continue;
        if (OrderSymbol() == _Symbol && OrderMagicNumber() == m_magic)
        {
            if (type == -1 || (OrderType() == OP_BUY && type == OP_BUY))
            {
                if (!OrderClose(OrderTicket(), OrderLots(), Bid, 10))
                    Print("Failed to close buy order with errorcode #", GetLastError());
            }

            if (type == -1 || (OrderType() == OP_SELL && type == OP_SELL))
            {
                if (!OrderClose(OrderTicket(), OrderLots(), Ask, 10))
                    Print("Failed to close sell order with errorcode #", GetLastError());
            }
        }
    }
}

void CloseBricks()
{
    for (int i = OrdersTotal(); i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS))
            continue;
        if (OrderSymbol() == _Symbol && OrderMagicNumber() == m_magic)
        {
            if (OrderType() == OP_BUY && ((OrderClosePrice() <= (OrderOpenPrice() - brick * 2 * _Point)) || (OrderClosePrice() <= (renko(0) - brick * 2 * _Point))))
            {
                if (!OrderClose(OrderTicket(), OrderLots(), Bid, 10))
                    Print("Failed to close buy order with errorcode #", GetLastError());
            }

            if (OrderType() == OP_SELL && ((OrderClosePrice() >= (OrderOpenPrice() + brick * 2 * _Point)) || (OrderClosePrice() >= (renko(0) + brick * 2 * _Point))))
            {
                if (!OrderClose(OrderTicket(), OrderLots(), Ask, 10))
                    Print("Failed to close sell order with errorcode #", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrdCount(int type = -1)
{
    int res = 0;
    for (int i = OrdersTotal(); i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS))
            continue;
        if (OrderMagicNumber() == m_magic && OrderSymbol() == _Symbol)
        {
            if (OrderType() == type || type == -1)
                res = res + 1;
        }
    }
    return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BE()
{
    for (int i = OrdersTotal(); i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS))
            continue;
        if (OrderMagicNumber() == m_magic && OrderSymbol() == _Symbol)
        {
            if (OrderType() == OP_BUY && OrderClosePrice() > OrderOpenPrice() + brick * _Point && OrderStopLoss() == 0)
            {
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * 2 * _Point, OrderTakeProfit(), 0))
                {
                }
            }
            if (OrderType() == OP_SELL && OrderClosePrice() < OrderOpenPrice() - brick * _Point && OrderStopLoss() == 0)
            {
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * 2 * _Point, OrderTakeProfit(), 0))
                {
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
