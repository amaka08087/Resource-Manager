# Resource Allocation Smart Contract

## About
A Clarity smart contract for managing and tracking digital resource allocation with robust security features. This contract enables systematic distribution of resources, tracks allocation history, and maintains user statistics while ensuring secure and controlled access to resources.

## Features

### Core Functionality
- Resource type registration and management
- Secure resource allocation and release
- User allocation tracking and statistics
- Comprehensive error handling
- Access control and authorization

### Data Structures

#### Managed Resource Types
```clarity
{
    resource-identifier: uint,
    resource-name: string-ascii,
    resource-total-supply: uint,
    resource-available-amount: uint
}
```

#### Resource Allocation Records
```clarity
{
    resource-holder: principal,
    resource-identifier: uint,
    allocated-amount: uint,
    allocation-timestamp: uint,
    allocation-status: string-ascii
}
```

#### Resource Holder Statistics
```clarity
{
    resource-holder: principal,
    lifetime-allocation-count: uint
}
```

## Contract Functions

### Administrative Functions

#### register-new-resource-type
```clarity
(register-new-resource-type (resource-identifier uint) (resource-name (string-ascii 64)) (initial-resource-supply uint))
```
- Registers a new resource type in the system
- Requires administrator privileges
- Parameters:
  - `resource-identifier`: Unique identifier for the resource
  - `resource-name`: Human-readable name for the resource
  - `initial-resource-supply`: Initial amount of resource available

### User Functions

#### submit-resource-allocation-request
```clarity
(submit-resource-allocation-request (resource-identifier uint) (requested-amount uint))
```
- Requests allocation of a specific resource
- Parameters:
  - `resource-identifier`: ID of the resource to allocate
  - `requested-amount`: Amount of resource requested
- Validates resource availability and updates records

#### return-allocated-resource
```clarity
(return-allocated-resource (resource-identifier uint))
```
- Returns previously allocated resources
- Parameters:
  - `resource-identifier`: ID of the resource to return
- Updates availability and allocation records

### Read-Only Functions

#### get-resource-details
```clarity
(get-resource-details (resource-identifier uint))
```
- Returns details of a specific resource type

#### get-allocation-details
```clarity
(get-allocation-details (resource-holder principal) (resource-identifier uint))
```
- Returns details of a specific allocation

#### get-holder-allocation-history
```clarity
(get-holder-allocation-history (resource-holder principal))
```
- Returns allocation history for a specific user

## Error Handling

### Error Constants
- `ERROR_UNAUTHORIZED_ACCESS`: Unauthorized operation attempt
- `ERROR_INVALID_RESOURCE_AMOUNT`: Invalid resource amount specified
- `ERROR_INSUFFICIENT_RESOURCE_BALANCE`: Insufficient resources available
- `ERROR_RESOURCE_IDENTIFIER_NOT_FOUND`: Resource not found
- `ERROR_RESOURCE_ALLOCATION_EXISTS`: Resource already exists

## Usage Examples

### Registering a New Resource
```clarity
(contract-call? .resource-manager register-new-resource-type u1 "Computing Power" u1000)
```

### Requesting Resource Allocation
```clarity
(contract-call? .resource-manager submit-resource-allocation-request u1 u100)
```

### Returning Allocated Resources
```clarity
(contract-call? .resource-manager return-allocated-resource u1)
```

## Security Considerations

1. Access Control
   - Administrative functions restricted to contract administrator
   - User operations validated against ownership and permissions

2. Resource Management
   - Checks for resource availability before allocation
   - Validation of resource amounts and identifiers
   - Prevention of duplicate allocations

3. State Management
   - Atomic operations for state updates
   - Proper error handling and rollback capabilities

## Best Practices
1. Always verify transaction success
2. Monitor resource availability
3. Regularly audit allocation records
4. Maintain proper access controls
5. Document all resource type additions

## Contributing
1. Fork the repository
2. Create feature branch
3. Submit pull request with tests
4. Ensure documentation is updated