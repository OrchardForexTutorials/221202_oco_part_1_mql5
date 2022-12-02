/*

   OCO Part 1

   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

#property copyright "Copyright 2013-2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"

input int    InpTradeCounter   = 5;    // How many trade pairs to place
input int    InpTradeGapPoints = 500;  // How far from opening price to place trades
input int    InpSLTPPoints     = 50;   // SL/TP points, really just for demonstration
input double InpVolume         = 0.01; // Lot size

int          TradeCounter;
double       TradeGap;
double       SLTP;

struct SOCOPair
{
   ulong ticket1;
   ulong ticket2;
   SOCOPair() {}
   SOCOPair( ulong t1, ulong t2 ) {
      ticket1 = t1;
      ticket2 = t2;
   }
};

SOCOPair OCOPairs[];

#include <Trade/Trade.mqh>
CTrade Trade;

int    OnInit( void ) {

   TradeCounter = InpTradeCounter;
   TradeGap     = PointsToDouble( InpTradeGapPoints );
   SLTP         = PointsToDouble( InpSLTPPoints );

   return ( INIT_SUCCEEDED );
}

void OnTick( void ) {

   // Only trade until counter reaches zero
   if ( TradeCounter <= 0 ) return;

   // This part so we only trade once per bar
   static datetime previousTime = 0;
   datetime        currentTime  = iTime( Symbol(), Period(), 0 );
   if ( currentTime == previousTime ) return;
   previousTime     = currentTime;

   ulong buyTicket  = OpenOrder( ORDER_TYPE_BUY_STOP );
   ulong sellTicket = OpenOrder( ORDER_TYPE_SELL_STOP );

   OCOAdd( buyTicket, sellTicket );
   TradeCounter--;
}

void OnTradeTransaction( const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result ) {

   if ( trans.type == TRADE_TRANSACTION_ORDER_DELETE ) OCOClose( trans.order );
}

ulong OpenOrder( ENUM_ORDER_TYPE type ) {

   double price;
   double tp;
   double sl;
   if ( type % 2 == ORDER_TYPE_BUY ) {
      price = SymbolInfoDouble( Symbol(), SYMBOL_ASK ) + TradeGap;
      tp    = price + SLTP;
      sl    = price - SLTP;
   }
   else {
      price = SymbolInfoDouble( Symbol(), SYMBOL_BID ) - TradeGap;
      tp    = price - SLTP;
      sl    = price + SLTP;
   }

   ulong ticket = 0;
   if ( Trade.OrderOpen( Symbol(), type, InpVolume, 0, price, sl, tp, ORDER_TIME_GTC ) ) ticket = Trade.ResultOrder();

   return ticket;
}

bool   CloseOrder( ulong ticket ) { return Trade.OrderDelete( ticket ); }

double PointsToDouble( int points ) {

   double point = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   return ( point * points );
}

void OCOAdd( ulong ticket1, ulong ticket2 ) {

   if ( ticket1 <= 0 || ticket2 <= 0 ) return;
   int      count = ArraySize( OCOPairs );
   SOCOPair pair( ticket1, ticket2 );
   ArrayResize( OCOPairs, count + 1 );
   OCOPairs[count] = pair;
}

void OCOClose( ulong ticket ) {

   for ( int i = ArraySize( OCOPairs ) - 1; i >= 0; i-- ) {
      if ( OCOPairs[i].ticket1 == ticket ) {
         CloseOrder( OCOPairs[i].ticket2 );
         OCORemove( i );
         return;
      }
      if ( OCOPairs[i].ticket2 == ticket ) {
         CloseOrder( OCOPairs[i].ticket1 );
         OCORemove( i );
         return;
      }
   }
}

void OCORemove( int index ) {

   ArrayRemove( OCOPairs, index, 1 );
   return;
}
