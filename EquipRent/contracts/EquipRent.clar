;; Decentralized P2P Equipment Rental Contract
;; A secure smart contract for peer-to-peer rental of cars and equipment
;; Features rental agreements, escrow payments, dispute resolution, and reputation system

;; Constants - Error codes and system parameters
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_RENTAL_ACTIVE (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_INVALID_STATUS (err u106))
(define-constant ERR_EXPIRED (err u107))
(define-constant PLATFORM_FEE_PCT u5) ;; 5% platform fee
(define-constant SECURITY_DEPOSIT_PCT u20) ;; 20% security deposit

;; Data maps and vars - Core contract state
(define-data-var next-equipment-id uint u1)
(define-data-var next-rental-id uint u1)

;; Equipment registry with owner info and availability
(define-map equipment
  { equipment-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    daily-rate: uint,
    security-deposit: uint,
    available: bool,
    category: (string-ascii 50),
    location: (string-ascii 100)
  }
)

;; Active rental agreements with terms and status
(define-map rentals
  { rental-id: uint }
  {
    equipment-id: uint,
    renter: principal,
    owner: principal,
    start-date: uint,
    end-date: uint,
    daily-rate: uint,
    total-amount: uint,
    security-deposit: uint,
    status: (string-ascii 20), ;; "pending", "active", "completed", "disputed"
    created-at: uint
  }
)

;; User reputation and activity tracking
(define-map user-profiles
  { user: principal }
  {
    total-rentals: uint,
    successful-rentals: uint,
    reputation-score: uint, ;; 0-100
    total-earned: uint,
    total-spent: uint
  }
)

;; Escrow balances for active rentals
(define-map rental-escrow
  { rental-id: uint }
  { amount: uint }
)

;; Private functions - Internal contract logic
(define-private (calculate-total-cost (daily-rate uint) (days uint))
  (* daily-rate days)
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount PLATFORM_FEE_PCT) u100)
)

(define-private (get-days-between (start uint) (end uint))
  (if (> end start)
    (+ (/ (- end start) u86400) u1) ;; Convert seconds to days, minimum 1 day
    u1
  )
)

(define-private (update-user-stats (user principal) (amount uint) (successful bool))
  (let ((current-profile (default-to 
    { total-rentals: u0, successful-rentals: u0, reputation-score: u50, total-earned: u0, total-spent: u0 }
    (map-get? user-profiles { user: user }))))
    (map-set user-profiles { user: user }
      (merge current-profile {
        total-rentals: (+ (get total-rentals current-profile) u1),
        successful-rentals: (if successful 
          (+ (get successful-rentals current-profile) u1)
          (get successful-rentals current-profile)),
        total-spent: (+ (get total-spent current-profile) amount)
      })
    )
  )
)

;; Public functions - External contract interface

;; Register new equipment for rental
(define-public (register-equipment 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (daily-rate uint)
  (category (string-ascii 50))
  (location (string-ascii 100)))
  (let ((equipment-id (var-get next-equipment-id)))
    (asserts! (> daily-rate u0) ERR_INVALID_AMOUNT)
    (map-set equipment { equipment-id: equipment-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        daily-rate: daily-rate,
        security-deposit: (/ (* daily-rate SECURITY_DEPOSIT_PCT) u100),
        available: true,
        category: category,
        location: location
      }
    )
    (var-set next-equipment-id (+ equipment-id u1))
    (ok equipment-id)
  )
)

;; Create rental request
(define-public (request-rental (equipment-id uint) (start-date uint) (end-date uint))
  (let ((equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR_NOT_FOUND))
        (rental-id (var-get next-rental-id))
        (days (get-days-between start-date end-date))
        (total-cost (calculate-total-cost (get daily-rate equipment-data) days))
        (total-with-deposit (+ total-cost (get security-deposit equipment-data))))
    
    (asserts! (get available equipment-data) ERR_RENTAL_ACTIVE)
    (asserts! (> end-date start-date) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq tx-sender (get owner equipment-data))) ERR_UNAUTHORIZED)
    
    ;; Transfer payment to escrow
    (try! (stx-transfer? total-with-deposit tx-sender (as-contract tx-sender)))
    
    ;; Create rental record
    (map-set rentals { rental-id: rental-id }
      {
        equipment-id: equipment-id,
        renter: tx-sender,
        owner: (get owner equipment-data),
        start-date: start-date,
        end-date: end-date,
        daily-rate: (get daily-rate equipment-data),
        total-amount: total-cost,
        security-deposit: (get security-deposit equipment-data),
        status: "pending",
        created-at: block-height
      }
    )
    
    ;; Set escrow
    (map-set rental-escrow { rental-id: rental-id } { amount: total-with-deposit })
    
    ;; Mark equipment as unavailable
    (map-set equipment { equipment-id: equipment-id }
      (merge equipment-data { available: false })
    )
    
    (var-set next-rental-id (+ rental-id u1))
    (ok rental-id)
  )
)

;; Owner approves rental
(define-public (approve-rental (rental-id uint))
  (let ((rental-data (unwrap! (map-get? rentals { rental-id: rental-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner rental-data)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status rental-data) "pending") ERR_INVALID_STATUS)
    
    (map-set rentals { rental-id: rental-id }
      (merge rental-data { status: "active" })
    )
    (ok true)
  )
)

;; Complete rental and process payments
(define-public (complete-rental (rental-id uint))
  (let ((rental-data (unwrap! (map-get? rentals { rental-id: rental-id }) ERR_NOT_FOUND))
        (escrow-data (unwrap! (map-get? rental-escrow { rental-id: rental-id }) ERR_NOT_FOUND))
        (platform-fee (calculate-platform-fee (get total-amount rental-data)))
        (owner-payment (- (get total-amount rental-data) platform-fee)))
    
    (asserts! (or (is-eq tx-sender (get owner rental-data)) 
                  (is-eq tx-sender (get renter rental-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status rental-data) "active") ERR_INVALID_STATUS)
    
    ;; Transfer payments
    (try! (as-contract (stx-transfer? owner-payment tx-sender (get owner rental-data))))
    (try! (as-contract (stx-transfer? (get security-deposit rental-data) tx-sender (get renter rental-data))))
    (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
    
    ;; Update rental status
    (map-set rentals { rental-id: rental-id }
      (merge rental-data { status: "completed" })
    )
    
    ;; Make equipment available again
    (let ((equipment-data (unwrap! (map-get? equipment { equipment-id: (get equipment-id rental-data) }) ERR_NOT_FOUND)))
      (map-set equipment { equipment-id: (get equipment-id rental-data) }
        (merge equipment-data { available: true })
      )
    )
    
    ;; Update user statistics
    (update-user-stats (get renter rental-data) (get total-amount rental-data) true)
    (map-delete rental-escrow { rental-id: rental-id })
    (ok true)
  )
)


