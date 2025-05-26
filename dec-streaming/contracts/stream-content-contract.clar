;; STREAMVAULT-PLATFORM - Complete Media Streaming Ecosystem
;; Full-featured platform with advanced monetization, queue management, and analytics

;; Comprehensive error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-USER-EXISTS u101)
(define-constant ERR-USER-NOT-FOUND u102)
(define-constant ERR-CONTENT-NOT-FOUND u103)
(define-constant ERR-SESSION-NOT-FOUND u104)
(define-constant ERR-PLAYLIST-FULL u105)
(define-constant ERR-CONTENT-UNAVAILABLE u106)
(define-constant ERR-INSUFFICIENT-CREDITS u107)
(define-constant ERR-QUEUE-FULL u108)
(define-constant ERR-SUBSCRIPTION-EXPIRED u109)
(define-constant ERR-INVALID-PAYMENT u110)

;; Platform constraints
(define-constant MAX-TITLE-LENGTH u1024)
(define-constant MAX-CREATOR-LENGTH u512)
(define-constant MAX-PLAYLIST-SIZE u50)
(define-constant MAX-QUEUE-SIZE u20)
(define-constant SESSION-DURATION u7200)
(define-constant PREMIUM-TIER u2)
(define-constant BASIC-TIER u1)

;; Comprehensive counters
(define-data-var total-users uint u0)
(define-data-var total-content uint u0)
(define-data-var total-sessions uint u0)
(define-data-var total-revenue uint u0)
(define-data-var platform-queue-count uint u0)

;; Advanced data structures
(define-map platform-users principal 
  {
    username: (string-ascii 50),
    active: bool,
    joined-at: uint,
    subscription-tier: uint,
    subscription-expires: uint,
    total-streams: uint,
    credits-balance: uint,
    revenue-earned: uint
  }
)

(define-map content-catalog uint 
  {
    title: (string-ascii 1024),
    creator: (string-ascii 512),
    uploader: principal,
    created-at: uint,
    available: bool,
    view-count: uint,
    category: (string-ascii 50),
    price-per-view: uint,
    total-earnings: uint,
    premium-only: bool
  }
)

(define-map streaming-sessions uint 
  {
    viewer: principal,
    content-id: uint,
    started-at: uint,
    ended-at: (optional uint),
    duration: uint,
    completed: bool,
    cost: uint,
    quality: (string-ascii 20)
  }
)

(define-map content-queue uint 
  {
    user: principal,
    content-id: uint,
    queued-at: uint,
    priority: uint,
    status: (string-ascii 20)
  }
)

(define-map user-playlists principal (list 50 uint))
(define-map user-queues principal (list 20 uint))
(define-map user-favorites principal (list 100 uint))

;; Revenue sharing pools
(define-map creator-earnings principal uint)
(define-map monthly-revenue uint uint)

;; Time and utility functions
(define-private (get-block-time)
  (default-to u0 (get-block-info? time u0))
)

(define-private (calculate-monthly-key)
  (/ (get-block-time) u2592000)
)

;; Comprehensive read-only functions
(define-read-only (get-user-profile (user principal))
  (map-get? platform-users user)
)

(define-read-only (get-content-details (content-id uint))
  (map-get? content-catalog content-id)
)

(define-read-only (get-session-info (session-id uint))
  (map-get? streaming-sessions session-id)
)

(define-read-only (get-queue-item (queue-id uint))
  (map-get? content-queue queue-id)
)

(define-read-only (get-user-playlist (user principal))
  (default-to (list) (map-get? user-playlists user))
)

(define-read-only (get-user-queue (user principal))
  (default-to (list) (map-get? user-queues user))
)

(define-read-only (get-user-favorites (user principal))
  (default-to (list) (map-get? user-favorites user))
)

(define-read-only (get-creator-earnings (creator principal))
  (default-to u0 (map-get? creator-earnings creator))
)

(define-read-only (get-platform-analytics)
  {
    total-users: (var-get total-users),
    total-content: (var-get total-content),
    total-sessions: (var-get total-sessions),
    platform-revenue: (var-get total-revenue),
    active-queues: (var-get platform-queue-count)
  }
)

(define-read-only (get-content-analytics (content-id uint))
  (match (get-content-details content-id)
    content-data (some {
      title: (get title content-data),
      views: (get view-count content-data),
      earnings: (get total-earnings content-data),
      category: (get category content-data),
      premium-content: (get premium-only content-data)
    })
    none
  )
)

(define-read-only (check-subscription-valid (user principal))
  (match (get-user-profile user)
    user-data (> (get subscription-expires user-data) (get-block-time))
    false
  )
)

;; Enhanced user registration with subscription
(define-public (register-premium-user (username (string-ascii 50)) (subscription-months uint))
  (let (
    (user tx-sender)
    (current-time (get-block-time))
    (expiry-time (+ current-time (* subscription-months u2592000)))
  )
    ;; Check if user already exists
    (asserts! (is-none (get-user-profile user)) (err ERR-USER-EXISTS))
    
    ;; Create premium user record
    (map-set platform-users user
      {
        username: username,
        active: true,
        joined-at: current-time,
        subscription-tier: PREMIUM-TIER,
        subscription-expires: expiry-time,
        total-streams: u0,
        credits-balance: u100,
        revenue-earned: u0
      }
    )
    
    ;; Initialize user collections
    (map-set user-playlists user (list))
    (map-set user-queues user (list))
    (map-set user-favorites user (list))
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

(define-public (register-basic-user (username (string-ascii 50)))
  (let (
    (user tx-sender)
    (current-time (get-block-time))
  )
    ;; Check if user already exists
    (asserts! (is-none (get-user-profile user)) (err ERR-USER-EXISTS))
    
    ;; Create basic user record
    (map-set platform-users user
      {
        username: username,
        active: true,
        joined-at: current-time,
        subscription-tier: BASIC-TIER,
        subscription-expires: u0,
        total-streams: u0,
        credits-balance: u10,
        revenue-earned: u0
      }
    )
    
    ;; Initialize user collections
    (map-set user-playlists user (list))
    (map-set user-queues user (list))
    (map-set user-favorites user (list))
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Premium content upload
(define-public (upload-premium-content (title (string-ascii 1024)) (creator (string-ascii 512)) (category (string-ascii 50)) (price uint))
  (let (
    (uploader tx-sender)
    (content-id (var-get total-content))
    (current-time (get-block-time))
    (user-data (unwrap! (get-user-profile uploader) (err ERR-USER-NOT-FOUND)))
  )
    ;; Verify premium subscription
    (asserts! (>= (get subscription-tier user-data) PREMIUM-TIER) (err ERR-NOT-AUTHORIZED))
    (asserts! (check-subscription-valid uploader) (err ERR-SUBSCRIPTION-EXPIRED))
    
    ;; Create premium content record
    (map-set content-catalog content-id
      {
        title: title,
        creator: creator,
        uploader: uploader,
        created-at: current-time,
        available: true,
        view-count: u0,
        category: category,
        price-per-view: price,
        total-earnings: u0,
        premium-only: true
      }
    )
    
    ;; Update counter
    (var-set total-content (+ content-id u1))
    (ok content-id)
  )
)

(define-public (upload-free-content (title (string-ascii 1024)) (creator (string-ascii 512)) (category (string-ascii 50)))
  (let (
    (uploader tx-sender)
    (content-id (var-get total-content))
    (current-time (get-block-time))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user-profile uploader)) (err ERR-USER-NOT-FOUND))
    
    ;; Create free content record
    (map-set content-catalog content-id
      {
        title: title,
        creator: creator,
        uploader: uploader,
        created-at: current-time,
        available: true,
        view-count: u0,
        category: category,
        price-per-view: u0,
        total-earnings: u0,
        premium-only: false
      }
    )
    
    ;; Update counter
    (var-set total-content (+ content-id u1))
    (ok content-id)
  )
)

;; Advanced streaming with payment
(define-public (start-premium-stream (content-id uint) (quality (string-ascii 20)))
  (let (
    (user tx-sender)
    (session-id (var-get total-sessions))
    (current-time (get-block-time))
    (content-data (unwrap! (get-content-details content-id) (err ERR-CONTENT-NOT-FOUND)))
    (user-data (unwrap! (get-user-profile user) (err ERR-USER-NOT-FOUND)))
    (stream-cost (get price-per-view content-data))
  )
    ;; Check content availability
    (asserts! (get available content-data) (err ERR-CONTENT-UNAVAILABLE))
    
    ;; Check premium access for premium content
    (if (get premium-only content-data)
        (asserts! (and (>= (get subscription-tier user-data) PREMIUM-TIER)
                      (check-subscription-valid user)) 
                 (err ERR-SUBSCRIPTION-EXPIRED))
        true)
    
    ;; Check credits for paid content
    (if (> stream-cost u0)
        (asserts! (>= (get credits-balance user-data) stream-cost) (err ERR-INSUFFICIENT-CREDITS))
        true)
    
    ;; Deduct credits if applicable
    (if (> stream-cost u0)
        (map-set platform-users user
          (merge user-data { 
            credits-balance: (- (get credits-balance user-data) stream-cost),
            total-streams: (+ (get total-streams user-data) u1)
          }))
        (map-set platform-users user
          (merge user-data { 
            total-streams: (+ (get total-streams user-data) u1)
          })))
    
    ;; Create streaming session
    (map-set streaming-sessions session-id
      {
        viewer: user,
        content-id: content-id,
        started-at: current-time,
        ended-at: none,
        duration: u0,
        completed: false,
        cost: stream-cost,
        quality: quality
      }
    )
    
    ;; Update content metrics
    (map-set content-catalog content-id
      (merge content-data { 
        view-count: (+ (get view-count content-data) u1),
        total-earnings: (+ (get total-earnings content-data) stream-cost)
      })
    )
    
    ;; Update creator earnings
    (let ((creator-share (/ (* stream-cost u70) u100)))
      (map-set creator-earnings (get uploader content-data)
        (+ (get-creator-earnings (get uploader content-data)) creator-share))
    )
    
    ;; Update platform revenue
    (var-set total-revenue (+ (var-get total-revenue) stream-cost))
    (var-set total-sessions (+ session-id u1))
    
    (ok session-id)
  )
)

;; End streaming session with analytics
(define-public (end-stream-session (session-id uint))
  (let (
    (user tx-sender)
    (session-data (unwrap! (get-session-info session-id) (err ERR-SESSION-NOT-FOUND)))
    (end-time (get-block-time))
    (duration (- end-time (get started-at session-data)))
  )
    ;; Verify session owner
    (asserts! (is-eq (get viewer session-data) user) (err ERR-NOT-AUTHORIZED))
    
    ;; Update session
    (map-set streaming-sessions session-id
      (merge session-data { 
        ended-at: (some end-time),
        duration: duration,
        completed: true
      })
    )
    
    (ok duration)
  )
)

;; Advanced queue management
(define-public (add-to-priority-queue (content-id uint) (priority uint))
  (let (
    (user tx-sender)
    (queue-id (var-get platform-queue-count))
    (current-time (get-block-time))
    (user-queue (get-user-queue user))
    (content-data (unwrap! (get-content-details content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user-profile user)) (err ERR-USER-NOT-FOUND))
    
    ;; Check queue size
    (asserts! (< (len user-queue) MAX-QUEUE-SIZE) (err ERR-QUEUE-FULL))
    
    ;; Create queue entry
    (map-set content-queue queue-id
      {
        user: user,
        content-id: content-id,
        queued-at: current-time,
        priority: priority,
        status: "pending"
      }
    )
    
    ;; Update user queue
    (map-set user-queues user
      (unwrap-panic (as-max-len? (append user-queue queue-id) u20))
    )
    
    ;; Update counters
    (var-set platform-queue-count (+ queue-id u1))
    (ok queue-id)
  )
)

;; Credits purchase system
(define-public (purchase-credits (amount uint))
  (let (
    (user tx-sender)
    (user-data (unwrap! (get-user-profile user) (err ERR-USER-NOT-FOUND)))
    (credit-cost (* amount u2))
  )
    ;; Verify payment (simplified - in real implementation would integrate with payment system)
    (asserts! (> amount u0) (err ERR-INVALID-PAYMENT))
    
    ;; Add credits to user balance
    (map-set platform-users user
      (merge user-data { 
        credits-balance: (+ (get credits-balance user-data) amount)
      })
    )
    
    (ok true)
  )
)

;; Subscription renewal
(define-public (renew-subscription (months uint))
  (let (
    (user tx-sender)
    (user-data (unwrap! (get-user-profile user) (err ERR-USER-NOT-FOUND)))
    (current-expiry (get subscription-expires user-data))
    (extension (* months u2592000))
    (new-expiry (if (> current-expiry (get-block-time))
                    (+ current-expiry extension)
                    (+ (get-block-time) extension)))
  )
    ;; Verify payment (simplified)
    (asserts! (> months u0) (err ERR-INVALID-PAYMENT))
    
    ;; Update subscription
    (map-set platform-users user
      (merge user-data { 
        subscription-expires: new-expiry,
        subscription-tier: PREMIUM-TIER
      })
    )
    
    (ok new-expiry)
  )
)

;; Favorites management
(define-public (add-to-favorites (content-id uint))
  (let (
    (user tx-sender)
    (current-favorites (get-user-favorites user))
    (content-data (unwrap! (get-content-details content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user-profile user)) (err ERR-USER-NOT-FOUND))
    
    ;; Add to favorites
    (map-set user-favorites user
      (unwrap-panic (as-max-len? (append current-favorites content-id) u100))
    )
    
    (ok true)
  )
)

;; Playlist management
(define-public (create-custom-playlist (content-ids (list 10 uint)))
  (let (
    (user tx-sender)
    (current-playlist (get-user-playlist user))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user-profile user)) (err ERR-USER-NOT-FOUND))
    
    ;; Verify playlist capacity
    (asserts! (<= (+ (len current-playlist) (len content-ids)) MAX-PLAYLIST-SIZE) (err ERR-PLAYLIST-FULL))
    
    ;; Add all content to playlist
    (map-set user-playlists user
      (unwrap-panic (as-max-len? (concat current-playlist content-ids) u50))
    )
    
    (ok true)
  )
)

;; Content moderation
(define-public (report-content (content-id uint) (reason (string-ascii 100)))
  (let (
    (reporter tx-sender)
    (content-data (unwrap! (get-content-details content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user-profile reporter)) (err ERR-USER-NOT-FOUND))
    
    ;; Temporarily disable content pending review
    (map-set content-catalog content-id
      (merge content-data { available: false })
    )
    
    (ok true)
  )
)

;; Creator payout system
(define-public (withdraw-creator-earnings)
  (let (
    (creator tx-sender)
    (earnings (get-creator-earnings creator))
    (user-data (unwrap! (get-user-profile creator) (err ERR-USER-NOT-FOUND)))
  )
    ;; Verify earnings exist
    (asserts! (> earnings u0) (err ERR-INSUFFICIENT-CREDITS))
    
    ;; Reset creator earnings
    (map-set creator-earnings creator u0)
    
    ;; Update user revenue earned
    (map-set platform-users creator
      (merge user-data { 
        revenue-earned: (+ (get revenue-earned user-data) earnings)
      })
    )
    
    (ok earnings)
  )
)

;; Advanced analytics functions
(define-read-only (get-user-analytics (user principal))
  (match (get-user-profile user)
    user-data (some {
      username: (get username user-data),
      total-streams: (get total-streams user-data),
      credits-balance: (get credits-balance user-data),
      revenue-earned: (get revenue-earned user-data),
      subscription-tier: (get subscription-tier user-data),
      subscription-active: (check-subscription-valid user),
      playlist-count: (len (get-user-playlist user)),
      queue-count: (len (get-user-queue user)),
      favorites-count: (len (get-user-favorites user))
    })
    none
  )
)

(define-read-only (get-trending-content)
  {
    total-content: (var-get total-content),
    total-sessions: (var-get total-sessions),
    platform-revenue: (var-get total-revenue)
  }
)

;; Platform health monitoring
(define-read-only (get-platform-health)
  {
    system-status: "operational",
    total-users: (var-get total-users),
    active-content: (var-get total-content),
    streaming-sessions: (var-get total-sessions),
    revenue-generated: (var-get total-revenue),
    queue-backlog: (var-get platform-queue-count),
    current-timestamp: (get-block-time)
  }
)

;; Emergency functions
(define-public (emergency-pause-content (content-id uint))
  (let (
    (admin tx-sender)
    (content-data (unwrap! (get-content-details content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Only content uploader or platform admin can pause
    (asserts! (is-eq (get uploader content-data) admin) (err ERR-NOT-AUTHORIZED))
    
    ;; Pause content
    (map-set content-catalog content-id
      (merge content-data { available: false })
    )
    
    (ok true)
  )
)

;; Queue processing helper
(define-private (process-queue-item (queue-id uint))
  (match (get-queue-item queue-id)
    queue-data (map-set content-queue queue-id
                 (merge queue-data { status: "processed" }))
    false
  )
)

;; Monthly revenue tracking
(define-private (update-monthly-revenue (amount uint))
  (let (
    (current-month (calculate-monthly-key))
    (current-revenue (default-to u0 (map-get? monthly-revenue current-month)))
  )
    (map-set monthly-revenue current-month (+ current-revenue amount))
  )
)