//+------------------------------------------------------------------+
//|                                                     RenkoRSI.mq4 |
//|                                   Copyright 2023, Tradecube Ltd. |
//|                                        https://www.tradecube.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Tradecube Ltd."
#property link      "https://www.tradecube.net"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot RSI
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "MA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- indicator buffers

input int rsi_per=7; // RSI period
input int MA_per=20;   // MA period
extern int   brick = 100;       // Brick size
input bool useTrim=true;        // Use rounded decimals

double         RSIBuffer[],MABuffer[];
double close_[];
int bars=0;

//--getting renko bars values to an array
void get()
  {
   bars=0;
   for(int i=0; i<100000; i++)
     {
      double lad=iCustom(_Symbol,_Period,"renko",brick,11,useTrim,0,i);
      if(lad==0||lad==EMPTY_VALUE)
         break;
      ArrayResize(close_,bars+1);
      close_[i]=lad;
      bars++;
     }
   ArrayResize(RSIBuffer,bars-1);
   ArrayResize(MABuffer,bars-1);
  }
datetime t0=0;
double aEMA[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,RSIBuffer);
   ArraySetAsSeries(RSIBuffer,true);
   SetIndexBuffer(1,MABuffer);
   ArraySetAsSeries(MABuffer,true);
   ArraySetAsSeries(aEMA,true);

   IndicatorShortName("RenkoRSI");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(t0!=iTime(_Symbol,PERIOD_M1,0))
     {
      t0=iTime(_Symbol,PERIOD_M1,0);
      get();
      //Print(bars);
      for(int i=0; i<bars; i++)
        {
         RSIBuffer[i]=getRSI(rsi_per,i);
        }
      ArrayResize(aEMA,bars);
      for(int i=(bars-1-MA_per); i>=0; i--)
        {
         MABuffer[i]=iEMA(RSIBuffer[i],MA_per,i);
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|  RSI calculations                                                |
//+------------------------------------------------------------------+
double getRSI(int RSIperiod, int shift)
  {
   double vSumUp = 0, vSumDown = 0, vDiff = 0;

// Need to get the RSI on the very first bar,
   int iStartBar = bars - RSIperiod - 1;
   for(int iFirstCalc = iStartBar; iFirstCalc < iStartBar + RSIperiod; iFirstCalc++)
     {
      vDiff = close_[iFirstCalc] - close_[iFirstCalc + 1];
      if(vDiff > 0)
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
   for(int iRepeat = iStartBar - 1; iRepeat >= shift; iRepeat--)
     {
      vDiff = close_[iRepeat] - close_[iRepeat + 1];

      if(vDiff > 0)
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

   if(vAvgDown == 0)
      return 0;
   else
      return(100.0 - 100.0/(1+(vAvgUp/vAvgDown)));
  }
  
double iEMA(double price, int period, int i) 
{
    double  length, alpha;

    length = (period>1) ? period:1;
    alpha = 2.0/(length + 1.0);


    if(aEMA[i+1]>0 && aEMA[i+1]!=EMPTY_VALUE) {
        aEMA[i] = aEMA[i+1] + alpha*(price-aEMA[i+1]);
    } else {
        aEMA[i] = price;
    }

    return (aEMA[i]);
        
}
//+------------------------------------------------------------------+
