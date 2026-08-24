/**
 * Normalized Gear Check model (schemaVersion 2).
 *
 * Produced by `Raidwise/GearCheck.lua`. Phase 3+ rules must consume this shape
 * only — no WoW API calls inside the rules engine.
 *
 * `itemLevel` is informational and must never affect OK / REPLACE / BAD.
 * Unknown data uses `gaps[]` (`{ code, detail? }`); never invent a BAD verdict.
 */

export type GearCheckSchemaVersion = 2;

export type SlotPolicy = "CHECKED" | "IGNORED" | "PLANNED";

export type GearCheckGapCode =
  | "SPEC_UNKNOWN"
  | "SLOT_UNAVAILABLE"
  | "ITEM_LINK_PENDING"
  | "ITEM_LINK_INVALID"
  | "ITEM_INFO_UNKNOWN"
  | "ARMOR_TYPE_UNKNOWN"
  | "WEAPON_TYPE_UNKNOWN"
  | "STATS_UNAVAILABLE"
  | "ENCHANT_UNMAPPED"
  | "GEM_INFO_UNKNOWN";

export type GearCheckGap = {
  code: GearCheckGapCode | string;
  detail?: string;
};

/** Locale-independent stat ids from GetItemStats mapping. */
export type GearCheckStatId =
  | "strength"
  | "agility"
  | "stamina"
  | "intellect"
  | "spirit"
  | "hitRating"
  | "critRating"
  | "hasteRating"
  | "expertiseRating"
  | "armorPenetration"
  | "spellPower"
  | "attackPower"
  | "feralAttackPower"
  | "spellPenetration"
  | "defenseRating"
  | "dodgeRating"
  | "parryRating"
  | "blockRating"
  | "blockValue"
  | "resilience"
  | "mp5"
  | "hp5"
  | "armor";

export type GearCheckStats = Partial<Record<GearCheckStatId, number>>;

export type GearCheckSockets = {
  meta: number;
  red: number;
  yellow: number;
  blue: number;
  prismatic: number;
  total: number;
};

export type GearCheckEnchant = {
  enchantId: number;
  present: boolean;
  /** True when id is 0 (no enchant) or a catalog has resolved the id. Phase 2: only 0 is known. */
  known: boolean;
  gaps: GearCheckGap[];
};

export type GearCheckGemColor =
  | "red"
  | "blue"
  | "yellow"
  | "purple"
  | "green"
  | "orange"
  | "meta"
  | "prismatic"
  | "simple"
  | "unknown";

export type GearCheckGem = {
  socketIndex: number;
  itemId: number;
  present: true;
  known: boolean;
  isMeta: boolean;
  color: GearCheckGemColor;
  name?: string;
  stats: GearCheckStats;
  gaps: GearCheckGap[];
};

export type GearCheckItemCategory = "armor" | "weapon" | "relic" | "other" | "unknown";

export type GearCheckArmorType =
  | "cloth"
  | "leather"
  | "mail"
  | "plate"
  | "shield"
  | "offhand"
  | "misc"
  | "unknown";

export type GearCheckWeaponType =
  | "axe1h"
  | "axe2h"
  | "bow"
  | "gun"
  | "mace1h"
  | "mace2h"
  | "polearm"
  | "sword1h"
  | "sword2h"
  | "staff"
  | "fist"
  | "dagger"
  | "thrown"
  | "crossbow"
  | "wand"
  | "fishingPole"
  | "misc"
  | "unknown";

export type GearCheckItem = {
  itemId: number;
  link?: string;
  name?: string;
  quality?: number;
  /** Informational only — must not affect verdicts. */
  itemLevel?: number;
  /** INVTYPE_* token, locale-independent. */
  equipLoc?: string;
  itemType?: string;
  itemSubType?: string;
  texture?: string;
  category: GearCheckItemCategory;
  armorType?: GearCheckArmorType;
  weaponType?: GearCheckWeaponType;
  isRelic: boolean;
  stats: GearCheckStats;
  sockets: GearCheckSockets;
  enchant: GearCheckEnchant;
  gems: GearCheckGem[];
  metaGemId?: number;
  infoKnown: boolean;
  pendingLink: boolean;
  gaps: GearCheckGap[];
};

export type GearCheckSlot = {
  key: string;
  slotName: string;
  slotId?: number;
  policy: SlotPolicy;
  policyNote?: "planned" | "ignored" | "relic";
  empty: boolean;
  item?: GearCheckItem;
  gaps: GearCheckGap[];
};

export type GearCheckCharacter = {
  unit: string;
  isSelf: boolean;
  name?: string;
  realm?: string;
  guid?: string;
  className?: string;
  /** English class token, e.g. `"WARRIOR"`. */
  classFile?: string;
  specName?: string;
  specIcon?: string;
  specTab: number;
  specKnown: boolean;
  gaps: GearCheckGap[];
};

/** Inspect / scan metadata. Not an input to suitability rules. */
export type GearCheckCollection = {
  collectedAt: number;
  scanStatus?: string;
  inspect: {
    needed: boolean;
    canInspect: boolean;
    notified: boolean;
    complete: boolean;
    tooFar?: boolean;
    timedOut?: boolean;
  };
  counts: {
    checkedSlots: number;
    filledCheckedSlots: number;
  };
};

/**
 * Frozen Gear Check report.
 * Rules read `character` + `equipment` (+ top-level `gaps`). Ignore `collection`.
 *
 * Convenience aliases (`name`, `isSelf`, `inspect`, `slots`, …) may also be present
 * for UI/inspect orchestration; prefer the nested fields in new code.
 */
export type GearCheckReport = {
  schemaVersion: GearCheckSchemaVersion;
  character: GearCheckCharacter;
  equipment: GearCheckSlot[];
  gaps: GearCheckGap[];
  collection: GearCheckCollection;
};
