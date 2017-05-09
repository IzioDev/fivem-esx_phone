require "resources/[essential]/es_extended/lib/MySQL"
MySQL:open("127.0.0.1", "gta5_gamemode_essential", "root", "foo")

local RegisteredCallbacks = {}

local function GenerateUniquePhoneNumber()

	local foundNumber = false
	local phoneNumber = nil

	while not foundNumber do

		phoneNumber = math.random(10000, 99999)

		local executed_query = MySQL:executeQuery("SELECT COUNT(*) as count FROM users WHERE phone_number = '@phoneNumber'", {['@phoneNumber'] = number})
		local result         = MySQL:getResults(executed_query, {'count'})
		local count          = tonumber(result[1].count)

		if count == 0 then
			foundNumber = true
		end

	end

	return phoneNumber

end

AddEventHandler('onResourceStart', function(ressource)
	if ressource == 'esx_phone' then
		TriggerEvent('esx_phone:ready')
	end
end)

AddEventHandler('esx:playerLoaded', function(source)

	local _source = source

	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)

		local executed_query = MySQL:executeQuery("SELECT * FROM users WHERE identifier = '@identifier'", {['@identifier'] = xPlayer.identifier})
		local result         = MySQL:getResults(executed_query, {'phone_number'})
		local phoneNumber    = result[1].phone_number

		if phoneNumber == nil then
			phoneNumber = GenerateUniquePhoneNumber()
			MySQL:executeQuery("UPDATE users SET phone_number = '@phone_number' WHERE identifier = '@identifier'", {['@identifier'] = xPlayer.identifier, ['@phone_number'] = phoneNumber})
		end

		xPlayer['phoneNumber'] = phoneNumber

		local contacts = {}

		local executed_query2 = MySQL:executeQuery("SELECT * FROM user_contacts WHERE identifier = '@identifier'", {['@identifier'] = xPlayer.identifier})
		local result2         = MySQL:getResults(executed_query2, {'name', 'number'})

		for i=1, #result2, 1 do
			
			table.insert(contacts, {
				name   = result2[i].name,
				number = result2[i].number,
				type   = 'player'
			})

		end

		xPlayer['contacts'] = contacts

		TriggerClientEvent('esx_phone:loaded', _source, phoneNumber, contacts)

	end)
end)

RegisterServerEvent('esx_phone:registerCallback')
AddEventHandler('esx_phone:registerCallback', function(type, cb)
	if RegisteredCallbacks[type] == nil then
		RegisteredCallbacks[type] = {}
	end
	table.insert(RegisteredCallbacks[type], cb)
end)

RegisterServerEvent('esx_phone:send')
AddEventHandler('esx_phone:send', function(type, phoneNumber, playerName, message)
	for i=1, #RegisteredCallbacks[type], 1 do
		RegisteredCallbacks[type][i](source, phoneNumber, playerName, type, message)
	end
end)

RegisterServerEvent('esx_phone:addPlayerContact')
AddEventHandler('esx_phone:addPlayerContact', function(phoneNumber)

		local _source = source

		TriggerEvent('esx:getPlayers', function(xPlayers)
			
			local foundNumber = false;
			local foundPlayer = nil

			for k, v in pairs(xPlayers) do
				if v.phoneNumber == phoneNumber then
					foundNumber = true
					foundPlayer = v
				end
			end

			if foundNumber then

				TriggerEvent('esx:getPlayerFromId', _source, function(xPlayer)

					if phoneNumber == xPlayer.phoneNumber then
						TriggerClientEvent('esx:showNotification', _source, 'Vous ne pouvez pas vous ajouter vous-même')
					else

						local hasAlreadyAdded = false

						for i=1, #xPlayer.contacts, 1 do
							if xPlayer.contacts[i].number == phoneNumber then
								hasAlreadyAdded = true
							end
						end

						if hasAlreadyAdded then
							TriggerClientEvent('esx:showNotification', _source, 'Ce numéro est déja dans votre liste de contacts')
						else
							TriggerClientEvent('esx_phone:requestPlayerNameForAddPlayerContact', foundPlayer.player.source, phoneNumber, _source)
						end
					end

				end)

			else
				TriggerClientEvent('esx:showNotification', _source, 'Ce numéro n\'existe pas ou le joueur n\'est pas connecté')
			end

		end)
end)

RegisterServerEvent('esx_phone:responsePlayerNameForAddPlayerContact')
AddEventHandler('esx_phone:responsePlayerNameForAddPlayerContact', function(playerName, phoneNumber, requestSource)
		TriggerEvent('esx:getPlayerFromId', requestSource, function(xPlayer)
			
			table.insert(xPlayer.contacts, {
				name   = playerName,
				number = phoneNumber,
				type   = 'player'
			})

			MySQL:executeQuery("INSERT INTO user_contacts (identifier, name, number) VALUES ('@identifier', '@name', '@number')", {['@identifier'] = xPlayer.identifier, ['@name'] = playerName, ['@number'] = phoneNumber})
			TriggerClientEvent('esx_phone:addContact', requestSource, playerName, phoneNumber, 'player', true)
		end)

end)

AddEventHandler('esx_phone:ready', function()
	
	TriggerEvent('esx_phone:registerCallback', 'player', function(source, phoneNumber, playerName, type, message)
		TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
			TriggerEvent('esx:getPlayers', function(xPlayers)
				for k, v in pairs(xPlayers) do
					if v.phoneNumber == phoneNumber then
						RconPrint('Message => ' .. playerName .. ' ' .. message)
						TriggerClientEvent('esx_phone:onMessage', v.player.source, xPlayer.phoneNumber, playerName, type, message, xPlayer.player.coords, {reply = 'Répondre'})
					end
				end
			end)
		end)
	end)

end)