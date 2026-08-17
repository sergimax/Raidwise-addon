import type { InstanceLockout } from "./CharacterExport";

/** One character entry in the account-wide cooldown export. */
export type CooldownCharacterExport = {
  /** SavedVariables key, e.g. `"Rhee-RealmName"`. */
  key: string;
  name: string;
  realm: string;
  /** English class token, e.g. `"SHAMAN"`. */
  class: string;
  /** Primary talent tree name. */
  spec: string;
  /** Unix timestamp when this character record was last updated. */
  updatedAt: number;
  lockouts: InstanceLockout[];
};

/**
 * JSON object produced by Raidwise's Export cooldowns tab.
 * Includes every character saved on the account in `RaidwiseDB.characters`.
 */
export type CooldownsExport = {
  /** Unix timestamp when the export was generated (`time()` in-game). */
  exportedAt: number;
  characters: CooldownCharacterExport[];
};
