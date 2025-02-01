;; Baskt - Shopping Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-shared (err u103))

;; Data Variables 
(define-data-var total-users uint u0)

;; Data Maps
(define-map Users principal 
  {
    username: (string-ascii 50),
    email: (string-ascii 100),
    created-at: uint
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
      purchased: bool
    }),
    shared-with: (list 10 principal),
    created-at: uint
  }
)

(define-map ShippingAddresses principal
  {
    addresses: (list 10 {
      label: (string-ascii 20),
      street: (string-ascii 100),
      city: (string-ascii 50),
      state: (string-ascii 20),
      zip: (string-ascii 10),
      country: (string-ascii 50)
    })
  }
)

(define-map Orders uint
  {
    owner: principal,
    store: (string-ascii 50),
    items: (list 50 {
      name: (string-ascii 100),
      quantity: uint,
      price: uint
    }),
    status: (string-ascii 20),
    shipping-address: uint,
    created-at: uint
  }
)

;; Public Functions
(define-public (create-profile (username (string-ascii 50)) (email (string-ascii 100)))
  (let
    ((user-data {
      username: username,
      email: email,
      created-at: block-height
    }))
    (begin
      (map-set Users tx-sender user-data)
      (var-set total-users (+ (var-get total-users) u1))
      (ok true)
    )
  )
)

(define-public (create-shopping-list (name (string-ascii 50)) (store (string-ascii 50)))
  (let
    ((new-list-id (var-get total-users))
     (list-data {
      owner: tx-sender,
      name: name,
      store: store,
      items: (list),
      shared-with: (list),
      created-at: block-height
    }))
    (begin
      (map-set ShoppingLists new-list-id list-data)
      (ok new-list-id)
    )
  )
)

(define-public (share-shopping-list (list-id uint) (user principal))
  (let 
    ((current-list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (if (and
          (is-eq (get owner current-list) tx-sender)
          (not (is-some (index-of? (get shared-with current-list) user))))
      (ok (map-set ShoppingLists list-id
        (merge current-list 
          {shared-with: (unwrap! (as-max-len? 
            (append (get shared-with current-list) user) u10) 
            err-unauthorized)})))
      err-unauthorized
    )
  )
)

(define-public (unshare-shopping-list (list-id uint) (user principal))
  (let
    ((current-list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (if (is-eq (get owner current-list) tx-sender)
      (ok (map-set ShoppingLists list-id
        (merge current-list
          {shared-with: (filter not-user (get shared-with current-list))})))
      err-unauthorized
    )
  )
)

(define-private (not-user (p principal))
  (not (is-eq p tx-sender)))

(define-read-only (can-access-list (list-id uint) (user principal))
  (let
    ((list (unwrap! (map-get? ShoppingLists list-id) err-not-found)))
    (ok (or
      (is-eq (get owner list) user)
      (is-some (index-of? (get shared-with list) user))))))

(define-public (add-shipping-address 
    (label (string-ascii 20))
    (street (string-ascii 100))
    (city (string-ascii 50))
    (state (string-ascii 20))
    (zip (string-ascii 10))
    (country (string-ascii 50)))
  (let
    ((new-address {
      label: label,
      street: street,
      city: city,
      state: state,
      zip: zip,
      country: country
    })
     (current-addresses (default-to {addresses: (list)} (map-get? ShippingAddresses tx-sender))))
    (ok (map-set ShippingAddresses tx-sender 
      {addresses: (unwrap! (as-max-len? (append (get addresses current-addresses) new-address) u10) err-unauthorized)}))
  )
)

(define-public (create-order 
    (store (string-ascii 50))
    (items (list 50 {
      name: (string-ascii 100),
      quantity: uint,
      price: uint
    }))
    (shipping-address-id uint))
  (let
    ((order-id (var-get total-users))
     (order-data {
      owner: tx-sender,
      store: store,
      items: items,
      status: "pending",
      shipping-address: shipping-address-id,
      created-at: block-height
    }))
    (begin
      (map-set Orders order-id order-data)
      (ok order-id)
    )
  )
)

;; Read Only Functions
(define-read-only (get-profile (user principal))
  (ok (map-get? Users user))
)

(define-read-only (get-shopping-list (list-id uint))
  (ok (map-get? ShoppingLists list-id))
)

(define-read-only (get-shipping-addresses)
  (ok (map-get? ShippingAddresses tx-sender))
)

(define-read-only (get-order (order-id uint))
  (ok (map-get? Orders order-id))
)
