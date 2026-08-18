# Raid composition tracking

What the **Raid composition** tab (**Анализ состава**) checks for Wrath of the Lich King **3.3.5a**. Layout follows the [Wowhead raid composition](https://www.wowhead.com/wotlk/raid-composition) tool: roles, then exclusive buff/debuff/utility categories.

Only the strongest effect in a category applies to the raid. The tab marks a category **present** if anyone in the current party or raid can bring it, and **missing** otherwise. Spec is the player’s **primary talent tree** (same inspect data as Raid roster). Deep talent points are not read: if the tree is right, the addon assumes the usual raid talent is taken.

Sources: [Icy Veins buffs and debuffs](https://www.icy-veins.com/wotlk-classic/raid-buffs-and-debuffs), Blizzard’s WotLK exclusive-category list, and the Wowhead composition sections named below.

## Roles

Already used on Raid roster. Counted here from the same tank / healer / melee / ranged rules (`RaidRoles.lua`).

| Role | Typical trees |
|------|----------------|
| Tank | Warrior Protection, Paladin Protection, Death Knight Blood (or Main Tank flag) |
| Healer | Priest Discipline/Holy, Paladin Holy, Shaman Restoration, Druid Restoration |
| Melee DPS | Arms/Fury, Retribution, Combat/Assassination/Subtlety, Unholy/Frost DK, Enhancement, Feral |
| Ranged DPS | Hunter (all), Mage (all), Warlock (all), Shadow Priest, Elemental, Balance |

## Buffs

Raid-wide stat and throughput buffs. Spells in the same row **do not stack**.

| Category | Effect | Who brings it |
|----------|--------|----------------|
| 10% stats | Blessing of Kings; Blessing of Sanctuary (Prot) | Any Paladin; Protection Paladin |
| Mark of the Wild | Flat stats + resistances | Any Druid |
| Stamina | Power Word: Fortitude / Prayer of Fortitude | Any Priest |
| Intellect | Arcane Intellect / Arcane Brilliance; Fel Intelligence | Any Mage; Affliction Warlock |
| Spirit | Divine Spirit / Prayer of Spirit; Fel Intelligence | Any Priest; Affliction Warlock |
| Attack power | Battle Shout; Blessing of Might | Any Warrior; Any Paladin |
| Strength / Agility | Horn of Winter; Strength of Earth Totem | Any Death Knight; Any Shaman |
| Health | Commanding Shout; Blood Pact (Imp) | Any Warrior; Any Warlock (Imp; Destruction improves it) |
| Mana per 5 | Blessing of Wisdom; Mana Spring Totem | Any Paladin; Any Shaman (Restoration improves it) |
| Spell power | Flametongue Totem; Totem of Wrath; Demonic Pact | Any Shaman; Elemental Shaman; Demonology Warlock |
| 5% melee/ranged crit | Leader of the Pack; Rampage | Feral Druid; Fury Warrior |
| 5% spell crit (raid aura) | Moonkin Aura; Elemental Oath | Balance Druid; Elemental Shaman |
| Melee haste | Improved Icy Talons; Windfury Totem | Frost Death Knight; Any Shaman (Enhancement improves it) |
| Spell haste | Wrath of Air Totem | Any Shaman |
| 3% haste (all) | Swift Retribution; Improved Moonkin Aura | Retribution Paladin; Balance Druid |
| 3% damage | Sanctified Retribution; Ferocious Inspiration; Arcane Empowerment | Retribution Paladin; Beast Mastery Hunter; Arcane Mage |
| 10% attack power | Trueshot Aura; Unleashed Rage; Abomination’s Might | Marksmanship Hunter; Enhancement Shaman; Blood Death Knight |
| Bloodlust / Heroism | Raid haste, 10 min CD | Any Shaman |
| Healing received | Tree of Life; Improved Devotion Aura | Restoration Druid; Holy Paladin |

## External buffs

Single-target (or small-group) spells you put **on an ally**. Count is how many people in the raid can cast it.

Rows marked **hidden** stay in this list for reference but are omitted from the Raid composition tab (self-targeted or not useful for raid-lead coverage).

| Spell | Who | View |
|-------|-----|------|
| Focus Magic | Arcane Mage | |
| Tricks of the Trade | Any Rogue | |
| Hysteria | Blood Death Knight | |
| Power Infusion | Discipline Priest | |
| Innervate | Any Druid | |
| Hand of Salvation | Any Paladin | |
| Hand of Sacrifice | Any Paladin | |
| Hand of Freedom | Any Paladin | |
| Hand of Protection | Any Paladin | |
| Pain Suppression | Discipline Priest | |
| Guardian Spirit | Holy Priest | |
| Misdirection | Any Hunter | |
| Earth Shield | Restoration Shaman | |
| Beacon of Light | Holy Paladin | |
| Sacred Shield | Holy Paladin | hidden |
| Divine Sacrifice | Protection Paladin | |
| Intervene | Any Warrior | hidden |

## Damage reduction

Raid or personal CDs and passives that cut damage. Pain Suppression, Guardian Spirit, and Hand of Sacrifice are also listed under External buffs.

Self-targeted defensives are marked **hidden** and are omitted from the Raid composition tab.

| Spell / effect | Who | View |
|----------------|-----|------|
| Anti-Magic Zone | Unholy Death Knight | hidden |
| Divine Guardian | Protection Paladin | |
| Aura Mastery | Any Paladin (Retribution talent is the usual raid take) | |
| Shield Wall | Any Warrior | hidden |
| Last Stand | Protection Warrior | hidden |
| Icebound Fortitude | Any Death Knight | hidden |
| Vampiric Blood | Blood Death Knight | hidden |
| Survival Instincts | Feral Druid | hidden |
| Frenzied Regeneration | Feral Druid | hidden |
| Dispersion | Shadow Priest | hidden |
| Divine Protection | Any Paladin | hidden |
| Divine Shield | Any Paladin | |
| Barkskin | Any Druid | hidden |
| Ice Block | Any Mage | hidden |
| Cloak of Shadows | Any Rogue | hidden |
| Anti-Magic Shell | Any Death Knight | hidden |
| Lay on Hands | Any Paladin | |
| Divine Hymn | Any Priest | |
| Tranquility | Restoration Druid | |
| Blessing of Sanctuary / Grace | Protection Paladin; Discipline Priest | |
| Inspiration / Ancestral Healing | Discipline or Holy Priest; Restoration Shaman | |

Aura Mastery is treated as present for **any Paladin** (the ability exists on the class; Retribution is the typical raid talent). Divine Guardian requires Protection.

## Debuffs

Boss debuffs. Major and minor armor **do stack with each other**. Moonkin Aura / Elemental Oath are the **raid buff** for 5% spell crit; Improved Shadow Bolt is the **boss debuff** in the same exclusive category as Improved Scorch and Winter’s Chill.

| Category | Effect | Who |
|----------|--------|-----|
| Armor (major, 20%) | Sunder Armor; Expose Armor; Acid Spit (worm pet) | Any Warrior; Any Rogue; Beast Mastery Hunter (pet) |
| Armor (minor, 5%) | Faerie Fire; Curse of Weakness; Sting (wasp pet) | Any Druid; Any Warlock; Any Hunter (pet) |
| Bleed damage | Mangle; Trauma; Stampede (pet) | Feral Druid; Arms Warrior; Beast Mastery Hunter |
| Physical damage taken | Blood Frenzy; Savage Combat | Arms Warrior; Combat Rogue |
| Spell damage taken | Curse of the Elements; Earth and Moon; Ebon Plaguebringer | Any Warlock; Balance Druid; Unholy Death Knight |
| Spell hit (Misery) | Misery; Improved Faerie Fire | Shadow Priest; Balance Druid |
| Crit chance taken | Heart of the Crusader; Totem of Wrath; Master Poisoner | Retribution or Protection Paladin; Elemental Shaman; Assassination Rogue |
| Spell crit taken | Improved Scorch; Winter’s Chill; Improved Shadow Bolt | Fire Mage; Frost Mage; Destruction Warlock |
| Attack speed slow | Thunder Clap; Icy Touch; Infected Wounds; Judgements of the Just | Any Warrior; Any Death Knight; Feral Druid; Protection Paladin |
| Attack power down | Demoralizing Shout; Demoralizing Roar; Curse of Weakness; Vindication | Any Warrior; Feral Druid; Any Warlock; Ret/Prot Paladin |
| Healing reduction | Mortal Strike; Aimed Shot; Wound Poison; Furious Attacks | Arms Warrior; Any Hunter; Any Rogue; Fury Warrior |
| Cast speed slow | Curse of Tongues; Slow; Mind-numbing Poison; Lava Breath (pet) | Any Warlock; Arcane Mage; Any Rogue; Beast Mastery Hunter |
| Melee hit reduction | Insect Swarm; Scorpid Sting | Balance Druid; Any Hunter |
| Judgement of Light | Health return on melee hits | Any Paladin |
| Judgement of Wisdom | Mana return on melee/spell hits | Any Paladin |

Acid Spit, Hunter Sting, Stampede, and Lava Breath depend on the pet. Beast Mastery / any Hunter is listed as a **possible** source.

## Mana regeneration

| Spell / effect | Who | View |
|----------------|-----|------|
| Replenishment | Shadow Priest (Vampiric Touch); Survival Hunter (Hunting Party); Retribution Paladin (Judgements of the Wise); Frost Mage (Enduring Winter); Destruction Warlock (Improved Soul Leech) | |
| Mana Tide Totem | Restoration Shaman | |
| Hymn of Hope | Any Priest | |
| Innervate | Any Druid | |
| Shadowfiend | Any Priest | hidden |
| Revitalize | Restoration Druid | |

One Replenishment source covers 10 people; 25-man raids usually want two.

## Health regeneration

| Spell / effect | Who | View |
|----------------|-----|------|
| Improved Leader of the Pack | Feral Druid | |
| Vampiric Embrace | Shadow Priest | |
| Judgement of Light | Any Paladin | |
| Gift of the Naaru | Draenei (any class) | hidden |

## Limits

- Primary talent tab only; a Balance Druid without Earth and Moon still lights that row.
- Pets (Imp Blood Pact, Acid Spit, Sting) are not inspected; the class/spec is enough to mark coverage.
- Blessings and totems are “can provide”, not “currently assigned on this subgroup”.
- Party (5) and raid (40) both feed the same checklist; solo shows only your own rows as present.
- Rows marked **hidden** (self-targeted defensives, Sacred Shield, Intervene, Shadowfiend, Gift of the Naaru) are not shown in the tab.
