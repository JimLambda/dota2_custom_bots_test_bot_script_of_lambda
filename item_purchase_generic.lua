local bot = GetBot()
local courier = nil

local currentItemToPurchase
local itemPurchaseThinkMoment = -90

-- Item purchase lists for npc_dota_hero_skeleton_king.
local itemPurchaseListSkeletonKing = {
    "item_boots", "item_crimson_guard", "item_assault", "item_heart",
    "item_aeon_disk", "item_ultimate_scepter", "item_aghanims_shard",
    "item_travel_boots", "item_ultimate_scepter_2", "item_sphere",
    "item_travel_boots_2", "item_moon_shard"
}

function GetTheSmallestComponentListOfABigItem(bigItemName)
    local componentList = {}
    local directComponentStringList = GetItemComponents(bigItemName)
    if #directComponentStringList == 0 then
        table.insert(componentList, bigItemName)
    else
        for directComponentStringListIndex, directComponentName in ipairs(
                                                                       directComponentStringList) do
            table.insert(componentList, GetTheSmallestComponentListOfABigItem(
                             directComponentName))
        end
    end
    return componentList
end

function GetTheDirectComponentListOfABigItem(bigItemName)
    local componentList = {}
    local directComponentStringList = GetItemComponents(bigItemName)
    if #directComponentStringList == 0 then
        table.insert(componentList, bigItemName)
    else
        table.insert(componentList, directComponentStringList)
    end
    return componentList
end

function CheckIfTheBotAlreadyHasThisItem(bot, courier, itemNameToCheck)
    if itemNameToCheck == 'item_ultimate_scepter' and bot:HasScepter() then
        return true
    end
    if itemNameToCheck == 'item_moon_shard' and
        bot:HasModifier("modifier_item_moon_shard_consumed") then return true end
    if itemNameToCheck == 'item_ultimate_scepter_2' then
        return (bot:HasScepter() and bot:FindItemSlot('item_ultimate_scepter') <
                   0)
    end

    local foundItemSlotOnBot = bot:FindItemSlot(itemNameToCheck)
    local foundItemSlotOnCourier = courier:FindItemSlot(itemNameToCheck)

    if foundItemSlotOnBot >= 0 and (foundItemSlotOnBot <= 14) then
        return true
    end
    if foundItemSlotOnCourier >= 0 and (foundItemSlotOnBot <= 8) then
        return true
    end

    return false
end

function PurchaseItem(itemPurchaseList)
    for itemPurchaseListIndex, currentItemInItemPurchaseList in ipairs(
                                                                    itemPurchaseList) do
        repeat
            if next(GetItemComponents(currentItemInItemPurchaseList)) == nil then
                if CheckIfTheBotAlreadyHasThisItem(bot, courier,
                                                   currentItemInItemPurchaseList) then
                    do break end
                else
                    if bot:GetGold() <
                        GetItemCost(currentItemInItemPurchaseList) then
                        return
                    else
						print("Purchasing item!!!!!!"..currentItemInItemPurchaseList)
                        bot:ActionImmediate_PurchaseItem(
                            currentItemInItemPurchaseList)
                    end
                end
            else
                PurchaseItem(GetItemComponents(currentItemInItemPurchaseList))
            end
        until true
    end
end

-- Implement ItemPurchaseThink() to override decisionmaking around item purchasing.
function ItemPurchaseThink()
    if DotaTime() < itemPurchaseThinkMoment then
        return
    else
		if courier == nil then
			courier = GetCourier(bot:GetPlayerID())
		end
        itemPurchaseThinkMoment = itemPurchaseThinkMoment + 0.5
        PurchaseItem(itemPurchaseListSkeletonKing)
    end
end
