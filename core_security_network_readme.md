# CoreNetwork & CoreSecurity - Documentação Oficial de Fluxo de Segurança

## Arquitetura dos Componentes
```
┌────────────────────┐        ┌────────────────────┐
│    CoreNetwork      │        │    CoreSecurity     │
│                    │        │                    │
│  APIClient ------->│------->│ CryptoUtils         │
│  RequestBuilder -->│------->│ DeviceKeyProvider   │
│  Security Modes -->│------->│ KeyRotationManager  │
│  Middleware ------->│------->│ JailbreakDetector   │
└────────────────────┘        └────────────────────┘
```

Cada requisição utiliza um **modo de segurança específico**, definido pelo `Endpoint`.

---

## Modos de Segurança (`SecurityMode`)
```swift
public enum SecurityMode {
    case basic
    case hash
    case nonce
    case middleware
    case keyProvider
    case keyRotation
}
```

### 1. `.basic`
- Endpoints públicos
- Lista de itens, conteúdo estático

### 2. `.hash`
- Proteção de integridade
- `sha256(body)` + timestamp + assinatura HMAC

### 3. `.nonce`
- Anti-replay
- `nonce` único por requisição + limite de tempo (X-Time-Window)

### 4. `.middleware`
- Envia fingerprints e risco do dispositivo
- Headers como `X-Device-Risk`, `X-Device-Model`, etc.

### 5. `.keyProvider`
- Proteção baseada em chave composta
- `compositeKey = SHA256(clientKey + deviceKey)`

### 6. `.keyRotation`
- Segurança máxima
- Chaves rotacionadas enviadas pelo backend + deviceKey fixa

---

## Fluxo Completo de uma Requisição

### 1. APIClient recebe endpoint
```swift
let user = try await api.request(endpoint)
```

### 2. APIClient escolhe o modo de segurança
```swift
switch endpoint.security {
    case .basic:       buildRequest()
    case .hash:        buildRequestHash()
    case .nonce:       buildResquestNonce()
    case .middleware:  buildResquestMiddleware()
    case .keyProvider: buildResquestKeyProvider()
    case .keyRotation: buildResquestKeyRotation()
}
```

### 3. RequestBuilder monta a requisição
- Monta URL
- Serializa body
- Aplica hash, nonce, HMAC, compositeKey
- Aplica middleware (se houver)

### 4. APIClient envia e valida resposta
- 200–299 → decode
- 400–599 → serverError
- Erros de rede → networkError
- JSON inválido → decodingError

---

## Validações do Backend

### `.hash`
```
if sha256(body) != X-Body-Hash reject
if hmac(secretKey) != X-Signature reject
```

### `.nonce`
```
if timestamp > allowedWindow reject
if nonce already used reject
```

### `.middleware`
```
if deviceRisk == compromised reject
```

### `.keyProvider`
```
composite = sha256(clientKey + deviceKey)
validate HMAC(composite)
```

### `.keyRotation`
```
validate clientKey expiration
deviceKey bind
composite = sha256(rotatedClientKey + deviceKey)
validate signature
```

---

## Casos Reais de Uso
| SecurityMode     | Finalidade | Proteção |
|------------------|------------|----------|
| basic            | Público    | Nenhuma |
| hash             | Integridade | SHA256 + HMAC |
| nonce            | Anti-replay | Nonce + timestamp |
| middleware       | Risco | Fingerprint de device |
| keyProvider      | Device-binding | Composite key |
| keyRotation      | Alta segurança | Chave dinâmica + rotação |

---

## Conclusão
O fluxo de segurança combina múltiplas camadas (hash, nonce, fingerprints, chaves fixas e rotacionadas) para oferecer um sistema robusto, modular e adequado para apps financeiros, e-commerce e operações sensíveis.

Essa documentação serve como referência para integração entre iOS e Backend e governança de segurança.

