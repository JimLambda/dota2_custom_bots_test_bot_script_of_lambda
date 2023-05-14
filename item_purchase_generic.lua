-- TODO Sell scepter or scepter components after having roshan scepter.
local bot = GetBot()
local courier = nil

local RAD_SECRET_SHOP = GetShopLocation(GetTeam(), SHOP_SECRET)
local DIRE_SECRET_SHOP = GetShopLocation(GetTeam(), SHOP_SECRET2)

local currentItemToPurchase
local itemPurchaseThinkMoment = -90
local sellGarbageItemThinkMoment = -90

-- I copied this TablePrint method from stackoverflow, it's used to print the contents of a table(/list). url: https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua
function TablePrint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. TablePrint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

function GetPreferedSecretShopLocation()
    if GetTeam() == TEAM_RADIANT then
        if GetUnitToLocationDistance(bot, DIRE_SECRET_SHOP) <= 3800 then
            return DIRE_SECRET_SHOP;
        else
            return RAD_SECRET_SHOP;
        end
    elseif GetTeam() == TEAM_DIRE then
        if GetUnitToLocationDistance(bot, RAD_SECRET_SHOP) <= 3800 then
            return RAD_SECRET_SHOP;
        else
            return DIRE_SECRET_SHOP;
        end
    end
    return nil;
end

-- Item purchase lists for npc_dota_hero_skeleton_king.
local itemPurchaseListSkeletonKing = {
    "item_boots", "item_crimson_guard", "item_aghanims_shard", "item_assault",
    "item_heart", "item_aeon_disk", "item_ultimate_scepter",
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

function CheckIfTheBotAlreadyHasThisItem(bot, courier, itemNameToCheck,
                                         isItDoubleItem)
    if isItDoubleItem == nil then isItDoubleItem = false end

    if itemNameToCheck == 'item_ultimate_scepter' and bot:HasScepter() then
        return true
    end
    if itemNameToCheck == 'item_moon_shard' and
        bot:HasModifier("modifier_item_moon_shard_consumed") then return true end
    if itemNameToCheck == 'item_ultimate_scepter_2' then
        return (bot:HasScepter() and bot:FindItemSlot('item_ultimate_scepter') <
                   0)
    end
    if itemNameToCheck == 'item_aghanims_shard' then
        local allModifiersList = bot:GetModifierList()
        for k, v in ipairs(allModifiersList) do
            print(k .. v)
        end
        -- print("bot:FindAllModifiers(): " .. allModifiersList)
    end

    if isItDoubleItem == true then
        local tableOfAllItemsTheBotHas = {}
        local tableOfTheItemToCheckThatTheBotHas = {}
        for i = 0, 16, 1 do
            local itemName = bot:GetItemInSlot(i):GetName()
            if itemName then
                table.insert(tableOfAllItemsTheBotHas, itemName)
            end
        end
        for i = 0, 8, 1 do
            local itemName = courier:GetItemInSlot(i):GetName()
            if itemName then
                table.insert(tableOfAllItemsTheBotHas, itemName)
            end
        end
        for itemIndex, itemName in ipairs(tableOfAllItemsTheBotHas) do
            if itemName == itemNameToCheck then
                table.insert(tableOfTheItemToCheckThatTheBotHas, itemName)
            end
        end
        if #tableOfTheItemToCheckThatTheBotHas >= 2 then
            return true
        else
            return false
        end
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
    local isItDoubleItemFlag = false
    for currentItemIndexInItemPurchaseList, currentItemNameInItemPurchaseList in
        ipairs(itemPurchaseList) do
        repeat
            if currentItemIndexInItemPurchaseList >= 2 then
                if itemPurchaseList[currentItemIndexInItemPurchaseList - 1] ==
                    currentItemNameInItemPurchaseList then
                    isItDoubleItemFlag = true
                end
            end

            if CheckIfTheBotAlreadyHasThisItem(bot, courier,
                                               currentItemNameInItemPurchaseList,
                                               isItDoubleItemFlag) then
                do break end
            elseif #GetItemComponents(currentItemNameInItemPurchaseList) == 0 then
                if CheckIfTheBotAlreadyHasThisItem(bot, courier,
                                                   currentItemNameInItemPurchaseList,
                                                   isItDoubleItemFlag) then
                    do break end
                else
                    local itemCost = GetItemCost(
                                         currentItemNameInItemPurchaseList)
                    if bot:GetGold() < itemCost then
                        return
                    else
                        if IsItemPurchasedFromSecretShop(
                            currentItemNameInItemPurchaseList) then
                            if bot:DistanceFromSecretShop() == 0 then
                                print(
                                    "Bot purchasing item from secret shop, bot " ..
                                        bot:GetPlayerID() .. " purchasing: " ..
                                        currentItemNameInItemPurchaseList .. ".")
                                if bot:ActionImmediate_PurchaseItem(
                                    currentItemNameInItemPurchaseList) ==
                                    PURCHASE_ITEM_SUCCESS then
                                    bot:ActionImmediate_Courier(courier,
                                                                COURIER_ACTION_TRANSFER_ITEMS)
                                end
                                return
                            elseif bot:DistanceFromSecretShop() <= 500 then
                                print("Bot moving to secret shop, bot " ..
                                          bot:GetPlayerID() ..
                                          " moving to secret shop.")
                                bot:Action_MoveToLocation(
                                    GetPreferedSecretShopLocation() +
                                        RandomVector(20))
                                return
                            else
                                if GetCourierState(courier) ~=
                                    COURIER_STATE_DEAD then
                                    if courier:DistanceFromSecretShop() == 0 then
                                        print(
                                            "Courier purchasing item from secret shop, bot " ..
                                                bot:GetPlayerID() ..
                                                "'s courier purchasing: " ..
                                                currentItemNameInItemPurchaseList ..
                                                ".")
                                                courier = GetCourier(bot:GetPlayerID())
                                        if courier:ActionImmediate_PurchaseItem(
                                            currentItemNameInItemPurchaseList) ==
                                            PURCHASE_ITEM_SUCCESS then
                                            bot:ActionImmediate_Courier(courier,
                                                                        COURIER_ACTION_TRANSFER_ITEMS)
                                        end
                                        return
                                    else
                                        print(
                                            "Courier moving to secret shop, bot " ..
                                                bot:GetPlayerID() ..
                                                "'s courier moving to secret shop.")
                                                courier = GetCourier(bot:GetPlayerID())
                                        bot:ActionImmediate_Courier(courier,
                                                                    COURIER_ACTION_SECRET_SHOP)
                                        return
                                    end
                                else
                                    bot:Action_MoveToLocation(
                                        GetPreferedSecretShopLocation() +
                                            RandomVector(20))
                                    return
                                end
                            end
                        else
                            print("Bot purchasing item from base, bot " ..
                                      bot:GetPlayerID() .. " purchasing: " ..
                                      currentItemNameInItemPurchaseList .. ".")
                            if bot:ActionImmediate_PurchaseItem(
                                currentItemNameInItemPurchaseList) ==
                                PURCHASE_ITEM_SUCCESS then
                                bot:ActionImmediate_Courier(courier,
                                                            COURIER_ACTION_TRANSFER_ITEMS)
                            end

                            return
                        end
                    end
                end
            else
                PurchaseItem(
                    GetItemComponents(currentItemNameInItemPurchaseList)[1])
                return
            end
        until true
    end
end

local realTimeRecordList = {0, 0, 0}
local isGamePausedList = {false, false, false}
local sellAfterUnpausedThinkMoment = RealTime()
local botStashItemCountList = {0, 0, 0}
local botBodyItemCountList = {0, 0, 0}
local botCourierItemCountList = {0, 0, 0}
local botStashItemCountBeforePause = 0
local botBodyItemCountBeforePause = 0
local botCourierItemCountBeforePause = 0

function RecordRealTime(realTimeRecordList)
    realTimeRecordList[1] = realTimeRecordList[2]
    realTimeRecordList[2] = realTimeRecordList[3]
    realTimeRecordList[3] = RealTime()
end

function RecordIfGameIsUnpaused(isGamePausedList)
    if realTimeRecordList[3] - realTimeRecordList[2] > 3.5 then
        isGamePausedList[1] = isGamePausedList[2]
        isGamePausedList[2] = isGamePausedList[3]
        isGamePausedList[3] = true
    else
        isGamePausedList[1] = isGamePausedList[2]
        isGamePausedList[2] = isGamePausedList[3]
        isGamePausedList[3] = false
    end
end

function RecordBotItemLists(botStashItemCountList, botBodyItemCountList,
                            botCourierItemCountList)
    local botStashItemCount = 0
    for i = 9, 14, 1 do
        if bot:GetItemInSlot(i) then
            botStashItemCount = botStashItemCount + 1
        else
            break
        end
    end
    botStashItemCountList[1] = botStashItemCountList[2]
    botStashItemCountList[2] = botStashItemCountList[3]
    botStashItemCountList[3] = botStashItemCount

    local botBodyItemCount = 0
    for i = 0, 8, 1 do
        if bot:GetItemInSlot(i) then
            botBodyItemCount = botBodyItemCount + 1
        else
            break
        end
    end
    botBodyItemCountList[1] = botBodyItemCountList[2]
    botBodyItemCountList[2] = botBodyItemCountList[3]
    botBodyItemCountList[3] = botBodyItemCount

    local botCourierItemCount = 0
    for i = 0, 8, 1 do
        if courier:GetItemInSlot(i) then
            botCourierItemCount = botCourierItemCount + 1
        else
            break
        end
    end
    botCourierItemCountList[1] = botCourierItemCountList[2]
    botCourierItemCountList[2] = botCourierItemCountList[3]
    botCourierItemCountList[3] = botCourierItemCount
end

function SellingItemsAfterTheGameIsUnpaused()
    if (isGamePausedList[1] == false and isGamePausedList[2] == false and
        isGamePausedList[3] == true) then
        botStashItemCountBeforePause = botStashItemCountList[1]
        botBodyItemCountBeforePause = botBodyItemCountList[1]
        botCourierItemCountBeforePause = botCourierItemCountList[1]
    end
    if (isGamePausedList[2] == true and isGamePausedList[3] == false) or
        (isGamePausedList[1] == true and isGamePausedList[3] == false) then
        print("Unpaused!...")
        if botStashItemCountBeforePause < 6 then
            for botStashSlotIndex = 9 + botStashItemCountBeforePause, 14, 1 do
                print("selling...")
                if bot:GetItemInSlot(botStashSlotIndex) then
                    bot:ActionImmediate_SellItem(bot:GetItemInSlot(
                                                     botStashSlotIndex))
                end
            end
        end
        if botBodyItemCountBeforePause + botStashItemCountBeforePause < 9 then
            for botBodySlotIndex = 0 + botBodyItemCountBeforePause +
                botStashItemCountBeforePause, 8, 1 do
                print("selling...")
                if bot:GetItemInSlot(botBodySlotIndex) then
                    bot:ActionImmediate_SellItem(bot:GetItemInSlot(
                                                     botBodySlotIndex))
                end
            end
        end
        if botCourierItemCountBeforePause + botStashItemCountBeforePause < 9 then
            for botCourierSlotIndex = 0 + botCourierItemCountBeforePause +
                botStashItemCountBeforePause, 8, 1 do
                print("selling...")
                if courier:GetItemInSlot(botCourierSlotIndex) then
                    print("courier returning: " ..
                              courier:GetItemInSlot(botCourierSlotIndex)
                                  :GetName())
                    bot:ActionImmediate_Courier(courier, COURIER_ACTION_RETURN)
                    -- courier:ActionImmediate_SellItem(
                    --     courier:GetItemInSlot(botCourierSlotIndex))
                end
            end
        end
    end
end

-- Implement ItemPurchaseThink() to override decisionmaking around item purchasing.
function ItemPurchaseThink()
    if DotaTime() < itemPurchaseThinkMoment then
        return
    else
        if courier == nil then courier = GetCourier(bot:GetPlayerID()) end
        itemPurchaseThinkMoment = itemPurchaseThinkMoment + 0.5
        PurchaseItem(itemPurchaseListSkeletonKing)
    end

    -- if RealTime() > sellAfterUnpausedThinkMoment then
    --     sellAfterUnpausedThinkMoment = RealTime() + 0.5
    --     print(sellAfterUnpausedThinkMoment)
    --     print(TablePrint(isGamePausedList))
    --     print(TablePrint(realTimeRecordList))
    --     RecordRealTime(realTimeRecordList)
    --     RecordIfGameIsUnpaused(isGamePausedList)
    --     RecordBotItemLists(botStashItemCountList, botBodyItemCountList,
    --                        botCourierItemCountList)
    --     print(TablePrint(botStashItemCountList))
    --     print(TablePrint(botBodyItemCountList))
    --     print(TablePrint(botCourierItemCountList))
    --     SellingItemsAfterTheGameIsUnpaused()
    --     print(botStashItemCountBeforePause)
    --     print(botBodyItemCountBeforePause)
    --     print(botCourierItemCountBeforePause)
    -- end
end
