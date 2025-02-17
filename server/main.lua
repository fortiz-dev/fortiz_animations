RegisterNetEvent("dbl_animations:requestSynced", function(target, emote)
	if target == -1 then
        return
    end

	local ped = GetPlayerPed(source)
    local tped = GetPlayerPed(target)
    local pedcoord = GetEntityCoords(ped)
    local targetcoord = GetEntityCoords(tped)
    local distance = #(pedcoord - targetcoord)
	TriggerClientEvent('dbl_animations:syncRequest', target, source, emote)
end)

RegisterNetEvent("dbl_animations:syncAccepted", function(target, emote)
	if target == -1 then
        return
    end
	
	local ped = GetPlayerPed(source)
    local tped = GetPlayerPed(target)
    local pedcoord = GetEntityCoords(ped)
    local targetcoord = GetEntityCoords(tped)

    local distance = #(pedcoord - targetcoord)

    if distance > 3 then
        return
    end
	
	TriggerClientEvent('dbl_animations:playSyncedSource', target, emote, source)
	TriggerClientEvent('dbl_animations:playSynced', source, emote, target)
end)

RegisterNetEvent("dbl_animations:stopSynced", function( plyId)
    TriggerClientEvent("dbl_animations:stopSynced", plyId, source)
end)

RegisterNetEvent("dbl_animations:syncPtfx", function(asset, name, offset, rot, bone, scale, color)
    if type(asset) ~= "string" or type(name) ~= "string" or type(offset) ~= "vector3" or type(rot) ~= "vector3" then
        print("[dbl_animations] ptfx:sync: invalid arguments for source:", source)
        return
    end
    local srcPlayerState = Player(source).state
    srcPlayerState:set('ptfxAsset', asset, true)
    srcPlayerState:set('ptfxName', name, true)
    srcPlayerState:set('ptfxOffset', offset, true)
    srcPlayerState:set('ptfxRot', rot, true)
    srcPlayerState:set('ptfxBone', bone, true)
    srcPlayerState:set('ptfxScale', scale, true)
    srcPlayerState:set('ptfxColor', color, true)
    srcPlayerState:set('ptfxPropNet', false, true)
    srcPlayerState:set('ptfx', false, true)
end)

RegisterNetEvent("dbl_animations:syncPtfxProp", function(propNet)
    local srcPlayerState = Player(source).state
    if propNet then
        local waitForEntityToExistCount = 0
        while waitForEntityToExistCount <= 100 and not DoesEntityExist(NetworkGetEntityFromNetworkId(propNet)) do
            Wait(10)
            waitForEntityToExistCount = waitForEntityToExistCount + 1
        end

        if waitForEntityToExistCount < 100 then
            srcPlayerState:set('ptfxPropNet', propNet, true)
            return
        end
    end
    srcPlayerState:set('ptfxPropNet', false, true)
end)

RegisterNetEvent("dbl_animations:CreateEntity", function(obj)
    TriggerClientEvent("dbl_animations:CreateEntity", -1, obj)
end)