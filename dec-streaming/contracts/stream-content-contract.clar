;; STREAMVAULT-CORE - Basic Media Streaming Contract
;; Initial implementation with essential subscriber and content management

;; Basic error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-USER-EXISTS u101)
(define-constant ERR-USER-NOT-FOUND u102)
(define-constant ERR-CONTENT-NOT-FOUND u103)

;; Simple constraints
(define-constant MAX-TITLE-LENGTH u512)
(define-constant MAX-CREATOR-LENGTH u256)

;; Basic counters
(define-data-var total-users uint u0)
(define-data-var total-content uint u0)

;; Core data structures
(define-map users principal 
  {
    username: (string-ascii 50),
    active: bool,
    joined-at: uint
  }
)

(define-map content-items uint 
  {
    title: (string-ascii 512),
    creator: (string-ascii 256),
    uploader: principal,
    created-at: uint,
    available: bool
  }
)

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

(define-read-only (get-platform-stats)
  {
    users: (var-get total-users),
    content: (var-get total-content)
  }
)

;; User registration
(define-public (register-user (username (string-ascii 50)))
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
        joined-at: current-time
      }
    )
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Content upload
(define-public (upload-content (title (string-ascii 512)) (creator (string-ascii 256)))
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
        available: true
      }
    )
    
    ;; Update counter
    (var-set total-content (+ content-id u1))
    (ok content-id)
  )
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