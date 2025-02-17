local Functions = Animations()
robiemotke = false

CreateThread(function()
    while not Functions do
        Functions = Animations()
        Wait(100)
    end

    for i = 1, #(Config.Animations) do
        local items = Config.Animations[i].items
        for j = 1, #(items) do
            local item = items[j]
            if item.keyword then
                TriggerEvent("chat:addSuggestion", "/e " .. item.keyword, item.label)
            end
        end
    end
    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword then
            TriggerEvent("chat:addSuggestion", "/e " .. item.keyword, item.label)
        end
    end

    Functions.AnimationsFavorites = json.decode(GetResourceKvpString("NeedRP-AnimationsFavorites"))
    if not Functions.AnimationsFavorites then
        Functions.AnimationsFavorites = {}
    end

    Functions.AnimationsBinds = json.decode(GetResourceKvpString("NeedRP-AnimationsBinds"))
    if not Functions.AnimationsBinds then
        Functions.AnimationsBinds = {}
    end
end)

AddEventHandler('playerSpawned', function()
    if not PlayerLoaded then
        return
    end

    local MovementClipset = GetResourceKvpString("NeedRP-MovementClipset")
    if MovementClipset then
        Functions.SetMovementClipset(MovementClipset)
    end

    local FacialAnim = GetResourceKvpString("NeedRP-FacialAnim")
    if FacialAnim then
        Functions.SetFacialAnim(FacialAnim)
    end
end)

RegisterCommand("e", function(source, args)
    if ESX.PlayerData.dead then
        return
    end
    
    if not args[1] then
        return
    end

    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword == args[1] then
            if ESX.UI.Inventory.Area.Check(3.0) then
                ESX.UI.Inventory.Area.Build(3.0, false, false, function(target, _, npc)
                    if target then
                        ESX.ShowNotification("~y~Oczekiwanie na akceptację przez obywatela")
                        TriggerServerEvent("dbl_animations:requestSynced", target, item.keyword)
                    else
                        ESX.ShowNotification("~r~Brak obywateli w pobliżu")
                    end
                end, true, false)
            else
                ESX.ShowNotification("~r~Brak obywateli w pobliżu")
            end
            break
        end
    end

    for i = 1, #(Config.Animations) do
        local group = Config.Animations[i]
        local items = group.items
        for j = 1, #(items) do
            local item = items[j]
            if item.keyword == args[1] then
                item.positioning = group.positioning
                Functions.PlayAnimation(item)
                break
            end
        end
    end
end)

for i = 1, 9 do
    RegisterCommand("+playAnim-" .. i, function() end)
    RegisterCommand("-playAnim-" .. i, function()
        if not Functions.AnimationsBinds[i] then
            return
        end
        if ESX.PlayerData.dead then
            return
        end
        if not IsControlPressed(0, 21) then
            return
        end
        Functions.PlayAnimation(Functions.AnimationsBinds[i])
    end)
    RegisterKeyMapping("+playAnim-" .. i, "Klawisz " .. i, "KEYBOARD", i)
end

RegisterNetEvent("dbl_animations:openMenu", function()
    if ESX.PlayerData.dead then
        return
    end
    Functions.OpenAnimationsMain()
end)

RegisterKeyMapping('animacje', 'Otwórz menu animacji', 'keyboard', 'F3');

RegisterCommand("animacje",function()
	Functions.OpenAnimationsMain()
end)


RegisterNetEvent("dbl_animations:stopSynced", function(plyId)
    if Functions.SyncedPlayer and Functions.SyncedPlayer == plyId then
        Functions.ClearTasks()
        Functions.SyncedPlayer = nil
    end
end)

RegisterCommand('anulujanimacje', function (source, args, raw)
    Functions.ClearTasks()
end, false)

RegisterCommand("+cancelTask", function() end)
RegisterCommand("-cancelTask", function()
    if ESX.PlayerData.dead then
        return
    end
    if not robiemotke then return end
    Functions.ClearTasks()
    robiemotke = false
end)

RegisterCommand("+putTakeProp", function() end)
RegisterCommand("-putTakeProp", function()
    if ESX.PlayerData.dead then
        return
    end
    Functions.PlaceEntities()
end)

RegisterNetEvent("dbl_animations:syncRequest", function(requester, emote)
    ESX.UI.Menu.CloseAll()

    local animLabel = emote
    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword == emote then
            animLabel = item.label
            break
        end
    end
    Citizen.CreateThread(function()
        local menu = ESX.UI.Menu.Open("default", GetCurrentResourceName(), "animations_sync_request_menu", {
            title    = "Propozycja animacji " .. animLabel .. " od " .. requester,
            align    = "center",
            elements = {
                { label = "<span style='color: lightgreen'>Zaakceptuj</span>", value = true },
                { label = "<span style='color: lightcoral'>Odrzuć</span>", value = false }
            }
        }, function(data, menu)
            menu.close()
            if data.current.value then
                TriggerServerEvent("dbl_animations:syncAccepted", requester, emote)
            end
        end, function(data, menu)
            menu.close()
        end)
        Wait(5000)
        menu.close()
    end)
end)

RegisterNetEvent("dbl_animations:playSynced", function(emote, player)
    Functions.ClearTasks()
    Wait(300)

    local targetEmote
    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword == emote then
            emote = item
            targetEmote = item.target
            break
        end
    end

    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword == targetEmote then
            targetEmote = item
            break
        end
    end

    local plyServerId = GetPlayerFromServerId(player)
    if targetEmote and targetEmote.options and targetEmote.options.Attachto then
        local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())
        local bone = targetEmote.options.bone or -1 -- No bone
        local xPos = targetEmote.options.xPos or 0.0
        local yPos = targetEmote.options.yPos or 0.0
        local zPos = targetEmote.options.zPos or 0.0
        local xRot = targetEmote.options.xRot or 0.0
        local yRot = targetEmote.options.yRot or 0.0
        local zRot = targetEmote.options.zRot or 0.0
        AttachEntityToEntity(ESX.PlayerData.ped, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot, false, false, false, true, 1, true)
    end
    
    Functions.SyncedPlayer = player
    Functions.PlayAnimation(targetEmote)
end)

RegisterNetEvent("dbl_animations:playSyncedSource", function(emote, player)
    Functions.ClearTasks()
    Wait(300)
    
    local plyServerId = GetPlayerFromServerId(player)
    local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())
    local SyncOffsetFront = 1.0
    local SyncOffsetSide = 0.0
    local SyncOffsetHeight = 0.0
    local SyncOffsetHeading = 180.1

    for i = 1, #(Config.Shared) do
        local item = Config.Shared[i]
        if item.keyword == emote then
            emote = item
            break
        end
    end

    local AnimationOptions = emote.options
    if AnimationOptions then
        if AnimationOptions.SyncOffsetFront then
            SyncOffsetFront = AnimationOptions.SyncOffsetFront + 0.0
        end
        if AnimationOptions.SyncOffsetSide then
            SyncOffsetSide = AnimationOptions.SyncOffsetSide + 0.0
        end
        if AnimationOptions.SyncOffsetHeight then
            SyncOffsetHeight = AnimationOptions.SyncOffsetHeight + 0.0
        end
        if AnimationOptions.SyncOffsetHeading then
            SyncOffsetHeading = AnimationOptions.SyncOffsetHeading + 0.0
        end

        if (AnimationOptions.Attachto) then
            local bone = AnimationOptions.bone or -1 -- No bone
            local xPos = AnimationOptions.xPos or 0.0
            local yPos = AnimationOptions.yPos or 0.0
            local zPos = AnimationOptions.zPos or 0.0
            local xRot = AnimationOptions.xRot or 0.0
            local yRot = AnimationOptions.yRot or 0.0
            local zRot = AnimationOptions.zRot or 0.0
            AttachEntityToEntity(ESX.PlayerData.ped, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot, false, false, false, true, 1, true)
        end
    end
    local coords = GetOffsetFromEntityInWorldCoords(pedInFront, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
    local heading = GetEntityHeading(pedInFront)
    SetEntityHeading(ESX.PlayerData.ped, heading - SyncOffsetHeading)
    SetEntityCoordsNoOffset(ESX.PlayerData.ped, coords.x, coords.y, coords.z, 0)
    
    Functions.SyncedPlayer = player
    Functions.PlayAnimation(emote)
end)

RegisterNetEvent("dbl_animations:CreateEntity", function(obj)
    exports.ox_target:addEntity(obj.prop, {
        {
            name = "pick up",
            label = "Podnieś",
            icon = "fa-solid fa-hand-holding",
            obj = obj,
            onSelect = function(data)
                local ped = ESX.PlayerData.ped
                RequestAnimDict("anim@mp_snowball")
                while not HasAnimDictLoaded("anim@mp_snowball") do
                    Wait(0)
                end

                TaskPlayAnim(ped, "anim@mp_snowball", "pickup_snowball", 5.0, 5.0, 2000, 46, 0, false, false, false)
                RemoveAnimDict("anim@mp_snowball")

                Wait(2000)

                ClearPedTasks(ped)
                DeleteEntity(NetToEnt(data.obj.prop))
                Functions.PlayAnimation(data.obj.animCfg)
            end
        }
    })
end)