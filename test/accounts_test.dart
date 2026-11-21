import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:finscope/core/storage.dart';
import 'package:finscope/core/accounts.dart';
void main(){
  test('local profiles persist, sign out, switch and delete without touching workspace',(){
    final store=LocalStore(sqlite3.openInMemory());addTearDown(store.close);
    store.write('workspace',{'keep':true});
    final a=LocalAccounts(store);
    a.create(name:'Test',saltValue:'unused',hash:'test-verifier',avatar:1,method:'Google');
    final id=a.active!;expect(LocalAccounts(store).current!['name'],'Test');
    a.signOut();expect(LocalAccounts(store).current,isNull);
    expect(a.signIn(id,'wrong'),isFalse);expect(a.signIn(id,'test-verifier'),isTrue);
    a.update({'name':'Updated','phoneDemo':'0400000000'});
    expect(LocalAccounts(store).current!['name'],'Updated');
    a.deleteCurrent();expect(LocalAccounts(store).profiles,isEmpty);expect(store.read('workspace')!['keep'],true);
  });
  test('remember preference controls startup session',(){final store=LocalStore(sqlite3.openInMemory());addTearDown(store.close);final a=LocalAccounts(store);a.create(name:'Local',saltValue:'unused',hash:'test-verifier',avatar:0,method:'Local',remember:false);final b=LocalAccounts(store);b.restoreSession();expect(b.current,isNull);expect(b.profiles.length,1);});
}
