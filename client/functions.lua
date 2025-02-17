function Animations()
    local self = {}

    self.Entities = {}
    self.AnimationsFavorites = {}
    self.AnimationsBinds = {}

    self.SyncedPlayer = nil
    self.AnimationPositioningPed = nil
    self.AnimationPositioningCoords = nil

    self.AnimationPositioning = false
    
    self.EnterKeyword = function(cb)
        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'outfit_name', {
            title = "Wprowadź keyword animacji"
        }, function(data, menu)
            local value = data.value
            if value then
                local found = false
                for i = 1, #(Config.Animations) do
                    local items = Config.Animations[i].items
                    for j = 1, #(items) do
                        local item = items[j]
                        if value == item.keyword then
                            found = item
                            break
                        end
                    end
                    if found then
                        break
                    end
                end

                if not found then
                    ESX.ShowNotification("Podana animacja nie istnieje!")
                else
                    menu.close()
                    cb(found)
                end
            end
        end, function(data, menu)
            menu.close()
            cb()
        end)
    end

    -- MAIN
    self.OpenAnimationsMain = function()
        ESX.UI.Menu.CloseAll()

        local elements = {}

        elements[#elements + 1] = {label = "⭐ Ulubione", action = "favorite"}
        elements[#elements + 1] = {label = "⌨ Bindowanie", action = "binding"}
        elements[#elements + 1] = {label = "❌ PRZERWIJ", action = "cancel"}
        elements[#elements + 1] = {label = " "}

        for i = 1, #(Config.Animations) do
            local group = Config.Animations[i]
            if not group.hide then
                elements[#elements + 1] = {label = group.label, value = group.name, items = #group.items > 0}
            end
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "animations_menu", {
            title    = "Animacje",
            align    = "right",
            elements = elements
        }, function(data, menu)
            if data.current.action == "favorite" then
                self.OpenAnimationsFavorites()
            elseif data.current.action == "binding" then
                self.OpenAnimationsBinds()
            elseif data.current.action == "cancel" then
                self.ClearTasks()
            elseif data.current.value == "shared" then
                self.OpenAnimationsSynced()
            elseif data.current.items then
                self.OpenAnimationsItems(data.current.value, false)
            else
                self.OpenAnimationsCategory(data.current.value)
            end
        end, function(data, menu)
            menu.close()
        end)
    end

    self.OpenAnimationsCategory = function(category)
        ESX.UI.Menu.CloseAll()

        local elements = {}

        for i = 1, #(Config.Animations) do
            local group = Config.Animations[i]
            if group.hide and group.attachTo == category then
                elements[#elements + 1] = {label = group.label, value = group.name, items = #group.items > 0}
            end
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "animations_menu", {
            title    = "Animacje",
            align    = "right",
            elements = elements
        }, function(data, menu)
            if data.current.items then
                self.OpenAnimationsItems(data.current.value, false)
            else
                self.OpenAnimationsCategory(data.current.value)
            end
        end, function(data, menu)
            menu.close()
            self.OpenAnimationsMain()
        end)
    end

    self.OpenAnimationsItems = function(category, isAttached)
        ESX.UI.Menu.CloseAll()

        local title, elements = nil, {}
        for i = 1, #(Config.Animations) do
            local group = Config.Animations[i]
            if group.name == category then
                title = group.label

                local items = group.items
                for j = 1, #(items) do
                    local item = items[j]
                    elements[#elements + 1] = {
                        label = (item.keyword and item.label .. " <span style='color: #7700ff'>/e " .. item.keyword .. "</span>" or item.label),
                        keyword = item.keyword
                    }
                end
                break
            end
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "animations_sub_menu", {
            title    = title,
            align    = "right",
            elements = elements
        }, function(data, menu)
            for i = 1, #(Config.Animations) do
                local group = Config.Animations[i]
                if group.name == category then
                    local items = group.items
                    for j = 1, #(items) do
                        local item = items[j]
                        if item.keyword == data.current.keyword then
                            item.positioning = group.positioning
                            self.PlayAnimation(item)
                            break
                        end
                    end
                end
            end
        end, function(data, menu)
            menu.close()
            if isAttached then
                self.OpenAnimationsCategory(isAttached)
            else
                self.OpenAnimationsMain()
            end
        end)
    end

    self.OpenAnimationsSynced = function()
        ESX.UI.Menu.CloseAll()

        local elements = {}
        for i = 1, #(Config.Shared) do
            local item = Config.Shared[i]
            elements[#elements + 1] = {
                label = (item.keyword and item.label .. " <span style='color: #7700ff'>/e " .. item.keyword .. "</span>" or item.label),
                keyword = item.keyword
            }
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "animations_sub_menu", {
            title    = "👭 Wspólne Animacje",
            align    = "right",
            elements = elements
        }, function(data, menu)
            if ESX.UI.Inventory.Area.Check(3.0) then
                ESX.UI.Inventory.Area.Build(3.0, false, false, function(target, _, npc)
                    if target then
                        ESX.ShowNotification("Oczekiwanie na akceptację przez obywatela")
                        TriggerServerEvent("dbl_animations:requestSynced", target, data.current.keyword)
                    else
                        ESX.ShowNotification("Brak obywateli w pobliżu")
                    end
                end, true, false)
            else
                ESX.ShowNotification("~r~Brak obywateli w pobliżu")
            end
        end, function(data, menu)
            menu.close()
            self.OpenAnimationsMain()
        end)
    end
    
    -- FAVORITES
    self.OpenAnimationsFavorites = function()
        ESX.UI.Menu.CloseAll()

        local Favorites = self.AnimationsFavorites
        local elements = {}

        if #Favorites > 0 then
            for i = 1, #(Favorites) do
                elements[#elements + 1] = Favorites[i]
            end
            elements[#elements + 1] = {label = " "}
        end
        
        elements[#elements + 1] = {label = "➕ Dodaj", value = "add"}
        elements[#elements + 1] = {label = "➖ Usuń", value = "delete"}

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "favorites_animations", {
            title    = "⭐ Ulubione",
            align    = "right",
            elements = elements
        }, function(data, menu)
            if data.current.value == "add" then
                menu.close()
                self.EnterKeyword(function(value)
                    if value then
                        local found = false
                        for i = 1, #(Favorites) do
                            if Favorites[i].keyword == value.keyword then
                                found = true
                                break
                            end
                        end
                        if not found then
                            value.label = value.keyword
                            self.AnimationsFavorites[#self.AnimationsFavorites + 1] = value
                            SetResourceKvp("NeedRP-AnimationsFavorites", json.encode(self.AnimationsFavorites))
                        else
                            ESX.ShowNotification("Ta animacja znajduje się w ulubionych!")
                        end
                    end
                    self.OpenAnimationsFavorites()
                end)
            elseif data.current.value == "delete" then
                menu.close()
                self.OpenAnimationsFavoritesDelete()
            else
                self.PlayAnimation(data.current)
            end
        end, function(data, menu)
            menu.close()
            self.OpenAnimationsMain()
        end)
    end

    self.OpenAnimationsFavoritesDelete = function()
        ESX.UI.Menu.CloseAll()

        local Favorites = self.AnimationsFavorites
        local elements = {}

        for i = 1, #(Favorites) do
            elements[#elements + 1] = Favorites[i]
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "delete_favorites_animations", {
            title    = "Usuwanie ulubionych animacji",
            align    = "right",
            elements = elements
        }, function(data, menu)
            menu.close()
            for i = 1, #(Favorites) do
                if Favorites[i].keyword == data.current.keyword then
                    table.remove(self.AnimationsFavorites, i)
                    break
                end
            end
            self.OpenAnimationsFavoritesDelete()
        end, function(data, menu)
            menu.close()
            self.OpenAnimationsFavorites()
        end)
    end

    -- BINDS
    self.OpenAnimationsBinds = function()
        ESX.UI.Menu.CloseAll()

        local Binds = self.AnimationsBinds
        local elements = {}

        for i = 1, 9 do
            if Binds[i] then
                elements[#elements + 1] = {label = "Klawisz " .. i .. " - " .. Binds[i].keyword, data = Binds[i], key = i, has = true}
            else
                elements[#elements + 1] = {label = "Klawisz " .. i, key = i, has = false}
            end
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "binds_animations", {
            title    = "⌨ Bindowanie",
            align    = "right",
            elements = elements
        }, function(data, menu)
            if data.current.has then
                self.AnimationsBinds[data.current.key] = nil
                SetResourceKvp("NeedRP-AnimationsBinds", json.encode(self.AnimationsBinds))
                self.OpenAnimationsBinds()
            else
                menu.close()
                self.EnterKeyword(function(value)
                    if value then
                        self.AnimationsBinds[data.current.key] = value
                        SetResourceKvp("NeedRP-AnimationsBinds", json.encode(self.AnimationsBinds))
                    end
                    self.OpenAnimationsBinds()
                end)
            end
        end, function(data, menu)
            menu.close()
            self.OpenAnimationsMain()
        end)
    end

    -- ANIMATIONS
    self.PosAnimation = function(data, AnimationMode, AnimationDuration, props, cb)
        TriggerEvent('skinchanger:getSkin', function(skin)
            local coords = GetEntityCoords(ESX.PlayerData.ped)
            local heading = GetEntityHeading(ESX.PlayerData.ped)

            self.AnimationPositioning = true
            self.AnimationPositioningPed = CreatePed(2, GetEntityModel(ESX.PlayerData.ped), coords.x, coords.y, coords.z - 1.0, heading, false)

            TriggerEvent("skinchanger:loadPedSkin", self.AnimationPositioningPed, skin, function()
                FreezeEntityPosition(self.AnimationPositioningPed, true)
                SetEntityCollision(self.AnimationPositioningPed, false, false)
                SetEntityCompletelyDisableCollision(self.AnimationPositioningPed, false, false)
                SetEntityAlpha(self.AnimationPositioningPed, 200, false)

                self.TaskPlayAnimation(data, AnimationMode, AnimationDuration, props, self.AnimationPositioningPed)

                while self.AnimationPositioning do
                    DisableControlAction(0, 14, true)
                    DisableControlAction(0, 15, true)
                    DisableControlAction(0, 18, true)
                    DisableControlAction(0, 30,  true)
                    DisableControlAction(0, 31,  true)
                    DisableControlAction(0, 32, true)
                    DisableControlAction(0, 33, true)
                    DisableControlAction(0, 34, true)
                    DisableControlAction(0, 35, true)
                    DisableControlAction(0, 38, true)
                    DisableControlAction(0, 44, true)

                    local xoff = 0.0
                    local yoff = 0.0
                    local zoff = 0.0
                    local heading = GetEntityHeading(self.AnimationPositioningPed)

                    if IsDisabledControlJustReleased(0, 15) then
                        heading = heading + 5
                    end
                    if IsDisabledControlJustReleased(0, 14) then
                        heading = heading - 1
                    end
    
                    if IsDisabledControlPressed(0, 34) then
                        xoff = -0.01;
                    end
                    if IsDisabledControlPressed(0, 35) then
                        xoff = 0.01;
                    end
    
                    if IsDisabledControlPressed(0, 32) then
                        yoff = 0.01;
                    end
                    if IsDisabledControlPressed(0, 33) then
                        yoff = -0.01;
                    end
    
                    if IsDisabledControlPressed(0, 38) then
                        zoff = 0.01;
                    end
                    if IsDisabledControlPressed(0, 44) then
                        zoff = -0.01;
                    end

                    if IsDisabledControlJustPressed(0, 18) then
                        if HasEntityClearLosToEntity(self.AnimationPositioningPed, ESX.PlayerData.ped, 2) then
                            self.AnimationPositioningCoords = {
                                x = coords.x,
                                y = coords.y,
                                z = coords.z - 1.0,
                                h = heading
                            }
                            
                            SetEntityCoordsNoOffset(ESX.PlayerData.ped, GetEntityCoords(self.AnimationPositioningPed), false, true, true)
                            SetEntityHeading(ESX.PlayerData.ped, GetEntityHeading(self.AnimationPositioningPed))
                            
                            for i = 1, #(self.Entities) do
                                DeleteEntity(self.Entities[i].prop)
                            end
                            self.Entities = {}
                            DeleteEntity(self.AnimationPositioningPed)            
                            break
                        else
                            ESX.ShowNotification("Nie możesz ustawić animacji w tym miejscu!")
                        end
                    end

                    local newPos = GetOffsetFromEntityInWorldCoords(self.AnimationPositioningPed, xoff, yoff, zoff)
                    if #(vec3(coords.x, coords.y, coords.z) - vec3(newPos.x, newPos.y, newPos.z)) < 3 then
                        SetEntityCoordsNoOffset(self.AnimationPositioningPed, newPos.x, newPos.y, newPos.z, false, true, true)
                    end
                    SetEntityHeading(self.AnimationPositioningPed, heading)

                    Wait(0)
                end

                cb(self.AnimationPositioning)
                self.AnimationPositioning = false
            end)
        end)
    end

    self.PlayAnimation = function(data)
        if self.AnimationPositioning then
            return
        end

        if self.AnimationPositioningCoords then
            return
        end

        if data.type == "walk" then
            self.SetMovementClipset(data.animdict)
            return
        end

        if data.type == "expression" then
            self.SetFacialAnim(data.animdict)
            return
        end

        local AnimationMode = 0
        local AnimationDuration = -1
        local AnimationOptions = data.options

        if IsPedInAnyVehicle(ESX.PlayerData.ped, true) then
            AnimationMode = 51
        elseif AnimationOptions then
            if AnimationOptions.moving then
                AnimationMode = 51
            elseif AnimationOptions.loop then
                AnimationMode = 1
            elseif AnimationOptions.stuck then
                AnimationMode = 50
            end
        end

        if AnimationOptions and AnimationOptions.duration then
            AnimationDuration = AnimationOptions.duration
        end

        local StartAnim = function()
            self.TaskPlayAnimation(data, AnimationMode, AnimationDuration, AnimationOptions and AnimationOptions.props)

            Wait(250)

            local PtfxNoProp = false
            if AnimationOptions and AnimationOptions.ptfx then
                local PtfxAsset = AnimationOptions.ptfx.asset
                local PtfxName = AnimationOptions.ptfx.name
                if AnimationOptions.ptfx.noProp then
                    PtfxNoProp = AnimationOptions.ptfx.noProp
                else
                    PtfxNoProp = false
                end
                local Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6, PtfxScale = table.unpack(AnimationOptions.ptfx.placement)
                local PtfxBone = AnimationOptions.ptfx.bone
                local PtfxColor = AnimationOptions.ptfx.color
                local PtfxInfo = AnimationOptions.ptfx.info
                local PtfxWait = AnimationOptions.ptfx.wait
                local PtfxCanHold = AnimationOptions.ptfx.canHold
                TriggerServerEvent("dbl_animations:syncPtfx", PtfxAsset, PtfxName, vector3(Ptfx1, Ptfx2, Ptfx3), vector3(Ptfx4, Ptfx5, Ptfx6), PtfxBone, PtfxScale, PtfxColor)

                CreateThread(function()
                    if PtfxCanHold then
                        ESX.ShowNotification(PtfxInfo ~= "false" and PtfxInfo or "G")
                        while IsEntityPlayingAnim(ESX.PlayerData.ped, data.dict, data.name, 3) do
                            if IsControlPressed(0, 47) then
                                self.StartPtfx()
                                Wait(PtfxWait)
                                while IsControlPressed(0, 47) and IsEntityPlayingAnim(ESX.PlayerData.ped, data.dict, data.name, 3) do
                                    Wait(5)
                                end
                                self.StopPtfx()
                            end
                            Wait(0)
                        end
                    else
                        Wait(PtfxWait)
                        self.StartPtfx()
                        self.StopPtfx()
                    end
                end)
            end

            if AnimationOptions and AnimationOptions.ptfx and not PtfxNoProp then
                TriggerServerEvent("dbl_animations:syncPtfxProp", ObjToNet(self.Entities[1].prop))
            end

            CreateThread(function()
                while IsEntityPlayingAnim(ESX.PlayerData.ped, data.dict, data.name, 3) do
                    Wait(100)
                end
                FreezeEntityPosition(ESX.PlayerData.ped, false)
                SetEntityCollision(ESX.PlayerData.ped, true, true)
                SetEntityCompletelyDisableCollision(ESX.PlayerData.ped, true, true)
                
                local coords = self.AnimationPositioningCoords
                if coords then
                    SetEntityCoords(ESX.PlayerData.ped, coords.x, coords.y, coords.z)
                    SetEntityHeading(ESX.PlayerData.ped, coords.h)
                    self.AnimationPositioningCoords = nil
                end
            end)
        end

        if data.positioning then
            self.PosAnimation(data, AnimationMode, AnimationDuration, AnimationOptions and AnimationOptions.props, function(bool)
                if bool then
                    FreezeEntityPosition(ESX.PlayerData.ped, true)
                    StartAnim()
                end
            end)
        else
            StartAnim()
        end
    end

    self.TaskPlayAnimation = function(data, AnimationMode, AnimationDuration, props, clone)
        local ped = clone or ESX.PlayerData.ped

        for i = 1, #(self.Entities) do
            DeleteEntity(self.Entities[i].prop)
        end
        self.Entities = {}

        RequestAnimDict(data.dict)
        while not HasAnimDictLoaded(data.dict) do
            Wait(0)
        end

        TaskPlayAnim(ped, data.dict, data.name, 5.0, 5.0, AnimationDuration, AnimationMode, 0, false, false, false)
        robiemotke = true
        RemoveAnimDict(data.dict)

        if props then
            local x, y, z = table.unpack(GetEntityCoords(ped))
            for i = 1, #(props) do
                local obj = props[i]
                local name = obj.name
                local bone = obj.bone
                local off1, off2, off3, rot1, rot2, rot3 = table.unpack(obj.placement)
                if IsModelValid(name) then
                    while not HasModelLoaded(joaat(name)) do
                        RequestModel(joaat(name))
                        Wait(10)
                    end

                    if clone then
                        local prop = CreateObject(joaat(name), x, y, z + 0.2, false, true, true)
                        SetEntityAlpha(prop, 200, false)
                        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
                        table.insert(self.Entities, {prop = prop, animCfg = data})
                        SetModelAsNoLongerNeeded(prop)
                    else
                        local prop = CreateObject(joaat(name), x, y, z + 0.2, true, true, true)
                        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
                        table.insert(self.Entities, {prop = prop, animCfg = data})
                        SetModelAsNoLongerNeeded(prop)
                    end
                end
            end
        end
    end

    self.ClearTasks = function()
        ClearPedTasks(ESX.PlayerData.ped)

        for i = 1, #(self.Entities) do
            DeleteEntity(self.Entities[i].prop)
        end
        self.Entities = {}

        if self.AnimationPositioning then
            self.AnimationPositioning = nil
        end

        if self.AnimationPositioningPed then
            DeleteEntity(self.AnimationPositioningPed)
            self.AnimationPositioningPed = nil
        end

        if self.SyncedPlayer then
            DetachEntity(ESX.PlayerData.ped, true, false)
            TriggerServerEvent("dbl_animations:stopSynced", self.SyncedPlayer)
            self.SyncedPlayer = nil
        end

        if LocalPlayer.state.ptfx then
            self.StopPtfx()
        end

        local coords = self.AnimationPositioningCoords
        if coords then
            SetEntityCoords(ESX.PlayerData.ped, coords.x, coords.y, coords.z)
            SetEntityHeading(ESX.PlayerData.ped, coords.h)
            self.AnimationPositioningCoords = nil
        end
    end

    -- PTFX
    self.StartPtfx = function()
        LocalPlayer.state:set('ptfx', true, true)
    end

    self.StopPtfx = function()
        LocalPlayer.state:set('ptfx', false, true)
    end

    self.PlayerParticles = {}
    AddStateBagChangeHandler('ptfx', nil, function(bagName, key, value, _unused, replicated)
        local plyId = tonumber(bagName:gsub('player:', ''), 10)

        if (self.PlayerParticles[plyId] and value) or (not self.PlayerParticles[plyId] and not value) then return end

        local ply = GetPlayerFromServerId(plyId)
        if ply == 0 then return end

        local plyPed = GetPlayerPed(ply)
        if not DoesEntityExist(plyPed) then return end

        local stateBag = Player(plyId).state
        if value then
            local asset = stateBag.ptfxAsset
            local name = stateBag.ptfxName
            local offset = stateBag.ptfxOffset
            local rot = stateBag.ptfxRot
            local boneIndex = stateBag.ptfxBone and GetPedBoneIndex(plyPed, stateBag.ptfxBone) or GetEntityBoneIndexByName(name, "VFX")
            local scale = stateBag.ptfxScale or 1
            local color = stateBag.ptfxColor
            local propNet = stateBag.ptfxPropNet
            local entityTarget = plyPed
            
            if propNet then
                local propObj = NetToObj(propNet)
                if DoesEntityExist(propObj) then
                    entityTarget = propObj
                end
            end
            
            while not HasNamedPtfxAssetLoaded(asset) do
                RequestNamedPtfxAsset(asset)
                Wait(10)
            end
            UseParticleFxAsset(asset)
            
            self.PlayerParticles[plyId] = StartNetworkedParticleFxLoopedOnEntityBone(name, entityTarget, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneIndex, scale + 0.0, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)
            if color then
                if color[1] and type(color[1]) == 'table' then
                    local randomIndex = math.random(1, #color)
                    color = color[randomIndex]
                end
                SetParticleFxLoopedAlpha(self.PlayerParticles[plyId], color.A)
                SetParticleFxLoopedColour(self.PlayerParticles[plyId], color.R / 255, color.G / 255, color.B / 255, false)
            end
        else
            if self.PlayerParticles[plyId] then
                StopParticleFxLooped(self.PlayerParticles[plyId], false)
                RemoveParticleFx(self.PlayerParticles[plyId])
                RemoveNamedPtfxAsset(stateBag.ptfxAsset)
                self.PlayerParticles[plyId] = nil
            end
        end
    end)

    self.SetMovementClipset = function(name)
        RequestAnimSet(name)
        while not HasAnimSetLoaded(name) do
            Citizen.Wait(1)
        end
        SetPedMovementClipset(ESX.PlayerData.ped, name, 0.2)
        RemoveAnimSet(name)
        SetResourceKvp("NeedRP-MovementClipset", name)
    end

    self.SetFacialAnim = function(name)
        SetFacialIdleAnimOverride(ESX.PlayerData.ped, name, 0)
        SetResourceKvp("NeedRP-FacialAnim", name)
    end

    self.PlaceEntities = function()
        if self.AnimationPositioning then
            return
        end
        if #self.Entities <= 0 then
            return
        end

        local ped = ESX.PlayerData.ped
        RequestAnimDict("anim@mp_fireworks")
        while not HasAnimDictLoaded("anim@mp_fireworks") do
            Wait(0)
        end

        TaskPlayAnim(ped, "anim@mp_fireworks", "place_firework_3_box", 5.0, 5.0, 2000, 46, 0, false, false, false)
        RemoveAnimDict("anim@mp_fireworks")

        Wait(2000)

        ped = ESX.PlayerData.ped
        local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, -0.5)
        for i = 1, #(self.Entities) do
            local obj = self.Entities[i]
            DetachEntity(obj.prop, true)
            SetEntityCoords(obj.prop, coords)
            obj.prop = ObjToNet(obj.prop)
            TriggerServerEvent("dbl_animations:CreateEntity", obj)
        end
        self.Entities = {}
        self.ClearTasks()
    end

    return self
end