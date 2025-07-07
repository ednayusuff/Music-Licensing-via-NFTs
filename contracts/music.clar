
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


(define-map license-renewal-settings
  uint 
  {
    renewal-price: uint,
    renewal-duration: uint
  }
)

(define-public (set-renewal-terms (token-id uint) (price uint) (duration uint))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> duration u0) err-invalid-price)
    
    (map-set license-renewal-settings token-id {
      renewal-price: price,
      renewal-duration: duration
    })
    
    (ok true)
  )
)

(define-public (renew-license (token-id uint))
  (let ((settings (unwrap! (map-get? license-renewal-settings token-id) (err u101)))
        (rights (unwrap! (map-get? license-usage-rights token-id) err-token-not-found))
        (owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (try! (stx-transfer? (get renewal-price settings) tx-sender (get artist (unwrap! (get-royalty-info token-id) err-token-not-found))))
    
    (map-set license-usage-rights token-id 
      (merge rights { duration: (+ (get duration rights) (get renewal-duration settings)) }))
    
    (ok true)
  )
)


(define-map license-usage-log
  { token-id: uint, usage-id: uint }
  {
    user: principal,
    timestamp: uint,
    usage-type: (string-ascii 50),
    territory: (string-ascii 50)
  }
)

(define-data-var usage-counter uint u0)

(define-public (log-license-usage (token-id uint) (usage-type (string-ascii 50)) (territory (string-ascii 50)))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found))
        (rights (unwrap! (map-get? license-usage-rights token-id) err-token-not-found))
        (usage-id (+ (var-get usage-counter) u1)))
    
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (var-set usage-counter usage-id)
    
    (map-set license-usage-log 
      { token-id: token-id, usage-id: usage-id }
      {
        user: tx-sender,
        timestamp: stacks-block-height,
        usage-type: usage-type,
        territory: territory
      }
    )
    
    (ok usage-id)
  )
)

(define-read-only (get-usage-log (token-id uint) (usage-id uint))
  (map-get? license-usage-log { token-id: token-id, usage-id: usage-id })
)


(define-non-fungible-token collaborative-music-license uint)

(define-data-var last-collaborative-token-id uint u0)

(define-constant err-invalid-collaborator (err u200))
(define-constant err-invalid-percentage (err u201))
(define-constant err-not-collaborator (err u202))
(define-constant err-insufficient-approvals (err u203))
(define-constant err-collaborator-exists (err u204))
(define-constant err-cannot-remove-self (err u205))
(define-constant err-subscription-expired (err u206))
(define-constant err-subscription-not-found (err u207))
(define-constant err-invalid-subscription (err u208))
(define-constant err-subscription-already-exists (err u209))

(define-map collaborative-tokens
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creation-date: uint,
    license-type: (string-ascii 20),
    total-collaborators: uint,
    approval-threshold: uint
  }
)

(define-map collaborator-ownership
  { token-id: uint, collaborator: principal }
  {
    ownership-percentage: uint,
    is-active: bool,
    join-date: uint
  }
)

(define-map collaborator-approvals
  { token-id: uint, action-id: uint, collaborator: principal }
  bool
)

(define-map pending-actions
  { token-id: uint, action-id: uint }
  {
    action-type: (string-ascii 20),
    target-collaborator: principal,
    new-percentage: uint,
    approvals-count: uint,
    is-executed: bool,
    created-by: principal
  }
)

(define-data-var action-counter uint u0)

(define-map collaborative-listings
  uint
  {
    price: uint,
    approvals-count: uint,
    required-approvals: uint,
    is-active: bool
  }
)

(define-map listing-approvals
  { token-id: uint, collaborator: principal }
  bool
)

(define-read-only (get-collaborative-token (token-id uint))
  (map-get? collaborative-tokens token-id)
)

(define-read-only (get-collaborator-info (token-id uint) (collaborator principal))
  (map-get? collaborator-ownership { token-id: token-id, collaborator: collaborator })
)

(define-read-only (is-collaborator (token-id uint) (user principal))
  (match (map-get? collaborator-ownership { token-id: token-id, collaborator: user })
    ownership (get is-active ownership)
    false
  )
)

(define-read-only (get-collaborative-listing (token-id uint))
  (map-get? collaborative-listings token-id)
)

(define-public (create-collaborative-license 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (license-type (string-ascii 20))
  (collaborators (list 10 principal))
  (percentages (list 10 uint))
  (approval-threshold uint))
  
  (let ((token-id (+ (var-get last-collaborative-token-id) u1))
        (total-collaborators (len collaborators)))
    
    (asserts! (is-eq (len collaborators) (len percentages)) err-invalid-percentage)
    (asserts! (> total-collaborators u0) err-invalid-collaborator)
    (asserts! (<= approval-threshold total-collaborators) err-invalid-percentage)
    (asserts! (is-eq (fold + percentages u0) u100) err-invalid-percentage)
    
    (try! (nft-mint? collaborative-music-license token-id tx-sender))
    (var-set last-collaborative-token-id token-id)
    
    (map-set collaborative-tokens token-id {
      title: title,
      description: description,
      creation-date: stacks-block-height,
      license-type: license-type,
      total-collaborators: total-collaborators,
      approval-threshold: approval-threshold
    })
    
    ;; (try! (add-collaborators-helper token-id collaborators percentages))
    
    (ok token-id)
  )
)

;; (define-private (add-collaborators-helper (token-id uint) (collaborators (list 10 principal)) (percentages (list 10 uint)))
;;   (let ((zipped-collaborators (zip collaborators percentages)))
;;     (fold add-single-collaborator zipped-collaborators { token-id: token-id, success: true })
;;   )
;;   (ok true)
;; )

(define-private (add-single-collaborator 
  (collab-data { collaborator: principal, percentage: uint })
  (acc { token-id: uint, success: bool }))
  
  (if (get success acc)
    (begin
      (map-set collaborator-ownership 
        { token-id: (get token-id acc), collaborator: (get collaborator collab-data) }
        {
          ownership-percentage: (get percentage collab-data),
          is-active: true,
          join-date: stacks-block-height
        }
      )
      acc
    )
    acc
  )
)

(define-private (zip (list-a (list 10 principal)) (list-b (list 10 uint)))
  (map combine-elements list-a list-b)
)

(define-private (combine-elements (a principal) (b uint))
  { collaborator: a, percentage: b }
)

(define-public (propose-collaborator-change 
  (token-id uint)
  (action-type (string-ascii 20))
  (target-collaborator principal)
  (new-percentage uint))
  
  (let ((action-id (+ (var-get action-counter) u1))
        (token-info (unwrap! (map-get? collaborative-tokens token-id) err-token-not-found)))
    
    (asserts! (is-collaborator token-id tx-sender) err-not-collaborator)
    
    (var-set action-counter action-id)
    
    (map-set pending-actions 
      { token-id: token-id, action-id: action-id }
      {
        action-type: action-type,
        target-collaborator: target-collaborator,
        new-percentage: new-percentage,
        approvals-count: u1,
        is-executed: false,
        created-by: tx-sender
      }
    )
    
    (map-set collaborator-approvals 
      { token-id: token-id, action-id: action-id, collaborator: tx-sender }
      true
    )
    
    (ok action-id)
  )
)

(define-public (approve-collaborator-action (token-id uint) (action-id uint))
  (let ((action (unwrap! (map-get? pending-actions { token-id: token-id, action-id: action-id }) err-token-not-found))
        (token-info (unwrap! (map-get? collaborative-tokens token-id) err-token-not-found))
        (current-approvals (get approvals-count action)))
    
    (asserts! (is-collaborator token-id tx-sender) err-not-collaborator)
    (asserts! (not (get is-executed action)) err-unauthorized)
    (asserts! (is-none (map-get? collaborator-approvals { token-id: token-id, action-id: action-id, collaborator: tx-sender })) err-already-listed)
    
    (map-set collaborator-approvals 
      { token-id: token-id, action-id: action-id, collaborator: tx-sender }
      true
    )
    
    (let ((new-approvals (+ current-approvals u1)))
      (map-set pending-actions 
        { token-id: token-id, action-id: action-id }
        (merge action { approvals-count: new-approvals })
      )
      
      (if (>= new-approvals (get approval-threshold token-info))
        (execute-collaborator-action token-id action-id)
        (ok false)
      )
    )
  )
)
(define-private (execute-collaborator-action (token-id uint) (action-id uint))
  (let ((action (unwrap! (map-get? pending-actions { token-id: token-id, action-id: action-id }) err-token-not-found)))
    
    (if (is-eq (get action-type action) "add")
      (begin
        (map-set collaborator-ownership 
          { token-id: token-id, collaborator: (get target-collaborator action) }
          {
            ownership-percentage: (get new-percentage action),
            is-active: true,
            join-date: stacks-block-height
          }
        )
        (ok true)
      )
      (if (is-eq (get action-type action) "remove")
        (begin
          (map-set collaborator-ownership 
            { token-id: token-id, collaborator: (get target-collaborator action) }
            {
              ownership-percentage: u0,
              is-active: false,
              join-date: stacks-block-height
            }
          )
          (ok true)
        )
        (ok false)
      )
    )
  )
)

(define-public (propose-collaborative-sale (token-id uint) (price uint))
  (let ((token-info (unwrap! (map-get? collaborative-tokens token-id) err-token-not-found)))
    
    (asserts! (is-collaborator token-id tx-sender) err-not-collaborator)
    (asserts! (> price u0) err-invalid-price)
    
    (map-set collaborative-listings token-id {
      price: price,
      approvals-count: u1,
      required-approvals: (get approval-threshold token-info),
      is-active: true
    })
    
    (map-set listing-approvals 
      { token-id: token-id, collaborator: tx-sender }
      true
    )
    
    (ok true)
  )
)

(define-public (approve-collaborative-sale (token-id uint))
  (let ((listing (unwrap! (map-get? collaborative-listings token-id) err-not-listed))
        (current-approvals (get approvals-count listing)))
    
    (asserts! (is-collaborator token-id tx-sender) err-not-collaborator)
    (asserts! (get is-active listing) err-not-listed)
    (asserts! (is-none (map-get? listing-approvals { token-id: token-id, collaborator: tx-sender })) err-already-listed)
    
    (map-set listing-approvals 
      { token-id: token-id, collaborator: tx-sender }
      true
    )
    
    (map-set collaborative-listings token-id 
      (merge listing { approvals-count: (+ current-approvals u1) })
    )
    
    (ok true)
  )
)

(define-public (buy-collaborative-license (token-id uint))
  (let ((listing (unwrap! (map-get? collaborative-listings token-id) err-not-listed))
        (price (get price listing)))
    
    (asserts! (get is-active listing) err-not-listed)
    (asserts! (>= (get approvals-count listing) (get required-approvals listing)) err-insufficient-approvals)
    
    ;; (try! (distribute-collaborative-payment token-id price tx-sender))
    ;; (try! (nft-transfer? collaborative-music-license token-id (nft-get-owner? collaborative-music-license token-id) tx-sender))
    
    (map-delete collaborative-listings token-id)
    
    (ok true)
  )
)



(define-private (is-active-collaborator (collaborator principal) (token-id uint))
  (match (get-collaborator-info token-id collaborator)
    ownership (get is-active ownership)
    false
  )
)

(define-read-only (get-collaborator-list)
  (list
    contract-owner ;; Replace this with actual list of collaborators
  )
)
(define-private (distribute-to-collaborator 
  (collaborator principal) 
  (acc { token-id: uint, total: uint, buyer: principal }))
  
  (let ((ownership (unwrap! (map-get? collaborator-ownership { token-id: (get token-id acc), collaborator: collaborator }) err-token-not-found)))
    (let ((percentage (get ownership-percentage ownership))
          (amount (/ (* (get total acc) percentage) u100)))
      (try! (stx-transfer? amount (get buyer acc) collaborator))
      (ok acc)
    )
  )
)

(define-read-only (get-last-collaborative-token-id)
  (var-get last-collaborative-token-id)
)

(define-map license-subscriptions
  uint
  {
    monthly-price: uint,
    is-active: bool,
    subscriber-count: uint,
    created-at: uint
  }
)

(define-map subscription-records
  { token-id: uint, subscriber: principal }
  {
    start-date: uint,
    last-payment: uint,
    payment-amount: uint,
    is-active: bool
  }
)

(define-public (create-subscription-plan (token-id uint) (monthly-price uint))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found)))
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> monthly-price u0) err-invalid-price)
    (asserts! (is-none (map-get? license-subscriptions token-id)) err-subscription-already-exists)
    
    (map-set license-subscriptions token-id {
      monthly-price: monthly-price,
      is-active: true,
      subscriber-count: u0,
      created-at: stacks-block-height
    })
    
    (ok true)
  )
)

(define-public (subscribe-to-license (token-id uint))
  (let ((subscription-plan (unwrap! (map-get? license-subscriptions token-id) err-subscription-not-found))
        (owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found))
        (royalty-info (unwrap! (map-get? royalty-recipients token-id) err-token-not-found))
        (monthly-price (get monthly-price subscription-plan)))
    
    (asserts! (get is-active subscription-plan) err-invalid-subscription)
    (asserts! (is-none (map-get? subscription-records { token-id: token-id, subscriber: tx-sender })) err-subscription-already-exists)
    
    (try! (stx-transfer? monthly-price tx-sender owner))
    (try! (stx-transfer? (/ (* monthly-price (get percentage royalty-info)) u100) owner (get artist royalty-info)))
    
    (map-set subscription-records 
      { token-id: token-id, subscriber: tx-sender }
      {
        start-date: stacks-block-height,
        last-payment: stacks-block-height,
        payment-amount: monthly-price,
        is-active: true
      }
    )
    
    (map-set license-subscriptions token-id 
      (merge subscription-plan { subscriber-count: (+ (get subscriber-count subscription-plan) u1) })
    )
    
    (ok true)
  )
)

(define-public (renew-subscription (token-id uint))
  (let ((subscription-record (unwrap! (map-get? subscription-records { token-id: token-id, subscriber: tx-sender }) err-subscription-not-found))
        (subscription-plan (unwrap! (map-get? license-subscriptions token-id) err-subscription-not-found))
        (owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found))
        (royalty-info (unwrap! (map-get? royalty-recipients token-id) err-token-not-found))
        (monthly-price (get monthly-price subscription-plan)))
    
    (asserts! (get is-active subscription-record) err-subscription-expired)
    (asserts! (get is-active subscription-plan) err-invalid-subscription)
    
    (try! (stx-transfer? monthly-price tx-sender owner))
    (try! (stx-transfer? (/ (* monthly-price (get percentage royalty-info)) u100) owner (get artist royalty-info)))
    
    (map-set subscription-records 
      { token-id: token-id, subscriber: tx-sender }
      (merge subscription-record { last-payment: stacks-block-height })
    )
    
    (ok true)
  )
)

(define-public (cancel-subscription (token-id uint))
  (let ((subscription-record (unwrap! (map-get? subscription-records { token-id: token-id, subscriber: tx-sender }) err-subscription-not-found))
        (subscription-plan (unwrap! (map-get? license-subscriptions token-id) err-subscription-not-found)))
    
    (asserts! (get is-active subscription-record) err-subscription-expired)
    
    (map-set subscription-records 
      { token-id: token-id, subscriber: tx-sender }
      (merge subscription-record { is-active: false })
    )
    
    (map-set license-subscriptions token-id 
      (merge subscription-plan { subscriber-count: (- (get subscriber-count subscription-plan) u1) })
    )
    
    (ok true)
  )
)

(define-public (deactivate-subscription-plan (token-id uint))
  (let ((owner (unwrap! (nft-get-owner? music-license token-id) err-token-not-found))
        (subscription-plan (unwrap! (map-get? license-subscriptions token-id) err-subscription-not-found)))
    
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (map-set license-subscriptions token-id 
      (merge subscription-plan { is-active: false })
    )
    
    (ok true)
  )
)

(define-read-only (get-subscription-plan (token-id uint))
  (map-get? license-subscriptions token-id)
)

(define-read-only (get-subscription-status (token-id uint) (subscriber principal))
  (map-get? subscription-records { token-id: token-id, subscriber: subscriber })
)

(define-read-only (is-subscription-active (token-id uint) (subscriber principal))
  (match (map-get? subscription-records { token-id: token-id, subscriber: subscriber })
    record (and 
      (get is-active record)
      (< (- stacks-block-height (get last-payment record)) u4320)
    )
    false
  )
)