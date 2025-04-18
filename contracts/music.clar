
;; title: music License


(define-non-fungible-token music-license uint)

(define-data-var last-token-id uint u0)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-already-listed (err u104))
(define-constant err-not-listed (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-insufficient-funds (err u107))
(define-constant err-artist-not-verified (err u108))

(define-map token-metadata
  uint
  {
    title: (string-ascii 100),
    artist: principal,
    description: (string-ascii 500),
    creation-date: uint,
    license-type: (string-ascii 20),
    royalty-percentage: uint
  }
)

(define-map artist-verification
  principal
  {
    verified: bool,
    verification-date: uint
  }
)

(define-map token-listings
  uint
  {
    price: uint,
    seller: principal,
    listed: bool
  }
)

(define-map royalty-recipients
  uint
  {
    artist: principal,
    percentage: uint
  }
)

(define-map license-usage-rights
  uint
  {
    commercial-use: bool,
    derivative-works: bool,
    territory: (string-ascii 50),
    duration: uint
  }
)

(define-read-only (get-last-token-id)
  (var-get last-token-id)
)

(define-read-only (get-token-metadata (token-id uint))
  (map-get? token-metadata token-id)
)

(define-read-only (get-token-listing (token-id uint))
  (map-get? token-listings token-id)
)

(define-read-only (get-license-rights (token-id uint))
  (map-get? license-usage-rights token-id)
)

(define-read-only (is-artist-verified (artist principal))
  (default-to false (get verified (map-get? artist-verification artist)))
)

(define-read-only (get-royalty-info (token-id uint))
  (map-get? royalty-recipients token-id)
)

(define-read-only (get-owner (token-id uint))
  (nft-get-owner? music-license token-id)
)

(define-public (verify-artist (artist principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set artist-verification artist {verified: true, verification-date: stacks-block-height}))
  )
)

(define-public (mint-music-license (title (string-ascii 100)) 
                                  (description (string-ascii 500))
                                  (license-type (string-ascii 20))
                                  (royalty-percentage uint)
                                  (commercial-use bool)
                                  (derivative-works bool)
                                  (territory (string-ascii 50))
                                  (duration uint))
  (let ((token-id (+ (var-get last-token-id) u1)))
    (asserts! (is-artist-verified tx-sender) err-artist-not-verified)
    (asserts! (<= royalty-percentage u100) err-invalid-price)
    
    (try! (nft-mint? music-license token-id tx-sender))
    (var-set last-token-id token-id)
    
    (map-set token-metadata token-id {
      title: title,
      artist: tx-sender,
      description: description,
      creation-date: stacks-block-height,
      license-type: license-type,
      royalty-percentage: royalty-percentage
    })
    
    (map-set royalty-recipients token-id {
      artist: tx-sender,
      percentage: royalty-percentage
    })
    
    (map-set license-usage-rights token-id {
      commercial-use: commercial-use,
      derivative-works: derivative-works,
      territory: territory,
      duration: duration
    })
    
    (ok token-id)
  )
)

(define-public (list-license-for-sale (token-id uint) (price uint))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (is-none (map-get? token-listings token-id)) err-already-listed)
    
    (map-set token-listings token-id {
      price: price,
      seller: tx-sender,
      listed: true
    })
    
    (ok true)
  )
)

(define-public (unlist-license (token-id uint))
  (let ((listing (unwrap! (map-get? token-listings token-id) err-not-listed))
        (owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (get listed listing) err-not-listed)
    
    (map-delete token-listings token-id)
    
    (ok true)
  )
)

(define-public (buy-license (token-id uint))
  (let ((listing (unwrap! (map-get? token-listings token-id) err-not-listed))
        (owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found))
        (royalty-info (unwrap! (map-get? royalty-recipients token-id) err-token-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (royalty-amount (/ (* price (get percentage royalty-info)) u100))
        (seller-amount (- price royalty-amount)))
    
    (asserts! (get listed listing) err-not-listed)
    (asserts! (is-eq owner seller) err-unauthorized)
    
    (try! (stx-transfer? price tx-sender seller))
    (try! (stx-transfer? royalty-amount seller (get artist royalty-info)))
    (try! (nft-transfer? music-license token-id seller tx-sender))
    
    (map-delete token-listings token-id)
    
    (ok true)
  )
)

(define-public (transfer-license (token-id uint) (recipient principal))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (try! (nft-transfer? music-license token-id tx-sender recipient))
    
    (map-delete token-listings token-id)
    
    (ok true)
  )
)

(define-public (update-license-rights (token-id uint)
                                     (commercial-use bool)
                                     (derivative-works bool)
                                     (territory (string-ascii 50))
                                     (duration uint))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (map-set license-usage-rights token-id {
      commercial-use: commercial-use,
      derivative-works: derivative-works,
      territory: territory,
      duration: duration
    })
    
    (ok true)
  )
)