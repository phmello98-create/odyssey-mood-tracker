import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status das permissões de notificação
enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  needsBatteryWhitelist,
}

/// Tipos de OEM com otimização agressiva de bateria
enum DeviceOEM {
  xiaomi,
  huawei,
  samsung,
  oppo,
  vivo,
  oneplus,
  realme,
  other,
}

/// Helper para gerenciamento de permissões de notificação
class PermissionHelper {
  static final PermissionHelper _instance = PermissionHelper._();
  static PermissionHelper get instance => _instance;
  PermissionHelper._();

  static const String _keyPermissionShown = 'notification_permission_shown';
  static const String _keyBatteryDialogShown = 'battery_dialog_shown';

  /// Verifica status atual das permissões
  Future<NotificationPermissionStatus> checkPermissionsStatus() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    
    if (!isAllowed) {
      // Verifica se foi negado permanentemente
      // No Android 13+, após negar 2x, é permanente
      final prefs = await SharedPreferences.getInstance();
      final wasShownBefore = prefs.getBool(_keyPermissionShown) ?? false;
      
      if (wasShownBefore) {
        return NotificationPermissionStatus.permanentlyDenied;
      }
      return NotificationPermissionStatus.denied;
    }

    // Em Android, verificar se precisa whitelist de bateria
    if (Platform.isAndroid) {
      final oem = getDeviceOEM();
      if (oem != DeviceOEM.other) {
        final prefs = await SharedPreferences.getInstance();
        final batteryDialogShown = prefs.getBool(_keyBatteryDialogShown) ?? false;
        if (!batteryDialogShown) {
          return NotificationPermissionStatus.needsBatteryWhitelist;
        }
      }
    }

    return NotificationPermissionStatus.granted;
  }

  /// Detecta o OEM do dispositivo
  DeviceOEM getDeviceOEM() {
    if (!Platform.isAndroid) return DeviceOEM.other;

    final manufacturer = _getManufacturer().toLowerCase();
    
    if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi') || manufacturer.contains('poco')) {
      return DeviceOEM.xiaomi;
    } else if (manufacturer.contains('huawei') || manufacturer.contains('honor')) {
      return DeviceOEM.huawei;
    } else if (manufacturer.contains('samsung')) {
      return DeviceOEM.samsung;
    } else if (manufacturer.contains('oppo')) {
      return DeviceOEM.oppo;
    } else if (manufacturer.contains('vivo')) {
      return DeviceOEM.vivo;
    } else if (manufacturer.contains('oneplus')) {
      return DeviceOEM.oneplus;
    } else if (manufacturer.contains('realme')) {
      return DeviceOEM.realme;
    }
    
    return DeviceOEM.other;
  }

  String _getManufacturer() {
    // Em produção, usar device_info_plus package
    // Por agora, retornamos string vazia
    return '';
  }

  /// Retorna instruções de whitelist específicas por OEM
  BatteryWhitelistInstructions getWhitelistInstructions(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.xiaomi:
        return BatteryWhitelistInstructions(
          title: 'Configurar Xiaomi/MIUI',
          steps: [
            'Abra Configurações',
            'Vá em Aplicativos → Gerenciar aplicativos',
            'Encontre Odyssey',
            'Toque em "Economia de bateria"',
            'Selecione "Sem restrições"',
            'Ative "Inicialização automática"',
          ],
          actionPath: 'miui.permission.AUTO_START',
        );
      case DeviceOEM.huawei:
        return BatteryWhitelistInstructions(
          title: 'Configurar Huawei/EMUI',
          steps: [
            'Abra Configurações',
            'Vá em Bateria → Inicialização de aplicativos',
            'Encontre Odyssey',
            'Desative "Gerenciar automaticamente"',
            'Ative todas as opções: Inicialização automática, Executar em segundo plano, Executar após fechado',
          ],
          actionPath: 'huawei.intent.action.HSM_BOOTAPP_MANAGER',
        );
      case DeviceOEM.samsung:
        return BatteryWhitelistInstructions(
          title: 'Configurar Samsung',
          steps: [
            'Abra Configurações',
            'Vá em Aplicativos → Odyssey',
            'Toque em Bateria',
            'Selecione "Sem restrições"',
            'Remova o app de "Apps em suspensão"',
          ],
          actionPath: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        );
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return BatteryWhitelistInstructions(
          title: 'Configurar OPPO/Realme',
          steps: [
            'Abra Configurações',
            'Vá em Bateria → Economia de energia',
            'Encontre Odyssey e desative otimização',
            'Em "Gerenciador de inicialização", permita Odyssey',
          ],
          actionPath: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        );
      case DeviceOEM.vivo:
        return BatteryWhitelistInstructions(
          title: 'Configurar Vivo',
          steps: [
            'Abra Configurações',
            'Vá em Bateria → Consumo de energia em segundo plano alto',
            'Permita Odyssey',
            'Em Gerenciador de inicialização automática, permita Odyssey',
          ],
          actionPath: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        );
      case DeviceOEM.oneplus:
        return BatteryWhitelistInstructions(
          title: 'Configurar OnePlus',
          steps: [
            'Abra Configurações',
            'Vá em Bateria → Otimização de bateria',
            'Encontre Odyssey',
            'Selecione "Não otimizar"',
          ],
          actionPath: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      case DeviceOEM.other:
        return BatteryWhitelistInstructions(
          title: 'Configurar Economia de Bateria',
          steps: [
            'Abra Configurações',
            'Vá em Bateria ou Apps',
            'Encontre Odyssey',
            'Desative otimização de bateria',
          ],
          actionPath: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
    }
  }

  /// Marca que o diálogo de permissão foi mostrado
  Future<void> markPermissionDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionShown, true);
  }

  /// Marca que o diálogo de bateria foi mostrado
  Future<void> markBatteryDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBatteryDialogShown, true);
  }

  /// Verifica se deve mostrar o rationale dialog
  Future<bool> shouldShowRationaleDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyPermissionShown) ?? false);
  }

  /// Verifica se deve mostrar o diálogo de bateria
  Future<bool> shouldShowBatteryDialog() async {
    if (!Platform.isAndroid) return false;
    
    final oem = getDeviceOEM();
    if (oem == DeviceOEM.other) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyBatteryDialogShown) ?? false);
  }

  /// Solicita permissão de notificação
  Future<bool> requestNotificationPermission() async {
    await markPermissionDialogShown();
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}

/// Instruções de whitelist para cada OEM
class BatteryWhitelistInstructions {
  final String title;
  final List<String> steps;
  final String actionPath;

  BatteryWhitelistInstructions({
    required this.title,
    required this.steps,
    required this.actionPath,
  });
}
