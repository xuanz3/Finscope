import 'package:flutter/material.dart';
import '../design_system/theme.dart';
import '../design_system/motion.dart';
import '../features/account_workspace.dart' show profileAvatar;
import 'experience.dart';

class TerminalShell extends StatelessWidget {
  const TerminalShell({super.key,required this.labels,required this.icons,required this.selected,required this.onSelect,required this.child,this.profile});
  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget child;
  final Map<String,dynamic>? profile;
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,bounds){
    final desktop=bounds.maxWidth>=800 && bounds.maxHeight>=560;
    final expanded=bounds.maxWidth>=1150;
    final account=labels.indexOf('Account');
    void showMore(){showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(ctx)=>SafeArea(child:ListView(shrinkWrap:true,children:[for(var i=4;i<labels.length;i++)ListTile(leading:BrandGlyph(i),title:Text(labels[i]),selected:selected==i,onTap:(){Navigator.pop(ctx);onSelect(i);})])));}
    return Scaffold(body:SafeArea(child:Row(children:[
      if(desktop)SizedBox(width:expanded?164:60,child:ColoredBox(color:FinTheme.header,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        SizedBox(height:64,child:Padding(padding:EdgeInsets.symmetric(horizontal:expanded?14:10),child:Row(children:[const FinScopeMark(size:25),if(expanded)...[const SizedBox(width:9),const Expanded(child:Text('Finscope',style:TextStyle(fontSize:19,fontWeight:FontWeight.w500,letterSpacing:-.85)))]]))),
        if(expanded)const Padding(padding:EdgeInsets.fromLTRB(13,6,8,8),child:Text('WORKSPACE',style:TextStyle(fontSize:9,color:FinTheme.steel,letterSpacing:1.25))),
        Expanded(child:ListView(padding:const EdgeInsets.all(6),children:[for(final i in [0,1,2,3,5,6,7,4,8])if(i<labels.length)Padding(padding:const EdgeInsets.only(bottom:4),child:navItem(i,expanded))])),
        if(expanded)Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(profile!=null)Row(children:[profileAvatar(profile,size:28),const SizedBox(width:7),Expanded(child:Text(profile!['name'].toString(),maxLines:1,overflow:TextOverflow.ellipsis))]),const SizedBox(height:7),const Text('LOCAL EDITION',style:TextStyle(fontSize:9,color:FinTheme.steel,letterSpacing:1)),const SizedBox(height:4),const Text('Xuanze Chen',style:TextStyle(fontSize:10,color:FinTheme.steel))]))
      ]))),
      if(desktop)const VerticalDivider(width:1,thickness:1),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        ColoredBox(color:FinTheme.header,child:SizedBox(height:52,child:Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:Row(children:[
          if(!desktop)...[const FinScopeMark(size:20),const SizedBox(width:9)],
          Expanded(child:Text(labels[selected],overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w500))),
          const Icon(Icons.circle,size:6,color:FinTheme.gain),const SizedBox(width:6),const Text('LOCAL DATA',style:TextStyle(fontSize:10,color:FinTheme.steel,letterSpacing:.6)),
          if(account>=0&&profile!=null)...[const SizedBox(width:12),Lift(semanticLabel:'Open account',onTap:()=>onSelect(account),child:Padding(padding:const EdgeInsets.all(3),child:profileAvatar(profile,size:29)))]
        ])))),const Divider(height:1),
        Expanded(child:DeskTransition(child:child)),
        if(desktop)const ColoredBox(color:FinTheme.header,child:Padding(padding:EdgeInsets.symmetric(horizontal:12,vertical:5),child:Row(children:[Icon(Icons.lock_outline,size:12,color:FinTheme.steel),SizedBox(width:5),Expanded(child:Text('Local workspace  /  Historical & sample data only',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,color:FinTheme.steel))),Text('Finscope  /  RC7',style:TextStyle(fontSize:10,color:FinTheme.steel))])))
      ]))
    ])),bottomNavigationBar:desktop?null:NavigationBar(selectedIndex:selected<4?selected:4,onDestinationSelected:(i){if(i==4){showMore();}else{onSelect(i);}},destinations:List.generate(5,(i)=>NavigationDestination(icon:BrandGlyph(i),selectedIcon:BrandGlyph(i,color:FinTheme.ivory),label:labels[i]))));
  });
  Widget navItem(int i,bool expanded)=>Lift(semanticLabel:labels[i],onTap:()=>onSelect(i),child:AnimatedContainer(duration:FinMotion.hover,height:40,decoration:BoxDecoration(color:selected==i?FinTheme.slate:Colors.transparent,border:Border(left:BorderSide(width:2,color:selected==i?FinTheme.ivory:Colors.transparent))),child:Row(mainAxisAlignment:expanded?MainAxisAlignment.start:MainAxisAlignment.center,children:[if(expanded)const SizedBox(width:10),BrandGlyph(i,color:selected==i?FinTheme.ink:FinTheme.steel,size:19),if(expanded)...[const SizedBox(width:9),Expanded(child:Text(labels[i],overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:12,color:selected==i?FinTheme.ink:FinTheme.steel)))]])));
}
