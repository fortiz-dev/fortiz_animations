
--- ### POINTING ### ---
local mp_pointing = false
function StartPointing()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end
function StopPointing(bool)
    local ped = PlayerPedId()
    if not IsPedInjured(ped) and not bool then
        ClearPedSecondaryTask(ped)
    end
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
end
RegisterCommand("+playPointing", function()
    if not mp_pointing and IsPedOnFoot(PlayerPedId()) then
        StartPointing()
        mp_pointing = true
        while mp_pointing do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            if not Citizen.InvokeNative(0x921CE12C489C4C41, ped) and mp_pointing then
                mp_pointing = false
                StopPointing(true)
            end
            if Citizen.InvokeNative(0x921CE12C489C4C41, ped) then
                if not IsPedOnFoot(ped) then
                    mp_pointing = false
                    StopPointing()
                else
                    local camPitch = GetGameplayCamRelativePitch()
                    if camPitch < -70.0 then
                        camPitch = -70.0
                    elseif camPitch > 42.0 then
                        camPitch = 42.0
                    end
                    camPitch = (camPitch + 70.0) / 112.0

                    local camHeading = GetGameplayCamRelativeHeading()
                    local cosCamHeading = Cos(camHeading)
                    local sinCamHeading = Sin(camHeading)
                    if camHeading < -180.0 then
                        camHeading = -180.0
                    elseif camHeading > 180.0 then
                        camHeading = 180.0
                    end
                    camHeading = (camHeading + 180.0) / 360.0

                    local blocked = 0
                    local nn = 0

                    local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                    local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                    nn,blocked,coords,coords = GetRaycastResult(ray)

                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

                end
            end
        end
    end
end)
RegisterCommand("-playPointing", function()
    if mp_pointing or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
        mp_pointing = false
        StopPointing()
    end
end)
RegisterKeyMapping("+playPointing", "Pokazuj Palcem", "keyboard", "B")

RegisterKeyMapping("+cancelTask", "Anuluj aktualną animację", "KEYBOARD", "X")
RegisterKeyMapping("+putTakeProp", "Odłóż przedmiot", "KEYBOARD", "E")
CreateThread(function()
    TriggerEvent("chat:removeSuggestion", "/+playHandsup")
    TriggerEvent("chat:removeSuggestion", "/-playHandsup")
    TriggerEvent("chat:removeSuggestion", "/+playPointing")
    TriggerEvent("chat:removeSuggestion", "/-playPointing")
    TriggerEvent("chat:removeSuggestion", "/+cancelTask")
    TriggerEvent("chat:removeSuggestion", "/-cancelTask")
    TriggerEvent("chat:removeSuggestion", "/+putTakeProp")
    TriggerEvent("chat:removeSuggestion", "/-putTakeProp")
end)