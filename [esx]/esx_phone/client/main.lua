local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local GUI                        = {}
GUI.Time                         = 0
GUI.PhoneIsShowed                = false
GUI.MessageEditorIsShowed        = false
GUI.MessagesIsShowed             = false
GUI.AddContactIsShowed           = false
local PhoneData                  = {phoneNumber = 0, contacts = {}}
local RegisteredMessageCallbacks = {}

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	
	PhoneData.phoneNumber = phoneNumber

	for i=1, #contacts, 1 do
		table.insert(PhoneData.contacts, contacts[i])
	end

	SendNUIMessage({
		reloadPhone = true,
		phoneData   = PhoneData
	})

	TriggerEvent('esx_phone:registerMessageCallback', 'reply', function(sender, phoneNumber, type, message, position)

		SendNUIMessage({
			showMessages = false
		})

		SendNUIMessage({
			showMessageEditor = true,
			sender            = sender,
			phoneNumber       = phoneNumber,
			type              = 'player',
			message           = message
		})

		SetNuiFocus(true)

		GUI.MessagesIsShowed      = false
		GUI.MessageEditorIsShowed = true

	end)

	TriggerEvent('esx_phone:registerMessageCallback', 'gps', function(sender, phoneNumber, type, message, position)
		SetNewWaypoint(position.x,  position.y)
		TriggerEvent('esx:showNotification', 'Position entrée dans le GPS')
	end)

end)


RegisterNetEvent('esx_phone:addContact')
AddEventHandler('esx_phone:addContact', function(name, phoneNumber, type, notif)

	table.insert(PhoneData.contacts, {
		name   = name,
		number = phoneNumber,
		type   = type
	})

	SendNUIMessage({
		reloadPhone = true,
		phoneData   = PhoneData
	})

	if notif then

		SendNUIMessage({
			showAddContact = false
		})

		TriggerEvent('esx:showNotification', 'Contact ajouté')

	end

end)

RegisterNetEvent('esx_phone:requestPlayerNameForAddPlayerContact')
AddEventHandler('esx_phone:requestPlayerNameForAddPlayerContact', function(phoneNumber, requestSource)
	TriggerServerEvent('esx_phone:responsePlayerNameForAddPlayerContact', GetPlayerName(PlayerId()), phoneNumber, requestSource)
end)

RegisterNetEvent('esx_phone:onMessage')
AddEventHandler('esx_phone:onMessage', function(phoneNumber, playerName, type, message, position, actions)

	TriggerEvent('esx:showNotification', playerName .. ' : ' .. message)
	
	SendNUIMessage({
		newMessage  = true,
		sender      = playerName,
		phoneNumber = phoneNumber,
		type        = type,
		message     = message,
		position    = position,
		actions     = actions
	})
end)

AddEventHandler('esx_phone:registerMessageCallback', function(action, cb)
	
	if RegisteredMessageCallbacks[action] == nil then
		RegisteredMessageCallbacks[action] = {}
	end

	table.insert(RegisteredMessageCallbacks[action], cb)
end)

RegisterNUICallback('select', function(data, cb)

	if data.type == 'builtin' then

		if data.val == 'read_messages' then

			SendNUIMessage({
				showMessages = true
			})

			SetNuiFocus(true)

			GUI.MessagesIsShowed = true

		end

		if data.val == 'add_contact' then

			SendNUIMessage({
				showAddContact = true
			})

			SetNuiFocus(true)

			GUI.AddContactIsShowed = true

		end

	end

	if data.type == 'special' or data.type == 'player' then

		SendNUIMessage({
			showMessageEditor = true
		})

		SetNuiFocus(true)

		GUI.MessageEditorIsShowed = true

	end

	cb('ok')

end)

RegisterNUICallback('message_callback', function(data, cb)

	for i=1, #RegisteredMessageCallbacks[data.action], 1 do
		RegisteredMessageCallbacks[data.action][i](data.sender, data.phoneNumber, data.type, data.message, data.position);
	end

	cb('ok')

end)

RegisterNUICallback('add_contact', function(data, cb)

	local phoneNumber = tonumber(data.phoneNumber)

	if phoneNumber then
		TriggerServerEvent('esx_phone:addPlayerContact', phoneNumber)
	else
		TriggerEvent('esx:showNotification', 'Veuillez entrer un numéro valide')
	end

	cb('ok')

end)

RegisterNUICallback('send', function(data, cb)

	TriggerServerEvent('esx_phone:send', data.type, data.number, GetPlayerName(PlayerId()), data.message)
	TriggerEvent('esx:showNotification', 'Message envoyé')
	
	SendNUIMessage({
		showMessageEditor = false
	})

	SetNuiFocus(false)

	GUI.MessageEditorIsShowed = false

	cb('ok')
end)

RegisterNUICallback('escape', function(data, cb)

	if GUI.MessageEditorIsShowed then

		SendNUIMessage({
			showMessageEditor = false
		})

		SetNuiFocus(false)

		GUI.MessageEditorIsShowed = false

	end

	if GUI.MessagesIsShowed then

		SendNUIMessage({
			showMessages = false
		})

		SetNuiFocus(false)

		GUI.MessagesIsShowed = false
		
	end

	if GUI.AddContactIsShowed then

		SendNUIMessage({
			showAddContact = false
		})

		SetNuiFocus(false)

		GUI.AddContactIsShowed = false
		
	end


	cb('ok')

end)

-- Menu Controls
Citizen.CreateThread(function()
	while true do

		Wait(0)

    if GUI.MessageEditorIsShowed or GUI.MessagesIsShowed or GUI.AddContactIsShowed then

      DisableControlAction(0, 1,   true) -- LookLeftRight
      DisableControlAction(0, 2,   true) -- LookUpDown
      DisableControlAction(0, 142, true) -- MeleeAttackAlternate
      DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

      DisableControlAction(0, 12, true) -- WeaponWheelUpDown
      DisableControlAction(0, 14, true) -- WeaponWheelNext
      DisableControlAction(0, 15, true) -- WeaponWheelPrev
      DisableControlAction(0, 16, true) -- SelectNextWeapon
      DisableControlAction(0, 17, true) -- SelectPrevWeapon

      if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
        SendNUIMessage({
          click = true
        })
      end

    else

			if IsControlPressed(0, Keys['9']) and (GetGameTimer() - GUI.Time) > 300 then

				if not GUI.PhoneIsShowed then

					SendNUIMessage({
						showPhone = true,
						phoneData = PhoneData
					})

					GUI.PhoneIsShowed = true

				end

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['ENTER']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					enterPressed = true
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['BACKSPACE']) and (GetGameTimer() - GUI.Time) > 300 then

				if GUI.PhoneIsShowed and not GUI.MessageEditorIsShowed and not GUI.MessagesIsShowed and not GUI.AddContactIsShowed then

					SendNUIMessage({
						showPhone = false,
					})

					GUI.PhoneIsShowed = false

				else

					SendNUIMessage({
						backspacePressed = true
					})

				end

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['LEFT']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'LEFT'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['RIGHT']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'RIGHT'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['TOP']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'UP'
				})

				GUI.Time = GetGameTimer()

			end

			if IsControlPressed(0, Keys['DOWN']) and (GetGameTimer() - GUI.Time) > 300 then

				SendNUIMessage({
					move = 'DOWN'
				})

				GUI.Time = GetGameTimer()

			end

		end

	end
end)