# AnimalHospitalAhhGame

A Roblox game written in **Luau** and structured with Rojo. The project uses server-authoritative services for gameplay, Red for networking, and a central `GameConfig` module for balancing.

## Quick start

```bash
rojo serve
```

Then connect the Rojo server from Roblox Studio. To build a place file instead:

```bash
rojo build -o "AnimalHospitalAhhGame.rbxlx"
```

## Project layout

- `src/config/GameConfig.luau` - central balancing and gameplay configuration
- `src/services/` - server/client gameplay services
- `src/network/` - Red events and remote functions with argument validation
- `src/ui/` - dialogue UI, controller, view, component, and typewriter utility
- `src/startup/` - client/server bootstrapping
- `Packages/` - external dependencies; avoid editing these directly

## Main gameplay flow

1. A shift starts.
2. Patients spawn over time, with anomaly chance increasing by shift.
3. Players resolve check-in and assign rooms.
4. Treatments resolve patients when progression requirements are satisfied.
5. Sanity drains during the shift and reaching zero ends the shift.
6. Completing the timer successfully ends the shift.

## Documentation

- [Configuration](docs/CONFIGURATION.md) - every central setting and what it does
- [Architecture](docs/ARCHITECTURE.md) - service responsibilities and data flow
- [Networking](docs/NETWORKING.md) - network events/functions and callback contracts

## Important conventions

- Server code is authoritative. Client requests should be treated as requests, not proof that an action is valid.
- Most gameplay tuning belongs in `GameConfig.luau`.
- Network callback handlers that only perform an action should return nothing unless their remote function explicitly has a result contract.
- Static definition tables may be frozen. Edit their source definitions rather than trying to mutate them at runtime.
