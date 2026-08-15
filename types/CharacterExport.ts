/** Item ids only (when "Include item names" is off). */
export type ItemIdListIdsOnly = {
  ids: number[];
};

/** Item ids with parallel display names (when "Include item names" is on). */
export type ItemIdListWithNames = {
  ids: number[];
  /** Same length and order as `ids`. */
  names: string[];
};

/**
 * Equipped gear or bag contents.
 * `names` is included only when the addon toggle is enabled.
 */
export type ItemIdList = ItemIdListIdsOnly | ItemIdListWithNames;

/**
 * WotLK raid difficulty IDs from `GetSavedInstanceInfo`.
 * 5-man dungeons may use other numeric values at runtime.
 */
export enum InstanceDifficulty {
  /** 10-player normal */
  Raid10Normal = 1,
  /** 25-player normal */
  Raid25Normal = 2,
  /** 10-player heroic */
  Raid10Heroic = 3,
  /** 25-player heroic */
  Raid25Heroic = 4,
}

/** One saved raid/dungeon lockout from GetSavedInstanceInfo. */
export type InstanceLockout = {
  name: string;
  /** Instance lockout ID. */
  id: number;
  /** Seconds remaining until reset at export time. */
  reset: number;
  /** Unix timestamp when the lockout resets (`time() + reset` in-game). */
  resetAt: number;
  /**
   * Numeric difficulty from the client.
   * For raids, see {@link InstanceDifficulty}; dungeons may use other values.
   */
  difficulty: InstanceDifficulty | number;
  /** Localized difficulty label, e.g. "25 Player". */
  difficultyName: string;
  /** True if the character is currently saved/cleared on this ID. */
  locked: boolean;
  extended: boolean;
  isRaid: boolean;
  maxPlayers: number;
};

/**
 * JSON object produced by mrc-exporter's character export.
 * `gear.names` / `bags.names` are omitted when "Include item names" is disabled.
 * `gearScore` is omitted when the GearScore addon is not available.
 */
export type CharacterExport = {
  name: string;
  /** English class token, e.g. `"MAGE"`. */
  class: string;
  /** Primary talent tree name on the active dual-spec. */
  spec: string;
  /**
   * Current GearScore from the GearScore addon (character-window value).
   * Omitted if GearScore is not loaded.
   */
  gearScore?: number;
  /** Equipped items; `names` optional per export toggle. */
  gear: ItemIdList;
  /** Bag items; `names` optional per export toggle. */
  bags: ItemIdList;
  lockouts: InstanceLockout[];
};
