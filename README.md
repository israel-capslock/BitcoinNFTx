# Bitcoin Fractionalized NFT Smart Contract

## Overview

This Stacks blockchain smart contract enables the fractionalization of Bitcoin UTXOs (Unspent Transaction Outputs) into tradable Non-Fungible Tokens (NFTs). The contract provides a robust framework for creating, transferring, and managing fractional ownership of Bitcoin assets in a decentralized manner.

## Key Features

- **Fractionalization**: Convert Bitcoin UTXOs into divisible, tradable fractions
- **Secure Ownership Management**: Track and transfer fractional ownership
- **Administrative Controls**: Toggle tradability and manage fractionalized assets
- **Comprehensive Validations**: Robust input checking and error handling

## Contract Functions

### 1. `create-fraction`

Create a new fractionalized Bitcoin NFT.

**Parameters:**

- `utxo-id`: Unique identifier for the UTXO (64-character ASCII string)
- `bitcoin-address`: Associated Bitcoin address (26-35 characters)
- `original-value`: Total value of the UTXO
- `total-fractions`: Number of fractions to create

**Restrictions:**

- Only callable by the contract owner
- UTXO must not be already fractionalized
- Requires valid input parameters

### 2. `transfer-fraction`

Transfer a specified number of fractions to another user.

**Parameters:**

- `utxo-id`: Identifier of the fractionalized UTXO
- `new-owner`: Principal (address) receiving the fractions
- `fraction-amount`: Number of fractions to transfer

**Restrictions:**

- Fractions must be tradable
- Sender must have sufficient fractions
- Transfer updates fraction ownership tracking

### 3. `burn-fraction`

Burn a fractionalized Bitcoin NFT.

**Parameters:**

- `utxo-id`: Identifier of the fractionalized UTXO to burn

**Restrictions:**

- Only the UTXO owner can burn
- All fractions must be available (not distributed)

### 4. `set-fraction-tradability`

Toggle the tradability of a fractionalized UTXO.

**Parameters:**

- `utxo-id`: Identifier of the fractionalized UTXO
- `is-tradable`: Boolean to enable/disable trading

**Restrictions:**

- Only callable by the contract owner

### Read-Only Functions

- `get-fraction-details`: Retrieve details of a fractionalized UTXO
- `get-fraction-ownership`: Check fraction ownership for a specific UTXO and holder

## Error Handling

The contract includes comprehensive error constants to provide clear feedback:

- `ERR-NOT-OWNER`: Unauthorized ownership action
- `ERR-INVALID-FRACTIONS`: Invalid fraction count
- `ERR-ALREADY-FRACTIONALIZED`: UTXO already converted to NFT
- `ERR-INSUFFICIENT-FRACTIONS`: Not enough fractions for transfer
- `ERR-UTXO-LOCKED`: UTXO is locked and cannot be modified
- `ERR-INVALID-UTXO-ID`: Incorrect UTXO identifier
- `ERR-INVALID-BITCOIN-ADDRESS`: Invalid Bitcoin address
- `ERR-UNAUTHORIZED-TRANSFER`: Unauthorized transfer attempt
- `ERR-FRACTION-TRADING-DISABLED`: Trading disabled for this UTXO
- `ERR-INVALID-PRINCIPAL`: Invalid principal (address)

## Technical Details

- **Blockchain**: Stacks
- **Token Type**: Non-Fungible Token (NFT)
- **Storage**:
  - `bitcoin-utxo-storage`: Stores UTXO metadata
  - `fraction-ownership`: Tracks fractional ownership

## Security Considerations

- Input validation for all critical parameters
- Owner-only administrative functions
- Prevents double-spending and unauthorized transfers
- Comprehensive error checking

## Usage Example

```clarity
;; Create a fraction
(contract-call? .bitcoin-nft create-fraction
  "unique-utxo-id"
  "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
  u10000
  u100)

;; Transfer a fraction
(contract-call? .bitcoin-nft transfer-fraction
  "unique-utxo-id"
  'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
  u10)
```
