# CoreNetwork

O **CoreNetwork** é o módulo responsável por toda a orquestração das requisições HTTP do aplicativo.  
Ele constrói, assina, envia e interpreta requisições, integrando automaticamente todas as camadas de segurança fornecidas pelo módulo **CoreSecurity**.

---

# 📘 1. Objetivos

- Centralizar a comunicação HTTP.
- Padronizar a criação e execução de requests.
- Integrar com CoreSecurity (hash, nonce, timestamp, assinatura HMAC, device/app info, anti-tamper).
- Garantir testabilidade via protocolos.
- Desacoplar infraestrutura da camada de domínio.

---

# 🧱 2. Arquitetura do Módulo

## 🔹 2.1 Endpoint
Define uma rota da API:

- `path`
- `method`
- `headers`
- `queryItems`
- `body`

Cada feature implementa seus próprios endpoints.

---

## 🔹 2.2 RequestBuilder

Componente central do CoreNetwork.  
Responsável por:

1. Construir o `URLRequest` base.
2. Aplicar **todas** as camadas de segurança fornecidas pelo CoreSecurity:
   - Hash do corpo
   - Nonce
   - Timestamp
   - Assinatura HMAC
   - Headers de device/app/anti-tamper

A cada etapa, o request é enriquecido antes do envio.

---

## 🔹 2.3 APIClient / APIClientProtocol

Fluxo básico:

```swift
func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
```

Responsabilidades:

- Solicitar ao `RequestBuilder` a construção do request.
- Enviar via URLSession.
- Validar status code.
- Decodificar resposta.
- Mapear erros em `NetworkError`.

---

## 🔹 2.4 NetworkError

Enum de erros padronizados:

- `.invalidURL`
- `.transportError`
- `.decodingError`
- `.serverError(code)`
- `.unauthorized`
- `.unknown`

---

# 🔁 3. Pipeline Completo da Requisição

```
Feature → Endpoint
        → RequestBuilder.buildRequest()
        → applyHash()
        → applyNonce()
        → applyHMAC()
        → applyMiddlewareDeviceAppIntegrity()
        → applyKeyProvider()
        → applyKeyRotation() 
        → URLRequest final assinado
        → APIClient.execute()
        → validação
        → decoding
        → retorno
```

---

# 🔐 4. Integração com CoreSecurity

O CoreNetwork **não implementa criptografia**.

Ele apenas chama:

- `buildRequestHash()`
- `buildRequestNonce()`
- `buildRequestMiddleware()`
- `buildResquestKeyProvider()`
- `buildResquestKeyRotation()`    

# 🚀 5. Exemplo de Uso

### Endpoint

```swift
struct GetUserEndpoint: Endpoint {
    var path: String { "/user/me" }
    var method: HTTPMethod { .get }
}
```

### Execução

```swift
let apiClient = APIClient(
    session: URLSession.shared,
    requestBuilder: SecureRequestBuilder(
        baseURL: URL(string: "https://api.seubanco.com")!,
        securityProvider: securityProvider
    )
)

let user: User = try await apiClient.request(GetUserEndpoint())
```

---

# 🧪 6. Testabilidade

Mock via protocolo:

```swift
final class APIClientMock: APIClientProtocol {
    var result: Any?
    var error: Error?

    func request<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        if let error { throw error }
        return result as! T
    }
}
```

---

# 📦 7. Instalação (Swift Package Manager)

```swift
.package(url: "https://github.com/seu-org/CoreNetwork.git", branch: "main")
```

---

# ✅ 8. Resumo

- Módulo oficial de comunicação HTTP.
- Fornece API simples baseada em Endpoint.
- Aplicação automática das camadas de segurança.
- Separação clara entre segurança (CoreSecurity) e rede (CoreNetwork).
