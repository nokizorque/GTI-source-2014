tableName, tableAmmo = "gundbGun", "gundbAmmo"

--db = dbConnect( "mysql", "dbname=gtishared;host=127.0.0.1", "GTIShared", "8tEMgtFKJS3Epy")
db = dbConnect( "mysql", "dbname=gtishared;host=127.0.0.1", "LilDolla", "haUNWUd!52Bf")
dbExec ( db, "CREATE TABLE IF NOT EXISTS "..tableName.." ( name TEXT)")
dbExec ( db, "CREATE TABLE IF NOT EXISTS "..tableAmmo.." ( name TEXT)")
--db = dbConnect( "sqlite", "guns.db")
local BACKUP_INTERVAL = 60

gunAccData = {}
gunAmmoAccData = {}

if (BACKUP_INTERVAL) then

function hourlyBackup()
	destroyElement(db)
	--db = dbConnect( "mysql", "dbname=gtishared;host=127.0.0.1", "GTIShared", "8tEMgtFKJS3Epy")
	db = dbConnect( "mysql", "dbname=gtishared;host=127.0.0.1", "LilDolla", "haUNWUd!52Bf")
	--db = dbConnect( "sqlite", "guns.db")
end
setTimer( hourlyBackup, 60000*BACKUP_INTERVAL, 1)
end

function cacheDatabase()
	dbQuery(cacheDatabaseGuns, {}, db, "SELECT * FROM `"..tableName.."`")
	dbQuery(cacheDatabaseAmmo, {}, db, "SELECT * FROM `"..tableAmmo.."`")
end
addEventHandler("onResourceStart", resourceRoot, cacheDatabase)

function cacheDatabaseGuns(qh)
	local accData = dbPoll(qh, 0)
	gunAccData["Console"] = {}
	for i,row in ipairs(accData) do
		gunAccData[row.name] = {}
		for column,value in pairs(row) do
			if (column ~= "name") then
				if (value == nil) then value = "nil" end
				gunAccData["Console"][column] = true
				gunAccData[row.name][column] = value
			end
		end
	end
end

function cacheDatabaseAmmo(qh)
	local accData = dbPoll(qh, 0)
	gunAmmoAccData["Console"] = {}
	for i,row in ipairs(accData) do
		gunAmmoAccData[row.name] = {}
		for column,value in pairs(row) do
			if (column ~= "name") then
				if (value == nil) then value = "nil" end
				gunAmmoAccData["Console"][column] = true
				gunAmmoAccData[row.name][column] = value
			end
		end
	end
end

function setGunAccountData(account, key, value, ammo)
	if (not account or not key or not value or not ammo) then return false end
	if (isGuestAccount(account) or type(key) ~= "string") then return false end
	if (type(key) == "string" or type(key) == "number") then
		local account = getAccountName( account)
		if (type(gunAccData[account]) ~= "table") then
			gunAccData[account] = {}
			gunAmmoAccData[account] = {}
			dbExec(db, "INSERT INTO `"..tableName.."` (name) VALUES(?)", account)
			dbExec(db, "INSERT INTO `"..tableAmmo.."` (name) VALUES(?)", account)
		end
		if (gunAccData["Console"][key] == nil) then
			dbExec(db, "ALTER TABLE `"..tableName.."` ADD `??` text", key)
			dbExec(db, "ALTER TABLE `"..tableAmmo.."` ADD `??` text", key)
			gunAccData["Console"][key] = true
			gunAmmoAccData["Console"][key] = true
		end
		gunAccData[account][key] = value
		gunAmmoAccData[account][key] = ammo
		--outputDebugString("Gun Data Placed: Account:'"..account.."' Key:'"..key.."' Value:'"..value.."' Ammo:'"..ammo.."'")
		dbExec(db, "UPDATE `"..tableName.."` SET `??`=? WHERE name=?", key, tostring(value), account) --convert value to string by default.
		dbExec(db, "UPDATE `"..tableAmmo.."` SET `??`=? WHERE name=?", key, tostring(ammo), account) --convert value to string by default.
		return true
		else return false end
    end

function getGunAccountData(account, key)
	if (not account or not key) then return nil end
	if (isGuestAccount(account) or type(key) ~= "string") then return nil end
	local account = getAccountName(account)
	if (gunAccData[account] == nil) then return nil end
	if (gunAccData[account][key] == nil) then return nil end
	return tonumber(gunAccData[account][key]) or gunAccData[account][key]
end

function getAmmoAccountData(account, key)
	if (not account or not key) then return nil end
	if (isGuestAccount(account) or type(key) ~= "string") then return nil end
	local account = getAccountName(account)
	if (gunAmmoAccData[account] == nil) then return nil end
	if (gunAmmoAccData[account][key] == nil) then return nil end
	return tonumber(gunAmmoAccData[account][key]) or gunAmmoAccData[account][key]
end

function getPlayerWeapons(player)
	local playerWeapons = {}
	if player and isElement(player) and getElementType(player) == "player" then
		for i=1,12 do
			local wep = getPedWeapon(player,i)
			if wep and wep ~= 0 then
				table.insert(playerWeapons,wep)
			end
		end
	else
		return false
	end
	return playerWeapons
end

local maxGunCapacity = {
	--Handguns
	[22] = 3500,
	[23] = 3500,
	[24] = 3500,
	--Shotguns
	[25] = 1500,
	[26] = 1500,
	[27] = 1500,
	--Sub-Machine Guns
	[28] = 6000,
	[29] = 6000,
	[32] = 6000,
	--Assault Rifles
	[30] = 9999,
	[31] = 9999,
	--Snipers
	[33] = 500,
	[34] = 500,
	--Minigun/FlameThrower
	[37] = 9999,
	[38] = 9999,
	--Rocket Launchers
	[35] = 20,
	[36] = 20,
	--Projectiles
	[16] = 20,
	[17] = 20,
	[18] = 20,
	[39] = 20,
}

local weaponT = {}
local ammoT = {}
local wepToGive = {}

function givePlayerWeapons( player, type)
	if isElement( player) then
		local account = getPlayerAccount(player)
		for id=1, 60, 1 do
			local name = getWeaponNameFromID(id)
			if name then
				local weapon = getGunAccountData( account, name)
				local ammo = getAmmoAccountData( account, name)
				local limit = maxGunCapacity[weapon]
				if weapon and ammo then
					takeAllWeapons(player)
					if type == "logon" then
						if ammo >= limit then
							setTimer(giveWeapon, 1000, 1, player, weapon, limit)
						else
							setTimer(giveWeapon, 1000, 1, player, weapon, ammo-1406)
						end
					elseif type == "spawn" then
						if ammo >= limit then
							setTimer(giveWeapon, 1000, 1, player, weapon, limit)
						else
							setTimer(giveWeapon, 1000, 1, player, weapon, ammo)
						end
					end
					--giveWeapon( player, weapon, ammo)
				elseif weapon then
					setTimer(giveWeapon, 1000, 1, player, weapon, 200)
				end
			end
		end
	end
end

function giveWeaponLogin()
	givePlayerWeapons( source, "logon")
end
addEventHandler("onPlayerLogin", root, giveWeaponLogin)

function savePlayerWeapons( account, player)
	if (isGuestAccount(account) or not isElement(player)) then return end
	for _, wep in ipairs (getPlayerWeapons(player)) do
		local name = getWeaponNameFromID( wep)
		local weaponAmmo = getPedTotalAmmo( player , getSlotFromWeapon(wep))
		return name, weaponAmmo
	end
end


function saveWeaponLogout(account, player)
	if (isGuestAccount(account) or not isElement(player)) then return end
	for _, wep in pairs (getPlayerWeapons(player)) do
		local weaponName = getWeaponNameFromID( wep)
		local weaponAmmo = getPedTotalAmmo( player,getSlotFromWeapon(wep))
		setGunAccountData(account, weaponName, wep, weaponAmmo)
	end
end

function onPlayerQuit()
	local account = getPlayerAccount( source)
	--saveWeaponLogout( account, source)
end
addEventHandler("onPlayerQuit", root, onPlayerQuit)

function convertWeaponsToSJSON(player)
	local weaponSlots = 12
	local weaponsTable = {}
	for slot = 1, weaponSlots do
		local weapon = getPedWeapon(player, slot)
		local name = getWeaponNameFromID( weapon)
		local ammo = getPedTotalAmmo(player, slot)
		if (weapon > 0 and ammo > 0) then
			setGunAccountData( getPlayerAccount(player), name, weapon, ammo)
			weaponsTable[weapon] = ammo
		end
	end
end


function onPlayerDeath()
	local acc = getPlayerAccount( source)
	local name, ammo = savePlayerWeapons( acc, source)
	saveWeaponLogout( acc, source)
	--outputChatBox( "Weapon:'"..name.."' Ammo:'"..ammo.."'", source, 255, 255 ,255)
end
addEventHandler("onPlayerWasted", root, onPlayerDeath)

function giveWeaponsJSON(player, weapons)
	if (weapons and weapons ~= "") then
		for weapon, ammo in pairs(fromJSON(weapons)) do
			if (weapon and ammo) then
				giveWeapon(player, tonumber(weapon), tonumber(ammo))
			end
		end
	end
end

function giveOnSpawn()
	givePlayerWeapons( source, "spawn")
end
addEventHandler ( "onPlayerSpawn", root, giveOnSpawn)
