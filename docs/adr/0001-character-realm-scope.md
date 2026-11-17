# One realm per character dataset

On 2026-11-06 the user confirmed one realm per SavedVariables dataset.
Keep the existing GUID keys, including saved Gear Check reports, rather than introducing partial multi-realm namespacing.
Realm conflict guards prevent an obvious collision; they do not distinguish independent servers with identical realm names.
Revisit this scope only with a server identity and migration of all references, reports and recovery archives. Operational limits and repair are in [character storage](../characters/Character-System-Contract.md).
