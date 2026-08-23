import type { InstanceLockout } from "./CharacterExport";

/** One currency/badge entry from the in-game Currency tab (WotLK 3.3.5). */
export type CharacterCurrencyEntry = {
  /** `"gold"`, `"honor"`, `"arena"`, or emblem item id. */
  id: string | number;
  label: string;
  icon: string;
  count: number;
  displayCount?: string;
  tooltipCount?: string;
};

/** Currency snapshot from the in-game Currency tab. */
export type CharacterCurrencySnapshot = {
  entries: CharacterCurrencyEntry[];
};

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
  /** Present when the character was logged in after currency tracking was added. */
  currency?: CharacterCurrencySnapshot;
  lockouts: InstanceLockout[];
};

/**
 * JSON object produced by Raidwise's account cooldown export.
 * Includes every character saved on the account in `RaidwiseDB.characters`.
 */
export type CooldownsExport = {
  /** Unix timestamp when the export was generated (`time()` in-game). */
  exportedAt: number;
  characters: CooldownCharacterExport[];
};
