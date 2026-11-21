import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:finscope/core/storage.dart';
import 'package:finscope/features/product_state.dart';
void main(){test('SQLite workspace restores journal, portfolio and replay',(){final store=LocalStore(sqlite3.openInMemory());try{final state=ProductState(store:store);state.session.advance();state.portfolio.trade('TEST',2,50,1);state.journal.add({'title':'Review','notes':'Test','date':'2020-01-01'});state.save();final r=ProductState(store:store);expect(r.session.index,state.session.index);expect(r.portfolio.equity,state.portfolio.equity);expect(r.journal.single['title'],'Review');}finally{store.close();}});}
