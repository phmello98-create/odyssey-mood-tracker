
// test_showcases.dart - Script para testar ShowcaseView
// Execute: flutter run -t lib/test_showcases.dart

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

void main() => runApp(const ShowcaseTestApp());

class ShowcaseTestApp extends StatelessWidget {
  const ShowcaseTestApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Showcase Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF07E092)),
        useMaterial3: true,
      ),
      home: const ShowcaseTestScreen(),
    );
  }
}

class ShowcaseTestScreen extends StatefulWidget {
  const ShowcaseTestScreen({super.key});
  
  @override
  State<ShowcaseTestScreen> createState() => _ShowcaseTestScreenState();
}

class _ShowcaseTestScreenState extends State<ShowcaseTestScreen> {
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();
  final GlobalKey _key3 = GlobalKey();
  final GlobalKey _key4 = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      globalFloatingActionWidget: (ctx) => FloatingActionWidget(
        left: 16,
        bottom: 16,
        child: ElevatedButton(
          onPressed: () => ShowcaseView.get().dismiss(),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07E092)),
          child: const Text('Pular', style: TextStyle(color: Colors.white)),
        ),
      ),
      blurValue: 1,
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
      ),
      globalTooltipActions: const [
        TooltipActionButton(type: TooltipDefaultActionType.previous, name: 'Anterior'),
        TooltipActionButton(type: TooltipDefaultActionType.next, name: 'Próximo'),
      ],
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowcaseView.get().startShowCase([_key1, _key2, _key3, _key4]);
    });
  }
  
  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste ShowcaseView'),
        actions: [
          Showcase(
            key: _key1,
            title: 'Configurações',
            description: 'Acesse as configurações do app',
            child: IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Showcase(
              key: _key2,
              title: 'Card de Destaque',
              description: 'Este é um card importante com informações',
              targetBorderRadius: BorderRadius.circular(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.star, size: 48, color: Colors.amber),
                      const SizedBox(height: 12),
                      Text('Destaque', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Showcase(
              key: _key3,
              title: 'Lista de Itens',
              description: 'Aqui você vê todos os seus itens',
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Meus Itens'),
                  subtitle: const Text('3 itens'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Showcase(
        key: _key4,
        title: 'Adicionar',
        description: 'Toque para adicionar um novo item',
        targetBorderRadius: BorderRadius.circular(16),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Reinicia o tour
            ShowcaseView.get().startShowCase([_key1, _key2, _key3, _key4]);
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ),
    );
  }
}
