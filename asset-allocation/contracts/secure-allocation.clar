;; Resource Allocation Contract
;; Handles resource distribution and management with robust security features

;; Constants
(define-constant CONTRACT_ADMINISTRATOR tx-sender)
(define-constant ERROR_UNAUTHORIZED_ACCESS (err u1))
(define-constant ERROR_INVALID_RESOURCE_AMOUNT (err u2))
(define-constant ERROR_INSUFFICIENT_RESOURCE_BALANCE (err u3))
(define-constant ERROR_RESOURCE_IDENTIFIER_NOT_FOUND (err u4))
(define-constant ERROR_RESOURCE_ALLOCATION_EXISTS (err u5))
(define-constant ERROR_INVALID_RESOURCE_IDENTIFIER (err u6))
(define-constant ERROR_INVALID_RESOURCE_NAME (err u7))
(define-constant MAX_RESOURCE_IDENTIFIER u1000000)
(define-constant MIN_RESOURCE_NAME_LENGTH u1)

;; Data Maps
(define-map managed-resource-types
    { resource-identifier: uint }
    { 
        resource-name: (string-ascii 64),
        resource-total-supply: uint,
        resource-available-amount: uint
    }
)

(define-map resource-allocation-records
    { resource-holder: principal, resource-identifier: uint }
    {
        allocated-amount: uint,
        allocation-timestamp: uint,
        allocation-status: (string-ascii 20)
    }
)

(define-map resource-holder-statistics
    { resource-holder: principal }
    { lifetime-allocation-count: uint }
)

;; Private Functions
(define-private (is-administrator-call)
    (is-eq tx-sender CONTRACT_ADMINISTRATOR)
)

(define-private (verify-resource-exists (resource-identifier uint))
    (match (map-get? managed-resource-types { resource-identifier: resource-identifier })
        resource-data true
        false
    )
)

(define-private (validate-resource-identifier (resource-identifier uint))
    (and 
        (> resource-identifier u0)
        (<= resource-identifier MAX_RESOURCE_IDENTIFIER)
    )
)

(define-private (validate-resource-name (resource-name (string-ascii 64)))
    (>= (len resource-name) MIN_RESOURCE_NAME_LENGTH)
)

(define-private (update-resource-inventory (resource-identifier uint) (modification-amount uint) (is-increment bool))
    (begin
        (asserts! (validate-resource-identifier resource-identifier) ERROR_INVALID_RESOURCE_IDENTIFIER)
        (match (map-get? managed-resource-types { resource-identifier: resource-identifier })
            existing-resource (begin
                (if is-increment
                    (map-set managed-resource-types
                        { resource-identifier: resource-identifier }
                        {
                            resource-name: (get resource-name existing-resource),
                            resource-total-supply: (get resource-total-supply existing-resource),
                            resource-available-amount: (+ (get resource-available-amount existing-resource) modification-amount)
                        })
                    (map-set managed-resource-types
                        { resource-identifier: resource-identifier }
                        {
                            resource-name: (get resource-name existing-resource),
                            resource-total-supply: (get resource-total-supply existing-resource),
                            resource-available-amount: (- (get resource-available-amount existing-resource) modification-amount)
                        })
                )
                (ok true))
            ERROR_RESOURCE_IDENTIFIER_NOT_FOUND
        )
    )
)

;; Public Functions
(define-public (register-new-resource-type (resource-identifier uint) (resource-name (string-ascii 64)) (initial-resource-supply uint))
    (begin
        (asserts! (is-administrator-call) ERROR_UNAUTHORIZED_ACCESS)
        (asserts! (validate-resource-identifier resource-identifier) ERROR_INVALID_RESOURCE_IDENTIFIER)
        (asserts! (validate-resource-name resource-name) ERROR_INVALID_RESOURCE_NAME)
        (asserts! (not (verify-resource-exists resource-identifier)) ERROR_RESOURCE_ALLOCATION_EXISTS)
        (asserts! (> initial-resource-supply u0) ERROR_INVALID_RESOURCE_AMOUNT)
        
        (map-set managed-resource-types
            { resource-identifier: resource-identifier }
            {
                resource-name: resource-name,
                resource-total-supply: initial-resource-supply,
                resource-available-amount: initial-resource-supply
            }
        )
        (ok true)
    )
)

(define-public (submit-resource-allocation-request (resource-identifier uint) (requested-amount uint))
    (begin
        (asserts! (validate-resource-identifier resource-identifier) ERROR_INVALID_RESOURCE_IDENTIFIER)
        (let (
            (resource-data (unwrap! (map-get? managed-resource-types { resource-identifier: resource-identifier }) 
                ERROR_RESOURCE_IDENTIFIER_NOT_FOUND))
            (current-block-height block-height)
        )
            (asserts! (>= (get resource-available-amount resource-data) requested-amount) 
                ERROR_INSUFFICIENT_RESOURCE_BALANCE)
            (asserts! (> requested-amount u0) ERROR_INVALID_RESOURCE_AMOUNT)
            
            ;; Update resource availability
            (unwrap! (update-resource-inventory resource-identifier requested-amount false) 
                ERROR_RESOURCE_IDENTIFIER_NOT_FOUND)
            
            ;; Create allocation record
            (map-set resource-allocation-records
                { resource-holder: tx-sender, resource-identifier: resource-identifier }
                {
                    allocated-amount: requested-amount,
                    allocation-timestamp: current-block-height,
                    allocation-status: "active"
                }
            )
            
            ;; Update holder statistics
            (match (map-get? resource-holder-statistics { resource-holder: tx-sender })
                holder-data (map-set resource-holder-statistics
                    { resource-holder: tx-sender }
                    { lifetime-allocation-count: (+ (get lifetime-allocation-count holder-data) u1) }
                )
                (map-set resource-holder-statistics
                    { resource-holder: tx-sender }
                    { lifetime-allocation-count: u1 }
                )
            )
            (ok true)
        )
    )
)

(define-public (return-allocated-resource (resource-identifier uint))
    (begin
        (asserts! (validate-resource-identifier resource-identifier) ERROR_INVALID_RESOURCE_IDENTIFIER)
        (let (
            (allocation-record (unwrap! (map-get? resource-allocation-records 
                { resource-holder: tx-sender, resource-identifier: resource-identifier }) 
                ERROR_RESOURCE_IDENTIFIER_NOT_FOUND))
        )
            (asserts! (is-eq (get allocation-status allocation-record) "active") ERROR_INVALID_RESOURCE_AMOUNT)
            
            ;; Return resource to available pool
            (unwrap! (update-resource-inventory resource-identifier (get allocated-amount allocation-record) true) 
                ERROR_RESOURCE_IDENTIFIER_NOT_FOUND)
            
            ;; Update allocation record
            (map-set resource-allocation-records
                { resource-holder: tx-sender, resource-identifier: resource-identifier }
                {
                    allocated-amount: (get allocated-amount allocation-record),
                    allocation-timestamp: (get allocation-timestamp allocation-record),
                    allocation-status: "returned"
                }
            )
            (ok true)
        )
    )
)

;; Read-Only Functions
(define-read-only (get-resource-details (resource-identifier uint))
    (if (validate-resource-identifier resource-identifier)
        (map-get? managed-resource-types { resource-identifier: resource-identifier })
        none
    )
)

(define-read-only (get-allocation-details (resource-holder principal) (resource-identifier uint))
    (if (validate-resource-identifier resource-identifier)
        (map-get? resource-allocation-records { resource-holder: resource-holder, resource-identifier: resource-identifier })
        none
    )
)

(define-read-only (get-holder-allocation-history (resource-holder principal))
    (match (map-get? resource-holder-statistics { resource-holder: resource-holder })
        holder-data (ok (get lifetime-allocation-count holder-data))
        (ok u0)
    )
)