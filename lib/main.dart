import 'package:flutter/material.dart';
import 'core/storage.dart';
import 'core/accounts.dart';
import 'features/account_workspace.dart';
import 'design_system/theme.dart';
import 'features/product_state.dart';
import 'features/workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {final store=await LocalStore.open();final accounts=LocalAccounts(store);accounts.restoreSession();runApp(FinScopeApp(state:ProductState(store:store),accounts:accounts));}
  catch(e){runApp(MaterialApp(theme:FinTheme.dark,home:Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Finscope could not open local storage. Your existing database has not been reset.\n$e'))))));}
}
class FinScopeApp extends StatelessWidget {
  const FinScopeApp({super.key,this.state,this.accounts});
  final ProductState? state;
  final LocalAccounts? accounts;
  @override
  Widget build(BuildContext context) => MaterialApp(title:'Finscope',debugShowCheckedModeBanner:false,theme:FinTheme.dark,home:accounts==null?Workspace(state:state):AccountGate(accounts:accounts!,workspace:(a,refresh)=>Workspace(state:state,accounts:a,onSession:refresh)));
}
