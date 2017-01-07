--[[
Author: Dolgubon
Filename: LibLazyCrafting.lua
Version: 0.1
]]--


local libLoaded
local LIB_NAME, VERSION = "LibLazyCrafting", 0.1
local LibLazyCrafting, oldminor = LibStub:NewLibrary(LIB_NAME, VERSION)
if not LibLazyCrafting then return end

local SetIndexes = -- First is the name of the set. Second is the name of the equipment. Third is the number of required traits.
{
	[0]  = {"No Set"						,"No Set"					,0},
	[1]  = {"Death's Wind"					,"Death's Wind"				,2},
	[2]  = {"Night's Silence"				,"Night's Silence"			,2},
	[3]  = {"Ashen Grip"					,"Ashen Grip"				,2},
	[4]  = {"Torug's Pact"					,"Torug's Pact"				,3},
	[5]  = {"Twilight's Embrace"			,"Twilight's Embrace"		,3},
	[6]  = {"Armour of the Seducer"			,"Seducer"					,3},
	[7]  = {"Magnus' Gift"					,"Magnus'"					,4},
	[8]  = {"Hist Bark"						,"Hist Bark"				,4},
	[9]  = {"Whitestrake's Retribution"		,"Whitestrake's"			,4},
	[10] = {"Vampire's Kiss"				,"Vampire's Kiss"			,5},
	[11] = {"Song of the Lamae"				,"Song of the Lamae"		,5},
	[12] = {"Alessia's Bulwark"				,"Alessia's Bulwark"		,5},
	[13] = {"Night Mother's Gaze"			,"Night Mother"				,6},
	[14] = {"Willow's Path"					,"Willow's Path"			,6},
	[15] = {"Hunding's Rage"				,"Hunding's Rage"			,6},
	[16] = {"Kagrenac's Hope"				,"Kagrenac's Hope"			,8},
	[17] = {"Orgnum's Scales"				,"Orgnum's Scales"			,8},
	[18] = {"Eyes of Mara"					,"Eyes of Mara"				,8},
	[19] = {"Shalidor's Curse"				,"Shalidor's Curse"			,8},
	[20] = {"Oblivion's Foe"				,"Oblivion's Foe"			,8},
	[21] = {"Spectre's Eye"					,"Spectre's Eye"			,8},
	[22] = {"Way of the Arena"				,"Arena"					,8},
	[23] = {"Twice-Born Star"				,"Twice Born Star"			,9},
	[24] = {"Noble's Conquest"				,"Noble's Conquest"			,5},
	[25] = {"Redistributor"					,"Redistributor"			,7},
	[26] = {"Armour Master"					,"Armor Master"				,9},
	[27] = {"Trial by Fire"					,"Trials"					,3},
	[28] = {"Law of Julianos"				,"Julianos"					,6},
	[29] = {"Morkudlin"						,"Morkudlin"				,9},
	[30] = {"Tava's Favour"					,"Tava's Favor"				,5},
	[31] = {"Clever Alchemist"				,"Clever Alchemist"			,7},
	[32] = {"Eternal Hunt"					,"Eternal Hunt"				,9},
	[33] = {"Kvatch Gladiator"				,"Gladiator's"				,5},
	[34] = {"Varen's Legacy"				,"Varen's Legacy"			,7},
	[35] = {"Pelinal's Aptitude"			,"Pelinal's"				,9},

}

local qualityIndexes = 
{
	[0] = "White",
	[1] = "Green",
	[2] = "Blue",
	[3] = "Epic",
	[4] = "Gold",
}


local craftResultFunctions = 
{

}
--GetItemLinkSetInfo(string itemLink, boolean equipped)
--GetItemLinkInfo(string itemLink)
--GetItemId(number bagId, number slotIndex)
--|H1:item:72129:369:50:26845:370:50:0:0:0:0:0:0:0:0:0:15:1:1:0:17:0|h|h
--[[
/script 


|H1:item:43849:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0
|H1:item:48711:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h
|H1:item:48711:30:1:0:0:0:0:0:0:0:0:0:0:0:0:2:0:0:0:10000:0|h|h
]]

local craftingQueue = 
{
	[CRAFTING_TYPE_WOODWORKING] = {},
	[CRAFTING_TYPE_BLACKSMITHING] = {},
	[CRAFTING_TYPE_CLOTHIER] = {},
	[CRAFTING_TYPE_ENCHANTING] = {},
	[CRAFTING_TYPE_ALCHEMY] = {},
	[CRAFTING_TYPE_PROVISIONING] = {},
}

--Template for a craft request. Changes into an improvement request after crafting
local CraftSmithingRequestItem = 
{
	["pattern"] =0,
	["style"] = 0,
	["trait"] = 0,
	["materialIndex"] = 0,
	["materialQuantity"] = 0,
	["setIndex"] = 0,
	["quality"] = 0,
}

--Template for an improvement request
local ImprovementRequestItem = 
{
	["ItemLink"] = "",
	["ItemBagID"] = 0,
	["ItemSlotID"] = 0,
	["ItemUniqueID"] = 0,
	["ItemCreater"] = "",
	["FinalQuality"] = 0,
}

local CraftGlyphRequest = 
{
	["essenceItemID"] = 0,
	["aspectItemID"] = 0,
	["potencyItemID"] = 0,
}

local CraftAlchemyRequest = 
{
	["SolvenItemID"] = 0,
	["Reagents"] = 
	{
		[1] = 0,
		[2] = 0,
		[3] = 0,
	}
}

local ProvisioningRequest = 
{
	["RecipeID"] = 0,
}

local waitingOnCraftComplete = 
{
	["craftFunction"] = function() end,
	["slotID"] = 0,
	["itemLink"] = "",
	["creater"] = "",
	["finalQuality"] = "",
}


function GetID(itemLink) return string.match(itemLink,"|H%d:item:(%d+)") end

-- Returns SetIndex, Set Full Name, Set Item Name, Traits Required
function GetCurrentSetInteractionIndex()
	local baseSetPatternName
	local baseSetPatternName
	local currentStation = GetCraftingInteractionType()
	if currentStation == CRAFTING_TYPE_BLACKSMITHING then
		baseSetPatternName = GetSmithingPatternInfo(15)
	elseif currentStation == CRAFTING_TYPE_CLOTHIER then
		baseSetPatternName = GetSmithingPatternInfo(16)
	elseif currentStation == CRAFTING_TYPE_WOODWORKING then
		baseSetPatternName = GetSmithingPatternInfo(7)
	else
		return nil , nil, nil, nil
	end
	for i =1, #SetIndexes do
		if string.find(baseSetPatternName, SetIndexes[i][2]) then
			return i, SetIndexes[i][1], SetIndexes[i][2] , SetIndexes[i][3]
		end
	end
	return 0, SetIndexes[0][1], SetIndexes[0][2] , SetIndexes[0][3]
end

function canCraftItemHere(station, setIndex)
	if GetCraftingInteractionType()==station then
		if GetCurrentSetInteractionIndex(setIndex)==setIndex or setIndex==0 then
			return true
		end
	end
	return false

end


function LibLazyCrafting:Init()

	-- Same as the normal crafting function, with a few extra parameters.
	-- StationOverride 
	function LLC_CraftSmithingItem(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, useUniversalStyleItem, stationOverride, setIndex, quality)
		local station
		--Handle the extra values. If they're nil, assign default values.
		if not quality then setIndex = 0 end
		if not quality then quality = 0 end
		if not stationOverride then 
			if overallStationOverride then
				station = overallStationOverride
			else
				station = GetCraftingInteractionType()
				if station == 0 then
					d("Error: You must be at a crafting station, or specify a station Override")
				end
			end
		else
			station = stationOverride
		end
		local SmithingRequest = 
		{
			["pattern"] =patternIndex,
			["style"] = styleIndex,
			["trait"] = traitIndex,
			["materialIndex"] = materialIndex,
			["materialQuantity"] = materialQuantity,
			["setIndex"] = setIndex,
			["quality"] = quality,
		}

		if canCraftItemHere(station, setIndex) then
			if quality>0 then
				local slotID = FindFirstEmptySlotInBag(BAG_BACKPACK)
				local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, 0)
				CraftSmithingItem(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, useUniversalStyleItem)

				local ItemCreater = GetDisplayName()
				local FinalQuality = quality

				return
			else
				CraftSmithingItem(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, useUniversalStyleItem)
			end
		else
			craftingQueue[station] = SmithingRequest
		end
	end

	-- Since bag indexes can change, this ignores those. Instead, it takes in the name, or the index (table of indexes is found in table above, and is specific to this library)
	-- Bag indexes will be determined at time of crafting	
	function LLC_CraftEnchantingGlyphByTypes(PotencyNameOrIndex, EssenceNameOrIndex, AspectNameOrIndex)
	end

	function LLC_CraftAlchemyItem(SolventNameOrIndex, IngredientNameOrIndexOne, IngredientNameOrIndexTwo, IngredientNameOrIndexThree)
	end

	function LLC_GetQueue(Station)
	end

	function LLC_RemoveQueueItem(index)
	end

	function LLC_ClearQueue()
	end

	function LLC_GetSmithingResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, useUniversalStyleItem, linkstyle, stationOverride, setIndex, quality)
	end

	function LLC_GetSmithingPatternInfo(patternIndex, station, set)
	end

	-- We do take the bag and slot index here, because we need to know what to upgrade
	function LLC_ImproveSmithingItem(BagIndex, SlotIndex, newQuality)
	end

	-- Why use this instead of the EVENT_CRAFT_COMPLETE?
	-- Using this will allow the library to tell you how the craft failed, at least for some problems.
	-- Or that the craft was completed.
	-- AddonName is your addon. It will be used as a reference to the function
	-- funct is the function that will be called where:
	-- funct(event, station, LLCResult)
	function LLC_SetCraftCompleteFunction(AddonName, funct)
		craftResultFunctions[AddonName] = funct
	end

end

local function CraftInteract(event, station)


end


local function CraftComplete(event, station)
	local LLCResult = nil
	for k, v in pairs(craftResultFunctions) do
		v(event, station, LLCResult)
	end
end










local function OnAddonLoaded()
	if not libLoaded then
		libLoaded = true
		local LibLazyCrafting = LibStub('LibLazyCrafting')
		LibLazyCrafting:Init()
		EVENT_MANAGER:UnregisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED)
		EVENT_MANAGER:RegisterForEvent(LIB_NAME, EVENT_CRAFTING_STATION_INTERACT,CraftInteract)
		EVENT_MANAGER:RegisterForEvent(LIB_NAME, EVENT_CRAFT_COMPLETED, CraftComplete)
	end
end

EVENT_MANAGER:RegisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)