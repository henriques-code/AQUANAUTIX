# Google Play Console — Subscrições AQUANAUTIX (P0)

**App:** `com.aquanautix.app`  
**Ligação RevenueCat:** ver secção 6 + `REVENUECAT_SETUP.md`

> Sem APK/AAB numa faixa de teste (internal/closed), as subscrições **não funcionam** em dispositivo real.

---

## Pré-requisitos

- [ ] Conta Google Play Developer (taxa única $25)
- [ ] **Perfil de pagamentos** activo (Play Console → Configuração → Perfil de pagamentos)
- [ ] App `AQUANAUTIX` criada com package `com.aquanautix.app`

---

## 1. Criar subscrições (Monetização → Produtos → Subscrições)

Criar **3 subscrições** com estes **Product ID exactos** (case-sensitive):

### 1.1 PRO Mensal

| Campo | Valor |
|-------|--------|
| **Product ID** | `aquanautix_pro_monthly` |
| **Nome** | AQUANAUTIX PRO Mensal |
| **Descrição** | Oráculo avançado, Vision ilimitado, spots PRO, alertas |
| **Preço base** | €4.99 / mês |
| **Período** | 1 mês, renovação automática |

**Oferta introdutória (trial):**

- Tipo: **Teste gratuito**
- Duração: **3 dias**
- Aplicar a: novos subscritores

### 1.2 PRO Anual

| Campo | Valor |
|-------|--------|
| **Product ID** | `aquanautix_pro_annual` |
| **Nome** | AQUANAUTIX PRO Anual |
| **Preço base** | €39.99 / ano |
| **Período** | 1 ano |

*(Opcional: trial 3 dias também no anual — alinha com copy da app.)*

### 1.3 ELITE Anual

| Campo | Valor |
|-------|--------|
| **Product ID** | `aquanautix_elite_annual` |
| **Nome** | AQUANAUTIX ELITE Anual |
| **Preço base** | €59.99 / ano |
| **Período** | 1 ano |

---

## 2. Activar subscrições

Cada produto fica em **Rascunho** até:

1. Preencheres **política de cancelamento** / benefícios na ficha da app
2. Publicares numa faixa de teste (passo 4)

Estado alvo: **Activo** (verde) na lista de subscrições.

---

## 3. Testadores de licença (compras sem cobrança real)

Play Console → **Configuração** → **Teste de licença**:

- Adiciona o **Gmail** da conta do telemóvel Xiaomi (ex.: a tua conta Google)
- Compras de teste: renovação acelerada (5 min = 1 mês em sandbox Google)

---

## 4. Upload para faixa Internal testing (obrigatório para billing)

```powershell
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"
.\tools\flutter_build_apk_with_env.ps1
# ou AAB para produção:
# flutter build appbundle --release + signing android/key.properties
```

Play Console → **Testar e publicar** → **Teste interno**:

1. Criar release → upload `app-release.aab` (ou APK debug assinado release)
2. Adicionar lista de testadores (email)
3. **Rever e publicar** a release interna

Instalar no Xiaomi **a partir do link de teste interno** (não só `adb install` debug) para billing real — ou usar license tester com build assinada pela mesma chave de upload.

---

## 5. SHA-1 / SHA-256 (Google Sign-In + Play)

```powershell
.\tools\play_signing_fingerprints.ps1
```

Regista em **Google Cloud Console** → APIs → Credenciais → OAuth Android (`com.aquanautix.app`).

Play Console → **Configuração** → **Integridade da app** → certificados de assinatura (App signing by Google).

---

## 6. RevenueCat ↔ Google Play

### 6.1 Service account (Google Cloud)

1. [Google Cloud Console](https://console.cloud.google.com) → IAM → Contas de serviço → Criar
2. Nome: `revenuecat-play-billing`
3. Criar chave JSON → guardar **localmente** (nunca commitar)
4. Play Console → **Utilizadores e permissões** → Convidar utilizador → email da service account
5. Permissões: **Ver dados financeiros**, **Gerir pedidos e subscrições**

### 6.2 RevenueCat Dashboard

[app.revenuecat.com](https://app.revenuecat.com) → Projecto AQUANAUTIX → **Apps** → Android `com.aquanautix.app`:

1. **Google Play** → Upload JSON da service account
2. **Entitlements:** `pro`, `elite`
3. **Products** (Store: Google Play):

   | RC Product | Play Product ID | Entitlement |
   |------------|-----------------|-------------|
   | pro_monthly | aquanautix_pro_monthly | pro |
   | pro_annual | aquanautix_pro_annual | pro |
   | elite_annual | aquanautix_elite_annual | elite |

4. **Offerings** → `default` (marcar **Current**):

   | Package ID | Product |
   |------------|---------|
   | `pro_monthly` | aquanautix_pro_monthly |
   | `pro_annual` | aquanautix_pro_annual |
   | `elite_annual` | aquanautix_elite_annual |

---

## 7. Verificar na app

```powershell
.\tools\verify_revenuecat.ps1
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
```

Logcat (debug):

```
[AQUANAUTIX][RC] offering=default packages=3
```

Fluxo de teste:

1. Perfil → **PRO** → escolher plano → compra (license tester = €0)
2. **Restaurar compras** após reinstalar
3. Mapa → spot PRO **desbloqueado** (gate `SubscriptionGate`)

---

## Checklist rápido

| # | Tarefa | ✓ |
|---|--------|---|
| 1 | Perfil pagamentos activo | |
| 2 | 3 subscrições com IDs exactos | |
| 3 | Trial 3d no PRO mensal | |
| 4 | License testers | |
| 5 | Internal testing release publicada | |
| 6 | Service account + RC Google Play link | |
| 7 | Offering `default` com 3 packages | |
| 8 | Compra teste OK no Xiaomi | |

---

## Erros comuns

| Erro | Causa | Fix |
|------|-------|-----|
| `offerings empty` / packages=0 | RC sem products ou offering não current | Secção 6 |
| `Item unavailable` | Produto rascunho ou app não na faixa teste | Secções 2 + 4 |
| Compra não restaura | Conta Google diferente da compra | Mesmo Gmail + Restaurar |
| RC ConfigurationError | Play API key sem products no dashboard | Sync Play → RC |
