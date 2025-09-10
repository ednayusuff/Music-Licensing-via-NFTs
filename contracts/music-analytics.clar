;; Music License Analytics Contract
;; Provides performance tracking and insights for music licenses

;; Error constants
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-invalid-parameters (err u103))
(define-constant err-unauthorized (err u104))

;; Contract constants
(define-constant contract-owner tx-sender)

;; License performance tracking
(define-map license-stats
  uint
  {
    total-views: uint,
    total-revenue: uint,
    last-activity: uint,
    popularity-score: uint
  }
)

;; Daily revenue tracking for licenses
(define-map daily-license-revenue
  { license-id: uint, day: uint }
  {
    revenue: uint,
    transaction-count: uint
  }
)

;; Geographic usage distribution
(define-map geographic-usage
  { license-id: uint, region: (string-ascii 10) }
  {
    usage-count: uint,
    revenue: uint,
    last-usage: uint
  }
)

;; Artist performance aggregates
(define-map artist-analytics
  principal
  {
    total-revenue: uint,
    active-licenses: uint,
    total-views: uint,
    last-updated: uint
  }
)

;; License popularity rankings (simplified)
(define-map license-rankings
  uint
  {
    rank: uint,
    score: uint,
    updated-at: uint
  }
)

;; Top performing licenses list (top 10)
(define-data-var top-licenses (list 10 uint) (list))

;; Read-only functions
(define-read-only (get-license-stats (license-id uint))
  (map-get? license-stats license-id)
)

(define-read-only (get-daily-revenue (license-id uint) (day uint))
  (map-get? daily-license-revenue { license-id: license-id, day: day })
)

(define-read-only (get-geographic-usage (license-id uint) (region (string-ascii 10)))
  (map-get? geographic-usage { license-id: license-id, region: region })
)

(define-read-only (get-artist-analytics (artist principal))
  (map-get? artist-analytics artist)
)

(define-read-only (get-license-ranking (license-id uint))
  (map-get? license-rankings license-id)
)

(define-read-only (get-top-licenses)
  (var-get top-licenses)
)

;; Record license view/usage event
(define-public (record-license-view (license-id uint) (region (string-ascii 10)))
  (let ((current-stats (default-to 
                         { total-views: u0, total-revenue: u0, last-activity: u0, popularity-score: u0 }
                         (map-get? license-stats license-id)))
        (current-geo (default-to
                       { usage-count: u0, revenue: u0, last-usage: u0 }
                       (map-get? geographic-usage { license-id: license-id, region: region }))))
    
    ;; Update license stats
    (map-set license-stats license-id
      (merge current-stats {
        total-views: (+ (get total-views current-stats) u1),
        last-activity: stacks-block-height,
        popularity-score: (calculate-popularity-score license-id (+ (get total-views current-stats) u1) (get total-revenue current-stats))
      })
    )
    
    ;; Update geographic usage
    (map-set geographic-usage { license-id: license-id, region: region }
      (merge current-geo {
        usage-count: (+ (get usage-count current-geo) u1),
        last-usage: stacks-block-height
      })
    )
    
    ;; Update rankings if needed
    (try! (update-license-ranking license-id))
    
    (ok true)
  )
)

;; Record revenue event for a license
(define-public (record-license-revenue (license-id uint) (amount uint) (region (string-ascii 10)))
  (let ((current-stats (default-to 
                         { total-views: u0, total-revenue: u0, last-activity: u0, popularity-score: u0 }
                         (map-get? license-stats license-id)))
        (day (/ stacks-block-height u144)) ;; Approximate daily buckets
        (current-daily (default-to
                         { revenue: u0, transaction-count: u0 }
                         (map-get? daily-license-revenue { license-id: license-id, day: day })))
        (current-geo (default-to
                       { usage-count: u0, revenue: u0, last-usage: u0 }
                       (map-get? geographic-usage { license-id: license-id, region: region }))))
    
    (asserts! (> amount u0) err-invalid-parameters)
    
    ;; Update license stats
    (map-set license-stats license-id
      (merge current-stats {
        total-revenue: (+ (get total-revenue current-stats) amount),
        last-activity: stacks-block-height,
        popularity-score: (calculate-popularity-score license-id (get total-views current-stats) (+ (get total-revenue current-stats) amount))
      })
    )
    
    ;; Update daily revenue
    (map-set daily-license-revenue { license-id: license-id, day: day }
      (merge current-daily {
        revenue: (+ (get revenue current-daily) amount),
        transaction-count: (+ (get transaction-count current-daily) u1)
      })
    )
    
    ;; Update geographic revenue
    (map-set geographic-usage { license-id: license-id, region: region }
      (merge current-geo {
        revenue: (+ (get revenue current-geo) amount),
        last-usage: stacks-block-height
      })
    )
    
    ;; Update rankings
    (try! (update-license-ranking license-id))
    
    (ok true)
  )
)

;; Update artist analytics
(define-public (update-artist-stats (artist principal) (license-count uint))
  (let ((current-stats (default-to
                         { total-revenue: u0, active-licenses: u0, total-views: u0, last-updated: u0 }
                         (map-get? artist-analytics artist))))
    
    (map-set artist-analytics artist
      (merge current-stats {
        active-licenses: license-count,
        last-updated: stacks-block-height
      })
    )
    
    (ok true)
  )
)

;; Calculate popularity score (simplified algorithm)
(define-private (calculate-popularity-score (license-id uint) (views uint) (revenue uint))
  (+ (* views u2) (/ revenue u1000))
)

;; Update license ranking
(define-private (update-license-ranking (license-id uint))
  (let ((stats (unwrap! (map-get? license-stats license-id) err-token-not-found))
        (score (get popularity-score stats)))
    
    (map-set license-rankings license-id {
      rank: u0, ;; Simplified - would need full ranking algorithm
      score: score,
      updated-at: stacks-block-height
    })
    
    (ok true)
  )
)

;; Get revenue trend for a license over multiple days
(define-read-only (get-revenue-trend (license-id uint) (start-day uint) (end-day uint))
  (if (<= start-day end-day)
    (some { 
      start-day: start-day, 
      end-day: end-day,
      total-days: (- end-day start-day)
    })
    none
  )
)

;; Get license performance summary
(define-read-only (get-license-performance (license-id uint))
  (match (map-get? license-stats license-id)
    stats (some {
      views: (get total-views stats),
      revenue: (get total-revenue stats),
      popularity: (get popularity-score stats),
      active: (< (- stacks-block-height (get last-activity stats)) u1440) ;; Active in last ~10 days
    })
    none
  )
)

;; Get top regions for a license
(define-read-only (get-top-regions (license-id uint))
  ;; Simplified - returns sample regions
  (list "US" "EU" "ASIA")
)
