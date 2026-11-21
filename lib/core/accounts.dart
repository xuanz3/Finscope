import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'storage.dart';

// Local-only demonstration profiles. No OAuth, SMS or remote authentication.
class LocalAccounts {
  LocalAccounts(this.store) { final saved=store.read('local_accounts'); if(saved!=null){profiles.addAll((saved['profiles'] as List).map((v)=>Map<String,dynamic>.from(v as Map))); active=saved['active'] as String?;} }
  final LocalStore store;
  final profiles=<Map<String,dynamic>>[];
  String? active;
  Map<String,dynamic>? get current { for(final p in profiles){if(p['id']==active)return p;}return null; }
  void save()=>store.write('local_accounts',{'profiles':profiles,'active':active});
  static String salt()=>base64UrlEncode(List.generate(24,(_)=>Random.secure().nextInt(256)));
  static String digest(String password,String salt){
    final mac=Hmac(sha256,utf8.encode(password));
    final seed=[...base64Url.decode(salt),0,0,0,1];
    var u=mac.convert(seed).bytes;final result=List<int>.of(u);
    for(var i=1;i<120000;i++){u=mac.convert(u).bytes;for(var j=0;j<result.length;j++){result[j]^=u[j];}}
    return base64UrlEncode(result);
  }
  void create({required String name,required String saltValue,required String hash,required int avatar,required String method,String phone='',bool remember=true}){
    if(name.trim().isEmpty)throw ArgumentError('Name required');
    final id=salt();profiles.add({'id':id,'name':name.trim(),'salt':saltValue,'hash':hash,'avatar':avatar,'googleDemo':method=='Google','phoneDemo':phone,'created':DateTime.now().toIso8601String(),'lastLogin':DateTime.now().toIso8601String(),'remember':remember,'notifications':true,'market':'Forex'});active=id;save();
  }
  void update(Map<String,dynamic> values){current?.addAll(values);save();}
  void signOut(){active=null;save();}
  bool signIn(String id,String hash){for(final p in profiles){if(p['id']==id&&p['hash']==hash){active=id;p['lastLogin']=DateTime.now().toIso8601String();save();return true;}}return false;}
  void deleteCurrent(){profiles.removeWhere((p)=>p['id']==active);signOut();}
  void restoreSession(){if(current?['remember']!=true)signOut();}
}
