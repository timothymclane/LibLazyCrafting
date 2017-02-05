local LibLazyCrafting = LibStub("LibLazyCrafting")
local sortCraftQueue = LibLazyCrafting.sortCraftQueue

--------------------------------------
-- ENCHANTING HELPER FUNCTIONS
local function areIdsValid(potency, essence, aspect)
	if GetItemLinkEnchantingRuneClassification( getItemLinkFromItemId(potency)) ~= ENCHANTING_RUNE_POTENCY
		or GetItemLinkEnchantingRuneClassification( getItemLinkFromItemId(aspect)) ~= ENCHANTING_RUNE_ASPECT
		or GetItemLinkEnchantingRuneClassification( getItemLinkFromItemId(essence)) ~= ENCHANTING_RUNE_ESSENCE then

		return false
	else
		return true
	end
end

local function copy(t)
	local a = {}
	for k, v in pairs(t) do
		a[k] = v
	end
	return a
end



-----------------------------------------------------
-- ENCHANTING USER INTERACTION FUNCTIONS

-- Since bag indexes can change, this ignores those. Instead, it takes in the name, or the index (table of indexes is found in table above, and is specific to this library)
-- Bag indexes will be determined at time of crafting	
local function LLC_CraftEnchantingGlyphItemID(self, potencyItemID, essenceItemID, aspectItemID, autocraft)

	if not self then d("Please call with colon notation") end
	if autocraft==nil then autocraft = self.autocraft end
	if not potencyItemID or not essenceItemID or not aspectItemID then  return end
	if not areIdsValid(potencyItemID, essenceItemID, aspectItemID) then d("invalid essence Ids") return end

	table.insert(craftingQueue[self.addonName][CRAFTING_TYPE_ENCHANTING],
	{
		["potencyItemID"] = potencyItemID,
		["essenceItemID"] = essenceItemID,
		["aspectItemID"] = aspectItemID,
		["timestamp"] = GetTimeStamp(),
		["autocraft"] = autocraft,
		["Requester"] = self.addonName,
	}
	)

	sortCraftQueue()
	if GetCraftingInteractionType()==CRAFTING_TYPE_ENCHANTING then 
		LibLazyCrafting.craftInteract(event, CRAFTING_TYPE_ENCHANTING) end
end

local function LLC_CraftEnchantingGlyph(self, potencyBagId, potencySlot, essenceBagId, essenceSlot, aspectBagId, aspectSlot)
	LLC_CraftEnchantingGlyphItemID(self, GetItemId(potencyBagId, potencySlot),GetItemId(essenceBagId, essenceSlot),GetItemId(aspectBagId,aspectSlot))
end

------------------------------------------------------------------------
-- ENCHANTING STATION INTERACTION FUNCTIONS

local currentCraftAttempt = 
{
	["essenceItemID"] = 0,
	["aspectItemID"] = 0,
	["potencyItemID"] = 0,
	["timestamp"] = 1234566789012345,
	["autocraft"] = true,
	["Requester"] = "",
	["slot"]  = 0,
	["link"] = "",
	["callback"] = function() end,
	["position"] = 0,

}

timeGiven = 1800
local function LLC_EnchantingCraftinteraction(event, station)
	local earliest, addon , position = LibLazyCrafting.findEarliestRequest(CRAFTING_TYPE_ENCHANTING)
	if earliest then
		local locations = 
		{
		select(1,findItemLocationById(earliest["potencyItemID"])),
		select(2,findItemLocationById(earliest["potencyItemID"])),
		select(1,findItemLocationById(earliest["essenceItemID"])),
		select(2,findItemLocationById(earliest["essenceItemID"])),
		findItemLocationById(earliest["aspectItemID"]),
		}
		if locations[1] and locations[5] and locations[3] then
			d("craft")
			CraftEnchantingItem(unpack(locations))
			
			currentCraftAttempt= copy(earliest)
			currentCraftAttempt.callback = LibLazyCrafting.craftResultFunctions[addon]
			currentCraftAttempt.slot = FindFirstEmptySlotInBag(BAG_BACKPACK)
			currentCraftAttempt.link = GetEnchantingResultingItemLink(unpack(locations))
			currentCraftAttempt.position = position
			currentCraftAttempt.timestamp = GetTimeStamp()
			currentCraftAttempt.addon = addon

			ENCHANTING.potencySound = SOUNDS["NONE"]
			ENCHANTING.potencyLength = 0
			ENCHANTING.essenceSound = SOUNDS["NONE"]
			ENCHANTING.essenceLength = 0
			ENCHANTING.aspectSound = SOUNDS["NONE"]
			ENCHANTING.aspectLength = 0
			--zo_callLater(function() SCENE_MANAGER:ShowBaseScene() end, timeGiven)
		end
	end
end


local function LLC_EnchantingCraftingComplete(event, station, lastCheck)

	if GetItemLinkName(GetItemLink(BAG_BACKPACK, currentCraftAttempt.slot,0)) == GetItemLinkName(currentCraftAttempt.link)
		and GetItemLinkQuality(GetItemLink(BAG_BACKPACK, currentCraftAttempt.slot,0)) == GetItemLinkQuality(currentCraftAttempt.link)
		and (GetTimeStamp() - 4000) < currentCraftAttempt.timestamp
	then
	 
		craftingQueue[currentCraftAttempt.addon][CRAFTING_TYPE_ENCHANTING][currentCraftAttempt.position] = nil
		sortCraftQueue()
		local resultTable = 
		{
			["bag"] = BAG_BACKPACK,
			["slot"] = currentCraftAttempt.slot,
			['link'] = currentCraftAttempt.link,
			['uniqueId'] = GetItemUniqueId(BAG_BACKPACK, currentCraftAttempt.slot),
			["quantity"] = 1,
		}
		currentCraftAttempt.callback(LLC_CRAFT_SUCCESS, CRAFTING_TYPE_ENCHANTING, resultTable)
		currentCraftAttempt = {}
	elseif lastCheck then
		-- give up on finding it.
		currentCraftAttempt = {}
	else
		-- further search
		-- search again later
		zo_callLater(function() LLC_EnchantingCraftingComplete(event, station, true) end,100)
	end


end

local function LLC_EnchantingEndInteraction(event ,station)

	local slot = FindFirstEmptySlotInBag(BAG_BACKPACK)
	zo_callLater(function() d(GetItemLink(1,slot)) end, 3000)
	--currentCraftAttempt = nil

end


LibLazyCrafting.craftInteractionTables[CRAFTING_TYPE_ENCHANTING] =
{
	["check"] = function(station) return station == CRAFTING_TYPE_ENCHANTING end,
	['function'] = LLC_EnchantingCraftinteraction,
	["complete"] = LLC_EnchantingCraftingComplete,
	["endInteraction"] = function(station) --[[endInteraction()]] end,
	["isItemCraftable"] = function(station) if station == CRAFTING_TYPE_ENCHANTING then return true else return false end end,
}

LibLazyCrafting.functionTable.CraftEnchantingItemId = LLC_CraftEnchantingGlyphItemID
LibLazyCrafting.functionTable.CraftEnchantingGlyph = LLC_CraftEnchantingGlyph

--- testers:
-- /script LLC_Global:CraftEnchantingItemId(45830, 45838, 45851)

