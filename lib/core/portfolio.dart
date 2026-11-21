class PortfolioBook {
  PortfolioBook({this.initialCapital=100000}) {if(!initialCapital.isFinite||initialCapital<0.01||initialCapital>1e10)throw ArgumentError('Invalid capital');cashCents=(initialCapital*100).round();}
  final double initialCapital;
  late int cashCents;
  final quantities=<String,double>{};
  final marks=<String,double>{};
  final entries=<Map<String,dynamic>>[];
  double get cash=>cashCents/100;
  double get marketValue=>quantities.entries.fold(0.0,(sum,e)=>sum+e.value*(marks[e.key]??0));
  double get equity=>cash+marketValue;
  void trade(String symbol,double units,double audPrice,double fee){
    symbol=symbol.trim().toUpperCase();
    if(symbol.isEmpty||!units.isFinite||units.abs()<1e-8||units.abs()>1e9||!audPrice.isFinite||audPrice<=0||audPrice>1e9||!fee.isFinite||fee<0||fee>1e10)throw ArgumentError('Invalid portfolio trade');
    final position=(quantities[symbol]??0)+units;
    final next=cashCents-(units*audPrice*100).round()-(fee*100).round();
    if(position< -1e-8||next<0)throw StateError('Insufficient holdings or cash');
    cashCents=next;if(position.abs()<1e-8){quantities.remove(symbol);}else{quantities[symbol]=position;}
    marks[symbol]=audPrice;entries.add({'symbol':symbol,'units':units,'price':audPrice,'fee':fee});
  }
  void mark(String symbol,double value){if(!quantities.containsKey(symbol)||!value.isFinite||value<=0||value>1e9)throw ArgumentError('Invalid valuation');marks[symbol]=value;}
  Map<String,dynamic> toJson()=>{'capital':initialCapital,'entries':entries,'marks':marks};
  factory PortfolioBook.restore(Map<String,dynamic> j){final p=PortfolioBook(initialCapital:(j['capital'] as num).toDouble());for(final row in j['entries'] as List){p.trade(row['symbol'] as String,(row['units'] as num).toDouble(),(row['price'] as num).toDouble(),(row['fee'] as num).toDouble());}for(final e in (j['marks'] as Map).entries){if(p.quantities.containsKey(e.key))p.mark(e.key as String,(e.value as num).toDouble());}return p;}
}
