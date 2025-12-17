# 🚀 Guia Rápido: Feature de Comunidade

## Como Usar a Nova Feature

### 1️⃣ Acesso pela Home

Na tela inicial do app, role até a seção **"Comunidade"**:

- 📱 Verá um preview dos 3 posts mais recentes
- 👆 Toque em **"Ver tudo"** para abrir o feed completo
- ➕ Toque em **"Compartilhar algo"** para criar um novo post

### 2️⃣ Navegando no Feed

Na tela de comunidade:

- 📜 **Scroll** para ver mais posts
- 🔄 **Pull to refresh** para atualizar
- 💬 **Toque em um post** para ver detalhes e comentários
- ❤️ **Toque no coração** para dar like
- 💭 **Toque no balão** para ver/adicionar comentários
- ➕ **FAB** (botão flutuante) para criar post

### 3️⃣ Criando um Post

1. Toque no botão **"Criar Post"** ou FAB
2. Escolha o tipo:
   - 📝 **Texto**: Post livre
   - 😊 **Humor**: Compartilhe seu mood
3. Digite seu conteúdo (máx. 500 caracteres)
4. Toque em **"Publicar"**

### 4️⃣ Interagindo com Posts

**Likes (Reações)**
- Toque no ❤️ para curtir
- Toque novamente para remover o like
- Contador mostra total de likes

**Comentários**
- Toque no post ou no ícone 💬
- Digite seu comentário (máx. 300 caracteres)
- Toque em ➡️ para enviar
- Veja comentários em tempo real

### 5️⃣ Gerenciando Conteúdo

**Seus Posts**
- Veja seus posts no feed com seu avatar
- Badge de nível mostra sua progressão

**Seus Comentários**
- Toque em "Excluir" para remover
- Confirme a ação no diálogo

## 🔥 Recursos Principais

### ⚡ Tempo Real
Tudo atualiza automaticamente:
- Novos posts aparecem sem refresh
- Likes sincronizam instantaneamente
- Comentários aparecem ao vivo

### 📱 Offline-First
- Veja posts mesmo offline
- Ações são sincronizadas quando conectar

### 🎮 Gamificação
- Seu nível aparece em todos os posts
- Avatar personalizado
- Badges de conquistas (em breve)

### 🔒 Privacidade
- Dados sensíveis ficam privados
- Perfil público separado
- Controle o que compartilhar

## 💡 Dicas

1. **Seja Autêntico**: Compartilhe conquistas reais e sentimentos genuínos
2. **Interaja**: Comente e curta posts de outros usuários
3. **Inspire**: Suas experiências podem ajudar outros
4. **Respeite**: Mantenha um ambiente positivo e construtivo

## 🛠️ Para Desenvolvedores

### Setup Inicial

1. **Firestore Rules** - Configure as regras de segurança:
```javascript
// Em firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Posts públicos
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
      
      // Comentários
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth.uid == resource.data.userId;
      }
      
      // Reações
      match /reactions/{userId} {
        allow read: if true;
        allow write: if request.auth.uid == userId;
      }
    }
    
    // Perfis públicos
    match /users_public/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

2. **Índices Firestore** - Crie os índices necessários:
   - `posts`: `createdAt` (descending)
   - `comments`: `postId` + `createdAt` (ascending)
   - `comments`: `parentCommentId` + `createdAt` (ascending)

3. **Dependencies** - Já estão no pubspec.yaml:
   - `cloud_firestore`
   - `firebase_auth`
   - `timeago`
   - `flutter_riverpod`

### Testando Localmente

```bash
# 1. Certifique-se de que Firebase está configurado
flutter run

# 2. Crie uma conta de teste
# Use a tela de login do app

# 3. Sincronize perfil público
# Acontece automaticamente na primeira vez

# 4. Crie posts e teste interações
# Use a interface do app
```

### Debug

```dart
// Ver logs do Firestore
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Verificar autenticação
print('User: ${FirebaseAuth.instance.currentUser?.uid}');

// Testar provider
ref.read(feedProvider); // Deve retornar stream de posts
```

## 📊 Monitoramento

### Firebase Console
- **Firestore**: Veja posts, comentários e reações
- **Authentication**: Monitore usuários ativos
- **Usage**: Acompanhe leituras/escritas

### Analytics (Sugerido)
```dart
// Rastrear criação de posts
FirebaseAnalytics.instance.logEvent(
  name: 'post_created',
  parameters: {'type': post.type.name},
);

// Rastrear engajamento
FirebaseAnalytics.instance.logEvent(
  name: 'post_liked',
  parameters: {'post_id': postId},
);
```

## 🐛 Solução de Problemas

### Posts não aparecem
- ✅ Verifique conexão com internet
- ✅ Confirme que Firebase está inicializado
- ✅ Verifique regras do Firestore

### Não consigo criar posts
- ✅ Confirme que está autenticado
- ✅ Verifique permissões no Firestore
- ✅ Veja logs de erro no console

### Likes não sincronizam
- ✅ Verifique autenticação
- ✅ Confirme regras de reações no Firestore
- ✅ Teste conexão de rede

## 📞 Suporte

Problemas ou dúvidas?
1. Veja `COMMUNITY_FEATURE.md` para documentação completa
2. Verifique logs do console Flutter
3. Consulte Firebase Console para erros

---

**Versão**: 1.0.0  
**Última atualização**: Dezembro 2024  
**Status**: ✅ Produção Ready
