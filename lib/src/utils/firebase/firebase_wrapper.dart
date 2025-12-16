import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:firebase_analytics/firebase_analytics.dart' as firebase_analytics;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_remote_config/firebase_remote_config.dart' as firebase_remote_config;
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:flutter/foundation.dart';

/// Wrapper seguro para serviços do Firebase que lida com plataformas não suportadas
class FirebaseWrapper {
  // Flags para verificar se os serviços estão disponíveis
  static bool _isFirebaseInitialized = false;
  static bool _isAuthAvailable = false;
  static bool _isFirestoreAvailable = false;
  static bool _isMessagingAvailable = false;
  static bool _isAnalyticsAvailable = false;
  static bool _isStorageAvailable = false;
  static bool _isRemoteConfigAvailable = false;

  // Instâncias reais (pode ser nulo em plataformas não suportadas)
  static firebase_auth.FirebaseAuth? _auth;
  static cloud_firestore.FirebaseFirestore? _firestore;
  static firebase_messaging.FirebaseMessaging? _messaging;
  static firebase_analytics.FirebaseAnalytics? _analytics;
  static firebase_storage.FirebaseStorage? _storage;
  static firebase_remote_config.FirebaseRemoteConfig? _remoteConfig;

  /// Verifica se o Firebase está disponível na plataforma atual
  static bool get isAvailable => _isFirebaseInitialized;

  /// Verifica se o Firebase Auth está disponível
  static bool get isAuthAvailable => _isAuthAvailable;

  /// Verifica se o Firestore está disponível
  static bool get isFirestoreAvailable => _isFirestoreAvailable;

  /// Verifica se o Firebase Messaging está disponível
  static bool get isMessagingAvailable => _isMessagingAvailable;

  /// Verifica se o Firebase Analytics está disponível
  static bool get isAnalyticsAvailable => _isAnalyticsAvailable;

  /// Verifica se o Firebase Storage está disponível
  static bool get isStorageAvailable => _isStorageAvailable;

  /// Verifica se o Firebase Remote Config está disponível
  static bool get isRemoteConfigAvailable => _isRemoteConfigAvailable;

  /// Inicializa o wrapper com as instâncias de Firebase
  static Future<void> initialize({
    firebase_auth.FirebaseAuth? auth,
    cloud_firestore.FirebaseFirestore? firestoreInstance,
    firebase_messaging.FirebaseMessaging? messaging,
    firebase_analytics.FirebaseAnalytics? analytics,
    firebase_storage.FirebaseStorage? storage,
    firebase_remote_config.FirebaseRemoteConfig? remoteConfig,
  }) async {
    try {
      // Tentar acessar os serviços para verificar disponibilidade
      _auth = auth ?? firebase_auth.FirebaseAuth.instance;
      _isAuthAvailable = _checkAuthAvailability();
      
      _firestore = firestoreInstance ?? cloud_firestore.FirebaseFirestore.instance;
      _isFirestoreAvailable = _checkFirestoreAvailability();
      
      _messaging = messaging ?? firebase_messaging.FirebaseMessaging.instance;
      _isMessagingAvailable = _checkMessagingAvailability();
      
      _analytics = analytics ?? firebase_analytics.FirebaseAnalytics.instance;
      _isAnalyticsAvailable = _checkAnalyticsAvailability();
      
      _storage = storage ?? firebase_storage.FirebaseStorage.instance;
      _isStorageAvailable = _checkStorageAvailability();
      
      _remoteConfig = remoteConfig ?? firebase_remote_config.FirebaseRemoteConfig.instance;
      _isRemoteConfigAvailable = _checkRemoteConfigAvailability();
      
      _isFirebaseInitialized = true;
      
      debugPrint('✅ FirebaseWrapper: Todos os serviços verificados com sucesso');
    } catch (e) {
      debugPrint('⚠️ FirebaseWrapper: Erro na inicialização: $e');
      // Mesmo com erros, continuar com o que estiver disponível
      _isFirebaseInitialized = true;
    }
  }

  // Métodos para verificar a disponibilidade de cada serviço
  static bool _checkAuthAvailability() {
    try {
      // Tentar obter o usuário atual para verificar se está disponível
      _auth?.currentUser;
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase Auth não disponível: $e');
      return false;
    }
  }

  static bool _checkFirestoreAvailability() {
    try {
      // Tentar criar um documento para verificar se está disponível
      _firestore?.collection('test').doc('test');
      return true;
    } catch (e) {
      debugPrint('⚠️ Firestore não disponível: $e');
      return false;
    }
  }

  static bool _checkMessagingAvailability() {
    try {
      // Tentar obter token para verificar se está disponível
      _messaging?.getToken();
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase Messaging não disponível: $e');
      return false;
    }
  }

  static bool _checkAnalyticsAvailability() {
    try {
      // Verificar se a instância está disponível
      return _analytics != null;
    } catch (e) {
      debugPrint('⚠️ Firebase Analytics não disponível: $e');
      return false;
    }
  }

  static bool _checkStorageAvailability() {
    try {
      // Tentar obter a referência padrão para verificar se está disponível
      _storage?.ref();
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase Storage não disponível: $e');
      return false;
    }
  }

  static bool _checkRemoteConfigAvailability() {
    try {
      // Tentar obter um valor para verificar se está disponível
      _remoteConfig?.getString('test');
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase Remote Config não disponível: $e');
      return false;
    }
  }

  // Getters para as instâncias com verificação de disponibilidade
  static firebase_auth.FirebaseAuth? get auth {
    if (!_isAuthAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firebase Auth em plataforma não suportada');
      return null;
    }
    return _auth;
  }

  static cloud_firestore.FirebaseFirestore? get firestore {
    if (!_isFirestoreAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firestore em plataforma não suportada');
      return null;
    }
    return _firestore;
  }

  static firebase_messaging.FirebaseMessaging? get messaging {
    if (!_isMessagingAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firebase Messaging em plataforma não suportada');
      return null;
    }
    return _messaging;
  }

  static firebase_analytics.FirebaseAnalytics? get analytics {
    if (!_isAnalyticsAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firebase Analytics em plataforma não suportada');
      return null;
    }
    return _analytics;
  }

  static firebase_storage.FirebaseStorage? get storage {
    if (!_isStorageAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firebase Storage em plataforma não suportada');
      return null;
    }
    return _storage;
  }

  static firebase_remote_config.FirebaseRemoteConfig? get remoteConfig {
    if (!_isRemoteConfigAvailable) {
      debugPrint('⚠️ Tentativa de acessar Firebase Remote Config em plataforma não suportada');
      return null;
    }
    return _remoteConfig;
  }
}