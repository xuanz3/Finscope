import 'dart:convert';
import 'dart:io';
import 'chart_model.dart';
import 'trading.dart';

/// Daily official reference observations, NOT bid/ask or intraday OHLC.
/// Repeated O/H/L/C encode a single observed point, not an intraday range.
class EcbData {
  static const currencies=['USD','AUD','GBP','JPY','CHF','CAD','NZD'];
  static String day(DateTime d)=>d.toIso8601String().substring(0,10);
  static List<String> cells(String line){
    final out=<String>[];var field=StringBuffer();var quoted=false;
    for(var i=0;i<line.length;i++){final c=line[i];if(c=='"'){if(quoted&&i+1<line.length&&line[i+1]=='"'){field.write('"');i++;}else{quoted=!quoted;}}else if(c==','&&!quoted){out.add(field.toString());field=StringBuffer();}else{field.write(c);}}out.add(field.toString());return out;
  }
  static List<MarketSeries> parse(String csv,String start,String end){
    final lines=const LineSplitter().convert(csv.replaceFirst('\uFEFF',''));if(lines.isEmpty)throw const FormatException('Empty ECB response');
    final head=cells(lines.first);final ci=head.indexOf('CURRENCY'),di=head.indexOf('TIME_PERIOD'),vi=head.indexOf('OBS_VALUE');if(ci<0||di<0||vi<0)throw const FormatException('Unexpected ECB CSV format');
    final byDate=<String,Map<String,double>>{};
    for(final line in lines.skip(1)){if(line.trim().isEmpty)continue;final row=cells(line);if(row.length<=ci||row.length<=di||row.length<=vi)continue;final d=row[di],v=double.tryParse(row[vi]);if(v==null||!v.isFinite||v<=0||DateTime.tryParse(d)==null||d.compareTo(start)<0||d.compareTo(end)>0)continue;(byDate[d]??={'EUR':1.0})[row[ci]]=v;}
    final dates=byDate.keys.toList()..sort();final result=<MarketSeries>[];
    for(final pair in ['EUR/USD','AUD/USD','GBP/USD','USD/JPY','EUR/GBP','USD/CHF','USD/CAD','NZD/USD','EUR/AUD']){final p=pair.split('/');final bars=<DailyBar>[];for(final d in dates){final rates=byDate[d]!;final base=rates[p[0]],quote=rates[p[1]],aud=rates['AUD'];if(base==null||quote==null||aud==null)continue;final v=quote/base;bars.add(DailyBar(Candle(date:DateTime.parse('${d}T00:00:00Z'),open:v,high:v,low:v,close:v),aud/quote));}if(bars.length>=2)result.add(MarketSeries('$pair [ECB $start:$end]',bars,source:'ECB daily reference rate (derived cross)'));}
    if(result.isEmpty)throw const FormatException('No matching reference observations');return result;
  }
  static Future<List<MarketSeries>> download(String start,String end)async{
    final a=DateTime.tryParse(start),b=DateTime.tryParse(end);if(a==null||b==null||day(a)!=start||day(b)!=end||a.isBefore(DateTime.utc(1999))||!a.isBefore(b)||b.isAfter(DateTime.now().toUtc()))throw const FormatException('Choose valid dates from 1999 through today');
    final client=HttpClient()..connectionTimeout=const Duration(seconds:20);
    try{final uri=Uri.https('data-api.ecb.europa.eu','/service/data/EXR/D.${currencies.join('+')}.EUR.SP00.A',{'startPeriod':start,'endPeriod':end,'format':'csvdata','detail':'dataonly'});final req=await client.getUrl(uri);req.headers.set('Accept','text/csv');final res=await req.close().timeout(const Duration(seconds:60));if(res.statusCode!=200)throw HttpException('ECB returned HTTP ${res.statusCode}');final bytes=<int>[];await for(final part in res.timeout(const Duration(seconds:60))){bytes.addAll(part);if(bytes.length>24*1024*1024)throw const FormatException('Response exceeds 24 MB');}return parse(utf8.decode(bytes),start,end);}finally{client.close(force:true);}
  }
}
