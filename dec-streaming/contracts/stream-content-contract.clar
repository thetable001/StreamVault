;; STREAMVAULT-ENHANCED - Advanced Media Streaming Platform
;; Enhanced version with streaming sessions, playlists, and basic analytics

;; Enhanced error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-USER-EXISTS u101)
(define-constant ERR-USER-NOT-FOUND u102)
(define-constant ERR-CONTENT-NOT-FOUND u103)
(define-constant ERR-SESSION-NOT-FOUND u104)
(define-constant ERR-PLAYLIST-FULL u105)
(define-constant ERR-CONTENT-UNAVAILABLE u106)

;; Enhanced constraints
(define-constant MAX-TITLE-LENGTH u512)
(define-constant MAX-CREATOR-LENGTH u256)
(define-constant MAX-PLAYLIST-SIZE u25)
(define-constant SESSION-DURATION u3600)

;; Enhanced counters
(define-data-var total-users uint u0)
(define-data-var total-content uint u0)
(define-data-var total-sessions uint u0)

;; Enhanced data structures
(define-map users principal 
  {
    username: (string-ascii 50),
    active: bool,
    joined-at: uint,
    subscription-tier: uint,
    total-streams: uint
  }
)

(define-map content-items uint 
  {
    title: (string-ascii 512),
    creator: (string-ascii 256),
    uploader: principal,
    created-at: uint,
    available: bool,
    view-count: uint,
    category: (string-ascii 50)
  }
)

(define-map streaming-sessions uint 
  {
    user: principal,
    content-id: uint,
    started-at: uint,
    duration: uint,
    completed: bool
  }
)

(define-map user-playlists principal (list 25 uint))

;; Time utility
(define-private (get-block-time)
  (default-to u0 (get-block-info? time u0))
)

;; Read-only functions
(define-read-only (get-user (user principal))
  (map-get? users user)
)

(define-read-only (get-content (content-id uint))
  (map-get? content-items content-id)
)

(define-read-only (get-session (session-id uint))
  (map-get? streaming-sessions session-id)
)

(define-read-only (get-user-playlist (user principal))
  (default-to (list) (map-get? user-playlists user))
)

(define-read-only (get-platform-stats)
  {
    users: (var-get total-users),
    content: (var-get total-content),
    sessions: (var-get total-sessions)
  }
)

(define-read-only (get-content-stats (content-id uint))
  (match (get-content content-id)
    content-data (some {
      title: (get title content-data),
      views: (get view-count content-data),
      available: (get available content-data)
    })
    none
  )
)

;; User registration with tier
(define-public (register-user (username (string-ascii 50)) (tier uint))
  (let (
    (user tx-sender)
    (current-time (get-block-time))
  )
    ;; Check if user already exists
    (asserts! (is-none (get-user user)) (err ERR-USER-EXISTS))
    
    ;; Create user record
    (map-set users user
      {
        username: username,
        active: true,
        joined-at: current-time,
        subscription-tier: tier,
        total-streams: u0
      }
    )
    
    ;; Initialize playlist
    (map-set user-playlists user (list))
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Enhanced content upload with category
(define-public (upload-content (title (string-ascii 512)) (creator (string-ascii 256)) (category (string-ascii 50)))
  (let (
    (uploader tx-sender)
    (content-id (var-get total-content))
    (current-time (get-block-time))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user uploader)) (err ERR-USER-NOT-FOUND))
    
    ;; Create content record
    (map-set content-items content-id
      {
        title: title,
        creator: creator,
        uploader: uploader,
        created-at: current-time,
        available: true,
        view-count: u0,
        category: category
      }
    )
    
    ;; Update counter
    (var-set total-content (+ content-id u1))
    (ok content-id)
  )
)

;; Start streaming session
(define-public (start-stream (content-id uint))
  (let (
    (user tx-sender)
    (session-id (var-get total-sessions))
    (current-time (get-block-time))
    (content-data (unwrap! (get-content content-id) (err ERR-CONTENT-NOT-FOUND)))
    (user-data (unwrap! (get-user user) (err ERR-USER-NOT-FOUND)))
  )
    ;; Check content availability
    (asserts! (get available content-data) (err ERR-CONTENT-UNAVAILABLE))
    
    ;; Create streaming session
    (map-set streaming-sessions session-id
      {
        user: user,
        content-id: content-id,
        started-at: current-time,
        duration: u0,
        completed: false
      }
    )
    
    ;; Update user stream count
    (map-set users user
      (merge user-data { total-streams: (+ (get total-streams user-data) u1) })
    )
    
    ;; Update content view count
    (map-set content-items content-id
      (merge content-data { view-count: (+ (get view-count content-data) u1) })
    )
    
    ;; Update session counter
    (var-set total-sessions (+ session-id u1))
    (ok session-id)
  )
)

;; End streaming session
(define-public (end-stream (session-id uint) (duration uint))
  (let (
    (user tx-sender)
    (session-data (unwrap! (get-session session-id) (err ERR-SESSION-NOT-FOUND)))
  )
    ;; Verify session owner
    (asserts! (is-eq (get user session-data) user) (err ERR-NOT-AUTHORIZED))
    
    ;; Update session
    (map-set streaming-sessions session-id
      (merge session-data { 
        duration: duration,
        completed: true
      })
    )
    
    (ok true)
  )
)

;; Add to playlist
(define-public (add-to-playlist (content-id uint))
  (let (
    (user tx-sender)
    (current-playlist (get-user-playlist user))
    (content-data (unwrap! (get-content content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user user)) (err ERR-USER-NOT-FOUND))
    
    ;; Check playlist size
    (asserts! (< (len current-playlist) MAX-PLAYLIST-SIZE) (err ERR-PLAYLIST-FULL))
    
    ;; Add to playlist
    (map-set user-playlists user
      (unwrap-panic (as-max-len? (append current-playlist content-id) u25))
    )
    
    (ok true)
  )
)

;; Remove from playlist
(define-public (remove-from-playlist (content-id uint))
  (let (
    (user tx-sender)
    (current-playlist (get-user-playlist user))
  )
    ;; Verify user exists
    (asserts! (is-some (get-user user)) (err ERR-USER-NOT-FOUND))
    
    ;; Filter out the content
    (map-set user-playlists user
      (filter remove-content-filter current-playlist)
    )
    
    (ok true)
  )
)

;; Helper function for playlist filtering
(define-private (remove-content-filter (item uint))
  (not (is-eq item (var-get total-content)))
)

;; Toggle content availability
(define-public (toggle-content-availability (content-id uint))
  (let (
    (user tx-sender)
    (content-data (unwrap! (get-content content-id) (err ERR-CONTENT-NOT-FOUND)))
  )
    ;; Only uploader can toggle
    (asserts! (is-eq (get uploader content-data) user) (err ERR-NOT-AUTHORIZED))
    
    ;; Toggle availability
    (map-set content-items content-id
      (merge content-data { available: (not (get available content-data)) })
    )
    
    (ok true)
  )
)

;; Update user subscription tier
(define-public (update-subscription-tier (new-tier uint))
  (let (
    (user tx-sender)
    (user-data (unwrap! (get-user user) (err ERR-USER-NOT-FOUND)))
  )
    ;; Update tier
    (map-set users user
      (merge user-data { subscription-tier: new-tier })
    )
    
    (ok true)
  )
)