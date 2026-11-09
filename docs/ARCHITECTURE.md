# Architecture

## Startup

The startup scripts initialize the project and services for each environment:

- `Client.client.luau` - client bootstrap.
- `Server.server.luau` - server bootstrap and gameplay service startup.

## PatientService

Owns patient lifecycle and server-side patient state. The client module maintains replicated visible patient data, while the server module performs authoritative actions.

Typical lifecycle:

`spawn -> check-in resolution -> room assignment -> treatment -> resolved/removed`

Do not trust a client request alone. The server should verify that the patient exists and that the requested action is valid for its current state.

`Utils.luau` contains shared patient definitions such as species, traits, rooms, and treatments.

## AnomalyService

Rolls patient traits. Anomalous patients receive multiple traits; normal patients may receive low-weight red herrings. It also converts traits into descriptions visible to the player.

## ShiftService

Owns the global shift state and difficulty scaling. The server controls the timer and patient spawning. The client keeps a local presentation timer for UI.

A shift ends successfully when time expires and unsuccessfully when the service is failed, including through sanity depletion.

## SanityService

Tracks sanity per player on the server. Passive drain is applied continuously, but network replication is batched to reduce remote traffic. The client turns replicated values into local signals such as warning and critical thresholds.

## ClassService

Tracks owned classes, levels, and EXP. The server owns class data and broadcasts changes to clients. Class purchase validation should stay server-side, especially when a future currency/economy system is added.

## DialogueService and UI

The server is responsible for ensuring each player receives their dialogue UI. The client-side UI is split into:

- `DialogueController` - receives dialogue network messages and coordinates display.
- `Dialogue` component - presentation behavior.
- `DialogueView` - direct GUI references and simple view operations.
- `Typewrite` - RichText-aware typewriter behavior.
- `DialogueEnums` - dialogue constants/data.

## Shared configuration

`GameConfig` is the balancing boundary. Services should prefer reading from it instead of embedding gameplay constants directly in implementation code.
