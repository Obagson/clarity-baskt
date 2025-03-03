;; Baskt - Shopping Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-shared (err u103))
(define-constant err-invalid-operation (err u104))
(define-constant err-list-full (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-invalid-quantity (err u107))
(define-constant err-invalid-item-index (err u108))

;; Data Variables 
(define-data-var total-users uint u0)
(define-data-var total-lists uint u0)

;; Data Maps
(define-map Users principal 
  {
    username: (string-ascii 50),
    email: (string-ascii 100),
    created-at: uint,
    last-modified: uint
  }
)

(define-map ShoppingLists uint 
  {
    owner: principal,
    name: (string-ascii 50),
    store: (string-ascii 50),
    items: (list 50 {
      name: (string-ascii 100),
      quantity: uint,
      price: uint,
      purchased: bool,
      category: (string-ascii 20)
    }),
    shared-with: (list 10 principal),
    created-at: uint,
    last-modified: uint,
    version: uint
  }
)

;; Helper Functions
(define-private (is-list-owner (list-id uint))
  (let ((list (unwrap! (map-get? ShoppingLists list-id) false)))
    (is-eq (get owner list) tx-sender))
)

(define-private (can-modify-list (list-id uint))
  (let ((list (unwrap! (map-get? ShoppingLists list-id) false)))
    (or
      (is-eq (get owner list) tx-sender)
      (is-some (index-of? (get shared-with list) tx-sender))
    )
  )
)

(define-private (validate-item-input (quantity uint) (price uint))
  (and
    (> quantity u0)
    (>= price u0)
  )
)

;; Read-only Functions
(define-read-only (get-shopping-list (list-id uint))
  (map-get? ShoppingLists list-id)
)

(define-read-only (get-user-lists (user principal))
  (filter map-get? ShoppingLists
    (lambda (list-id)
      (let ((list (unwrap! (map-get? ShoppingLists list-id) false)))
        (or
          (is-eq (get owner list) user)
          (is-some (index-of? (get shared-with list) user))
        )
      )
    )
  )
)

;; Enhanced List Management Functions
(define-public (update-list-item 
  (list-id uint) 
  (item-index uint)
  (name (string-ascii 100))
  (quantity uint)
  (price uint)
  (category (string-ascii 20)))
  (let
    ((current-list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (if (not (validate-item-input quantity price))
      err-invalid-operation
      (if (can-modify-list list-id)
        (let
          ((updated-items (unwrap! 
            (as-max-len? 
              (map-set-at? (get items current-list) 
                item-index
                {
                  name: name,
                  quantity: quantity,
                  price: price,
                  purchased: false,
                  category: category
                }
              )
              u50
            )
            err-list-full)))
          (ok (map-set ShoppingLists list-id
            (merge current-list 
              {
                items: updated-items,
                last-modified: block-height,
                version: (+ (get version current-list) u1)
              }
            ))))
        err-unauthorized
      )
    )
  )
)

;; Batch Operations
(define-public (batch-update-items
  (list-id uint)
  (items (list 50 {
    name: (string-ascii 100),
    quantity: uint,
    price: uint,
    category: (string-ascii 20)
  })))
  (let
    ((current-list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (if (can-modify-list list-id)
      (let
        ((validated-items (map
          (lambda (item)
            (merge item { purchased: false })
          )
          items
        )))
        (ok (map-set ShoppingLists list-id
          (merge current-list
            {
              items: validated-items,
              last-modified: block-height,
              version: (+ (get version current-list) u1)
            }
          ))))
      err-unauthorized
    )
  )
)

;; [Previous functions remain unchanged...]
