import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/core/trading.dart';
import 'package:finscope/core/portfolio.dart';

MarketSeries input()=>MarketSeries.csv('TEST','''date,open,high,low,close,aud_per_quote
2020-01-01,100,101,99,100,1
2020-01-02,101,110,95,105,1
2020-01-03,105,120,90,110,1
2020-01-06,110,115,105,112,1''');
TradingSession setup()=>TradingSession(input(),spreadBps:0,commissionBps:0,slippageBps:0);
void main(){
  test('strict CSV rejects duplicate dates and invalid OHLC',(){expect(()=>MarketSeries.csv('X','date,open,high,low,close,aud_per_quote\n2020-01-01,10,9,8,10,1\n2020-01-02,10,11,9,10,1'),throwsFormatException);});
  test('future bars hidden; market order executes next open',(){final s=setup();s.submit(TradeOrder(units:10,kind:OrderKind.market));expect(s.visible.length,1);expect(s.fills,isEmpty);s.advance();expect(s.entry,101);expect(s.units,10);expect(s.equity,100040);s.submit(TradeOrder(units:-10,kind:OrderKind.market));s.advance();expect(s.cash,100040);expect(s.units,0);expect(s.unrealized,0);});
  test('protective stop takes precedence over target',(){final s=setup();s.submit(TradeOrder(units:10,kind:OrderKind.market,stopLoss:95,takeProfit:115));s.advance();s.advance();expect(s.cash,99940);expect(s.fills.last['reason'],'Stop loss');});
  test('limit order and insufficient margin',(){final s=setup();s.submit(TradeOrder(units:1,kind:OrderKind.limit,trigger:97));s.advance();expect(s.entry,97);s.submit(TradeOrder(units:100000,kind:OrderKind.market));s.advance();expect(s.units,1);expect(s.events.last,contains('insufficient'));});
  test('replay restores deterministically',(){final s=setup();s.submit(TradeOrder(units:-2,kind:OrderKind.market));s.advance();s.advance();final restored=TradingSession.restore(input(),s.toJson());expect(restored.equity,s.equity);expect(restored.fills,s.fills);expect(restored.equityHistory,s.equityHistory);});
  test('portfolio cash and valuation round-trip',(){final p=PortfolioBook();p.trade('ABC',10,100,2);p.trade('ABC',-2,110,1);p.mark('ABC',120);expect(p.cash,99217);expect(p.equity,100177);final r=PortfolioBook.restore(p.toJson());expect(r.equity,p.equity);expect(()=>p.trade('ABC',-100,10,0),throwsStateError);});
}
