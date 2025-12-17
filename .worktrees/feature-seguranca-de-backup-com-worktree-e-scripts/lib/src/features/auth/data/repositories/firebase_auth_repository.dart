import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/odyssey_user.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/models/account_type.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementação do AuthRepository usando Firebase Auth
/// 
/// Gerencia autenticação com Firebase Auth e Google Sign-In,
/// com suporte a modo visitante (local-only).
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _prefs;
  final Uuid _uuid;

  // Controllers para streams
  final _authStateController = StreamController<OdysseyUser?>.broadcast();
  
  // Cache do usuário atual
  OdysseyUser? _cachedUser;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required SharedPreferences prefs,
  })  : _firebaseAuth = firebaseAuth ?? _getFirebaseAuthOrNull(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _prefs = prefs,
        _uuid = const Uuid() {
    // Apenas escutar mudanças se Firebase estiver disponível
    if (_firebaseAuth != null) {
      _firebaseAuth.authStateChanges().listen(_handleAuthStateChange);
    }
    
    // Inicializar com estado atual
    _initializeAuthState();
  }

  /// Tenta obter FirebaseAuth.instance, retorna null se não disponível
  static firebase_auth.FirebaseAuth? _getFirebaseAuthOrNull() {
    try {
      return firebase_auth.FirebaseAuth.instance;
    } catch (e) {
      // Firebase não disponível nesta plataforma
      return null;
    }
  }

  /// Helper para verificar se Firebase está disponível e retornar erro se não estiver
  AuthResult _requireFirebase(String operation) {
    if (_firebaseAuth == null) {
      return const AuthResult.failure(
        message: 'Firebase não está disponível nesta plataforma. Use modo visitante.',
        errorCode: 'firebase-unavailable',
      );
    }
    return const AuthResult.initial(); // Nunca usado, só para tipo de retorno
  }

  /// Retorna _firebaseAuth ou lança exceção
  firebase_auth.FirebaseAuth get _fb {
    if (_firebaseAuth == null) {
      throw Exception('Firebase não disponível');
    }
    return _firebaseAuth;
  }

  void _initializeAuthState() {
    final firebaseUser = _firebaseAuth?.currentUser;
    if (firebaseUser != null) {
      _cachedUser = _mapFirebaseUser(firebaseUser);
      _authStateController.add(_cachedUser);
    } else {
      // Verificar se é modo guest
      final isGuest = _prefs.getBool('isGuest') ?? false;
      if (isGuest) {
        final guestUid = _prefs.getString('guestUid');
        final userName = _prefs.getString('userName') ?? 'Visitante';
        if (guestUid != null) {
          _cachedUser = OdysseyUser.guest(uid: guestUid, displayName: userName);
          _authStateController.add(_cachedUser);
        }
      }
    }
  }

  void _handleAuthStateChange(firebase_auth.User? firebaseUser) {
    if (firebaseUser != null) {
      _cachedUser = _mapFirebaseUser(firebaseUser);
      _authStateController.add(_cachedUser);
    } else {
      // Verificar se é modo guest antes de emitir null
      final isGuest = _prefs.getBool('isGuest') ?? false;
      if (!isGuest) {
        _cachedUser = null;
        _authStateController.add(null);
      }
    }
  }

  @override
  Stream<OdysseyUser?> get authStateChanges => _authStateController.stream;

  @override
  OdysseyUser? get currentUser => _cachedUser;

  @override
  bool get isAuthenticated => _cachedUser != null;

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Verificar se Firebase está disponível
    if (_firebaseAuth == null) {
      return const AuthResult.failure(
        message: 'Firebase não está disponível nesta plataforma',
        errorCode: 'firebase-unavailable',
      );
    }

    try {
      // Sign out primeiro para forçar seletor de conta
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult.failure(
          message: 'Login cancelado',
          errorCode: 'cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = _mapFirebaseUser(userCredential.user!);

      // Salvar localmente
      await _saveLocalAuth(user, isGuest: false);
      _cachedUser = user;
      _authStateController.add(user);

      return AuthResult.success(user: user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao fazer login com Google',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _fb.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = _mapFirebaseUser(userCredential.user!);
      await _saveLocalAuth(user, isGuest: false);
      _cachedUser = user;
      _authStateController.add(user);

      return AuthResult.success(user: user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao fazer login',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _fb.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualizar displayName
      await userCredential.user!.updateDisplayName(displayName);
      
      // Enviar email de verificação
      await userCredential.user!.sendEmailVerification();

      // Recarregar para pegar displayName atualizado
      await userCredential.user!.reload();
      final updatedUser = _fb.currentUser!;

      final user = _mapFirebaseUser(updatedUser);
      await _saveLocalAuth(user, isGuest: false);
      _cachedUser = user;
      _authStateController.add(user);

      return AuthResult.success(
        user: user,
        message: 'Conta criada! Verifique seu email.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao criar conta',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> signInAsGuest() async {
    try {
      final guestUid = 'guest_${_uuid.v4()}';
      final guestUser = OdysseyUser.guest(
        uid: guestUid,
        displayName: 'Visitante',
      );

      await _saveLocalAuth(guestUser, isGuest: true);
      _cachedUser = guestUser;
      _authStateController.add(guestUser);

      return AuthResult.success(user: guestUser);
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao entrar como visitante',
        errorCode: 'guest_error',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _fb.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.success(
        message: 'Email de recuperação enviado!',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao enviar email',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      // Logout do Firebase
      await _fb.signOut();
      
      // Logout do Google
      await _googleSignIn.signOut();
      
      // Limpar dados locais
      await _clearLocalAuth();
      
      _cachedUser = null;
      _authStateController.add(null);

      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao fazer logout',
        errorCode: 'signout_error',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _fb.currentUser;
      if (user != null) {
        await user.delete();
      }

      await _clearLocalAuth();
      _cachedUser = null;
      _authStateController.add(null);

      return const AuthResult.success(
        message: 'Conta deletada com sucesso',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AuthResult.failure(
          message: 'Por segurança, faça login novamente antes de deletar a conta',
          errorCode: 'requires-recent-login',
        );
      }
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao deletar conta',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> upgradeGuestAccount(String email, String password) async {
    try {
      // Criar nova conta
      final userCredential = await _fb.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Preservar nome se tiver
      final guestName = _prefs.getString('userName');
      if (guestName != null && guestName != 'Visitante') {
        await userCredential.user!.updateDisplayName(guestName);
      }

      // Enviar verificação de email
      await userCredential.user!.sendEmailVerification();

      await userCredential.user!.reload();
      final user = _mapFirebaseUser(_fb.currentUser!);
      await _saveLocalAuth(user, isGuest: false);
      _cachedUser = user;
      _authStateController.add(user);

      return AuthResult.success(
        user: user,
        message: 'Conta criada com sucesso! Verifique seu email.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao criar conta',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _fb.currentUser;
      if (user == null) {
        // Para guest, apenas atualizar local
        if (_cachedUser?.isGuest == true) {
          final updatedUser = _cachedUser!.copyWith(
            displayName: displayName ?? _cachedUser!.displayName,
            photoURL: photoURL ?? _cachedUser!.photoURL,
          );
          await _saveLocalAuth(updatedUser, isGuest: true);
          _cachedUser = updatedUser;
          _authStateController.add(updatedUser);
          return AuthResult.success(user: updatedUser);
        }
        return const AuthResult.failure(
          message: 'Nenhum usuário autenticado',
          errorCode: 'no_user',
        );
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      final updatedUser = _mapFirebaseUser(_fb.currentUser!);
      await _saveLocalAuth(updatedUser, isGuest: false);
      _cachedUser = updatedUser;
      _authStateController.add(updatedUser);

      return AuthResult.success(user: updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao atualizar perfil',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<AuthResult> resendVerificationEmail() async {
    try {
      final user = _fb.currentUser;
      if (user == null) {
        return const AuthResult.failure(
          message: 'Nenhum usuário autenticado',
          errorCode: 'no_user',
        );
      }

      await user.sendEmailVerification();
      return const AuthResult.success(
        message: 'Email de verificação enviado!',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
        exception: e,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Erro ao enviar email',
        errorCode: 'unknown',
        exception: e,
      );
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    try {
      final user = _fb.currentUser;
      if (user == null) return false;

      await user.reload();
      final isVerified = _fb.currentUser?.emailVerified ?? false;

      // Atualizar cache se verificado
      if (isVerified && _cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(emailVerified: true);
        _authStateController.add(_cachedUser);
      }

      return isVerified;
    } catch (e) {
      return false;
    }
  }

  // ============== HELPERS ==============

  OdysseyUser _mapFirebaseUser(firebase_auth.User firebaseUser) {
    return OdysseyUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'Usuário',
      email: firebaseUser.email,
      photoURL: firebaseUser.photoURL,
      isGuest: false,
      isPro: false, // Será atualizado pelo Firestore
      accountType: AccountType.free,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
      authProvider: _getAuthProvider(firebaseUser),
    );
  }

  String _getAuthProvider(firebase_auth.User user) {
    if (user.providerData.isEmpty) return 'email';
    final providerId = user.providerData.first.providerId;
    if (providerId.contains('google')) return 'google';
    if (providerId.contains('password')) return 'email';
    return providerId;
  }

  Future<void> _saveLocalAuth(OdysseyUser user, {required bool isGuest}) async {
    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setBool('isGuest', isGuest);
    await _prefs.setString('uid', user.uid);
    await _prefs.setString('userName', user.displayName);
    
    if (user.email != null) {
      await _prefs.setString('userEmail', user.email!);
    } else {
      await _prefs.remove('userEmail');
    }
    
    if (user.photoURL != null) {
      await _prefs.setString('userPhoto', user.photoURL!);
    } else {
      await _prefs.remove('userPhoto');
    }
    
    if (isGuest) {
      await _prefs.setString('guestUid', user.uid);
    } else {
      await _prefs.remove('guestUid');
    }
  }

  Future<void> _clearLocalAuth() async {
    await _prefs.remove('isLoggedIn');
    await _prefs.remove('isGuest');
    await _prefs.remove('uid');
    await _prefs.remove('userName');
    await _prefs.remove('userEmail');
    await _prefs.remove('userPhoto');
    await _prefs.remove('guestUid');
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Conta desabilitada';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento.';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email usando outro método de login';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente';
      default:
        return 'Erro: $code';
    }
  }

  /// Liberar recursos
  void dispose() {
    _authStateController.close();
  }
}
