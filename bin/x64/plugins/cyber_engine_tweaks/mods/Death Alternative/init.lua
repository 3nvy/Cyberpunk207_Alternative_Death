local moneyID = ItemID.new(TweakDBID.new("Items.money"))

local IProps = {
	deltaTime = 0,
	activePackage = nil,
	drawSetupMenu = false,
	canPayRevive = false,
	canDrawDeathScreen = false,
	canDrawBuyLifePackScreen = false,
	rootPath = "plugins.cyber_engine_tweaks.mods.Death Alternative.",
	hospitalCoords = {
		{ x = -1337.394, y = 1745.6206 },
		{ x = -1331.4171, y = 1745.0977 },
		{ x = -1361.3032, y = 1747.7123 },
		{ x = -1367.2804, y = 1748.2352 },
	}
}

local CPS = require(IProps.rootPath.."CPStyling")
local Utils = require(IProps.rootPath.."utilities")
local heme = CPS.theme
local color = CPS.color

local Config = {
	lifePackages = {
		{ name = "Platinum", time = 1, healthRegen = 100, price = 50000 },
		{ name = "Gold", time = 3, healthRegen = 50, price = 25000 },
		{ name = "Silver", time = 5, healthRegen = 25, price = 10000 },
	}
}


function hasGodMode(player)
	return Game.GetGodModeSystem():HasGodMode(player:GetEntityID(), "Immortal")
end

function enableGodMod(player)
	gms:EnableOverride(player:GetEntityID(), "Immortal", CName.new("SecondHeart"))
end

function disableGodMod(player)
	gms:DisableOverride(player:GetEntityID(), CName.new("SecondHeart"))
end

function revivePlayer(player)
	local player = Game.GetPlayer()
	if player and IProps.canDrawDeathScreen then
		local lpDetails = Config.lifePackages[IProps.activePackage]

		Game.Heal(lpDetails.healthRegen)
		ts:RemoveItem(player, moneyID, lpDetails.price)
		Game.TeleportPlayerToPosition(-372.268982, 271.240143, 215.515579)
		Game.GetPlayer():SetWarningMessage("Player Revived")
		Game.SetTimeDilation(0)
		IProps.canDrawDeathScreen = false
	end
end

function cancelRevive(player)
	local player = Game.GetPlayer()
	if player and IProps.canDrawDeathScreen then
		qs:SetFactStr("activeHealthPack", 0)
		IProps.activePackage = nil
		disableGodMod(player)
		player:Kill()
		Game.SetTimeDilation(0)
		IProps.canDrawDeathScreen = false
	end
end

function lowHealthThresholdReached(player)

	if IProps.activePackage > 0 then
		
		local playerMoney = ts:GetItemQuantity(player, moneyID)
		local packageValue = Config.lifePackages[IProps.activePackage].price

		if playerMoney < packageValue then 
			IProps.canPayRevive = false
		else
			IProps.canPayRevive = true
		end
		
		IProps.canDrawDeathScreen = true
		Game.SetTimeDilation(0.00001)
	else
		IProps.canDrawDeathScreen = true
		cancelRevive(player)
	end

end

function checkActiveLifePack()
	
	IProps.activePackage = qs:GetFactStr("activeHealthPack")

end

function playerIsInDistance(coordsList, maxDistance)
	local player = Game.GetPlayer()
	if player then
		local pLoc = player:GetWorldPosition()

		for _, coords in pairs(coordsList) do 
			local dx = coords.x - pLoc.x
			local dy = coords.y - pLoc.y
			local distance = math.sqrt( dx * dx + dy * dy )
			if distance <= maxDistance then
				return true
			end
		end
		
	end

	return false
end

function runUpdates()
	if Game.GetQuestsSystem():GetFactStr("q000_started") == 1 then 
		player = Game.GetPlayer()
	end

	if not player then return end

	local currentHealthPercentage = player.healthStatListener.healthEvent.value

	checkActiveLifePack()
	if not IProps.activePackage and hasGodMode(player) then 
		disableGodMod(player)
		Game.GetPlayer():SetWarningMessage("Alternative Death Disabled")
	end

	if IProps.activePackage and not hasGodMode(player) and currentHealthPercentage > 1 then 
		enableGodMod(player)
		-- Game.GetPlayer():SetWarningMessage("Alternative Death Enabled")
	end

	if IProps.activePackage and currentHealthPercentage == 1 then
		lowHealthThresholdReached(player, IProps.activePackage)
	end

	if playerIsInDistance(IProps.hospitalCoords, 3) then
		IProps.canDrawBuyLifePackScreen = true
	else 
		IProps.canDrawBuyLifePackScreen = false
	end

end

function drawDeathScreen()
	if IProps.canDrawDeathScreen then 
		local lp = Config.lifePackages[IProps.activePackage]

		CPS.setThemeBegin()
		CPS.colorBegin("WindowBg", {0,0,0,1})

		ImGui.SetNextWindowSize(wWidth, wHeight)
		ImGui.Begin("DeathScreen", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoBringToFrontOnFocus)
			ImGui.SetWindowPos(0,0)
		ImGui.End()

		ImGui.SetNextWindowSize(240, 220)
		ImGui.Begin("PopUp", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoMove)
			ImGui.SetWindowPos(wWidth / 2 - 120, wHeight / 2 - 110)
			ImGui.Spacing()
			ImGui.SameLine(95)
			ImGui.Text("You Died")
			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()
			ImGui.Spacing()
			ImGui.Text("Your Current Pack: "..lp.name)
			ImGui.Spacing()
			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()
			ImGui.Spacing()
			if IProps.canPayRevive then
				ImGui.Text("Revive Time: "..lp.time.." day(s)")
				ImGui.Spacing()
				ImGui.Spacing()

				ImGui.Text("Health Regenerated: "..lp.healthRegen.."%%")
				ImGui.Spacing()
				ImGui.Spacing()

				ImGui.Text("Revive Price: "..lp.price.." eddies")
			else
				ImGui.Text("You don't have enouth money")
				ImGui.Text("in you bank account to revive.")
				ImGui.Spacing()
				ImGui.Spacing()
				ImGui.Text("Trauma team has canceled your")
				ImGui.Text("insurance and wont be coming.")
			end
			ImGui.Spacing()
			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()
			ImGui.Spacing()
			ImGui.Spacing()
			if IProps.canPayRevive then
				revivePressed = CPS.CPButton("Revive", 100, 30)
				if revivePressed then
					revivePlayer()
				end
			end
			ImGui.SameLine(130)
			dieAndReload = CPS.CPButton("Die & Reload", 100, 30)
			if dieAndReload then
				cancelRevive()
			end

		ImGui.End()

		CPS.colorEnd(1)
		CPS.setThemeEnd()
	end
end

function drawActiveLifePackage()
	CPS.setThemeBegin()
	CPS.colorBegin("WindowBg", {0,0,0,0.5})
	ImGui.SetNextWindowSize(190, 10)
	if ImGui.Begin("ActiveLifePack", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoScrollbar) then
		ImGui.SetWindowPos(wWidth - 270, 328)
		if IProps.activePackage then
			ImGui.Text("Life Insurance: "..IProps.activePackage)
		else
			ImGui.Text("Life Insurance: None")
		end
	end
	ImGui.End()
	CPS.colorEnd(1)
	CPS.setThemeEnd()
end

function buyPackage(packageID, packageName)
	local qs = Game.GetQuestsSystem()
	IProps.activePackage = packageID
	qs:SetFactStr("activeHealthPack", packageID)
	Game.GetPlayer():SetWarningMessage(packageName.." Insurance Package Activated")
end

function drawBuyLifePack()
	if IProps.canDrawBuyLifePackScreen then
		CPS.setThemeBegin()
		CPS.colorBegin("WindowBg", {0,0,0,1})

		ImGui.SetNextWindowSize(240, 472)
		if ImGui.Begin("BuyLifePack", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoMove) then
			ImGui.SetWindowPos(wWidth / 2 - 120, wHeight / 2 + 30)
			ImGui.Spacing()
			ImGui.SameLine(70)
			ImGui.Text("Trauma Team HQ")
			ImGui.Spacing()

			for packageID, packDetails in pairs(Config.lifePackages) do 
				ImGui.Separator()
				ImGui.Spacing()
				ImGui.Spacing()
				if packDetails.name == "Gold" then
					CPS.colorBegin("Text", color.yellow)
				elseif packDetails.name == "Silver" then
					CPS.colorBegin("Text", color.silver)
				elseif packDetails.name == "Platinum" then
					CPS.colorBegin("Text", color.cyan)
				else
					CPS.colorBegin("Text", color.red)
				end
				ImGui.Text(packDetails.name.." Insurance Package")
				CPS.colorEnd(1)
				ImGui.Spacing()
				ImGui.Spacing()
				ImGui.Text("Treatment Time: "..packDetails.time.." day(s)")
				ImGui.Spacing()
				ImGui.Text("Health Regenerated: "..packDetails.healthRegen.."%%")
				ImGui.Spacing()
				ImGui.Text("Revive Cost: "..packDetails.price.." eddies")
				ImGui.Spacing()
				ImGui.Spacing()
				if IProps.activePackage > 0 and packDetails.name == Config.lifePackages[IProps.activePackage].name then
					CPS.CPButton("Already Owned", 222, 30)
				else
					local buy = CPS.CPButton("Activate "..packDetails.name.." Package", 222, 30)
					if buy then
						buyPackage(packageID, packDetails.name)
					end
				end
				ImGui.Spacing()
				ImGui.Spacing()
			end
		end

		ImGui.End()

		CPS.colorEnd(1)
		CPS.setThemeEnd()
	end
end

registerForEvent("onInit", function()
	ts = Game.GetTransactionSystem()
	as = Game.GetActivityLogSystem()
	tp = Game.GetTeleportationFacility()
	qs = Game.GetQuestsSystem()
	gms = Game.GetGodModeSystem()
	wWidth, wHeight = GetDisplayResolution()

	print("[Death Alternative] Initialized | Version: 1.0.0")
end)

registerForEvent("onUpdate", function(deltaTime)
	
	IProps.deltaTime = IProps.deltaTime + deltaTime

    if IProps.deltaTime > 1 then
        runUpdates()
        IProps.deltaTime = IProps.deltaTime - 1
    end

end)

registerHotkey("exit_hotel", "Exit Hotel", function()

	local coords = {{x = -364.96457, y = 267.6644}}
	
	local canTeleport = playerIsInDistance(coords, 3)
	if canTeleport then
		Game.TeleportPlayerToPosition(-346.79602, 221.25322, 27.59404)
	end
	
end)

registerForEvent("onDraw", function()

	drawDeathScreen(IProps.canDrawDeathScreen)

	drawBuyLifePack(IProps.canDrawBuyLifePackScreen, Game.GetQuestsSystem())

end)