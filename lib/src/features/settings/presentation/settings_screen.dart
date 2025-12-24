import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:odyssey/src/constants/app_themes.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/settings/presentation/backup_screen.dart';
import 'package:odyssey/src/features/settings/presentation/delete_account_screen.dart';
import 'package:odyssey/src/features/settings/services/data_export_service.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import 'package:odyssey/src/features/subscription/subscription_provider.dart';
import 'package:odyssey/src/features/subscription/presentation/pro_screen.dart';
import 'package:odyssey/src/features/home/presentation/widgets_config_screen.dart';
import 'package:odyssey/src/features/settings/presentation/modern_notification_settings_screen.dart';
import 'package:odyssey/src/features/auth/presentation/login_screen.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/sync_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/localization/app_localizations_x.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import 'package:odyssey/src/config/app_flavor.dart';
import 'package:odyssey/src/features/settings/presentation/dev_tools_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Showcase keys
  final GlobalKey _showcaseTheme = GlobalKey();
  final GlobalKey _showcaseNotifications = GlobalKey();
  final GlobalKey _showcaseBackup = GlobalKey();
  final GlobalKey _showcaseTour = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.settings);
    _animationController.dispose();
    super.dispose();
  }

  void _initShowcase() {
    final keys = [
      _showcaseTheme,
      _showcaseNotifications,
      _showcaseBackup,
      _showcaseTour,
    ];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.settings,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(
      showcase.ShowcaseTour.settings,
      keys,
    );
  }

  void _startTour() {
    final keys = [
      _showcaseTheme,
      _showcaseNotifications,
      _showcaseBackup,
      _showcaseTour,
    ];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.settings, keys);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final subscription = ref.watch(subscriptionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background gradient sutil
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header moderno com glassmorphism
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        _buildBackButton(colorScheme),
                        const Spacer(),
                        Text(
                          l10n.settings,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Card animado
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: _buildProfileCard(settings),
                  ),
                ),
              ),

              // PRO Banner (se não for PRO)
              if (!subscription.isProValid)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _buildProBanner(colorScheme),
                    ),
                  ),
                ),

              // Conta Section
              _buildSectionHeader(l10n.isEnglish ? 'Account' : 'Conta'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    // Upgrade de Guest (só aparece para guests)
                    if (ref.watch(currentUserProvider)?.isGuest ?? false) ...[
                      _buildSettingsTile(
                        icon: Icons.upgrade_rounded,
                        iconBgColor: Colors.green,
                        title: l10n.isEnglish
                            ? 'Create Permanent Account'
                            : 'Criar Conta Permanente',
                        value: l10n.isEnglish
                            ? 'Keep your data forever'
                            : 'Mantenha seus dados para sempre',
                        onTap: () => _showAccountUpgradeDialog(),
                      ),
                      _buildDivider(),
                    ],
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      iconBgColor: Colors.orange,
                      title: l10n.isEnglish ? 'Logout' : 'Sair da Conta',
                      value: l10n.isEnglish
                          ? 'Disconnect and go to login'
                          : 'Desconectar e ir para login',
                      onTap: () => _showLogoutDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconBgColor: Colors.red,
                      title: l10n.isEnglish
                          ? 'Delete Account'
                          : 'Excluir Conta',
                      value: l10n.isEnglish
                          ? 'Permanently delete all data'
                          : 'Apagar permanentemente todos os dados',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeleteAccountScreen(),
                        ),
                      ),
                      isDanger: true,
                    ),
                  ]),
                ),
              ),

              // Apoie Section
              _buildSectionHeader(l10n.supportTheApp),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.workspace_premium,
                      iconBgColor: const Color(0xFFFFD700),
                      title: subscription.isProValid
                          ? l10n.proActive
                          : l10n.goPro,
                      value: subscription.isProValid
                          ? (subscription.isLifetime
                                ? l10n.lifetimeLabel
                                : l10n.subscriptionLabel)
                          : l10n.removeAds,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProScreen()),
                      ),
                    ),
                  ]),
                ),
              ),

              // Aparência Section
              _buildSectionHeader(l10n.appearance),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.palette_outlined,
                      iconBgColor: Theme.of(context).colorScheme.primary,
                      title: l10n.theme,
                      value: AppThemes.getThemeData(
                        settings.selectedTheme,
                      ).name,
                      onTap: () => _showThemeSelector(settings.selectedTheme),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.widgets_outlined,
                      iconBgColor: const Color(0xFF9C27B0),
                      title: l10n.widgetsDaHome,
                      value: l10n.customize,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WidgetsConfigScreen(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      iconBgColor: const Color(0xFF2196F3),
                      title: l10n.language,
                      value:
                          ref
                                  .watch(localeStateProvider)
                                  .currentLocale
                                  .languageCode ==
                              'pt'
                          ? 'Português (BR)'
                          : 'English (US)',
                      onTap: () => _showLanguageSelector(),
                    ),
                  ]),
                ),
              ),

              // Som & Notificações Section
              _buildSectionHeader(
                l10n.isEnglish ? 'Sound & Notifications' : 'Som & Notificações',
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.volume_up_outlined,
                      iconBgColor: Colors.orange,
                      title: l10n.sounds,
                      subtitle: l10n.isEnglish
                          ? 'Sound feedback'
                          : 'Feedback sonoro',
                      value: settings.soundEnabled,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setSoundEnabled(v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.notifications_outlined,
                      iconBgColor: Colors.purple,
                      title: l10n.notifications,
                      subtitle: l10n.isEnglish
                          ? 'Habit reminders'
                          : 'Lembretes de hábitos',
                      value: settings.notificationsEnabled,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setNotificationsEnabled(v),
                    ),
                    if (settings.notificationsEnabled) ...[
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.tune,
                        iconBgColor: Colors.deepPurple,
                        title: l10n.isEnglish
                            ? 'Notification Settings'
                            : 'Configurar Notificações',
                        value: l10n.notificationTypesTimesFrequency,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ModernNotificationSettingsScreen(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.access_time_outlined,
                        iconBgColor: Colors.teal,
                        title: l10n.isEnglish ? 'Times' : 'Horários',
                        value: _formatReminderTimes(settings.reminderTimes),
                        onTap: () =>
                            _showReminderTimesEditor(settings.reminderTimes),
                      ),
                    ],
                  ]),
                ),
              ),

              // Dados Section
              _buildSectionHeader(l10n.isEnglish ? 'Data' : 'Dados'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    // Cloud Sync
                    _buildSyncTile(),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.cloud_outlined,
                      iconBgColor: Colors.cyan,
                      title: l10n.backup,
                      value: 'Google Drive, JSON',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BackupScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_outline,
                      iconBgColor: Colors.red,
                      title: l10n.isEnglish ? 'Clear Data' : 'Limpar Dados',
                      value: l10n.isEnglish ? 'Erase all' : 'Apagar tudo',
                      onTap: () => _showClearDataDialog(),
                      isDanger: true,
                    ),
                  ]),
                ),
              ),

              // Privacidade & LGPD Section
              _buildSectionHeader(
                l10n.isEnglish ? 'Privacy & LGPD' : 'Privacidade & LGPD',
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.download_rounded,
                      iconBgColor: Colors.blue,
                      title: l10n.isEnglish
                          ? 'Export My Data'
                          : 'Exportar Meus Dados',
                      value: l10n.isEnglish
                          ? 'Download all data as JSON'
                          : 'Baixar tudo em JSON',
                      onTap: () => _exportUserData(),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconBgColor: Colors.teal,
                      title: l10n.isEnglish
                          ? 'Privacy Policy'
                          : 'Política de Privacidade',
                      value: l10n.isEnglish
                          ? 'How we protect your data'
                          : 'Como protegemos seus dados',
                      onTap: () => _showPrivacyInfo(),
                    ),
                  ]),
                ),
              ),

              // Sobre Section
              _buildSectionHeader(l10n.about),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.explore_outlined,
                      iconBgColor: const Color(0xFF6366F1),
                      title: l10n.isEnglish
                          ? 'Tutorials & Tips'
                          : 'Tutoriais e Dicas',
                      value: l10n.isEnglish
                          ? 'Discover features'
                          : 'Descubra funcionalidades',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _OnboardingSettingsProxy(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      iconBgColor: Theme.of(context).colorScheme.primary,
                      title: l10n.isEnglish ? 'About the App' : 'Sobre o App',
                      value: '${l10n.version} 1.0.0',
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.star_outline,
                      iconBgColor: Colors.amber,
                      title: l10n.rateApp,
                      value: l10n.isEnglish
                          ? 'Leave your opinion'
                          : 'Deixe sua opinião',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      iconBgColor: Colors.indigo,
                      title: l10n.isEnglish ? 'Help' : 'Ajuda',
                      value: l10n.isEnglish
                          ? 'FAQ and support'
                          : 'FAQ e suporte',
                      onTap: () {},
                    ),
                  ]),
                ),
              ),

              // Dev Tools Section (apenas em Dev flavor)
              if (FlavorConfig.isDev) ...[
                _buildSectionHeader('🛠️ Ferramentas de Dev'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.developer_mode,
                        iconBgColor: Colors.orange,
                        title: 'Dev Tools',
                        value: 'Debug, cache, seed data',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DevToolsScreen(),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile() {
    final syncState = ref.watch(syncControllerProvider);
    final isSyncAvailable = ref.watch(isSyncAvailableProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Se sync não está disponível (usuário guest ou não logado)
    if (!isSyncAvailable) {
      return _buildSettingsTile(
        icon: Icons.cloud_off_outlined,
        iconBgColor: Colors.grey,
        title: l10n.isEnglish ? 'Cloud Sync' : 'Sincronização',
        value: l10n.isEnglish ? 'Login required' : 'Requer login',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.isEnglish
                    ? 'Login with your account to sync your data to the cloud'
                    : 'Faça login com sua conta para sincronizar seus dados na nuvem',
              ),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ),
          );
        },
      );
    }

    // Sync disponível
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: syncState.isSyncing
            ? null
            : () => ref.read(syncControllerProvider.notifier).syncAll(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: syncState.isSyncing
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      )
                    : Icon(
                        syncState.errorMessage != null
                            ? Icons.cloud_off
                            : Icons.cloud_sync,
                        color: syncState.errorMessage != null
                            ? Colors.red
                            : Colors.green,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.isEnglish ? 'Cloud Sync' : 'Sincronização',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (syncState.isSyncing &&
                        syncState.currentOperation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        syncState.currentOperation!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                    ] else if (syncState.errorMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.isEnglish ? 'Sync error' : 'Erro na sincronização',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!syncState.isSyncing) ...[
                Text(
                  syncState.lastSyncTime != null
                      ? _formatSyncTime(syncState.lastSyncTime!)
                      : (l10n.isEnglish ? 'Never' : 'Nunca'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return l10n.isEnglish ? 'Just now' : 'Agora';
    } else if (diff.inMinutes < 60) {
      return l10n.isEnglish
          ? '${diff.inMinutes}min ago'
          : 'Há ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return l10n.isEnglish ? '${diff.inHours}h ago' : 'Há ${diff.inHours}h';
    } else {
      return l10n.isEnglish ? '${diff.inDays}d ago' : 'Há ${diff.inDays}d';
    }
  }

  Widget _buildBackButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppSettings settings) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showProfileEditor(settings);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.15),
              colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar com anel de gradiente
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  image: settings.avatarPath != null
                      ? DecorationImage(
                          image: FileImage(File(settings.avatarPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: settings.avatarPath == null
                    ? Icon(
                        Icons.person_rounded,
                        color: colorScheme.primary,
                        size: 30,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.editarPerfil,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    indent: 60,
    endIndent: 16,
    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
  );

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconBgColor.withValues(alpha: 0.2),
                      iconBgColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconBgColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDanger ? Colors.red : colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconBgColor.withValues(alpha: 0.2),
                  iconBgColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBgColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              activeThumbColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReminderTimes(List<TimeOfDay> times) {
    final l10n = AppLocalizations.of(context)!;
    if (times.isEmpty) return l10n.noReminders;
    if (times.length == 1) {
      return '${times[0].hour.toString().padLeft(2, '0')}:${times[0].minute.toString().padLeft(2, '0')}';
    }
    return l10n.multipleReminders(times.length);
  }

  void _showThemeSelector(AppThemeType currentTheme) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.escolherTema,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.personalizeAAparenciaDoApp,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Seção Temas Escuros
                    _buildThemeSectionTitle('Temas Escuros'),
                    const SizedBox(height: 12),
                    _buildThemeGrid(AppThemes.darkThemes, currentTheme),

                    const SizedBox(height: 24),

                    // Seção Temas Claros
                    _buildThemeSectionTitle('Temas Claros'),
                    const SizedBox(height: 12),
                    _buildThemeGrid(AppThemes.lightThemes, currentTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeGrid(List<AppThemeType> themes, AppThemeType currentTheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeType = themes[index];
        final themeData = AppThemes.getThemeData(themeType);
        final isSelected = currentTheme == themeType;

        return _buildThemeCard(themeType, themeData, isSelected);
      },
    );
  }

  Widget _buildThemeCard(
    AppThemeType themeType,
    AppThemeData themeData,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(settingsProvider.notifier).setSelectedTheme(themeType);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview das cores
              Row(
                children: [
                  ...themeData.previewColors.map(
                    (color) => Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Nome e ícone
              Row(
                children: [
                  Icon(
                    themeData.icon,
                    size: 16,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      themeData.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                themeData.description,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(localeStateProvider);
          final locale = state.currentLocale;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.isEnglish ? 'Choose Language' : 'Escolher Idioma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                // Follow system option
                _buildLanguageOption(
                  l10n.followSystemLanguage,
                  null,
                  state.followSystem,
                  ref,
                  icon: Icons.phone_android,
                ),
                const Divider(),
                _buildLanguageOption(
                  'Português (BR)',
                  const Locale('pt', 'BR'),
                  !state.followSystem && locale.languageCode == 'pt',
                  ref,
                ),
                _buildLanguageOption(
                  'English (US)',
                  const Locale('en', 'US'),
                  !state.followSystem && locale.languageCode == 'en',
                  ref,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    Locale? locale,
    bool isSelected,
    WidgetRef ref, {
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        if (locale == null) {
          // Follow system
          ref.read(localeStateProvider.notifier).setFollowSystem(true);
        } else {
          ref.read(localeStateProvider.notifier).setLocale(locale);
        }
        Navigator.pop(context);
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.blue
                      : colorScheme.onSurfaceVariant,
                )
              : _buildFlagIcon(locale?.languageCode == 'pt'),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
    );
  }

  void _showProfileEditor(AppSettings settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController(text: settings.userName);
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.editarPerfil1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showAvatarOptions(),
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: settings.avatarPath == null
                          ? LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      image: settings.avatarPath != null
                          ? DecorationImage(
                              image: FileImage(File(settings.avatarPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: settings.avatarPath == null
                        ? Icon(
                            Icons.person,
                            color: colorScheme.onPrimary,
                            size: 40,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    ref
                        .read(settingsProvider.notifier)
                        .setUserName(nameController.text);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    final settings = ref.read(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: _buildOptionIcon(Icons.photo_library, Colors.blue),
              title: Text(
                AppLocalizations.of(context)!.galeria,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(settingsProvider.notifier)
                    .setAvatarFromGallery();
              },
            ),
            ListTile(
              leading: _buildOptionIcon(Icons.camera_alt, Colors.green),
              title: Text(
                AppLocalizations.of(context)!.camera,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(settingsProvider.notifier).setAvatarFromCamera();
              },
            ),
            if (settings.avatarPath != null)
              ListTile(
                leading: _buildOptionIcon(Icons.delete, Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.remove,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(settingsProvider.notifier).removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionIcon(IconData icon, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  Widget _buildProBanner(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D2D3A), Color(0xFF1E1E28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone com glow
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.black87,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFE066),
                        Color(0xFFFFD700),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      l10n.isEnglish ? 'Go PRO' : 'Seja PRO',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.isEnglish
                        ? 'Remove ads and unlock features'
                        : 'Remova anúncios e desbloqueie recursos',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.isEnglish ? 'VIEW' : 'VER',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderTimesEditor(List<TimeOfDay> currentTimes) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final settings = ref.watch(settingsProvider);
          final times = settings.reminderTimes;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.horarios,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (times.length < 5)
                      IconButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            await ref
                                .read(settingsProvider.notifier)
                                .addReminderTime(time);
                          }
                        },
                        icon: Icon(
                          Icons.add_circle,
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...times.asMap().entries.map((entry) {
                  final index = entry.key;
                  final time = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            final newTime = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (newTime != null) {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateReminderTime(index, newTime);
                            }
                          },
                          icon: Icon(
                            Icons.edit,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (times.length > 1)
                          IconButton(
                            onPressed: () async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .removeReminderTime(index);
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearDataDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.limparDados,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(
            context,
          )!.estaAcaoIraApagarTodosOsSeusRegistrosPer,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.dadosLimposComSucesso,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.limpar),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Odyssey',
        applicationVersion: '1.0.0',
        applicationIcon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: colorScheme.onPrimary,
            size: 32,
          ),
        ),
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.seuCompanheiroDeProdutividadeEBemestarPe,
          ),
        ],
      ),
    );
  }

  void _showAccountUpgradeDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upgrade_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              l10n.isEnglish
                  ? 'Create Permanent Account'
                  : 'Criar Conta Permanente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              l10n.isEnglish
                  ? 'Choose how you want to create your permanent account. Your data will be synced to the cloud and preserved.'
                  : 'Escolha como deseja criar sua conta permanente. Seus dados serão sincronizados na nuvem e preservados.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Email button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Reutilizar o mesmo dialog do ProfileScreen
                  _showEmailUpgradeDialog(colorScheme);
                },
                icon: const Icon(Icons.email_outlined),
                label: Text(
                  l10n.isEnglish
                      ? 'Create with Email/Password'
                      : 'Criar com Email/Senha',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Google button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  _handleGoogleUpgrade();
                },
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: Text(
                  l10n.isEnglish
                      ? 'Link Google Account'
                      : 'Vincular Conta Google',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.isEnglish ? 'Cancel' : 'Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailUpgradeDialog(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  '🔐 ${l10n.isEnglish ? 'Create Permanent Account' : 'Criar Conta Permanente'}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.isEnglish
                      ? 'Your data will be preserved and synced to the cloud.'
                      : 'Seus dados serão preservados e sincronizados na nuvem.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.isEnglish ? 'Password' : 'Senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setModalState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: l10n.isEnglish
                        ? 'Confirm Password'
                        : 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setModalState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Create button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      final confirm = confirmPasswordController.text;

                      if (email.isEmpty ||
                          password.isEmpty ||
                          confirm.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.isEnglish
                                  ? 'Fill all fields'
                                  : 'Preencha todos os campos',
                            ),
                          ),
                        );
                        return;
                      }

                      if (password != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.isEnglish
                                  ? 'Passwords do not match'
                                  : 'Senhas não conferem',
                            ),
                          ),
                        );
                        return;
                      }

                      if (password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.isEnglish
                                  ? 'Password must be at least 6 characters'
                                  : 'Senha deve ter no mínimo 6 caracteres',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      final result = await ref
                          .read(authControllerProvider.notifier)
                          .upgradeGuestAccount(email, password);

                      if (mounted) {
                        if (result.isSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message ??
                                    (l10n.isEnglish
                                        ? 'Account created successfully!'
                                        : 'Conta criada com sucesso!'),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message ??
                                    (l10n.isEnglish
                                        ? 'Error creating account'
                                        : 'Erro ao criar conta'),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: Text(
                      l10n.isEnglish ? 'Create Account' : 'Criar Conta',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleUpgrade() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(authControllerProvider.notifier)
        .upgradeGuestWithGoogle();

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  (l10n.isEnglish
                      ? 'Account linked successfully!'
                      : 'Conta vinculada com sucesso!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  (l10n.isEnglish
                      ? 'Error linking Google account'
                      : 'Erro ao vincular conta Google'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.isEnglish ? 'Logout' : 'Sair da Conta',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.isEnglish
              ? 'Are you sure you want to logout? You will need to login again to access your data.'
              : 'Tem certeza que deseja sair? Você precisará fazer login novamente para acessar seus dados.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.isEnglish ? 'Logout' : 'Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Limpar SharedPreferences de login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('isGuest');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userPhoto');

      // Fazer logout do Google se estiver logado
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {
        // Ignora erro do Google Sign In
      }

      // Limpar provider de auth usando o AuthController
      await ref.read(authControllerProvider.notifier).signOut();

      // Navegar para tela de login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.signOutError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportUserData() async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.isEnglish ? 'Exporting data...' : 'Exportando dados...',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final file = await DataExportService.exportAllUserData();

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      // Perguntar se quer compartilhar
      final share = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(l10n.isEnglish ? 'Export Complete' : 'Exportação Completa'),
            ],
          ),
          content: Text(
            l10n.isEnglish
                ? 'Your data has been exported.\n\nWould you like to share the file?'
                : 'Seus dados foram exportados.\n\nDeseja compartilhar o arquivo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.isEnglish ? 'No' : 'Não'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.share),
              label: Text(l10n.isEnglish ? 'Share' : 'Compartilhar'),
            ),
          ],
        ),
      );

      if (share == true) {
        await DataExportService.shareExport(file);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.isEnglish
                ? 'Error exporting data: $e'
                : 'Erro ao exportar dados: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPrivacyInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.isEnglish ? 'Your Privacy' : 'Sua Privacidade',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'LGPD & GDPR',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPrivacyItem(
                      Icons.lock,
                      Colors.blue,
                      l10n.isEnglish
                          ? 'Encrypted Data'
                          : 'Dados Criptografados',
                      l10n.isEnglish
                          ? 'All your sensitive data (mood, diary, notes) is encrypted with AES-256 on your device.'
                          : 'Todos os seus dados sensíveis (humor, diário, notas) são criptografados com AES-256 no seu dispositivo.',
                    ),
                    _buildPrivacyItem(
                      Icons.cloud_off,
                      Colors.orange,
                      l10n.isEnglish ? 'Local First' : 'Local Primeiro',
                      l10n.isEnglish
                          ? 'Your data is stored primarily on your device. Cloud sync is optional.'
                          : 'Seus dados são armazenados primariamente no seu dispositivo. Sincronização na nuvem é opcional.',
                    ),
                    _buildPrivacyItem(
                      Icons.visibility_off,
                      Colors.purple,
                      l10n.isEnglish ? 'No Tracking' : 'Sem Rastreamento',
                      l10n.isEnglish
                          ? 'We do not sell, share, or access your personal data. Your privacy is our priority.'
                          : 'Não vendemos, compartilhamos ou acessamos seus dados pessoais. Sua privacidade é nossa prioridade.',
                    ),
                    _buildPrivacyItem(
                      Icons.download,
                      Colors.green,
                      l10n.isEnglish ? 'Data Portability' : 'Portabilidade',
                      l10n.isEnglish
                          ? 'You can export all your data at any time in JSON format.'
                          : 'Você pode exportar todos os seus dados a qualquer momento em formato JSON.',
                    ),
                    _buildPrivacyItem(
                      Icons.delete,
                      Colors.red,
                      l10n.isEnglish
                          ? 'Right to Deletion'
                          : 'Direito ao Esquecimento',
                      l10n.isEnglish
                          ? 'You can permanently delete your account and all associated data.'
                          : 'Você pode excluir permanentemente sua conta e todos os dados associados.',
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isEnglish
                                ? 'Your Rights (LGPD Art. 18)'
                                : 'Seus Direitos (LGPD Art. 18)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.isEnglish
                                ? '• Access your data\n• Export your data\n• Correct inaccurate data\n• Delete your data\n• Revoke consent'
                                : '• Acessar seus dados\n• Exportar seus dados\n• Corrigir dados incorretos\n• Excluir seus dados\n• Revogar consentimento',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
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

  Widget _buildFlagIcon(bool isPT) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: isPT ? _buildBRFlag() : _buildUSFlag(),
    );
  }

  Widget _buildBRFlag() {
    return Stack(
      children: [
        Container(color: const Color(0xFF009739)),
        Center(
          child: Transform.rotate(
            angle: 45 * 3.14159 / 180,
            child: Container(
              width: 15,
              height: 15,
              color: const Color(0xFFFEDD00),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF012169),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUSFlag() {
    return Stack(
      children: [
        Container(color: Colors.white),
        Column(
          children: List.generate(7, (index) {
            return Expanded(
              child: Container(
                color: index % 2 == 0 ? const Color(0xFFB22234) : Colors.white,
              ),
            );
          }),
        ),
        Container(
          width: 11,
          height: 11,
          color: const Color(0xFF3C3B6E),
          child: const Center(
            child: Icon(Icons.star, color: Colors.white, size: 7),
          ),
        ),
      ],
    );
  }
}

/// Proxy widget para navegar para OnboardingSettingsScreen
/// Necessário para evitar referência circular de imports
class _OnboardingSettingsProxy extends StatelessWidget {
  const _OnboardingSettingsProxy();

  @override
  Widget build(BuildContext context) {
    return const OnboardingSettingsScreen();
  }
}
