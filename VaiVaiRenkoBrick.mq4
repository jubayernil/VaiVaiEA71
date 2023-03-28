//+------------------------------------------------------------------+
//|                                                      RENKO-2.mq4 |
//|                                  Copyright © 2023, Tradecube Ltd |
//|                                            https://tradecube.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023, Tradecube Ltd"
#property link      "https://tradecube.net"
//----
#property indicator_separate_window
#property indicator_buffers 5
//---- input parameters
extern int   brick1 = 100;       // Brick size
input int MA_per=11;            // MA period
input bool useTrim=true;        // Use rounded decimals
color ColorOfFon = White;
color Color1 = Blue;
color Color2 = Red;
//---- buffers
double Lab[];
double HU[];
double HD[];
double Fon[];
double MA[];
int brick=100;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   brick=brick1;
   if(_Digits==2)
      brick=brick1*100;
   ChartSetInteger(0,CHART_SHOW_GRID,false);
   IndicatorBuffers(4);
   IndicatorShortName("renko");
//---- indicators
   SetIndexStyle(0, DRAW_LINE,EMPTY, 0, ColorOfFon);
   SetIndexBuffer(0, Lab);
   SetIndexLabel(0, "RENKO");
   SetIndexEmptyValue(0,0);
   SetIndexStyle(1, DRAW_HISTOGRAM, EMPTY, 8, Color1);
   SetIndexBuffer(1, HU);
   SetIndexLabel(1, NULL);
   SetIndexEmptyValue(1,0);
   SetIndexStyle(2, DRAW_HISTOGRAM,EMPTY, 8, Color2);
   SetIndexBuffer(2, HD);
   SetIndexLabel(2, NULL);
   SetIndexEmptyValue(2,0);
   SetIndexStyle(3, DRAW_HISTOGRAM,EMPTY, 8, ChartGetInteger(0,CHART_COLOR_BACKGROUND));
   SetIndexBuffer(3, Fon);
   SetIndexLabel(3, NULL);
   SetIndexEmptyValue(3, 0);
   SetIndexStyle(4, DRAW_LINE,STYLE_SOLID, 2, clrCrimson);
   SetIndexBuffer(4, MA);
   SetIndexLabel(4, "MA");
   SetIndexEmptyValue(4,0);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete("RENKO-" + brick);
   return(0);
  }
datetime t0=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   Comment(TimeToString(iTime(_Symbol,PERIOD_M1,iBars(_Symbol,PERIOD_M1) - 2)));
   if(t0!=iTime(_Symbol,PERIOD_M1,0)||(iHigh(_Symbol,PERIOD_M1,0)-iLow(_Symbol,PERIOD_M1,0))>brick*Point)
     {
      t0=iTime(_Symbol,PERIOD_M1,0);
     }
   else
      return;
   int i, RenkoBuffShift = 0;
   double RenkoBuff[];
   double RenkoBuff2[];
   double digs=MathMax((1/(brick*_Point)),1);
   ArrayResize(RenkoBuff, iBars(_Symbol,PERIOD_M1));
   ArrayResize(RenkoBuff2, iBars(_Symbol,PERIOD_M1));
   RenkoBuff[RenkoBuffShift] = NormalizeDouble(iClose(_Symbol,PERIOD_M1,iBars(_Symbol,PERIOD_M1)-1),digs);
   if(useTrim)
     {
      double d=brick*_Point;
      string h=DoubleToString(d);
      int cc=0;
      for(int j=StringLen(h)-1; j>=0; j--)
        {
         if(StringSubstr(h,j,1)==".")
            break;
         if(StringSubstr(h,j,1)!="0"||cc>0)
            cc++;
        }
      RenkoBuff[RenkoBuffShift] = NormalizeDouble(iClose(_Symbol,PERIOD_M1,iBars(_Symbol,PERIOD_M1)-1),cc);
      if(cc==0)
        {
         for(j=0; j<StringLen(h)-1; j++)
           {
            if(StringSubstr(h,j,1)==".")
               break;
            if(StringSubstr(h,j,1)!="0"||cc>0)
               cc++;
           }
         d=NormalizeDouble(iClose(_Symbol,PERIOD_M1,iBars(_Symbol,PERIOD_M1)-1),1);
         h=DoubleToString(d);
         int count=0;
         string t="";
         for(j=StringLen(h)-1; j>=0; j--)
           {
            if(count>0 && count<cc+1)
              {
               t=t+"0";
               count++;
              }
            else
               if(count>0)
                  t=t+StringSubstr(h,j,1);
            if(StringSubstr(h,j,1)==".")
               count++;
           }
           string newPrice="";
           for(j=StringLen(t)-1; j>=0; j--)
           {
            newPrice=newPrice+StringSubstr(t,j,1);
           }
         RenkoBuff[RenkoBuffShift] = NormalizeDouble(StringToDouble(newPrice),_Digits);
        }
     }
   RenkoBuff[RenkoBuffShift] = NormalizeDouble(RenkoBuff[RenkoBuffShift],_Digits);
//----
   for(i = iBars(_Symbol,PERIOD_M1) - 2; i >= 0; i--)
     {
      if(RenkoBuffShift > ArraySize(RenkoBuff) - 100)
        {
         ArrayCopy(RenkoBuff2, RenkoBuff);
         ArrayResize(RenkoBuff, ArraySize(RenkoBuff) + iBars(_Symbol,PERIOD_M1));
         ArrayCopy(RenkoBuff, RenkoBuff2, 0, 0, RenkoBuffShift + 1);
         ArrayResize(RenkoBuff2, ArraySize(RenkoBuff2) + iBars(_Symbol,PERIOD_M1));
        }
      //----
      if(RenkoBuffShift == 0)
        {
         while(iClose(_Symbol,PERIOD_M1,i) > RenkoBuff[RenkoBuffShift] + brick*Point)
           {
            RenkoBuffShift++;
            RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] + brick*Point;
           }
         //----
         while(iClose(_Symbol,PERIOD_M1,i)<RenkoBuff[RenkoBuffShift]-brick*Point)
           {
            RenkoBuffShift++;
            RenkoBuff[RenkoBuffShift]=RenkoBuff[RenkoBuffShift-1]-brick*Point;
           }
        }
      //----
      if(RenkoBuff[RenkoBuffShift] > RenkoBuff[RenkoBuffShift-1])
        {
         if(iClose(_Symbol,PERIOD_M1,i) > RenkoBuff[RenkoBuffShift] + brick*Point)
           {
            while(iClose(_Symbol,PERIOD_M1,i) > RenkoBuff[RenkoBuffShift] + brick*Point)
              {
               RenkoBuffShift++;
               RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] + brick*Point;
              }
           }
         if(iClose(_Symbol,PERIOD_M1,i) < RenkoBuff[RenkoBuffShift] - 2*brick*Point)
           {
            RenkoBuffShift++;
            RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] - 2*brick*Point;
            while(iClose(_Symbol,PERIOD_M1,i) < RenkoBuff[RenkoBuffShift] - brick*Point)
              {
               RenkoBuffShift++;
               RenkoBuff[RenkoBuffShift]=RenkoBuff[RenkoBuffShift-1]-brick*Point;
              }
           }
        }
      //----
      if(RenkoBuff[RenkoBuffShift] < RenkoBuff[RenkoBuffShift-1])
        {
         if(iClose(_Symbol,PERIOD_M1,i) < RenkoBuff[RenkoBuffShift] - brick*Point)
           {
            while(iClose(_Symbol,PERIOD_M1,i) < RenkoBuff[RenkoBuffShift] - brick*Point)
              {
               RenkoBuffShift++;
               RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] - brick*Point;
              }
           }
         if(iClose(_Symbol,PERIOD_M1,i) > RenkoBuff[RenkoBuffShift] + 2*brick*Point)
           {
            RenkoBuffShift++;
            RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] + 2*brick*Point;
            while(iClose(_Symbol,PERIOD_M1,i) > RenkoBuff[RenkoBuffShift] + brick*Point)
              {
               RenkoBuffShift++;
               RenkoBuff[RenkoBuffShift] = RenkoBuff[RenkoBuffShift-1] + brick*Point;
              }
           }
        }
     }
//---- Ðèñóåì ãðàôèê
   ObjectCreate("RENKO-" + brick, OBJ_RECTANGLE, WindowFind("RENKO(" + brick + "pt)"),
                0, 0, 0, 0);
   ObjectSet("RENKO-" + brick, OBJPROP_TIME2, Time[0]);
   ObjectSet("RENKO-" + brick, OBJPROP_PRICE2, iHigh(_Symbol,PERIOD_M1,ArrayMaximum(RenkoBuff))*2);
   ObjectSet("RENKO-" + brick, OBJPROP_COLOR, ColorOfFon);
   for(i = 0; i < iBars(_Symbol,PERIOD_M1); i++)
     {
      Lab[i] = 0;
      HU[i] = 0;
      HD[i] = 0;
      Fon[i] = 0;
     }
   if(RenkoBuffShift > iBars(_Symbol,PERIOD_M1) - 100)
     {
      for(i = 0; i <= iBars(_Symbol,PERIOD_M1) - 100; i++)
         RenkoBuff[i] = RenkoBuff[i+RenkoBuffShift-(iBars(_Symbol,PERIOD_M1)-100)];
      RenkoBuffShift = iBars(_Symbol,PERIOD_M1) - 100;
     }
   for(i = 1; i <= RenkoBuffShift; i++)
      Lab[RenkoBuffShift-i] = RenkoBuff[i];
   for(i = 1; i <= RenkoBuffShift; i++)
     {
      if(RenkoBuff[i] > RenkoBuff[i-1] && RenkoBuff[i-1] > RenkoBuff[i-2])
        {
         HU[RenkoBuffShift-i] = RenkoBuff[i];
         HD[RenkoBuffShift-i] = RenkoBuff[i-1];
         Fon[RenkoBuffShift-i] = RenkoBuff[i-1];
        }
      if(RenkoBuff[i] > RenkoBuff[i-1] && RenkoBuff[i-1] < RenkoBuff[i-2])
        {
         HU[RenkoBuffShift-i] = RenkoBuff[i];
         HD[RenkoBuffShift-i] = RenkoBuff[i] - brick*Point;
         Fon[RenkoBuffShift-i] = RenkoBuff[i] - brick*Point;
        }
      if(RenkoBuff[i] < RenkoBuff[i-1] && RenkoBuff[i-1] < RenkoBuff[i-2])
        {
         HD[RenkoBuffShift-i] = RenkoBuff[i-1];
         HU[RenkoBuffShift-i] = RenkoBuff[i];
         Fon[RenkoBuffShift-i] = RenkoBuff[i];
        }
      if(RenkoBuff[i] < RenkoBuff[i-1] && RenkoBuff[i-1] > RenkoBuff[i-2])
        {
         HD[RenkoBuffShift-i] = RenkoBuff[i] + brick*Point;
         HU[RenkoBuffShift-i] = RenkoBuff[i];
         Fon[RenkoBuffShift-i] = RenkoBuff[i];
        }
     }
   sma(RenkoBuffShift,MA_per);
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sma(int bars,int MA_Period)
  {
   double sum=0;
   int    i,pos=bars-1;
//---- initial accumulation
   if(pos<MA_Period)
      pos=MA_Period;
   for(i=1; i<MA_Period; i++,pos--)
      sum+=Lab[pos];
//---- main calculation loop
   while(pos>=0)
     {
      sum+=Lab[pos];
      MA[pos]=sum/MA_Period;
      sum-=Lab[pos+MA_Period-1];
      pos--;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
