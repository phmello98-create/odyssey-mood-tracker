# Configuração do AdMob e In-App Purchases

## 1. Configuração do AdMob

### 1.1 Criar conta no AdMob

1. Acesse [AdMob](https://admob.google.com/)
2. Crie uma conta ou faça login
3. Adicione seu app (Android/iOS)
4. Anote o **App ID**

### 1.2 Criar unidades de anúncio

Crie as seguintes unidades no AdMob:

| Tipo | Uso | Nome sugerido |
|------|-----|---------------|
| Banner | Tela inicial, listas | odyssey_banner |
| Interstitial | Entre ações | odyssey_interstitial |
| Rewarded | XP bônus | odyssey_rewarded |

### 1.3 Configurar Android

Edite `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
    </application>
</manifest>
```

### 1.4 Configurar iOS

Edite `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- Adicione mais SKAdNetwork IDs conforme necessário -->
</array>
```

### 1.5 Atualizar IDs no código

Edite `lib/src/features/subscription/services/admob_service.dart`:

```dart
// Substituir pelos seus IDs reais
static const String _prodBannerAndroid = 'ca-app-pub-SEU_ID/BANNER_ID';
static const String _prodInterstitialAndroid = 'ca-app-pub-SEU_ID/INTERSTITIAL_ID';
static const String _prodRewardedAndroid = 'ca-app-pub-SEU_ID/REWARDED_ID';
```

### 1.6 Inicializar no main.dart

```dart
import 'package:odyssey/src/features/subscription/services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AdMob
  await AdMobService().initialize();
  
  runApp(const MyApp());
}
```

---

## 2. Configuração de In-App Purchases

### 2.1 Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app
3. Vá em **Monetização > Produtos**
4. Crie os seguintes produtos:

#### Compra Única (Non-consumable)

| Product ID | Nome | Preço |
|------------|------|-------|
| `odyssey_pro_lifetime` | Odyssey PRO Vitalício | R$ 29,90 |

#### Assinaturas

| Product ID | Nome | Preço | Período |
|------------|------|-------|---------|
| `odyssey_pro_monthly` | Odyssey PRO Mensal | R$ 4,90 | Mensal |
| `odyssey_pro_yearly` | Odyssey PRO Anual | R$ 39,90 | Anual |

### 2.2 Configurar Descrições

Para cada produto, adicione:

- **Título**: Nome curto (ex: "Odyssey PRO")
- **Descrição**: Benefícios (ex: "Sem anúncios, backup ilimitado...")
- **Imagem**: Ícone do PRO (512x512)

### 2.3 Testar compras

1. Adicione testadores no Play Console:
   - **Configurações > Teste de licença**
   - Adicione e-mails dos testadores

2. No código, use IDs de teste:
   - O código já usa IDs de teste em modo debug

### 2.4 App Store (iOS)

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Vá em **App > In-App Purchases**
3. Crie os mesmos produtos com os mesmos IDs

---

## 3. Uso dos Widgets

### 3.1 Banner de Anúncios

```dart
// Banner padrão (320x50)
AdBannerWidget()

// Banner com tamanho específico
AdBannerWidget(
  adSize: AdSize.mediumRectangle,
  height: 250,
)

// Banner adaptativo (recomendado)
AdaptiveBannerWidget()
```

### 3.2 Anúncio Intersticial

```dart
// Mostrar após ação (respeita cooldown)
await InterstitialAdManager().maybeShowAfterAction(ref);

// Forçar exibição
await InterstitialAdManager().showAd(ref);
```

### 3.3 Anúncio Recompensado

```dart
// Verificar disponibilidade
if (RewardedAdManager().isAvailable) {
  // Mostrar botão
}

// Mostrar e dar recompensa
final earned = await RewardedAdManager().showAd();
if (earned) {
  // Dar XP bônus, etc.
}
```

### 3.4 Botão de Recompensa

```dart
WatchAdButton(
  label: 'Ganhe XP Bônus',
  rewardDescription: '+50 XP ao assistir',
  onRewardEarned: () {
    ref.read(gamificationProvider.notifier).addXP(50);
  },
)
```

---

## 4. Compras

### 4.1 Comprar PRO

```dart
// Vitalício
await ref.read(subscriptionProvider.notifier).purchaseLifetime();

// Mensal
await ref.read(subscriptionProvider.notifier).purchaseMonthly();

// Anual
await ref.read(subscriptionProvider.notifier).purchaseYearly();
```

### 4.2 Restaurar Compras

```dart
await ref.read(subscriptionProvider.notifier).restorePurchase();
```

### 4.3 Verificar Status

```dart
final isPro = ref.watch(isProProvider);
final showAds = ref.watch(showAdsProvider);

if (isPro) {
  // Usuário é PRO
}

if (showAds) {
  // Mostrar anúncios
}
```

---

## 5. Checklist de Publicação

### AdMob

- [ ] Conta AdMob criada e verificada
- [ ] App adicionado (Android/iOS)
- [ ] Unidades de anúncio criadas (Banner, Interstitial, Rewarded)
- [ ] App ID configurado no AndroidManifest.xml
- [ ] App ID configurado no Info.plist (iOS)
- [ ] IDs de produção atualizados no código
- [ ] Testado com anúncios de teste
- [ ] Política de privacidade atualizada

### In-App Purchases

- [ ] Produtos criados no Google Play Console
- [ ] Produtos criados no App Store Connect (se iOS)
- [ ] Testadores adicionados
- [ ] Testado fluxo de compra completo
- [ ] Testado restauração de compras
- [ ] Verificação de compra no servidor (recomendado para produção)

---

## 6. Verificação de Compras no Servidor (Opcional)

Para maior segurança, implemente verificação de compras no seu backend:

### Android (Google Play)

```javascript
// Node.js exemplo
const { google } = require('googleapis');

async function verifyAndroidPurchase(packageName, productId, purchaseToken) {
  const auth = new google.auth.GoogleAuth({
    keyFile: 'service-account.json',
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  
  const androidPublisher = google.androidpublisher({ version: 'v3', auth });
  
  // Para compras únicas
  const result = await androidPublisher.purchases.products.get({
    packageName,
    productId,
    token: purchaseToken,
  });
  
  return result.data.purchaseState === 0; // 0 = purchased
}
```

### iOS (App Store)

```javascript
// Node.js exemplo
const axios = require('axios');

async function verifyiOSPurchase(receiptData) {
  // Produção
  const url = 'https://buy.itunes.apple.com/verifyReceipt';
  // Sandbox (teste)
  // const url = 'https://sandbox.itunes.apple.com/verifyReceipt';
  
  const response = await axios.post(url, {
    'receipt-data': receiptData,
    'password': 'YOUR_SHARED_SECRET',
  });
  
  return response.data.status === 0;
}
```

---

## 7. Troubleshooting

### Anúncios não aparecem

1. Verifique se o AdMob foi inicializado
2. Verifique os IDs das unidades
3. Em desenvolvimento, use IDs de teste
4. Nova conta AdMob pode demorar 24h para servir anúncios

### Compras não funcionam

1. Verifique se o app está publicado (pelo menos em teste interno)
2. Verifique se o e-mail do testador está na lista
3. Verifique se os produtos estão ativos no console
4. Limpe cache do Play Store no dispositivo

### Erro "BillingClient not ready"

1. Verifique conexão com internet
2. Verifique se o app está assinado com a mesma chave
3. Reinstale o app
