import 'package:flutter/material.dart';
import 'core/storage.dart';
import 'design_system/theme.dart';
import 'features/product_state.dart';
import 'features/workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {final store=await LocalStore.open();runApp(FinScopeApp(state:ProductState(store:store)));}
  catch(e){runApp(MaterialApp(theme:FinTheme.dark,home:Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('FinScope could not open local storage. Your existing database has not been reset.\n$e'))))));}
}
class FinScopeApp extends StatelessWidget {
  const FinScopeApp({super.key,this.state});
  final ProductState? state;
  @override
  Widget build(BuildContext context) => MaterialApp(title:'FinScope',debugShowCheckedModeBanner:false,theme:FinTheme.dark,home:Workspace(state:state));
}
