/** Equipped gear or bag contents: parallel id/name lists (names optional). */
export type ItemIdList = {
  ids: number[];
  /** Present when "Include item names" is enabled in the addon. */
  names?: string[];
};

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

/** JSON object produced by mrc-exporter's character export. */
export type CharacterExport = {
  name: string;
  /** English class token, e.g. `"MAGE"`. */
  class: string;
  /** Primary talent tree name on the active dual-spec. */
  spec: string;
  gear: ItemIdList;
  bags: ItemIdList;
  lockouts: InstanceLockout[];
};
