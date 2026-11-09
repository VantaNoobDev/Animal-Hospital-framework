# Networking

The project uses Red for network events and remote functions. Each module in `src/network/` defines a named network contract and validates arguments at the boundary.

## Events

These are one-way notifications:

- `PatientSpawned` - sends visible patient information to clients.
- `PatientResolved` - announces a resolved patient.
- `AssignRoom` - requests/announces room assignment depending on the calling side.
- `ShiftStarted` - announces a new shift number.
- `ShiftEnded` - announces shift completion and survival status.
- `SanityChanged` - sends a sanity value.
- `ClassDataSynced` - sends the complete class data set.
- `ClassPurchased` - announces a purchased class and its entry.
- `ClassLeveledUp` - announces a new level.
- `StartDialogue` - sends dialogue payloads.

## Remote functions

- `ResolveCheckIn(PatientId, Admitted)` - check-in request.
- `ApplyTreatment(PatientId, TreatmentId)` - treatment request.
- `PurchaseClass(ClassId)` - class purchase request.

### Callback contract

For these functions, the server callback is currently fire-and-forget. A successful callback returns no value (`nil`). Do not accidentally return internal booleans or unrelated values unless the remote contract is intentionally changed to expose a result.

A network validator should validate data shape and primitive types. Gameplay authorization belongs in the server service itself. For example, a treatment request can have valid strings but still be invalid because the patient is in the wrong room or already resolved.

## Adding a new network contract

1. Create a module in `src/network/` using the same Red pattern as the existing contracts.
2. Validate every public argument that crosses the client/server boundary.
3. Keep validators focused on shape/range validation.
4. Put permission, progression, ownership, and other gameplay checks in the server-side callback/service.
5. Document the payload and return contract here.

## Validation note

Do not use `if not Value` when `false` is a valid input. For booleans, check `type(Value) == "boolean"` instead. This matters for inputs such as `Admitted = false`.
