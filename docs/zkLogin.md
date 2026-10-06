# zkLogin Authentication Documentation

zkLogin is a zero-knowledge authentication system that enables users to authenticate with the MySo blockchain using OAuth providers (Google, Facebook, Twitch, Apple) without revealing their OAuth credentials to the blockchain. This documentation covers the complete zkLogin implementation in MySoKit.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Core Components](#core-components)
- [Authentication Flow](#authentication-flow)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Security Considerations](#security-considerations)
- [Testing](#testing)
- [Error Handling](#error-handling)

## Overview

zkLogin combines OAuth authentication with zero-knowledge proofs to provide a seamless, secure authentication experience. Users can authenticate using familiar OAuth providers while maintaining privacy and security on the blockchain.

### Key Benefits

- **User-friendly**: No need to manage private keys or seed phrases
- **Privacy-preserving**: OAuth credentials never leave the client
- **Secure**: Zero-knowledge proofs ensure authenticity without revealing sensitive data
- **Multi-provider**: Support for Google, Facebook, Twitch, and Apple
- **Cross-platform**: Works across iOS, macOS, tvOS, and watchOS

## Architecture

The zkLogin system consists of several key components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   OAuth Flow    │    │  ZK Proof Gen   │    │ Transaction     │
│                 │    │                 │    │ Execution       │
│ 1. Generate     │    │ 4. Generate     │    │ 7. Sign & Send  │
│    Nonce        │    │    ZK Proof     │    │    Transaction  │
│ 2. OAuth Login  │───▶│ 5. Create       │───▶│ 8. Verify       │
│ 3. Get JWT      │    │    Signature    │    │    Signature    │
│                 │    │ 6. Derive       │    │                 │
│                 │    │    Address      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Components

### ZkLoginAuthenticator

The main orchestrator class that manages the zkLogin authentication flow.

**Key Methods:**
- `generateEphemeralKeypair()` - Creates temporary keypairs for signing
- `generateNonce()` - Creates nonces for OAuth flow
- `processJWT()` - Processes OAuth JWT tokens and generates zkLogin signatures
- `derivezkLoginAddress()` - Derives MySo addresses from JWT credentials
- `createSigner()` - Creates signers for transaction execution

### ZkLoginSigner

A comprehensive signer that can sign transactions and personal messages using zkLogin authentication.

**Key Features:**
- Transaction signing with zkLogin credentials
- Personal message signing
- Signature verification (with GraphQL client)
- Address derivation

### zkLoginSignature

The core data structure representing a zkLogin signature.

**Components:**
- `inputs` - ZK proof points, issuer details, header, and address seed
- `maxEpoch` - Maximum epoch for signature validity
- `userSignature` - Ephemeral signature bytes

### Supporting Utilities

- **zkLoginUtilities** - Core utility functions for address generation and cryptographic operations
- **zkLoginNonce** - Nonce generation for OAuth flows
- **zkLoginPublicKey** - Public key and address derivation
- **ZkProofService** - Interface for ZK proof generation services

## Authentication Flow

### Step 1: Initialize and Generate OAuth URL

```swift
let authenticator = ZkLoginAuthenticator(provider: mySoProvider)

// Generate ephemeral keypair
let ephemeralKeypair = try authenticator.generateEphemeralKeypair(scheme: .secp256r1)

// Get current epoch and set validity
let epochInfo = try await authenticator.getCurrentEpoch()
let maxEpoch = epochInfo.epoch + 2

// Generate randomness and nonce
let randomness = try authenticator.generateRandomness()
let nonce = try authenticator.generateNonce(
    publicKey: ephemeralKeypair.publicKey,
    maxEpoch: maxEpoch,
    randomness: randomness
)

// Construct OAuth URL
let oauthUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&response_type=id_token&redirect_uri=\(redirectUrl)&scope=openid&nonce=\(nonce)"
```

### Step 2: Complete OAuth Flow

The user completes OAuth authentication in a web view, which returns a JWT token.

### Step 3: Get User Salt

```swift
// Extract user salt (typically from a salt service)
let userSalt = try await getUserSaltFromService(jwt: jwtToken)
```

### Step 4: Generate zkLogin Signature

```swift
// Process JWT to create zkLogin signature
let zkLoginSignature = try await authenticator.processJWT(
    jwt: jwtToken,
    userSalt: userSalt,
    ephemeralKeyPair: ephemeralKeypair,
    maxEpoch: maxEpoch,
    randomness: randomness,
    proofService: proofService
)

// Derive user's zkLogin address
let userAddress = try authenticator.derivezkLoginAddress(
    jwt: jwtToken,
    userSalt: userSalt
)
```

### Step 5: Create Signer and Execute Transactions

```swift
// Create zkLogin signer
let signer = authenticator.createSigner(
    ephemeralKeyPair: ephemeralKeypair,
    zkLoginSignature: zkLoginSignature,
    userAddress: userAddress
)

// Create and execute transaction
var transaction = try TransactionBlock()
// ... configure transaction ...

let response = try await signer.signAndExecuteTransaction(
    transactionBlock: &transaction
)
```

## API Reference

### ZkLoginAuthenticator

#### Initialization

```swift
public init(provider: MySoProvider)
```

#### Key Generation

```swift
public func generateEphemeralKeypair(scheme: SignatureScheme = .ED25519) throws -> Account
public func generateRandomness() throws -> [UInt8]
```

#### Nonce Generation

```swift
public func generateNonce(
    publicKey: any PublicKeyProtocol,
    maxEpoch: UInt64,
    randomness: [UInt8]? = nil
) throws -> String
```

#### JWT Processing

```swift
public func processJWT(
    jwt: String,
    userSalt: String,
    ephemeralKeyPair: Account,
    maxEpoch: UInt64,
    randomness: [UInt8],
    proofService: ZkProofService? = nil
) async throws -> zkLoginSignature
```

#### Address Derivation

```swift
public func derivezkLoginAddress(jwt: String, userSalt: String) throws -> String
```

#### Signer Creation

```swift
public func createSigner(
    ephemeralKeyPair: Account,
    zkLoginSignature: zkLoginSignature,
    userAddress: String
) -> ZkLoginSigner

public func createzkLoginSigner(
    ephemeralKeyPair: Account,
    zkLoginSignature: zkLoginSignature,
    userAddress: String,
    graphQLClient: GraphQLClientProtocol? = nil
) -> ZkLoginSigner
```

### ZkLoginSigner

#### Signing Operations

```swift
public func signTransaction(_ transactionData: [UInt8]) throws -> String
public func signPersonalMessage(_ message: [UInt8]) throws -> String
```

#### Transaction Execution

```swift
public func signAndExecuteTransaction(
    transactionBlock: inout TransactionBlock,
    options: MySoTransactionBlockResponseOptions = .init()
) async throws -> MySoTransactionBlockResponse
```

#### Verification

```swift
public func verifyTransaction(
    transactionData: [UInt8],
    signature: zkLoginSignature
) async throws -> Bool

public func verifyPersonalMessage(
    message: [UInt8],
    signature: zkLoginSignature
) async throws -> Bool
```

### ZkProofService

```swift
public protocol ZkProofService {
    func generateProof(
        jwt: String,
        userSalt: String,
        ephemeralPublicKey: [UInt8],
        maxEpoch: UInt64,
        jwtRandomness: [UInt8]
    ) async throws -> ZkProof
}
```

## Usage Examples

### Complete zkLogin Flow Example

```swift
import MySoKit

class ZkLoginExample {
    private let provider: MySoProvider
    private let authenticator: ZkLoginAuthenticator
    private let proofService: RemoteZkProofService
    
    init() {
        self.provider = MySoProvider(url: URL(string: "https://fullnode.testnet.mysocial.network:443")!)
        self.authenticator = ZkLoginAuthenticator(provider: provider)
        self.proofService = RemoteZkProofService(url: URL(string: "https://prover.testnet.mysocial.network/v1")!)
    }
    
    func performzkLoginAuthentication() async throws {
        // Step 1: Generate ephemeral keypair and nonce
        let ephemeralKeypair = try authenticator.generateEphemeralKeypair(scheme: .secp256r1)
        let epochInfo = try await authenticator.getCurrentEpoch()
        let maxEpoch = epochInfo.epoch + 2
        let randomness = try authenticator.generateRandomness()
        
        let nonce = try authenticator.generateNonce(
            publicKey: ephemeralKeypair.publicKey,
            maxEpoch: maxEpoch,
            randomness: randomness
        )
        
        // Step 2: Construct OAuth URL and complete OAuth flow
        let oauthUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_CLIENT_ID&response_type=id_token&redirect_uri=YOUR_REDIRECT_URL&scope=openid&nonce=\(nonce)"
        
        // User completes OAuth flow and returns JWT
        let jwtToken = "JWT_FROM_OAUTH_FLOW"
        
        // Step 3: Get user salt
        let userSalt = try await getUserSalt(jwt: jwtToken)
        
        // Step 4: Process JWT and create zkLogin signature
        let zkLoginSignature = try await authenticator.processJWT(
            jwt: jwtToken,
            userSalt: userSalt,
            ephemeralKeyPair: ephemeralKeypair,
            maxEpoch: maxEpoch,
            randomness: randomness,
            proofService: proofService
        )
        
        // Step 5: Derive user address
        let userAddress = try authenticator.derivezkLoginAddress(
            jwt: jwtToken,
            userSalt: userSalt
        )
        
        // Step 6: Create signer and execute transaction
        let signer = authenticator.createSigner(
            ephemeralKeyPair: ephemeralKeypair,
            zkLoginSignature: zkLoginSignature,
            userAddress: userAddress
        )
        
        var transaction = try TransactionBlock()
        let coin = try transaction.splitCoins(transaction.gas, [transaction.pure(value: .number(1_000_000))])
        try transaction.transferObjects([coin], transaction.pure(value: .address("RECIPIENT_ADDRESS")))
        
        let response = try await signer.signAndExecuteTransaction(transactionBlock: &transaction)
        print("Transaction executed: \(response.digest)")
    }
    
    private func getUserSalt(jwt: String) async throws -> String {
        // Implementation to get user salt from salt service
        // This should be implemented based on your salt service API
        return "USER_SALT_FROM_SERVICE"
    }
}
```

### Simple Transaction Signing

```swift
// Assuming you have a zkLogin signer already created
let signer: ZkLoginSigner = // ... created from previous steps

// Create transaction data
let transactionData: [UInt8] = // ... your transaction bytes

// Sign the transaction
let signature = try signer.signTransaction(transactionData)

// The signature can now be used to submit the transaction
```

### Personal Message Signing

```swift
let signer: ZkLoginSigner = // ... your zkLogin signer
let message = "Hello, MySo blockchain!".data(using: .utf8)!

let signature = try signer.signPersonalMessage([UInt8](message))
print("Signed message: \(signature)")
```

## Security Considerations

### Ephemeral Key Management

- **Secure Generation**: Ephemeral keypairs are generated using cryptographically secure random number generators
- **Limited Lifespan**: Keys are only valid for a specific epoch range (typically current + 2 epochs)
- **Single Use**: Each authentication session should use fresh ephemeral keys

### Salt Management

- **Uniqueness**: Each user must have a unique salt value
- **Persistence**: User salts should be stored securely and consistently
- **Privacy**: Salts should not be derivable from public information

### JWT Handling

- **Validation**: Always validate JWT signatures and claims
- **Expiration**: Respect JWT expiration times
- **Scope**: Ensure JWTs have appropriate scopes for zkLogin

### Network Security

- **HTTPS**: All network communications should use HTTPS
- **Certificate Pinning**: Consider implementing certificate pinning for production
- **Error Handling**: Don't leak sensitive information in error messages

## Testing

MySoKit includes comprehensive test coverage for zkLogin functionality:

### Unit Tests

- **zkLoginSignatureTests** - Tests signature creation and serialization
- **zkLoginAddressTests** - Tests address derivation
- **zkLoginPublicIdentifierTests** - Tests public key operations
- **zkLoginSignatureSerializationTests** - Tests serialization/deserialization

### End-to-End Tests

- **zkLoginVerificationTest** - Tests complete verification flow

### Test Vectors

The project includes test vectors in `Tests/Resources/zklogin-test-vectors.json` for validation against known good values.

### Running Tests

```bash
swift test --filter zkLogin
```

## Error Handling

### Common Error Types

```swift
public enum MySoError: Error {
    case unsupportedSignatureScheme
    case failedToGenerateRandomData
    case missingProofService
    case missingJWTClaim
    case saltServiceError
    case invalidSaltServiceResponse
    case invalidURL
    // ... other error cases
}
```

### Error Handling Best Practices

1. **Graceful Degradation**: Handle errors gracefully and provide fallback options
2. **User-Friendly Messages**: Convert technical errors to user-friendly messages
3. **Logging**: Log errors for debugging while avoiding sensitive data
4. **Retry Logic**: Implement appropriate retry logic for network operations

### Example Error Handling

```swift
do {
    let signature = try await authenticator.processJWT(
        jwt: jwtToken,
        userSalt: userSalt,
        ephemeralKeyPair: ephemeralKeypair,
        maxEpoch: maxEpoch,
        randomness: randomness,
        proofService: proofService
    )
} catch MySoError.missingProofService {
    // Handle missing proof service
    print("Proof service not configured")
} catch MySoError.missingJWTClaim {
    // Handle invalid JWT
    print("Invalid JWT token")
} catch {
    // Handle other errors
    print("Authentication failed: \(error)")
}
```

## Advanced Topics

### Custom Proof Services

You can implement custom proof services by conforming to the `ZkProofService` protocol:

```swift
class CustomZkProofService: ZkProofService {
    func generateProof(
        jwt: String,
        userSalt: String,
        ephemeralPublicKey: [UInt8],
        maxEpoch: UInt64,
        jwtRandomness: [UInt8]
    ) async throws -> ZkProof {
        // Your custom proof generation logic
    }
}
```

### GraphQL Verification

For signature verification, you can use the built-in GraphQL client or implement your own:

```swift
let graphQLClient = MySoGraphQLClient(url: URL(string: "https://your-graphql-endpoint")!)
let signer = authenticator.createzkLoginSigner(
    ephemeralKeyPair: ephemeralKeypair,
    zkLoginSignature: zkLoginSignature,
    userAddress: userAddress,
    graphQLClient: graphQLClient
)
```

### Multi-Network Support

zkLogin works across different MySo networks (devnet, testnet, mainnet). Configure the appropriate endpoints:

```swift
// Testnet
let provider = MySoProvider(url: URL(string: "https://fullnode.testnet.mysocial.network:443")!)
let proofService = RemoteZkProofService(url: URL(string: "https://prover.testnet.mysocial.network/v1")!)

// Mainnet
let provider = MySoProvider(url: URL(string: "https://fullnode.mainnet.mysocial.network:443")!)
let proofService = RemoteZkProofService(url: URL(string: "https://zklogin-prover-mainnet.up.railway.app/v1")!)
```

---

This documentation provides a comprehensive guide to using zkLogin authentication in MySoKit. For additional examples and implementation details, refer to the test files and example code in the MySoKit repository.
