import '../models/odyssey_user.dart';
import '../models/auth_result.dart';

/// Interface abstrata para operações de autenticação
/// 
/// Define o contrato que qualquer implementação de autenticação deve seguir,
/// permitindo trocar facilmente entre Firebase, mock para testes, etc.
abstract class AuthRepository {
  /// Stream do estado de autenticação
  /// 
  /// Emite o usuário atual sempre que o estado de auth mudar.
  /// Emite null quando não há usuário autenticado.
  Stream<OdysseyUser?> get authStateChanges;

  /// Usuário atualmente autenticado (null se não autenticado)
  OdysseyUser? get currentUser;

  /// Verifica se há um usuário autenticado
  bool get isAuthenticated;

  /// Login com Google
  /// 
  /// Abre o seletor de contas Google e autentica com Firebase.
  /// Retorna [AuthResult.success] com o usuário ou [AuthResult.failure] com erro.
  Future<AuthResult> signInWithGoogle();

  /// Login com Email/Password
  /// 
  /// Autentica com email e senha existentes.
  /// Retorna [AuthResult.failure] se credenciais inválidas.
  Future<AuthResult> signInWithEmail(String email, String password);

  /// Cadastro com Email/Password
  /// 
  /// Cria nova conta com email, senha e nome de exibição.
  /// Envia email de verificação automaticamente.
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  /// Entrar como visitante (modo local-only)
  /// 
  /// Cria um usuário local sem conta Firebase.
  /// Dados ficam apenas no dispositivo, sem sincronização.
  Future<AuthResult> signInAsGuest();

  /// Recuperar senha
  /// 
  /// Envia email de recuperação de senha.
  /// Retorna [AuthResult.success] mesmo se email não existir (segurança).
  Future<AuthResult> resetPassword(String email);

  /// Fazer logout
  /// 
  /// Desconecta o usuário atual (Firebase e Google).
  /// Limpa dados de sessão local.
  Future<AuthResult> signOut();

  /// Deletar conta
  /// 
  /// Remove permanentemente a conta do Firebase.
  /// Pode requerer re-autenticação recente.
  Future<AuthResult> deleteAccount();

  /// Converter conta de visitante em conta real
  /// 
  /// Permite que um usuário guest crie uma conta mantendo seus dados.
  /// Útil para onboarding gradual.
  Future<AuthResult> upgradeGuestAccount(String email, String password);

  /// Atualizar perfil do usuário
  /// 
  /// Atualiza displayName e/ou photoURL.
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  });

  /// Reenviar email de verificação
  Future<AuthResult> resendVerificationEmail();

  /// Verificar se o email foi confirmado
  /// 
  /// Recarrega o usuário do Firebase e retorna o status.
  Future<bool> checkEmailVerified();
}
