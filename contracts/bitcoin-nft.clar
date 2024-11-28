;; Title: Bitcoin Fractionalized NFT Smart Contract

;; Summary:
;; This smart contract enables the creation, transfer, and management of fractionalized Bitcoin Non-Fungible Tokens (NFTs) on the Stacks blockchain. It includes functionalities for creating fractions, transferring ownership, burning fractions, and toggling tradability.

;; Description:
;; The Bitcoin Fractionalized NFT Smart Contract allows users to fractionalize Bitcoin UTXOs into NFTs, enabling the trading and management of Bitcoin fractions. Key features include:
;; - Creation of fractionalized Bitcoin NFTs with comprehensive input validations.
;; - Transfer of fractions between users with ownership and fraction count updates.
;; - Burning of fractionalized NFTs, ensuring all fractions are available before burning.
;; - Administrative control to toggle the tradability of fractions.
;; - Read-only functions to retrieve UTXO details and fraction ownership.
;; - Utility function to validate Bitcoin address length.
;; The contract ensures secure and efficient management of fractionalized Bitcoin assets, providing a robust framework for decentralized finance applications.

;; Error constants - grouped for clarity
(define-constant ERR-NOT-OWNER (err u1))
(define-constant ERR-INVALID-FRACTIONS (err u2))
(define-constant ERR-ALREADY-FRACTIONALIZED (err u3))
(define-constant ERR-INSUFFICIENT-FRACTIONS (err u4))
(define-constant ERR-UTXO-LOCKED (err u5))
(define-constant ERR-INVALID-UTXO-ID (err u6))
(define-constant ERR-INVALID-BITCOIN-ADDRESS (err u7))
(define-constant ERR-UNAUTHORIZED-TRANSFER (err u8))
(define-constant ERR-FRACTION-TRADING-DISABLED (err u9))

;; Non-fungible token definition
(define-non-fungible-token bitcoin-fraction (string-ascii 64))