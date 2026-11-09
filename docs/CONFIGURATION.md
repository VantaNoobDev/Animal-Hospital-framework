# Configuration

All primary balancing is centralized in `src/config/GameConfig.luau`. The config table is frozen after construction, so normal scripts cannot accidentally mutate global balancing during runtime.

## Shift

- `BaseDuration` - length of each shift in seconds.
- `BasePatientInterval` - initial time between patient spawns.
- `IntervalScalePerShift` - multiplier applied to the spawn interval as shifts increase. Values below `1` make patients spawn faster.
- `MinimumPatientInterval` - lower limit for spawn interval.
- `BaseAnomalyChance` - starting probability of a spawned patient being anomalous.
- `AnomalyChanceScalePerShift` - anomaly probability added per shift.
- `MaximumAnomalyChance` - hard cap for anomaly probability.
- `StartPatientImmediately` - if true, the first patient spawns immediately when a shift begins.

## Sanity

- `Max` - maximum sanity.
- `BaseDrainPerMinute` - sanity removed per minute before shift scaling.
- `DrainScalePerShift` - additional drain multiplier per shift.
- `ReplicationInterval` - minimum time between batched sanity network updates.
- `ReplicationEpsilon` - smallest sanity change worth replicating.
- `PassiveDrainEnabled` - enables/disables automatic sanity loss.

`SanityChanged` currently validates values in the `0-100` range. If you change `Sanity.Max` above 100, update that validator too.

## Anomalies

- `MinTraits` / `MaxTraits` - number of traits rolled for an anomalous patient.
- `RedHerringChance` - chance for a normal patient to receive a misleading trait.
- `RedHerringMaxWeight` - only traits at or below this weight can be used as red herrings.

## Patients

- `IdPrefix` - prefix used when generating patient IDs.
- `InitialRoom` - room/state assigned when a patient first spawns.
- `RequireCheckInBeforeRoom` - prevents room assignment before check-in is resolved.
- `RequireCorrectRoomForTreatment` - requires the patient's expected room before treatment.
- `AllowMultipleCheckInResolutions` - allows/disallows resolving check-in repeatedly.
- `ClearPatientOnSuccessfulTreatment` - removes resolved patients immediately when treatment succeeds.
- `RandomSpecies` - enables random species selection.

## Classes

- `ExpPerLevel` - EXP required for one level-up step.
- `AllowRepurchase` - allows a player to purchase an already-owned class.
- `AllowNegativeExp` - allows EXP values below zero.
- `AutoGrantIntern` - automatically grants the starter/intern class if supported by the service.

## Dialogue

- `InitializationDelay` - delay used while preparing dialogue UI.
- `AutoHideDelay` - delay before dialogue automatically hides.
- `TypewriteDelay` - delay between typewriter characters.

## Adding new settings

1. Add the setting to `GameConfig.luau` in the relevant category.
2. Replace hard-coded values in the service with the config field.
3. Keep units obvious - seconds, probability `0-1`, points, etc.
4. Update this document when adding a public gameplay setting.
5. If a network validator has a hard-coded limit affected by the setting, update that validator as well.
