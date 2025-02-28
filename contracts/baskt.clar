;; Baskt - Shopping Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-shared (err u103))
(define-constant err-invalid-operation (err u104))
(define-constant err-list-full (err u105))

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

;; Existing maps remain unchanged...

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

(define-public (delete-list-item (list-id uint) (item-index uint))
  (let
    ((current-list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (if (can-modify-list list-id)
      (let
        ((updated-items (unwrap!
          (as-max-len?
            (concat
              (take item-index (get items current-list))
              (drop (+ item-index u1) (get items current-list))
            )
            u50
          )
          err-invalid-operation)))
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

;; Existing functions modified to include versioning...

(define-public (create-shopping-list (name (string-ascii 50)) (store (string-ascii 50)))
  (let
    ((new-list-id (var-get total-lists))
     (list-data {
      owner: tx-sender,
      name: name,
      store: store,
      items: (list),
      shared-with: (list),
      created-at: block-height,
      last-modified: block-height,
      version: u1
    }))
    (begin
      (map-set ShoppingLists new-list-id list-data)
      (var-set total-lists (+ new-list-id u1))
      (ok new-list-id)
    )
  )
)

;; Other existing functions remain unchanged...
