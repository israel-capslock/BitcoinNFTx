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

;; Storage map for UTXO details with extended metadata
(define-map bitcoin-utxo-storage 
  { utxo-id: (string-ascii 64) }
  {
    total-fractions: uint,
    available-fractions: uint,
    owner: principal,
    bitcoin-address: (string-ascii 35),
    original-value: uint,
    is-locked: bool,
    is-tradable: bool,
    creation-time: uint
  }
)

;; Fraction ownership tracking
(define-map fraction-ownership
  { utxo-id: (string-ascii 64), holder: principal }
  { fraction-count: uint }
)

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Create a fractionalized Bitcoin NFT
(define-public (create-fraction 
  (utxo-id (string-ascii 64))
  (bitcoin-address (string-ascii 35))
  (original-value uint)
  (total-fractions uint)
)
  (begin
    ;; Comprehensive input validations
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-TRANSFER)
    (asserts! (> (len utxo-id) u0) ERR-INVALID-UTXO-ID)
    (asserts! (<= (len utxo-id) u64) ERR-INVALID-UTXO-ID)
    (asserts! (is-valid-bitcoin-length bitcoin-address) ERR-INVALID-BITCOIN-ADDRESS)
    (asserts! (> total-fractions u0) ERR-INVALID-FRACTIONS)
    (asserts! (> original-value u0) ERR-INVALID-FRACTIONS)

    ;; Check if UTXO is already fractionalized
    (asserts! 
      (is-eq 
        (default-to false 
          (get is-locked 
            (map-get? bitcoin-utxo-storage { utxo-id: utxo-id }))) 
        false
      ) 
      ERR-ALREADY-FRACTIONALIZED
    )

    ;; Store UTXO details with extended metadata
    (map-set bitcoin-utxo-storage 
      { utxo-id: utxo-id }
      {
        total-fractions: total-fractions,
        available-fractions: total-fractions,
        owner: tx-sender,
        bitcoin-address: bitcoin-address,
        original-value: original-value,
        is-locked: true,
        is-tradable: true,
        creation-time: block-height
      }
    )

    ;; Initial fraction ownership
    (map-set fraction-ownership 
      { utxo-id: utxo-id, holder: tx-sender }
      { fraction-count: total-fractions }
    )

    ;; Mint NFT
    (try! 
      (nft-mint? bitcoin-fraction utxo-id tx-sender)
    )

    (ok true)
  )
)

;; Transfer fractions between users
(define-public (transfer-fraction
  (utxo-id (string-ascii 64))
  (new-owner principal)
  (fraction-amount uint)
)
  (let 
    (
      (utxo-details 
        (unwrap! 
          (map-get? bitcoin-utxo-storage { utxo-id: utxo-id }) 
          ERR-INVALID-FRACTIONS
        )
      )
      (sender-current-fractions 
        (default-to u0 
          (get fraction-count 
            (map-get? fraction-ownership { utxo-id: utxo-id, holder: tx-sender })
          )
        )
      )
      (recipient-current-fractions 
        (default-to u0 
          (get fraction-count 
            (map-get? fraction-ownership { utxo-id: utxo-id, holder: new-owner })
          )
        )
      )
    )
    ;; Validation checks
    (asserts! (get is-tradable utxo-details) ERR-FRACTION-TRADING-DISABLED)
    (asserts! (is-eq tx-sender (get owner utxo-details)) ERR-NOT-OWNER)
    (asserts! (>= sender-current-fractions fraction-amount) ERR-INSUFFICIENT-FRACTIONS)
    (asserts! (> fraction-amount u0) ERR-INVALID-FRACTIONS)

    ;; Update fraction ownership
    (map-set fraction-ownership 
      { utxo-id: utxo-id, holder: tx-sender }
      { fraction-count: (- sender-current-fractions fraction-amount) }
    )
    (map-set fraction-ownership 
      { utxo-id: utxo-id, holder: new-owner }
      { fraction-count: (+ recipient-current-fractions fraction-amount) }
    )

    ;; Update UTXO storage if needed
    (map-set bitcoin-utxo-storage 
      { utxo-id: utxo-id }
      (merge utxo-details { 
        available-fractions: (- (get available-fractions utxo-details) fraction-amount) 
      })
    )

    ;; Transfer NFT
    (try! 
      (nft-transfer? bitcoin-fraction utxo-id tx-sender new-owner)
    )

    (ok true)
  )
)

;; Burn fractionalized Bitcoin NFT
(define-public (burn-fraction
  (utxo-id (string-ascii 64))
)
  (let 
    (
      (utxo-details 
        (unwrap! 
          (map-get? bitcoin-utxo-storage { utxo-id: utxo-id }) 
          ERR-INVALID-FRACTIONS
        )
    )
    )
    ;; Validate burn conditions
    (asserts! (is-eq tx-sender (get owner utxo-details)) ERR-NOT-OWNER)
    (asserts! (is-eq (get available-fractions utxo-details) (get total-fractions utxo-details)) ERR-INSUFFICIENT-FRACTIONS)

    ;; Burn NFT
    (try! 
      (nft-burn? bitcoin-fraction utxo-id tx-sender)
    )

    ;; Remove UTXO details and fraction ownership
    (map-delete bitcoin-utxo-storage { utxo-id: utxo-id })
    (map-delete fraction-ownership { utxo-id: utxo-id, holder: tx-sender })

    (ok true)
  )
)

;; Administrative function to toggle tradability
(define-public (set-fraction-tradability 
  (utxo-id (string-ascii 64))
  (is-tradable bool)
)
  (let 
    (
      (utxo-details 
        (unwrap! 
          (map-get? bitcoin-utxo-storage { utxo-id: utxo-id }) 
          ERR-INVALID-FRACTIONS
        )
    )
    )
    ;; Only contract owner can modify tradability
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-TRANSFER)

    ;; Update tradability
    (map-set bitcoin-utxo-storage 
      { utxo-id: utxo-id }
      (merge utxo-details { is-tradable: is-tradable })
    )

    (ok true)
  )
)

;; Read-only function to get UTXO details
(define-read-only (get-fraction-details 
  (utxo-id (string-ascii 64))
)
  (map-get? bitcoin-utxo-storage { utxo-id: utxo-id })
)

;; Read-only function to get fraction ownership
(define-read-only (get-fraction-ownership 
  (utxo-id (string-ascii 64))
  (holder principal)
)
  (map-get? fraction-ownership { utxo-id: utxo-id, holder: holder })
)