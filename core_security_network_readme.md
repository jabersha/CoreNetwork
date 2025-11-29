# CoreNetwork & CoreSecurity - Documentação Oficial de Fluxo de Segurança

## Arquitetura dos Componentes
```
┌────────────────────┐        ┌────────────────────┐
│    CoreNetwork     │        │    CoreSecurity    │
│                    │        │                    │
│  APIClient ------->│------->│ CryptoUtils        │
│  RequestBuilder -->│------->│ DeviceKeyProvider  │
│  Security Modes -->│------->│ KeyRotationManager │
│  Middleware ------>│------->│ JailbreakDetector  │
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

## Exemplo Real de Endpoint com Todas as Camadas Ativadas

A seguir, um exemplo completo de um endpoint crítico utilizando **todas as camadas de segurança**: nonce, hash, timestamp, HMAC, middleware, chaves compostas e rotação de chaves.

### Endpoint
```
POST /v2/transfer/send
```

### Definição no iOS
```swift
struct TransferRequest: Codable {
    let amount: Double
    let recipient: String
    let description: String
}

let endpoint = Endpoint(
    path: "v2/transfer/send",
    method: .post,
    body: TransferRequest(
        amount: 250.0,
        recipient: "user_98127",
        description: "Jantar"
    ),
    security: .keyRotation
)
```

---

### Valores usados no exemplo
| Elemento | Exemplo |
|---------|---------|
| timestamp | `1708102010` |
| nonce | `b1d93a28f09e4e91` |
| bodyHash | `fe2d83b3125a0abb691f1ea11232c1f923acf87c5f8c77e3e1b8a9d77a605d47` |
| deviceKey | `d3v1c3-k3y-s7or3d-l0c4lly` |
| clientKey rotacionada | `a92bb9f0de002fc743ed7ffe6080aaf1` |
| compositeKey | `9231aad990d42d6fc63f34a816b760573f3a213f75f171afec4abeeb7362b3a4` |
| assinatura final | `695ff4e2639d995cb2c8c8fefa0d2a1ef5b9e14e4dc49ab6eb1de8a90f4f23fb` |

---

### Headers enviados
```
X-Timestamp: 1708102010
X-Nonce: b1d93a28f09e4e91
X-Body-Hash: fe2d83b3125a0abb691f1ea11232c1f923acf87c5f8c77e3e1b8a9d77a605d47
X-Signature: 695ff4e2639d995cb2c8c8fefa0d2a1ef5b9e14e4dc49ab6eb1de8a90f4f23fb
X-Time-Window: 10

X-Device-Risk: safe
X-Device-Model: iPhone15,2
X-OS-Version: 17.4
X-App-Version: 3.2.0
X-Device-Id: C5F2D23E-2931-4C8F-A389-F82B67C8F9C9
```

---

### Body enviado
```json
{
  "amount": 250,
  "recipient": "user_98127",
  "description": "Jantar"
}
```

---

### Validações do Backend
1. **Timestamp** dentro da janela permitida.
2. **Nonce** não pode ter sido usado anteriormente.
3. **BodyHash** deve corresponder ao SHA256 do corpo recebido.
4. **CompositeKey** é calculada pelo backend:
   - Recupera `clientKey` rotacionada.
   - Recupera `deviceKey` fixa do usuário.
   - Gera `SHA256(clientKey + deviceKey)`.
5. **Assinatura (HMAC)** deve bater com `X-Signature`.
6. **Middleware**:
   - Se `X-Device-Risk = compromised`, a requisição é rejeitada.
7. **Device Binding**:
   - DeviceId precisa corresponder ao registrado.

---

## Conclusão
O fluxo de segurança combina múltiplas camadas (hash, nonce, fingerprints, chaves fixas e rotacionadas) para oferecer um sistema robusto, modular e adequado para apps financeiros, e-commerce e operações sensíveis.

Essa documentação serve como referência oficial para integração entre iOS e Backend e governança de segurança.

(Conteúdo será preenchido com toda a documentação completa. Próxima etapa: inserir material gerado.)

