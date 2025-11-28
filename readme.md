# 🔐 NetworkKit – Camadas de Segurança  
### Documento Técnico Oficial

Este documento descreve todas as **camadas de segurança implementadas** no módulo **NetworkKit**, incluindo criptografia, anti‑replay, assinatura HMAC, middleware de device/app e anti‑tamper.

É um guia independente e detalhado, com foco no que é crítico para a integridade, autenticidade e segurança das requisições enviadas pelo app.

---

# 📌 Sumário

1. Objetivos de Segurança  
2. Arquitetura das Camadas de Segurança  
3. Pipeline Seguro da Requisição  
4. Camada 1 — Hash da Requisição (Integridade)  
5. Camada 2 — Nonce + Timestamp + HMAC (Anti-Replay + Autenticidade)  
6. Camada 3 — Security Middleware (Device, App, Anti-Tamper)  
7. Implementações Internas  
8. Headers de Segurança Implementados  
9. Padrões e Boas Práticas Seguidas  
10. Extensões Futuras  

---

# 🎯 1. Objetivos de Segurança

As camadas de segurança do `NetworkKit` têm como metas principais:

- Garantir **integridade** do corpo da requisição (hash SHA256)  
- Prevenir **replay attacks**  
- Garantir **autenticidade** com assinatura HMAC‑SHA256  
- Identificar com segurança o dispositivo (Keychain)  
- Inserir metadados confiáveis (OS, modelo, versão do app)  
- Detectar **tampering do app** via hash do bundle  
- Manter as Features desacopladas da lógica de segurança  

Todo esse fluxo é transparente para camadas superiores.

---

# 🧱 2. Arquitetura das Camadas de Segurança

As camadas são organizadas em três blocos independentes:

```
Security Layer 1 → Hash (integridade)
Security Layer 2 → Nonce + Timestamp + HMAC (anti‑replay)
Security Layer 3 → Middleware (device, app, anti‑tamper)
```

Cada camada pode ser acionada por meio dessas funções (definidas no seu protocolo):

```swift
func buildRequest(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
func buildRequestHash(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
func buildResquestNonce(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
func buildResquestMiddleware(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
```

---

# 🔐 3. Pipeline Seguro da Requisição

Fluxo completo da composição segura:

```
Feature → Endpoint → SecureRequestBuilder
 → buildRequest()
 → buildRequestHash()
 → buildResquestMiddleware()
 → buildResquestNonce()
 → URLRequest Final Assinado
 → APIClient
```

---

# 🔒 4. Camada 1 — Hash da Requisição (Integridade)

### Objetivo  
Garantir que o corpo enviado ao servidor não sofreu adulteração.

### Funcionamento

1. Converte o `httpBody` para String  
2. Calcula o hash SHA256  
3. Adiciona o header:

```
X-Body-Hash: <sha256-hex>
```

### Utilitário utilizado

```swift
CryptoUtils.sha256(text)
```

Essa camada garante que ataques de modificação de pacote não afetem o conteúdo.

---

# 🛡 5. Camada 2 — Nonce + Timestamp + Assinatura HMAC (Anti-Replay)

Fundamental para impedir:

- replay de requisições  
- reenvio de pacotes capturados  
- ataques intermediários (MITM)  
- clonation attacks  

### Funcionamento

1. Gera *nonce* único por request  
2. Gera **timestamp UNIX**  
3. Calcula hash do corpo  
4. Monta mensagem:

```
<timestamp>
<nonce>
<bodyHash>
```

5. Assina com chave privada usando HMAC‑SHA256  
6. Adiciona headers:

```
X-Nonce
X-Timestamp
X-Body-Hash
X-Signature
X-Time-Window
```

### Utilitários

- `NonceGenerator.generate()`  
- `CryptoUtils.hmacSHA256(message:key:)`  

---

# 🧬 6. Camada 3 — Security Middleware  
### (Device Info + App Info + Anti‑Tamper)

Essa camada adiciona metadados confiáveis para que o backend possa:

- validar o dispositivo  
- detectar ambiente manipulado  
- identificar versão do app  
- medir risco  

### Headers adicionados

#### 📱 Device
```
X-Device-ID
X-Device-Model
X-System-Name
X-System-Version
```

#### 📦 App
```
X-App-Version
X-App-Build
```

#### 🛡 Anti‑Tamper
```
X-App-Integrity = SHA256(Info.plist)
```

### Utilitários internos

- `DeviceInfo`  
- `DeviceIDProvider` (Keychain)  
- `BundleHasher`  

---

# 🧩 7. Implementações Internas

### ✔ CryptoUtils
- SHA256  
- HMAC‑SHA256  

### ✔ AESCipher  
- Criptografia simétrica AES‑GCM (para usos futuros)

### ✔ NonceGenerator  
- UUID v4 → evita colisões  

### ✔ DeviceIDProvider  
- DeviceID persistente, salvo no Keychain  

### ✔ BundleHasher  
- Hash SHA256 do bundle → detecção de manipulação  

### ✔ SecurityMiddleware  
- Insere headers de segurança automaticamente  

---

# 📋 8. Headers Implementados

| Categoria           | Header                 | Descrição |
|--------------------|------------------------|-----------|
| Integridade        | `X-Body-Hash`          | SHA256 do body |
| Anti‑Replay        | `X-Nonce`              | Nonce único |
| Anti‑Replay        | `X-Timestamp`          | Data UNIX |
| Anti‑Replay        | `X-Signature`          | HMAC-SHA256 |
| Anti‑Replay        | `X-Time-Window`        | Janela de validade |
| Device             | `X-Device-ID`          | Persistente via Keychain |
| Device             | `X-Device-Model`       | Modelo do iPhone |
| Device             | `X-System-Name`        | iOS |
| Device             | `X-System-Version`     | Ex.: 17.3 |
| App                | `X-App-Version`        | Ex.: 1.3.2 |
| App                | `X-App-Build`          | Ex.: 42 |
| Anti‑Tamper        | `X-App-Integrity`      | Hash SHA256 do Info.plist |

---

# 📚 9. Padrões e Boas Práticas Seguidas

### ✔ OWASP MASVS  
(Mobile Application Security Verification Standard)

### ✔ OWASP MASTG  
(Regras de segurança mobile)

### ✔ Padrões de bancos e fintechs  
- Nonce  
- Timestamp  
- Assinatura HMAC  
- Device ID persistente  
- Anti-tamper  

### ✔ Zero Trust  
Toda request é tratada como suspeita até validação completa.

---

# 🚀 10. Extensões Futuras

O módulo está preparado para:

- TokenManager criptografado (AES + Keychain)  
- Cert‑pinning avançado  
- Assinatura dupla (client key + device key)  
- Detecção de jailbreak / root  
- Middlewares de risco (VPN/Proxy detection)  
- Auditoria e telemetria  

---

# ✔ Conclusão

Este documento cobre exclusivamente as **camadas de segurança** implementadas no NetworkKit.  
Ele serve como base técnica para auditoria, segurança, compliance e desenvolvedores iOS que integrarão as APIs protegidas pelo módulo.
