import 'package:flutter/material.dart';
import 'package:odyssey/src/shared/widgets/sound_widgets.dart';
import 'package:odyssey/src/utils/sound_helpers.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Exemplo completo de uso do sistema SND de sons UI/UX
/// 
/// Este widget demonstra todos os recursos implementados:
/// - Widgets com sons integrados
/// - Helpers para dialogs/modals
/// - Mixin para facilitar uso
/// - Transições automáticas (NavigatorObserver)
class SoundSystemDemoPage extends StatefulWidget {
  const SoundSystemDemoPage({Key? key}) : super(key: key);

  @override
  State<SoundSystemDemoPage> createState() => _SoundSystemDemoPageState();
}

class _SoundSystemDemoPageState extends State<SoundSystemDemoPage> with SoundMixin {
  bool _isChecked = false;
  bool _isEnabled = false;
  String _selectedOption = 'A';
  double _sliderValue = 0.5;
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SND Sound System Demo'),
        actions: [
          SoundIconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showSoundDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sistema SND'),
                  content: const Text('Sons profissionais inspirados em snd.dev'),
                  actions: [
                    SoundTextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SEÇÃO 1: BUTTONS
          _buildSection(
            title: '🔘 Buttons',
            children: [
              SoundButton(
                onPressed: () => playSuccessSound(),
                child: const Text('Elevated Button'),
              ),
              const SizedBox(height: 8),
              SoundFilledButton(
                onPressed: () => playCelebrationSound(),
                child: const Text('Filled Button'),
              ),
              const SizedBox(height: 8),
              SoundTextButton(
                onPressed: () {},
                child: const Text('Text Button'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoundIconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () {},
                  ),
                  SoundIconButton(
                    icon: const Icon(Icons.star),
                    onPressed: () {},
                  ),
                  SoundIconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),

          // SEÇÃO 2: INPUTS
          _buildSection(
            title: '📝 Text Input (Sons de Digitação)',
            children: [
              const Text(
                '🎹 Digite ou delete para ouvir os sons type_01 a type_05 aleatórios!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              SoundTextField(
                controller: _textController,
                labelText: 'Nome',
                hintText: 'Digite aqui...',
              ),
              const SizedBox(height: 12),
              SoundTextFormField(
                labelText: 'Email',
                hintText: 'exemplo@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                  if (!value!.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const SoundTextField(
                labelText: 'Mensagem',
                hintText: 'Escreva uma mensagem longa...',
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                '✨ Sons diferentes a cada tecla para evitar fadiga auditiva',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          // SEÇÃO 3: TOGGLES & CHECKBOXES
          _buildSection(
            title: '✓ Toggles & Checkboxes',
            children: [
              SoundSwitchListTile(
                value: _isEnabled,
                onChanged: (val) => setState(() => _isEnabled = val),
                title: const Text('Notificações'),
                subtitle: const Text('Som de toggle ON/OFF'),
              ),
              SoundCheckboxListTile(
                value: _isChecked,
                onChanged: (val) => setState(() => _isChecked = val ?? false),
                title: const Text('Aceito os termos'),
                subtitle: const Text('Som de select'),
              ),
            ],
          ),

          // SEÇÃO 4: RADIOS
          _buildSection(
            title: '◉ Radio Buttons',
            children: [
              SoundRadioListTile<String>(
                value: 'A',
                groupValue: _selectedOption,
                onChanged: (val) => setState(() => _selectedOption = val ?? 'A'),
                title: const Text('Opção A'),
              ),
              SoundRadioListTile<String>(
                value: 'B',
                groupValue: _selectedOption,
                onChanged: (val) => setState(() => _selectedOption = val ?? 'B'),
                title: const Text('Opção B'),
              ),
              SoundRadioListTile<String>(
                value: 'C',
                groupValue: _selectedOption,
                onChanged: (val) => setState(() => _selectedOption = val ?? 'C'),
                title: const Text('Opção C'),
              ),
            ],
          ),

          // SEÇÃO 5: SLIDER
          _buildSection(
            title: '🎚️ Slider',
            children: [
              SoundSlider(
                value: _sliderValue,
                onChanged: (val) => setState(() => _sliderValue = val),
                label: 'Volume: ${(_sliderValue * 100).toInt()}%',
              ),
              Text(
                'Som no início e fim do arrasto',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // SEÇÃO 6: CHIPS
          _buildSection(
            title: '🏷️ Chips',
            children: [
              Wrap(
                spacing: 8,
                children: [
                  SoundChoiceChip(
                    label: 'Flutter',
                    selected: true,
                    onSelected: (_) {},
                  ),
                  SoundChoiceChip(
                    label: 'Dart',
                    selected: false,
                    onSelected: (_) {},
                  ),
                  SoundFilterChip(
                    label: 'UI/UX',
                    selected: true,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ],
          ),

          // SEÇÃO 7: CARDS
          _buildSection(
            title: '🃏 Cards Interativos',
            children: [
              SoundCard(
                onTap: () => showSuccessSnackBar(
                  context,
                  message: 'Card clicado!',
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tap neste card'),
                ),
              ),
              const SizedBox(height: 8),
              SoundCard(
                onTap: () => showErrorSnackBar(
                  context,
                  message: 'Ops! Erro simulado',
                ),
                color: Colors.red.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Card de erro'),
                ),
              ),
            ],
          ),

          // SEÇÃO 8: DIALOGS & MODALS
          _buildSection(
            title: '💬 Dialogs & Modals',
            children: [
              SoundButton(
                onPressed: () {
                  showSoundDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Dialog com Som'),
                      content: const Text('Abrir/fechar toca sons de transição'),
                      actions: [
                        SoundTextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Abrir Dialog'),
              ),
              const SizedBox(height: 8),
              SoundButton(
                onPressed: () {
                  showSoundModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Bottom Sheet com Som',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text('Sons de transição hierárquica'),
                          const SizedBox(height: 24),
                          SoundFilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Abrir Bottom Sheet'),
              ),
            ],
          ),

          // SEÇÃO 9: SNACKBARS
          _buildSection(
            title: '📬 SnackBars',
            children: [
              Row(
                children: [
                  Expanded(
                    child: SoundButton(
                      onPressed: () => showSoundSnackBar(
                        context,
                        message: 'Notificação normal',
                      ),
                      child: const Text('Info'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoundButton(
                      onPressed: () => showErrorSnackBar(
                        context,
                        message: 'Erro!',
                      ),
                      child: const Text('Erro'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoundButton(
                      onPressed: () => showSuccessSnackBar(
                        context,
                        message: 'Sucesso!',
                        celebration: true,
                      ),
                      child: const Text('Sucesso'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // SEÇÃO 10: SONS DIRETOS
          _buildSection(
            title: '🎵 Sons Diretos (APIs)',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => soundService.playSndButton(),
                    child: const Text('Button'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndTap(),
                    child: const Text('Tap'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndSelect(),
                    child: const Text('Select'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndSwipe(),
                    child: const Text('Swipe'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndNotification(),
                    child: const Text('Notify'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndCaution(),
                    child: const Text('Caution'),
                  ),
                  ElevatedButton(
                    onPressed: () => soundService.playSndCelebration(),
                    child: const Text('Celebration!'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Sistema SND implementado com sucesso!\nInspirado em snd.dev',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
      floatingActionButton: SoundFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Nova Página')),
                body: const Center(
                  child: Text('Som de swipe automático na navegação!'),
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
