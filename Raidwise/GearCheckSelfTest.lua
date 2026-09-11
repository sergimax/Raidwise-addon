-- In-game and offline rule fixtures.
local Addon = Raidwise

local function MakeSlot(key, slotName, item)
	return {
		key = key,
		slotName = slotName,
		policy = "CHECKED",
		empty = item == nil,
		item = item,
		gaps = {},
	}
end

local function MakeItem(fields)
	fields.enchant = fields.enchant or { enchantId = 0, present = false, known = true, gaps = {} }
	fields.gems = fields.gems or {}
	fields.stats = fields.stats or {}
	fields.sockets = fields.sockets or { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 }
	fields.infoKnown = fields.infoKnown ~= false
	fields.pendingLink = fields.pendingLink == true
	fields.isRelic = fields.isRelic == true
	fields.gaps = fields.gaps or {}
	return fields
end

-- Offline fixtures for `/rw gearcheck test`.
function Addon:GearCheckRulesSelfTest()
	local results = {}
	local function Check(name, ok, detail)
		results[#results + 1] = { name = name, ok = ok and true or false, detail = detail }
	end

	local function HasCode(findings, code)
		for index = 1, #findings do
			if findings[index].code == code then
				return true
			end
		end
		return false
	end

	local function HasCodeOnSlot(findings, code, slotKey)
		for index = 1, #findings do
			local finding = findings[index]
			if finding.code == code and finding.slot == slotKey then
				return true
			end
		end
		return false
	end

	-- Cloth on Protection Warrior → ARMOR_FORBIDDEN
	local clothProt = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 1,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 10 },
				enchant = { enchantId = 3832, present = true, known = false, gaps = {} },
			})),
		},
	}
	local f1 = self:EvaluateGearCheck(clothProt)
	Check("cloth on prot warrior → ARMOR_FORBIDDEN", HasCode(f1, "ARMOR_FORBIDDEN"))
	Check("cloth on prot warrior → chest BAD", clothProt.equipment[1].verdict == "D")

	-- Resilience ring → RESILIENCE_PVE
	local resRing = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("finger1", "Finger0Slot", MakeItem({
				itemId = 2,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 50, stamina = 20 },
			})),
		},
	}
	local f2 = self:EvaluateGearCheck(resRing)
	Check("resilience ring → RESILIENCE_PVE", HasCode(f2, "RESILIENCE_PVE"))
	Check("resilience ring → finger1 REPLACE", resRing.equipment[1].verdict == "C")

	-- Missing chest enchant → MISSING_ENCHANT
	local missing = {
		character = { classFile = "MAGE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 3,
				category = "armor",
				armorType = "cloth",
				stats = { spellPower = 100 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local f3 = self:EvaluateGearCheck(missing)
	Check("missing chest enchant → MISSING_ENCHANT", HasCode(f3, "MISSING_ENCHANT"))
	Check("missing chest enchant → chest REPLACE", missing.equipment[1].verdict == "C")
	Check("missing chest enchant → gearGrade A", missing.overall and missing.overall.gearGrade == "A")
	Check("missing chest enchant → enchantSocketGrade C", missing.overall and missing.overall.enchantSocketGrade == "C")

	-- Spell Power on Fury → STAT_FORBIDDEN
	local spFury = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 4,
				category = "armor",
				armorType = "plate",
				stats = { spellPower = 80, stamina = 50 },
				enchant = { enchantId = 3832, present = true, known = false, gaps = {} },
			})),
		},
	}
	local f4 = self:EvaluateGearCheck(spFury)
	Check("spell power on fury → STAT_FORBIDDEN", HasCode(f4, "STAT_FORBIDDEN"))
	Check("spell power on fury → chest BAD", spFury.equipment[1].verdict == "D")

	-- Clean plate chest on Arms → GOOD (preferred plate + max-level enchant)
	local clean = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 5,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(clean)
	Check("clean plate chest → A", clean.equipment[1].verdict == "A")
	Check("clean plate chest → overall A", clean.overall and clean.overall.status == "A")

	-- Target inspect must be marked complete before OK→GOOD promotion.
	local incompleteInspect = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		inspect = { needed = true, complete = false },
		collection = { inspect = { needed = true, complete = false } },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 5,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(incompleteInspect)
	Check("incomplete target inspect → B not A", incompleteInspect.equipment[1].verdict == "B")
	Check("incomplete target inspect → INSPECT_INCOMPLETE", HasCode(incompleteInspect.findings, "INSPECT_INCOMPLETE"))
	incompleteInspect.inspect.complete = true
	incompleteInspect.collection.inspect.complete = true
	self:EvaluateGearCheck(incompleteInspect)
	Check("complete target inspect → A", incompleteInspect.equipment[1].verdict == "A")
	Check("complete target inspect → no INSPECT_INCOMPLETE", not HasCode(incompleteInspect.findings, "INSPECT_INCOMPLETE"))

	-- S = item ID on the spec BiS union, no item hard/soft findings.
	local bisRet = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 51277,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3808, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(bisRet)
	Check("ret BiS item ID → S", bisRet.equipment[1].verdict == "S")
	Check("ret BiS item ID → overall S", bisRet.overall and bisRet.overall.status == "S")
	Check("ret BiS item ID → gearGrade S", bisRet.overall and bisRet.overall.gearGrade == "S")
	Check("ret BiS item ID → enchantSocketGrade A", bisRet.overall and bisRet.overall.enchantSocketGrade == "A")

	local bisMissingEnch = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 51277,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(bisMissingEnch)
	Check("BiS + missing enchant → combined C", bisMissingEnch.equipment[1].verdict == "C")
	Check("BiS + missing enchant → gearGrade S", bisMissingEnch.overall and bisMissingEnch.overall.gearGrade == "S")
	Check("BiS + missing enchant → enchantSocketGrade C", bisMissingEnch.overall and bisMissingEnch.overall.enchantSocketGrade == "C")

	local bisUnknownSpec = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = false, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 51277,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3808, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(bisUnknownSpec)
	Check("unknown spec → no S", bisUnknownSpec.equipment[1].verdict ~= "S")

	-- Acceptable-but-not-preferred stays OK (mail on Arms with max enchant)
	local mailArms = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 5,
				category = "armor",
				armorType = "mail",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(mailArms)
	Check("mail on arms (acceptable) → B not A", mailArms.equipment[1].verdict == "B")
	Check("mail on arms → overall B", mailArms.overall and mailArms.overall.status == "B")
	Check("mail on arms → gearGrade B", mailArms.overall and mailArms.overall.gearGrade == "B")
	Check("mail on arms → enchantSocketGrade A", mailArms.overall and mailArms.overall.enchantSocketGrade == "A")

	-- Info-only (unknown enchant) → still OK
	local unmapped = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 6,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 999999, present = true, known = false, gaps = {} },
			})),
		},
	}
	local fInfo = self:EvaluateGearCheck(unmapped)
	Check("unknown enchant → ENCHANT_NOT_CHECKABLE", HasCode(fInfo, "ENCHANT_NOT_CHECKABLE"))
	Check("unknown enchant → still B (no false D)", unmapped.equipment[1].verdict == "B")
	Check("unknown enchant → overall B", unmapped.overall and unmapped.overall.status == "B")

	Check("cloth on prot → overall D", clothProt.overall and clothProt.overall.status == "D")
	Check("cloth on prot → gearGrade D", clothProt.overall and clothProt.overall.gearGrade == "D")
	Check("one resilience ring → overall C", resRing.overall and resRing.overall.status == "C")

	-- Two resilience items → overall BAD (locked PvE rule)
	local twoRes = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("finger1", "Finger0Slot", MakeItem({
				itemId = 7,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 40, stamina = 20 },
			})),
			MakeSlot("finger2", "Finger1Slot", MakeItem({
				itemId = 8,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 40, stamina = 20 },
			})),
		},
	}
	self:EvaluateGearCheck(twoRes)
	Check("two resilience rings → items C", twoRes.equipment[1].verdict == "C" and twoRes.equipment[2].verdict == "C")
	Check("two resilience rings → overall D", twoRes.overall and twoRes.overall.status == "D")
	Check("two resilience rings → resilienceItems=2", twoRes.overall and twoRes.overall.resilienceItems == 2)

	-- Chaotic Skyflare (2 blue) without blues → META_INACTIVE
	local noBlue = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 9,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 1, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 41285, present = true, known = true, isMeta = true, color = "meta", stats = { critRating = 21 }, gaps = {} },
				},
			})),
		},
	}
	local fMeta = self:EvaluateGearCheck(noBlue)
	Check("meta without blues → META_INACTIVE", HasCode(fMeta, "META_INACTIVE"))
	Check("meta without blues → head REPLACE", noBlue.equipment[1].verdict == "C")
	Check("meta without blues → overall C", noBlue.overall and noBlue.overall.status == "C")
	Check("meta without blues → gearGrade A", noBlue.overall and noBlue.overall.gearGrade == "A")
	Check("meta without blues → enchantSocketGrade C", noBlue.overall and noBlue.overall.enchantSocketGrade == "C")

	-- Same meta with 2 blue gems elsewhere → active
	local withBlue = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 9,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 1, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 41285, present = true, known = true, isMeta = true, color = "meta", stats = { critRating = 21 }, gaps = {} },
				},
			})),
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 10,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 2, prismatic = 0, total = 2 },
				gems = {
					{ socketIndex = 1, itemId = 40119, present = true, known = true, isMeta = false, color = "blue", stats = { stamina = 30 }, gaps = {} },
					{ socketIndex = 2, itemId = 40119, present = true, known = true, isMeta = false, color = "blue", stats = { stamina = 30 }, gaps = {} },
				},
			})),
		},
	}
	local fBlue = self:EvaluateGearCheck(withBlue)
	Check("meta with 2 blues → not META_INACTIVE", not HasCode(fBlue, "META_INACTIVE"))
	Check("meta with 2 blues → meta.active", withBlue.meta and withBlue.meta.active == true)

	-- T10 counts are informational and must not create verdicts
	local t10 = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 50832,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, attackPower = 80 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
			})),
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 50834,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 70 },
				enchant = { enchantId = 3808, present = true, known = true, gaps = {} },
			})),
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 50830,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, attackPower = 80 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 50831,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 70 },
				enchant = { enchantId = 1603, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(t10)
	local t10Count = 0
	if t10.sets then
		for index = 1, #t10.sets do
			if t10.sets[index].key == "T10" then
				t10Count = t10.sets[index].equipped
			end
		end
	end
	Check("T10 seed → 4/5 equipped", t10Count == 4)
	Check("T10 counts do not force D", t10.overall and t10.overall.status ~= "D")

	-- Phase 8: Enhancement intellect is preferred (not unwanted)
	local enhInt = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 20,
				category = "armor",
				armorType = "mail",
				stats = { intellect = 40, agility = 50, attackPower = 80, stamina = 60 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fEnh = self:EvaluateGearCheck(enhInt)
	Check("enhancement intellect → not STAT_UNWANTED", not HasCode(fEnh, "STAT_UNWANTED"))
	Check("enhancement intellect chest → GOOD", enhInt.equipment[1].verdict == "A")

	-- Frost/Unholy DK: intellect is unwanted (REPLACE), not forbidden (BAD)
	local udkInt = {
		character = { classFile = "DEATHKNIGHT", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("waist", "WaistSlot", MakeItem({
				itemId = 33,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 60, intellect = 30, stamina = 40, critRating = 30 },
			})),
		},
	}
	local fUdk = self:EvaluateGearCheck(udkInt)
	Check("unholy intellect → STAT_UNWANTED", HasCode(fUdk, "STAT_UNWANTED"))
	Check("unholy intellect → not STAT_FORBIDDEN", not HasCode(fUdk, "STAT_FORBIDDEN"))
	Check("unholy intellect waist → REPLACE", udkInt.equipment[1].verdict == "C")

	local fdkInt = {
		character = { classFile = "DEATHKNIGHT", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("waist", "WaistSlot", MakeItem({
				itemId = 34,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 60, intellect = 30, stamina = 40, critRating = 30 },
			})),
		},
	}
	local fFdk = self:EvaluateGearCheck(fdkInt)
	Check("frost intellect → STAT_UNWANTED", HasCode(fFdk, "STAT_UNWANTED"))
	Check("frost intellect → not STAT_FORBIDDEN", not HasCode(fFdk, "STAT_FORBIDDEN"))

	-- Retribution: leather offset + intellect on mail pieces are acceptable
	local retLeather = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 30,
				category = "armor",
				armorType = "leather",
				stats = { agility = 40, attackPower = 50, critRating = 30, stamina = 40 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 31,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 50, intellect = 30, stamina = 40 },
				enchant = { enchantId = 1603, present = true, known = true, gaps = {} },
			})),
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 32,
				category = "armor",
				armorType = "cloth",
				stats = { strength = 40, stamina = 40, critRating = 30 },
				enchant = { enchantId = 1099, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fRet = self:EvaluateGearCheck(retLeather)
	Check("ret leather wrist → not ARMOR_UNWANTED", not HasCode(fRet, "ARMOR_UNWANTED"))
	Check("ret mail intellect → not STAT_UNWANTED", not HasCode(fRet, "STAT_UNWANTED"))
	Check("ret cloak Major Agility → not ENCHANT_NOT_CHECKABLE", not HasCode(fRet, "ENCHANT_NOT_CHECKABLE"))
	Check("ret cloak Major Agility → not ENCHANT_LOWER_LEVEL", not HasCode(fRet, "ENCHANT_LOWER_LEVEL"))
	Check("ret leather wrist → GOOD (BiS offset)", retLeather.equipment[1].verdict == "A")

	-- Enhancement: Umbrage Armbands (leather wrist) are BiS offsets on mail
	local enhLeather = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 53126,
				category = "armor",
				armorType = "leather",
				stats = { agility = 96, attackPower = 96, critRating = 64, hasteRating = 64, stamina = 96 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40118, color = "red", isMeta = false } },
			})),
		},
	}
	local fEnhWrist = self:EvaluateGearCheck(enhLeather)
	Check("enh leather wrist → not ARMOR_UNWANTED", not HasCode(fEnhWrist, "ARMOR_UNWANTED"))
	Check("enh leather wrist → GOOD (BiS offset)", enhLeather.equipment[1].verdict == "A")

	-- Resto Druid: cloth chest is BiS-acceptable and should be GOOD
	local restoCloth = {
		character = { classFile = "DRUID", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 51379,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 80, spellPower = 100, spirit = 60, hasteRating = 50 },
				enchant = { enchantId = 3832, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 37835,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 74 },
			})),
		},
	}
	local fResto = self:EvaluateGearCheck(restoCloth)
	Check("resto cloth chest → not ARMOR_UNWANTED", not HasCode(fResto, "ARMOR_UNWANTED"))
	Check("resto cloth chest → GOOD", restoCloth.equipment[1].verdict == "A")
	Check("resto Je'Tze's Bell → not TRINKET_NOT_PREFERRED", not HasCode(fResto, "TRINKET_NOT_PREFERRED"))

	-- Blood DK: Pinnacle shoulders + armor cloak/gloves must not false-flag
	local bloodTank = {
		character = { classFile = "DEATHKNIGHT", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 40,
				category = "armor",
				armorType = "plate",
				stats = { stamina = 80, defenseRating = 40, dodgeRating = 30, strength = 40 },
				enchant = { enchantId = 3811, present = true, known = true, gaps = {} },
			})),
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 41,
				category = "armor",
				armorType = "cloth",
				stats = { stamina = 60, defenseRating = 40, strength = 30 },
				enchant = { enchantId = 3294, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 42,
				category = "armor",
				armorType = "plate",
				stats = { stamina = 70, defenseRating = 40, strength = 35 },
				enchant = { enchantId = 3860, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fBlood = self:EvaluateGearCheck(bloodTank)
	Check("blood Pinnacle → not ENCHANT_BAD_STAT", not HasCode(fBlood, "ENCHANT_BAD_STAT"))
	Check("blood Mighty Armor cloak → not ENCHANT_BAD_STAT", not HasCode(fBlood, "ENCHANT_BAD_STAT"))
	Check("blood Armor Webbing → not ENCHANT_NOT_CHECKABLE", not HasCode(fBlood, "ENCHANT_NOT_CHECKABLE"))

	-- Phase 8: unknown gem → not-checkable (info), not false GEM_LOWER_LEVEL
	local unkGem = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 21,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 999001, present = true, known = true, isMeta = false, color = "red", stats = { strength = 20 }, gaps = {} },
				},
			})),
		},
	}
	local fGem = self:EvaluateGearCheck(unkGem)
	Check("unknown gem → GEM_NOT_CHECKABLE", HasCode(fGem, "GEM_NOT_CHECKABLE"))
	Check("unknown gem → not GEM_LOWER_LEVEL", not HasCode(fGem, "GEM_LOWER_LEVEL"))
	Check("unknown gem → still OK (no false REPLACE)", unkGem.equipment[1].verdict == "B")

	-- Catalogued epic gem is max-level
	local epicGem = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 22,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 40111, present = true, known = true, isMeta = false, color = "red", stats = { strength = 20 }, gaps = {} },
				},
			})),
		},
	}
	local fEpic = self:EvaluateGearCheck(epicGem)
	Check("epic catalog gem → not GEM_LOWER_LEVEL", not HasCode(fEpic, "GEM_LOWER_LEVEL"))

	-- JC Dragon's Eye (Bold) is catalogued max-level, not unknown
	local jcGem = {
		character = { classFile = "DEATHKNIGHT", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 24,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 42142, present = true, known = true, isMeta = false, color = "red", stats = {}, gaps = {} },
				},
			})),
		},
	}
	local fJc = self:EvaluateGearCheck(jcGem)
	Check("JC Bold Dragon's Eye → not GEM_NOT_CHECKABLE", not HasCode(fJc, "GEM_NOT_CHECKABLE"))
	Check("JC Bold Dragon's Eye → not GEM_LOWER_LEVEL", not HasCode(fJc, "GEM_LOWER_LEVEL"))

	-- Stormjewel (Dalaran fishing) is catalogued max-level, not unknown
	local stormjewel = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("waist", "WaistSlot", MakeItem({
				itemId = 45824,
				category = "armor",
				armorType = "plate",
				stats = { strength = 87, stamina = 124, critRating = 60, hitRating = 49 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 1, total = 1, empty = 0 },
				gems = {
					{ socketIndex = 1, itemId = 45862, present = true, known = true, isMeta = false, color = "red", stats = { strength = 20 }, gaps = {} },
				},
			})),
		},
	}
	local fStorm = self:EvaluateGearCheck(stormjewel)
	Check("Bold Stormjewel → not GEM_NOT_CHECKABLE", not HasCode(fStorm, "GEM_NOT_CHECKABLE"))
	Check("Bold Stormjewel → not GEM_LOWER_LEVEL", not HasCode(fStorm, "GEM_LOWER_LEVEL"))

	-- Engineering Nitro Boosts on feet is max-level
	local nitro = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("feet", "FeetSlot", MakeItem({
				itemId = 23,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, intellect = 30, attackPower = 60 },
				enchant = { enchantId = 3606, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fNitro = self:EvaluateGearCheck(nitro)
	Check("nitro boots → not ENCHANT_NOT_CHECKABLE", not HasCode(fNitro, "ENCHANT_NOT_CHECKABLE"))
	Check("nitro boots → not ENCHANT_LOWER_LEVEL", not HasCode(fNitro, "ENCHANT_LOWER_LEVEL"))

	-- Icescale leg armor recognized
	local iceLeg = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("legs", "LegsSlot", MakeItem({
				itemId = 24,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, intellect = 40, attackPower = 80 },
				enchant = { enchantId = 3823, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fLeg = self:EvaluateGearCheck(iceLeg)
	Check("icescale legs → not ENCHANT_NOT_CHECKABLE", not HasCode(fLeg, "ENCHANT_NOT_CHECKABLE"))
	Check("icescale legs → not ENCHANT_LOWER_LEVEL", not HasCode(fLeg, "ENCHANT_LOWER_LEVEL"))

	-- +10 all stats chest enchant / Nightmare Tear: spirit is packaged, not a bad pick
	local allStats = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 25,
				category = "armor",
				armorType = "mail",
				stats = { agility = 80, intellect = 50, attackPower = 100 },
				enchant = { enchantId = 3832, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 1, total = 1, empty = 0 },
				gems = {
					{ socketIndex = 1, itemId = 49110, present = true, known = true, isMeta = false, color = "prismatic", stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 }, gaps = {} },
				},
			})),
		},
	}
	local fAll = self:EvaluateGearCheck(allStats)
	Check("powerful stats chest → not ENCHANT_BAD_STAT", not HasCode(fAll, "ENCHANT_BAD_STAT"))
	Check("nightmare tear → not GEM_BAD_STAT", not HasCode(fAll, "GEM_BAD_STAT"))

	-- BiS surface: Fury dual-wield expects off-hand; leather offset OK; 2H preferred
	local furyOh = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 50,
				category = "weapon",
				weaponType = "axe2h",
				stats = { strength = 80, stamina = 80 },
				enchant = { enchantId = 3789, present = true, known = true, gaps = {} },
			})),
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 51,
				category = "armor",
				armorType = "leather",
				stats = { strength = 40, stamina = 40, attackPower = 50 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 50362,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 54573,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 100 },
			})),
		},
	}
	local fFury = self:EvaluateGearCheck(furyOh)
	Check("fury missing OH → WEAPON_SETUP", HasCode(fFury, "WEAPON_SETUP"))
	Check("fury leather wrist → not ARMOR_UNWANTED", not HasCode(fFury, "ARMOR_UNWANTED"))
	Check("fury axe2h → not WEAPON_UNWANTED", not HasCode(fFury, "WEAPON_UNWANTED"))
	Check("fury DBW trinket → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fFury, "TRINKET_NOT_PREFERRED", "trinket1"))
	Check("fury glowing scale → TRINKET_NOT_PREFERRED", HasCodeOnSlot(fFury, "TRINKET_NOT_PREFERRED", "trinket2"))

	local furyToC = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 47464,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
		},
	}
	local fFuryToC = self:EvaluateGearCheck(furyToC)
	Check("fury Death's Choice → not TRINKET_NOT_PREFERRED", not HasCode(fFuryToC, "TRINKET_NOT_PREFERRED"))
	Check("fury Death's Choice → OK not GOOD", furyToC.equipment[1].verdict == "B")

	local retStarterTrinkets = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 49074,
				category = "armor",
				armorType = "misc",
				stats = { critRating = 84 },
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 47734,
				category = "armor",
				armorType = "misc",
				stats = { hitRating = 128 },
			})),
		},
	}
	local fRetStarter = self:EvaluateGearCheck(retStarterTrinkets)
	Check("ret Coren's Coaster → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fRetStarter, "TRINKET_NOT_PREFERRED", "trinket1"))
	Check("ret Coren's Coaster → OK not GOOD", retStarterTrinkets.equipment[1].verdict == "B")
	Check("ret Mark of Supremacy → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fRetStarter, "TRINKET_NOT_PREFERRED", "trinket2"))
	Check("ret Mark of Supremacy → OK not GOOD", retStarterTrinkets.equipment[2].verdict == "B")

	local retAbom = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 50706,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
		},
	}
	local fRetAbom = self:EvaluateGearCheck(retAbom)
	Check("ret Tiny Abom → not TRINKET_NOT_PREFERRED", not HasCode(fRetAbom, "TRINKET_NOT_PREFERRED"))

	-- Tank leather stays unwanted
	local tankLeather = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 52,
				category = "armor",
				armorType = "leather",
				stats = { stamina = 50, defenseRating = 30 },
				enchant = { enchantId = 3850, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 53,
				category = "armor",
				armorType = "shield",
				stats = { stamina = 80, blockRating = 40 },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 54,
				category = "weapon",
				weaponType = "axe1h",
				stats = { strength = 50, stamina = 50 },
				enchant = { enchantId = 3789, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fTank = self:EvaluateGearCheck(tankLeather)
	Check("prot leather wrist → ARMOR_UNWANTED", HasCode(fTank, "ARMOR_UNWANTED"))

	-- Disc priest: Reckless Ametrine (SP+haste), Greater Spirit boots, Lunar Dust,
	-- staff Greater Spellpower, wand without enchant.
	local discFix = {
		character = { classFile = "PRIEST", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("waist", "WaistSlot", MakeItem({
				itemId = 60,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, spirit = 30 },
				sockets = { meta = 0, red = 0, yellow = 1, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40155, color = "orange", isMeta = false } },
			})),
			MakeSlot("feet", "FeetSlot", MakeItem({
				itemId = 61,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, spirit = 30 },
				enchant = { enchantId = 1147, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 50358,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 179 },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 62,
				category = "weapon",
				weaponType = "staff",
				stats = { intellect = 80, spellPower = 200, spirit = 60 },
				enchant = { enchantId = 3854, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 2, yellow = 0, blue = 0, prismatic = 0, total = 2, empty = 0 },
				gems = {
					{ itemId = 40155, color = "orange", isMeta = false },
					{ itemId = 40155, color = "orange", isMeta = false },
				},
			})),
			MakeSlot("ranged", "RangedSlot", MakeItem({
				itemId = 63,
				category = "weapon",
				weaponType = "wand",
				stats = { intellect = 20, spellPower = 40, spirit = 20 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local fDisc = self:EvaluateGearCheck(discFix)
	Check("disc Reckless Ametrine → not GEM_BAD_STAT", not HasCode(fDisc, "GEM_BAD_STAT"))
	Check("disc Greater Spirit boots → not ENCHANT_NOT_CHECKABLE", not HasCode(fDisc, "ENCHANT_NOT_CHECKABLE"))
	Check("disc Purified Lunar Dust → not TRINKET_NOT_PREFERRED", not HasCode(fDisc, "TRINKET_NOT_PREFERRED"))
	Check("disc staff Greater Spellpower → not ENCHANT_NOT_CHECKABLE", not HasCodeOnSlot(fDisc, "ENCHANT_NOT_CHECKABLE", "mainHand"))
	Check("disc wand → not MISSING_ENCHANT", not HasCodeOnSlot(fDisc, "MISSING_ENCHANT", "ranged"))
	Check("disc wand → GOOD (no enchant required)", discFix.equipment[5].verdict == "A")

	-- Resto Shaman: Flexweave cloak ok; held OH (no spirit/hit) ok and unenchantable
	local restoSham = {
		character = { classFile = "SHAMAN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 70,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, hasteRating = 30 },
				enchant = { enchantId = 3859, present = true, known = true, gaps = {} },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 71,
				category = "weapon",
				weaponType = "mace1h",
				stats = { intellect = 50, spellPower = 400 },
				enchant = { enchantId = 3834, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 50309,
				category = "armor",
				armorType = "offhand",
				stats = { intellect = 34, spellPower = 78, critRating = 51, hasteRating = 50, stamina = 54 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local fRestoSham = self:EvaluateGearCheck(restoSham)
	Check("resto sham Flexweave → not ENCHANT_BAD_STAT", not HasCode(fRestoSham, "ENCHANT_BAD_STAT"))
	Check("resto sham held OH → not MISSING_ENCHANT", not HasCodeOnSlot(fRestoSham, "MISSING_ENCHANT", "offHand"))
	Check("resto sham held OH (no spirit/hit) → not WEAPON_SETUP", not HasCode(fRestoSham, "WEAPON_SETUP"))
	Check("resto sham held OH → GOOD", restoSham.equipment[3].verdict == "A")

	-- Resto Shaman: Royal Dreadstone (+12 SP / +5 mp5) and Spellsurge weapon enchant are healer-ok
	local restoShamCatalog = {
		character = { classFile = "SHAMAN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 51194,
				category = "armor",
				armorType = "mail",
				stats = { intellect = 92, spellPower = 132, hasteRating = 72 },
				enchant = { enchantId = 3809, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 1, prismatic = 0, total = 1, empty = 0 },
				gems = {
					{ itemId = 40134, color = "purple", isMeta = false },
				},
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 50428,
				category = "weapon",
				weaponType = "mace1h",
				stats = { intellect = 71, spellPower = 792 },
				enchant = { enchantId = 2674, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 49976,
				category = "armor",
				armorType = "shield",
				stats = { intellect = 69, spellPower = 106 },
				enchant = { enchantId = 1128, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fRestoCat = self:EvaluateGearCheck(restoShamCatalog)
	Check("resto sham Royal Dreadstone → not GEM_BAD_STAT", not HasCode(fRestoCat, "GEM_BAD_STAT"))
	Check("resto sham Spellsurge → not ENCHANT_NOT_CHECKABLE", not HasCode(fRestoCat, "ENCHANT_NOT_CHECKABLE"))
	Check("resto sham Spellsurge → not ENCHANT_BAD_STAT", not HasCode(fRestoCat, "ENCHANT_BAD_STAT"))
	Check("resto sham Royal/Spellsurge shoulder → GOOD", restoShamCatalog.equipment[1].verdict == "A")

	-- Fire Mage: Veiled Ametrine (+12 SP / +10 hit) and Sanctified Spellthread (tailoring legs)
	local fireMageCatalog = {
		character = { classFile = "MAGE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 47552,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 74, spellPower = 105, critRating = 65, hasteRating = 57 },
				enchant = { enchantId = 3722, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = {
					{ itemId = 40153, color = "orange", isMeta = false },
				},
			})),
			MakeSlot("legs", "LegsSlot", MakeItem({
				itemId = 51282,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 139, spellPower = 195, critRating = 122, hitRating = 106 },
				enchant = { enchantId = 3872, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 1, blue = 1, prismatic = 0, total = 2, empty = 0 },
				gems = {
					{ itemId = 40133, color = "purple", isMeta = false },
					{ itemId = 40152, color = "orange", isMeta = false },
				},
			})),
		},
	}
	local fFireCat = self:EvaluateGearCheck(fireMageCatalog)
	Check("fire mage Veiled Ametrine → not GEM_BAD_STAT", not HasCode(fFireCat, "GEM_BAD_STAT"))
	Check("fire mage Sanctified Spellthread → not ENCHANT_NOT_CHECKABLE", not HasCode(fFireCat, "ENCHANT_NOT_CHECKABLE"))
	Check("fire mage Sanctified Spellthread → not ENCHANT_BAD_STAT", not HasCode(fFireCat, "ENCHANT_BAD_STAT"))
	Check("fire mage Veiled cloak → GOOD", fireMageCatalog.equipment[1].verdict == "A")

	-- Cardinal Ruby Subtle/Precise stats (not expertise/hit swapped)
	local subtleRuby = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 1,
				category = "armor",
				armorType = "plate",
				stats = { strength = 50, stamina = 50, dodgeRating = 40, defenseRating = 40 },
				enchant = { enchantId = 3818, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40115, color = "red", isMeta = false } },
			})),
		},
	}
	local fSubtle = self:EvaluateGearCheck(subtleRuby)
	Check("prot warrior Subtle Cardinal Ruby → not GEM_BAD_STAT", not HasCode(fSubtle, "GEM_BAD_STAT"))

	-- Uncommon Northrend gem → soft GEM_LOWER_LEVEL (not not-checkable)
	local uncommonGem = {
		character = { classFile = "MAGE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 2,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, hasteRating = 30 },
				enchant = { enchantId = 2332, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 1, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 39918, color = "yellow", isMeta = false } },
			})),
		},
	}
	local fUnc = self:EvaluateGearCheck(uncommonGem)
	Check("Quick Sun Crystal → GEM_LOWER_LEVEL", HasCode(fUnc, "GEM_LOWER_LEVEL"))
	Check("Quick Sun Crystal → not GEM_NOT_CHECKABLE", not HasCode(fUnc, "GEM_NOT_CHECKABLE"))
	Check("Quick Sun Crystal → not GEM_BAD_STAT", not HasCode(fUnc, "GEM_BAD_STAT"))

	-- Resto Druid: 2H staff with empty OH is an acceptable temporary variant
	local restoStaff = {
		character = { classFile = "DRUID", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 54806,
				category = "weapon",
				weaponType = "staff",
				stats = { intellect = 92, spellPower = 550, critRating = 80, hasteRating = 80 },
				enchant = { enchantId = 3854, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", nil),
		},
	}
	local fRestoStaff = self:EvaluateGearCheck(restoStaff)
	Check("resto druid 2H staff → not WEAPON_SETUP", not HasCode(fRestoStaff, "WEAPON_SETUP"))
	Check("resto druid 2H staff → GOOD", restoStaff.equipment[1].verdict == "A")

	-- Combat Rogue: crossbow in ranged is acceptable; no enchant required.
	local rogueXbow = {
		character = { classFile = "ROGUE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("ranged", "RangedSlot", MakeItem({
				itemId = 50733,
				category = "weapon",
				weaponType = "crossbow",
				stats = { agility = 62, attackPower = 66, critRating = 41 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local fXbow = self:EvaluateGearCheck(rogueXbow)
	Check("rogue crossbow → not WEAPON_FORBIDDEN", not HasCode(fXbow, "WEAPON_FORBIDDEN"))
	Check("rogue crossbow → not MISSING_ENCHANT", not HasCodeOnSlot(fXbow, "MISSING_ENCHANT", "ranged"))

	-- Holy Paladin: cloth legs + shield blockValue are acceptable (not BAD).
	local holyCloth = {
		character = { classFile = "PALADIN", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("legs", "LegsSlot", MakeItem({
				itemId = 50694,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 139, spellPower = 185, hasteRating = 116 },
				enchant = { enchantId = 3721, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 50616,
				category = "armor",
				armorType = "shield",
				stats = { intellect = 78, spellPower = 110, blockValue = 259, armor = 9262 },
				enchant = { enchantId = 1128, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fHoly = self:EvaluateGearCheck(holyCloth)
	Check("holy cloth legs → not ARMOR_FORBIDDEN", not HasCode(fHoly, "ARMOR_FORBIDDEN"))
	Check("holy shield blockValue → not STAT_FORBIDDEN", not HasCode(fHoly, "STAT_FORBIDDEN"))

	-- Prot Pala: melee DPS trinkets are situational (info), not REPLACE.
	local protTrink = {
		character = { classFile = "PALADIN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 54590,
				category = "armor",
				armorType = "misc",
				stats = { armorPenetration = 184 },
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 50351,
				category = "armor",
				armorType = "misc",
				stats = { hitRating = 85 },
			})),
		},
	}
	local fProtTrink = self:EvaluateGearCheck(protTrink)
	Check("prot pala Sharpened Scale → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fProtTrink, "TRINKET_NOT_PREFERRED", "trinket1"))
	Check("prot pala Tiny Abom → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fProtTrink, "TRINKET_NOT_PREFERRED", "trinket2"))
	Check("prot pala Sharpened Scale → TRINKET_SITUATIONAL", HasCodeOnSlot(fProtTrink, "TRINKET_SITUATIONAL", "trinket1"))

	-- Below-max enchant is info only (does not demote to REPLACE).
	local lowerEnch = {
		character = { classFile = "PALADIN", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 70,
				category = "armor",
				armorType = "plate",
				stats = { intellect = 80, spellPower = 100, hasteRating = 60 },
				enchant = { enchantId = 3233, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fLower = self:EvaluateGearCheck(lowerEnch)
	Check("Mighty Health → ENCHANT_LOWER_LEVEL info", HasCode(fLower, "ENCHANT_LOWER_LEVEL"))
	Check("Mighty Health → chest not REPLACE", lowerEnch.equipment[1].verdict ~= "C")

	-- Accepted physical progression trinkets must not be flagged for replacement.
	local physicalSpecs = {
		{ "WARRIOR", 1 }, { "WARRIOR", 2 }, { "PALADIN", 3 },
		{ "HUNTER", 1 }, { "HUNTER", 2 }, { "HUNTER", 3 },
		{ "ROGUE", 1 }, { "ROGUE", 2 }, { "ROGUE", 3 },
		{ "DEATHKNIGHT", 2 }, { "DEATHKNIGHT", 3 },
		{ "SHAMAN", 2 }, { "DRUID", 2 },
	}
	for specIndex = 1, #physicalSpecs do
		local spec = physicalSpecs[specIndex]
		local skullReport = {
			character = { classFile = spec[1], specTab = spec[2], specKnown = true, gaps = {} },
			equipment = {},
		}
		for variant = 1, 2 do
			skullReport.equipment[variant] = MakeSlot("trinket" .. variant, "Trinket" .. (variant - 1) .. "Slot", MakeItem({
				itemId = 50341 + variant,
				category = "armor",
				armorType = "misc",
				stats = { critRating = 131 },
			}))
		end
		local skullFindings = self:EvaluateGearCheck(skullReport)
		Check(spec[1] .. spec[2] .. " accepts both Whispering Fanged Skull variants", not HasCode(skullFindings, "TRINKET_NOT_PREFERRED"))
	end

	-- Acceptable healer enchants remain B, without replacement/bad-stat findings.
	local healerSpecs = { { "PALADIN", 1 }, { "PRIEST", 1 }, { "PRIEST", 2 }, { "SHAMAN", 3 }, { "DRUID", 3 } }
	for specIndex = 1, #healerSpecs do
		local spec = healerSpecs[specIndex]
		local healerReport = {
			character = { classFile = spec[1], specTab = spec[2], specKnown = true, gaps = {} },
			equipment = {
				MakeSlot("chest", "ChestSlot", MakeItem({
					category = "armor", armorType = "cloth",
					stats = { intellect = 80, spellPower = 100 },
					enchant = { enchantId = 3233, present = true, known = true, gaps = {} },
				})),
			},
		}
		if (spec[1] == "PRIEST" and spec[2] == 2) or spec[1] == "DRUID" then
			healerReport.equipment[2] = MakeSlot("wrist", "WristSlot", MakeItem({
				category = "armor", armorType = "cloth",
				stats = { intellect = 80, spellPower = 100, spirit = 60 },
				enchant = { enchantId = 2326, present = true, known = true, gaps = {} },
			}))
		end
		local healerFindings = self:EvaluateGearCheck(healerReport)
		Check(spec[1] .. spec[2] .. " accepts healer enchants", not HasCode(healerFindings, "ENCHANT_BAD_STAT"))
		for slotIndex = 1, #healerReport.equipment do
			Check(spec[1] .. spec[2] .. " acceptable enchant slot " .. slotIndex .. " stays B", healerReport.equipment[slotIndex].verdict == "B")
		end
	end

	local profileCount = 0
	if self.GetGearCheckProfileCount then
		profileCount = self:GetGearCheckProfileCount() or 0
	end
	Check("profiles cover 30 specs + 10 class fallbacks", profileCount == 40)

	if self.GearCheckSavedReportsSelfTest then
		local savedResults = self:GearCheckSavedReportsSelfTest()
		for index = 1, #savedResults do
			results[#results + 1] = savedResults[index]
		end
	end

	local passed = 0
	for index = 1, #results do
		if results[index].ok then
			passed = passed + 1
		end
	end
	return results, passed, #results
end
