import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela de consentimento para coleta de dados de saúde mental
/// Conforme LGPD Art. 11 - Dados sensíveis requerem consentimento explícito
class HealthDataConsentScreen extends ConsumerStatefulWidget {
  const HealthDataConsentScreen({super.key});
  
  /// Verificar se o consentimento já foi dado
  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('health_data_consent_given') ?? false;
  }
  
  /// Obter data do consentimento
  static Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('health_data_consent_date');
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
  
  /// Revogar consentimento
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_data_consent_given', false);
    await prefs.remove('health_data_consent_date');
  }
  
  @override
  ConsumerState<HealthDataConsentScreen> createState() => _HealthDataConsentScreenState();
}

class _HealthDataConsentScreenState extends ConsumerState<HealthDataConsentScreen> {
  bool _consent = false;
  bool _loading = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Seus Dados de Saúde'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ícone principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              'O Odyssey coleta dados sensíveis de saúde mental',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Descrição
            Text(
              'Ao usar as funcionalidades de registro de humor e diário, '
              'você estará compartilhando informações sobre seu estado '
              'emocional e bem-estar mental. Esses dados são considerados '
              'sensíveis pela LGPD (Lei Geral de Proteção de Dados) e GDPR.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // Cards de features
            _buildFeatureCard(
              context,
              icon: Icons.phone_android,
              title: 'Armazenamento Local Criptografado',
              description: 'Seus dados são armazenados com criptografia AES-256 '
                          'no seu dispositivo. Ninguém além de você pode acessá-los.',
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              context,
              icon: Icons.cloud_off,
              title: 'Sincronização Opcional',
              description: 'Você escolhe se quer sincronizar na nuvem. '
                          'Por padrão, todos os dados ficam apenas no seu aparelho.',
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              context,
              icon: Icons.visibility_off,
              title: 'Privacidade Total',
              description: 'Não vendemos, não compartilhamos e não '
                          'acessamos seus dados pessoais. Sua privacidade é prioridade.',
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              context,
              icon: Icons.download,
              title: 'Seus Dados, Seu Controle',
              description: 'Você pode exportar todos os seus dados a qualquer momento '
                          'e solicitar exclusão completa da conta.',
              iconColor: Colors.purple,
            ),
            const SizedBox(height: 32),
            
            // Checkbox de consentimento
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _consent 
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CheckboxListTile(
                value: _consent,
                onChanged: (value) => setState(() => _consent = value ?? false),
                title: Text(
                  'Eu entendo e consinto explicitamente com a coleta '
                  'e processamento dos meus dados sensíveis de saúde mental, '
                  'conforme a Política de Privacidade.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Botão de aceitar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _consent && !_loading ? _saveConsent : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Aceitar e Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Link para política de privacidade
            TextButton.icon(
              onPressed: _showPrivacyPolicy,
              icon: Icon(Icons.article_outlined, color: colorScheme.primary),
              label: Text(
                'Ler Política de Privacidade Completa',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Aviso legal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você pode revogar este consentimento a qualquer momento nas configurações do app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveConsent() async {
    setState(() => _loading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_data_consent_given', true);
      await prefs.setString(
        'health_data_consent_date',
        DateTime.now().toIso8601String(),
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar consentimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  void _showPrivacyPolicy() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Política de Privacidade',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Última atualização: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPolicySection(
                      '1. Dados Coletados',
                      'O Odyssey coleta os seguintes dados sensíveis:\n'
                      '• Registros de humor e bem-estar\n'
                      '• Entradas de diário pessoal\n'
                      '• Notas e anotações privadas\n'
                      '• Tarefas e hábitos\n\n'
                      'Estes dados são classificados como dados sensíveis de saúde '
                      'mental conforme a LGPD (Lei 13.709/2018).',
                    ),
                    _buildPolicySection(
                      '2. Base Legal',
                      'O tratamento dos seus dados é realizado com base no seu '
                      'consentimento explícito, conforme Art. 11 da LGPD. Você pode '
                      'revogar este consentimento a qualquer momento.',
                    ),
                    _buildPolicySection(
                      '3. Armazenamento',
                      'Seus dados são armazenados localmente no seu dispositivo com '
                      'criptografia AES-256. A sincronização na nuvem é opcional e '
                      'utiliza os serviços do Firebase (Google) com criptografia em trânsito.',
                    ),
                    _buildPolicySection(
                      '4. Seus Direitos',
                      'Você tem direito a:\n'
                      '• Acessar seus dados a qualquer momento\n'
                      '• Exportar todos os seus dados (portabilidade)\n'
                      '• Solicitar correção de dados incorretos\n'
                      '• Solicitar exclusão completa dos dados\n'
                      '• Revogar o consentimento',
                    ),
                    _buildPolicySection(
                      '5. Compartilhamento',
                      'Seus dados NÃO são compartilhados com terceiros, vendidos '
                      'ou utilizados para publicidade. Não temos acesso aos seus '
                      'dados criptografados.',
                    ),
                    _buildPolicySection(
                      '6. Segurança',
                      'Implementamos medidas técnicas de segurança incluindo:\n'
                      '• Criptografia AES-256 para dados locais\n'
                      '• Chaves armazenadas no Keychain/Keystore\n'
                      '• Backups criptografados com senha\n'
                      '• HTTPS para comunicação',
                    ),
                    _buildPolicySection(
                      '7. Contato',
                      'Para exercer seus direitos ou tirar dúvidas sobre '
                      'privacidade, entre em contato pelo email:\n'
                      'privacidade@odyssey.app',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPolicySection(String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
