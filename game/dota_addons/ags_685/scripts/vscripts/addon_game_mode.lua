-- Generated from template

require('settings')
require('notifications')
require('storageapi/json')
require('storageapi/storage')
require("statcollection/init")


if CagsGameMode == nil then
	CagsGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.ags = CagsGameMode()
	GameRules.ags:InitGameMode()
end

function CagsGameMode:InitGameMode()
	print( "ags is loaded." )
	Storage:SetApiKey("fc80985d01e14165c9ca9d03848eaecd58d3ede3")
	CountN = 0
	TooltipReport = false
	FewPlayer = false
	FewPlayerBroadcast = false
	WinStreakBroadcast = false
	WinStreakRecord = false
	PudgeExist = false
	MiranaExist = false
	DruidExist = false
	TechiesSuicide = false
	FinalNotice = false
	PlayerSum = PlayerResource:GetPlayerCount()
	RadiantPlayers = 0
	DirePlayers = 0
	RadiantPlayersNow = 0
	DirePlayersNow = 0
	PlayerRandom = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerRepick = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
  PlayerAbandon = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
  AbandonTest = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerTeam = {}
	PlayerIDtoHeroIndex = {}
	PlayerStorage = {}
	GoldCoef = {2,1.414214,1.224745,1.154701,1.118034} --nil,sqrt(2/1),sqrt(3/2),sqrt(4/3),sqrt(5/4)
	RadiantGC = 1
	DireGC = 1
	RadiantScore = 0
	DireScore = 0
	--PlayerHeroRandomName = {}
	--SendToServerConsole("sv_cheats 1")
	
	GameRules:GetGameModeEntity():SetThink( "HeroSelectionThink", self, "HST")
	GameRules:GetGameModeEntity():SetThink( "AbandonCheckThink", self, "ACT")
	GameRules:GetGameModeEntity():SetThink( "AbandonReimburseThink", self, "ART")
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride ( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,RadiantScore)
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS,DireScore)
	
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CagsGameMode, 'OnStateChange' ), self )
	ListenToGameEvent( "dota_player_pick_hero", Dynamic_Wrap( CagsGameMode, 'OnHeroPicked' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CagsGameMode, 'OnNpcSpawned' ), self )
	ListenToGameEvent( "dota_player_used_ability", Dynamic_Wrap( CagsGameMode, 'OnPlayerUseAbility' ), self )
	ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CagsGameMode, 'OnEntityHurt' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CagsGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "player_score", Dynamic_Wrap( CagsGameMode, 'OnScoreChanged' ), self )
	ListenToGameEvent( "player_disconnect", Dynamic_Wrap( CagsGameMode, 'OnPlayerDisconnect' ), self )
	ListenToGameEvent( "game_end", Dynamic_Wrap( CagsGameMode, 'OnGameEnd' ), self )
end

function CagsGameMode:HeroSelectionThink()
	--print(GameRules:State_Get())
	if (GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION) and (GameRules:State_Get() <= DOTA_GAMERULES_STATE_PRE_GAME) then
		--ShowGenericPopup("#addon_game_name", "#addon_game_name", "", "",0|1)
		if not(TooltipReport) then
			GameRules:SendCustomMessage("#addon_report",0,0)
			TooltipReport = true
		end
		if (FewPlayerBroadcast) then
			GameRules:SendCustomMessage("#addon_few_player",0,0)
			FewPlayerBroadcast = false
		end
		for i = 0,31 do
			if (PlayerResource:HasRepicked(i)==true) and (PlayerRepick[i+1] == false) then
				GameRules:SendCustomMessage("#addon_repick", i, 0)	
				PlayerRepick[i+1] = true
			else
				if (PlayerResource:HasRandomed(i)==true) and (PlayerRandom[i+1] == false) then
					--PlayerHeroRandomName[i+1] = PlayerResource:GetSelectedHeroName(i)
					--PlayerHeroRandomName[i+1] = string.sub(PlayerHeroRandomName[i+1],15,string.len(PlayerHeroRandomName[i+1]))
					PlayerRandom[i+1] = true
					GameRules:SendCustomMessage("#addon_random_pick", i, 0)
				end
			end
		end
	end
	return 0.5
end

function CagsGameMode:AbandonCheckThink()
	--[[
	for i = 0, 31 do
		if (PlayerIDtoHeroIndex[i+1]~=nil) then
			if (EntIndexToHScript(PlayerIDtoHeroIndex[i+1]):HasOwnerAbandoned()==true) and (PlayerAbandon[i+1]==false) then
				GameRules:SendCustomMessage("%s1 has abandoned. Reimbursement will be realized in future updates ", i, 0)
				PlayerAbandon[i+1]=true
			end
		end
	end
	]]
	if GameRules:State_Get()>=DOTA_GAMERULES_STATE_STRATEGY_TIME then
		for i = 0, 31 do
			if ((PlayerResource:GetConnectionState(i)==DOTA_CONNECTION_STATE_ABANDONED)or(AbandonTest[i+1])) and (PlayerAbandon[i+1]==false) and ((PlayerTeam[i+1]==2)or(PlayerTeam[i+1]==3)) then
				PlayerAbandon[i+1]=true
				if PlayerTeam[i+1]==2 then
					GCMulti = GoldCoef[RadiantPlayersNow]
					RadiantGC = RadiantGC * GCMulti
					for j = 0, 31 do
						if PlayerTeam[j+1]==2 then
							ItemCost = 0 --get player j total item cost
							if PlayerResource:GetSelectedHeroEntity(j) then
								for k = 0, 11 do
									if PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k) then
										ItemCost = ItemCost + PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k):GetCost()
									end
								end
							end
							if i==j then
								ItemCosti = ItemCost
							end
							PlayerResource:ModifyGold(j,math.floor((PlayerResource:GetGold(j)+ItemCost)*(GCMulti-1)), false, 0)
						end
					end				
					PlayerResource:ModifyGold(i,math.floor(ItemCosti/2), false, 0)
					GameRules:SendCustomMessage("%s1 abandoned. All radiant players' gold, GPM and respawn speed become "..((math.floor(RadiantGC*100))/100).."x.", i, 0)				
  				Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(i), imagestyle="landscape", duration=10.0})
  				Notifications:BottomToAll({text="#addon_abandon_radiant_01", continue=true, style={["font-size"]="30px"}})
  				Notifications:BottomToAll({text=""..((math.floor(RadiantGC*100))/100), continue=true, style={["font-size"]="30px"}})
  				Notifications:BottomToAll({text="#addon_abandon_radiant_02", continue=true, style={["font-size"]="30px"}})
					RadiantPlayersNow = RadiantPlayersNow - 1
				else
					GCMulti = GoldCoef[DirePlayersNow]
					DireGC = DireGC * GCMulti
					for j = 0, 31 do
						if PlayerTeam[j+1]==3 then
							ItemCost = 0 --get player j total item cost
							if PlayerResource:GetSelectedHeroEntity(j) then
								for k = 0, 11 do
									if PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k) then
										ItemCost = ItemCost + PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k):GetCost()
									end
								end
							end
							if i==j then
								ItemCosti = ItemCost
							end
							PlayerResource:ModifyGold(j,math.floor((PlayerResource:GetGold(j)+ItemCost)*(GCMulti-1)), false, 0)
						end
					end				
					PlayerResource:ModifyGold(i,math.floor(ItemCosti/2), false, 0)
					GameRules:SendCustomMessage("%s1 abandoned. All dire players' gold, GPM and respawn speed "..((math.floor(DireGC*100))/100).."x.", i, 0)				
  				Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(i), imagestyle="landscape", duration=10.0})
  				Notifications:BottomToAll({text="#addon_abandon_dire_01", continue=true, style={["font-size"]="30px"}})
  				Notifications:BottomToAll({text=""..((math.floor(DireGC*100))/100), continue=true, style={["font-size"]="30px"}})
  				Notifications:BottomToAll({text="#addon_abandon_dire_02", continue=true, style={["font-size"]="30px"}})
					DirePlayersNow = DirePlayersNow - 1
				end
			end
		end
	end
	return 3
end

function CagsGameMode:AbandonReimburseThink()
	if (((GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME) or (GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS)) and not(GameRules:IsGamePaused())) then
		--print(PlayerResource:GetGold(0))
		--print(PlayerResource:GetGoldSpentOnItems(0))
		--print(PlayerResource:GetConnectionState(0))
		RadiantGoldReim = 0
		DireGoldReim = 0
		for i = 0, 31 do
			if PlayerTeam[i+1]==2 then
				PlayerResource:ModifyGold(i,math.floor(10*(10/(RadiantPlayers+DirePlayers))^1.5*(RadiantGC-1)), false, 0)
				if PlayerAbandon[i+1] then
					RadiantGoldReim = RadiantGoldReim + PlayerResource:GetGold(i)
					PlayerResource:SetGold(i,0,false)
					PlayerResource:SetGold(i,0,true)
				end
			end
			if PlayerTeam[i+1]==3 then
				PlayerResource:ModifyGold(i,math.floor(10*(10/(RadiantPlayers+DirePlayers))^1.5*(DireGC-1)), false, 0)
				if PlayerAbandon[i+1] then
					DireGoldReim = DireGoldReim + PlayerResource:GetGold(i)
					PlayerResource:SetGold(i,0,false)
					PlayerResource:SetGold(i,0,true)
				end
			end	
		end
		if RadiantPlayersNow>0 then
			RadiantGoldReim = math.floor(RadiantGoldReim / RadiantPlayersNow)
			for i = 0, 31 do
				if ((PlayerTeam[i+1]==2)and not(PlayerAbandon[i+1])) then
					PlayerResource:ModifyGold(i, RadiantGoldReim, false, 0)
				end
			end
		end
		if DirePlayersNow>0 then
			DireGoldReim = math.floor(DireGoldReim / DirePlayersNow)
			for i = 0, 31 do
				if ((PlayerTeam[i+1]==3)and not(PlayerAbandon[i+1])) then
					PlayerResource:ModifyGold(i, DireGoldReim, false, 0)
				end
			end
		end
	end
	return 6
end

function CagsGameMode:OnStateChange( event )
	--print(GameRules:State_Get())
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		for i = 0, 31 do
			PlayerTeam[i+1] = PlayerResource:GetTeam(i)
			--print(PlayerTeam[i+1])
			if (PlayerTeam[i+1]== 2) then
				RadiantPlayers = RadiantPlayers + 1
				CagsGameMode:StorageGet(i)
			end
			if (PlayerTeam[i+1]== 3) then
				DirePlayers = DirePlayers + 1
				CagsGameMode:StorageGet(i)
			end	
		end
		RadiantPlayersNow = RadiantPlayers
		DirePlayersNow = DirePlayers
		GameRules:SetGoldTickTime(6)
		GameRules:SetGoldPerTick(math.floor(10*(10/(RadiantPlayers+DirePlayers))^1.5))
		if ((RadiantPlayers+DirePlayers)<10) then
			FewPlayer=true
			FewPlayerBroadcast=true
		else
			WinStreakBroadcast=true
			WinStreakRecord=true
		end
		--print(RadiantPlayers)
		--print(DirePlayers)
		--print(FewPlayer)
	end
	if (GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME)and(DruidExist) then
		GameRules:GetGameModeEntity():SetThink( "DruidSellableThink", self, "DST", 11)	
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
		if (WinStreakBroadcast) then
			for i = 0,31 do
				if (PlayerTeam[i+1]==2) or (PlayerTeam[i+1]==3) then
					CagsGameMode:WinStreakBC(i)
				end
			end
			WinStreakBroadcast = false
		end
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then
		if WinStreakRecord then
			for i = 0, 31 do
				if (PlayerTeam[i+1]==2) or (PlayerTeam[i+1]==3) then
					CagsGameMode:StoragePut(i)
					--DeepPrintTable(PlayerStorage[i+1])
					CagsGameMode:WinStreakBC(i)
				end
			end
		end
	end
end

function CagsGameMode:StorageGet(i)
	--Storage:Get(90016, function( resultTable, successBool )
	Storage:Get(PlayerResource:GetSteamAccountID(i), function( resultTable, successBool )
		--DeepPrintTable(resultTable)
		if successBool then
			PlayerStorage[i+1] = resultTable
		elseif resultTable["error_code"]==5 then
			PlayerStorage[i+1] = {}
		else
			return nil
		end
		--DeepPrintTable(PlayerStorage[i+1])
		if PlayerStorage[i+1]["WinStreak"] == nil then
			PlayerStorage[i+1]["WinStreak"] = 0
			--print("WinStreak init")
		end
		if PlayerStorage[i+1]["WinStreakHistory"] == nil then
			PlayerStorage[i+1]["WinStreakHistory"] = 0
			--print("WinStreakHistory init")
		end
		if PlayerStorage[i+1]["LastMatch10"] == nil then
			PlayerStorage[i+1]["LastMatch10"] = {0,0,0,0,0,0,0,0,0,0} -- 0:null 1:win 2:lose
			--print("LastMatch10 init")
		end
		if PlayerStorage[i+1]["LastMatch10Point"] == nil then
			PlayerStorage[i+1]["LastMatch10Point"] = 1
			--print("LastMatch10Point init")
		end
		--DeepPrintTable(PlayerStorage[i+1])
	end)
end
		
function CagsGameMode:StoragePut(i)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	Storage:Put( PlayerResource:GetSteamAccountID(i), PlayerStorage[i+1], function( resultTable, successBool )
    if successBool then
       --print("Successfully put data in storage")
    end
  end)
end

function CagsGameMode:StorageClear(i)
	Storage:Put( PlayerResource:GetSteamAccountID(i), {}, function( resultTable, successBool )
    if successBool then
       --print("Successfully put data in storage")
    end
	end)
end

function CagsGameMode:WinStreakBC(i)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	LastMatch10String = ""
	for j = PlayerStorage[i+1]["LastMatch10Point"], (PlayerStorage[i+1]["LastMatch10Point"]+9) do
		k = (j-1) % 10 +1
		if PlayerStorage[i+1]["LastMatch10"][k] == 1 then
			LastMatch10String = LastMatch10String.."W"
		elseif PlayerStorage[i+1]["LastMatch10"][k] == 2 then
			LastMatch10String = LastMatch10String.."L"
		end
	end
	if LastMatch10String == "" then
		LastMatch10String = "No Record"
	end
	--GameRules:SendCustomMessage("%s1 WinStreak: "..PlayerStorage[i+1]["WinStreak"].."; HighestHistoryWinStreak: "..PlayerStorage[i+1]["WinStreakHistory"], i, 0)
	Say(PlayerResource:GetPlayer(i),"Win streak: "..PlayerStorage[i+1]["WinStreak"].."; History streak: "..PlayerStorage[i+1]["WinStreakHistory"].."; Last 10 games: "..LastMatch10String, false)     
  --Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(i), duration=30.0})
  --Notifications:BottomToAll({text="#addon_winstreak", continue=true, style={["font-size"]="30px"}})
  --Notifications:BottomToAll({text=PlayerStorage[i+1]["WinStreak"], continue=true, style={["font-size"]="30px"}})
  --Notifications:BottomToAll({text="#addon_winstreakhistory", continue=true, style={["font-size"]="30px"}})
  --Notifications:BottomToAll({text=PlayerStorage[i+1]["WinStreakHistory"], continue=true, style={["font-size"]="30px"}})
end

function CagsGameMode:WinStreakChange(i,flag)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	if flag then
		PlayerStorage[i+1]["WinStreak"] = PlayerStorage[i+1]["WinStreak"] + 1
		if PlayerStorage[i+1]["WinStreak"] > PlayerStorage[i+1]["WinStreakHistory"] then
			PlayerStorage[i+1]["WinStreakHistory"] = PlayerStorage[i+1]["WinStreak"]
		end
		PlayerStorage[i+1]["LastMatch10"][PlayerStorage[i+1]["LastMatch10Point"]] = 1
		PlayerStorage[i+1]["LastMatch10Point"] = PlayerStorage[i+1]["LastMatch10Point"] % 10 + 1
	else
		PlayerStorage[i+1]["WinStreak"] = 0
		PlayerStorage[i+1]["LastMatch10"][PlayerStorage[i+1]["LastMatch10Point"]] = 2
		PlayerStorage[i+1]["LastMatch10Point"] = PlayerStorage[i+1]["LastMatch10Point"] % 10 + 1
	end
	--DeepPrintTable(PlayerStorage[i+1])
end

function CagsGameMode:OnHeroPicked( event )
	--DeepPrintTable(event)
	local heroString = event.hero
	--print(heroString)
	local playerHero = EntIndexToHScript(event.heroindex)
	local playerID = playerHero:GetPlayerID()
	PlayerIDtoHeroIndex[playerID+1] = event.heroindex
	--print(playerHero:GetPlayerID())
	--print(PlayerResource:GetTeam(playerID))
	--print(playerHero:GetUnitName())
	--print(PlayerResource:HasRandomed(playerID))
	--print(PlayerResource:HasRepicked(playerID))
	--print((playerHero:GetUnitName()):sub(15,string.len(heroString)))
	if (PlayerResource:HasRandomed(playerID) and not(PlayerResource:HasRepicked(playerID))) then
		PlayerResource:ModifyGold(playerID, 175, false, 0)
	end
	--[[
	if heroString =="npc_dota_hero_ursa" then
		spawnedAbility = playerHero:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
	end	
	]]
	if heroString =="npc_dota_hero_lone_druid" then
		DruidExist = true
		DruidHero = playerHero
		playerHero:AddItemByName("item_ultimate_scepter")
		Druid_Scepter=playerHero:GetItemInSlot(0)
		playerHero:SetCanSellItems(false)
	end
	if heroString =="npc_dota_hero_pudge" then
		PudgeExist = true
		PudgeHero = playerHero
		PudgeHookSum = 0
		PudgeHookSuccess = 0
		MeatHookDead = false
		PudgeMpSet = true
	end
	if heroString =="npc_dota_hero_mirana" then
		MiranaExist = true
		MiranaHero = playerHero
		MiranaArrowSum = 0
		MiranaArrowSuccess = 0
	end
end

function CagsGameMode:DruidSellableThink()
	--print("Druid can sell")
	DruidHero:SetCanSellItems(true)
	return nil
end

function CagsGameMode:OnNpcSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	local spawendUnitName = spawnedUnit:GetUnitName()
	--print(event.entindex,spawendUnitName, " spawned")
	--[[
	if spawendUnitName == "npc_dota_lone_druid_bear1" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear2" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear3" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear4" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	]]
	if (spawendUnitName == "npc_dota_hero_pudge") and (MeatHookDead == true) then
		--SendToServerConsole("stopsound")
		MeatHookDead = false
		PudgeHero:SetOrigin(PudgeLocation)
		PudgeHero:SetForwardVector(PudgeForward)
		PudgeHero:SetHealth(PudgeHp)
		return
	end
end

function CagsGameMode:PudgeSuicideThink()
	PudgeHero:SetMana(PudgeMp)
	return nil
end

function CagsGameMode:OnPlayerUseAbility( event )
--[[	//Abandon simulation
	PlayerTeam[2+CountN]=2
	AbandonTest[2+CountN]=true
	if CountN == 0 then RadiantPlayersNow=5 end
	CountN = CountN + 1
	]]
--[[	//Storage test
	TableUpload={CountN}
	--TableUpload={PlayerResource:GetSteamAccountID(0)}
	--print(TableUpload[1])
	Storage:Put( PlayerResource:GetSteamAccountID(0), TableUpload, function( resultTable, successBool )
    if successBool then
        print("Successfully put data in storage")
    end
	end)
	Storage:Get( PlayerResource:GetSteamAccountID(0), function( resultTable, successBool )
    if successBool then
        DeepPrintTable(resultTable)
    end
	end)
	CountN = CountN + 1
	]]
--[[	//Win Streak Storage test
	--CagsGameMode:StorageClear(0)
	--CagsGameMode:WinStreakBC(0)
	--CagsGameMode:WinStreakChange(0,true)
	--CagsGameMode:WinStreakChange(0,false)
	]]
	local abilityName = event.abilityname
	local player = PlayerResource:GetPlayer(event.PlayerID)
	local playerName = (player:GetAssignedHero()):GetUnitName()
	--player:GetAssignedHero():AddNewModifier(player,nil,"MODIFIER_PROPERTY_IS_ILLUSION",{30})
	--player:SetMusicStatus(DOTA_MUSIC_STATUS_BATTLE,10000)
	if (abilityName=="pudge_meat_hook") and (playerName=="npc_dota_hero_pudge") then
		PudgeHookSum = PudgeHookSum + 1
		--GameRules:SendCustomMessage("Pudge's No."..PudgeHookSum.." suicide hook is on the way!", 0, 1)
		--Say(PudgeHero,"Pudge's No."..PudgeHookSum.." suicide hook is coming!", false)
  	Notifications:BottomToAll({text="#addon_pudge_hook", duration=5.0, style={color="red", ["font-size"]="30px"}})				
		PudgeLocation = PudgeHero:GetOrigin()
		PudgeForward = PudgeHero:GetForwardVector()
		PudgeHp = PudgeHero:GetHealth()
		PudgeMp = PudgeHero:GetMana()
		--Hook = PudgeHero:FindAbilityByName("pudge_meat_hook")
		--HookLevel = Hook:GetLevel()
		MeatHookDead = true
		PudgeHero:ForceKill(false)
		GameRules:GetGameModeEntity():SetThink( "PudgeSuicideThink", self, "PST", 0.2)
	end
	if (abilityName=="mirana_arrow") and (playerName=="npc_dota_hero_mirana") then
		MiranaArrowSum = MiranaArrowSum + 1
		--Say(MiranaHero,"Mirana's No."..MiranaArrowSum.." Arrow is coming!", false)
  	Notifications:BottomToAll({text="#addon_mirana_arrow", duration=5.0, style={color="blue", ["font-size"]="30px"}})				
	end
	if (abilityName=="techies_suicide") and (playerName=="npc_dota_hero_techies") then
		TechiesSuicide = true
	end
end

function CagsGameMode:OnEntityHurt( event )
  --print(event.entindex_inflictor)
	local killed = EntIndexToHScript(event.entindex_killed)
	local attack = EntIndexToHScript(event.entindex_attacker)
	if event.entindex_inflictor ~= nil then
		local inflict = EntIndexToHScript(event.entindex_inflictor)
		--print(killed:GetName(),attack:GetName(),inflict:GetName())
  	if (attack:GetName()=="npc_dota_hero_pudge") and (inflict:GetName() == "pudge_meat_hook") and (killed:IsRealHero() == true) then
			PudgeHookSuccess = PudgeHookSuccess + 1
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%"., false)
  		Notifications:BottomToAll({text="#addon_pudge_hook_accuracy", duration=5.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%", duration=5.0, continue=true, style={["font-size"]="30px"}})				
  	end
  	if (attack:GetName()=="npc_dota_hero_mirana") and (inflict:GetName() == "mirana_arrow") and (killed:IsRealHero() == true) then
			MiranaArrowSuccess = MiranaArrowSuccess + 1
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%.", false)
  		Notifications:BottomToAll({text="#addon_mirana_arrow_accuracy", duration=5.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", duration=5.0, continue=true, style={["font-size"]="30px"}})				
  	end
  end
  --print(killed:GetUnitName())
  --print(killed:GetHealthPercent())
  if (((killed:GetUnitName()=="npc_dota_badguys_fort")or(killed:GetUnitName()=="npc_dota_goodguys_fort"))and(killed:GetHealthPercent()<100)and(FinalNotice==false)) then
  	FinalNotice = true
  	if PudgeExist then
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%".." (on scoreboard deduct "..PudgeHookSum.." from pudge's deaths)", false) 
  		Notifications:BottomToAll({text="#addon_pudge_hook_accuracy", duration=60.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."% ", duration=60.0, continue=true, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text="#addon_pudge_death_deduct_01", duration=60.0, continue=true, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=PudgeHookSum.." ", duration=60.0, continue=true, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text="#addon_pudge_death_deduct_02", duration=60.0, continue=true, style={["font-size"]="30px"}})
  	end
  	if MiranaExist then
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", false)
  		Notifications:BottomToAll({text="#addon_mirana_arrow_accuracy", duration=60.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", duration=60.0, continue=true, style={["font-size"]="30px"}})					
  	end
  	for i = 0, 31 do
			if (PlayerTeam[i+1]== 2)or(PlayerTeam[i+1]== 3) then
				CagsGameMode:StorageGet(i)
			end	
		end
  end
end

function CagsGameMode:OnEntityKilled( event )
	--DeepPrintTable(event)
	--print (event.entindex_attacker:GetName())
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedUnitName = killedUnit:GetUnitName()
	local killedUnitTeam = killedUnit:GetTeam()
	local attackUnit = EntIndexToHScript( event.entindex_attacker )
	local attackUnitName = attackUnit:GetUnitName()
	local attackUnitTeam = attackUnit:GetTeam()
	local inflictName = "wtf"
	--print(killedUnitTeam, killedUnitName, "killed",attackUnitTeam, attackUnitName, "attack")
	if event.entindex_inflictor~=void then
		inflictName = EntIndexToHScript( event.entindex_inflictor ):GetName()
		--print (inflictName)
	end
	if killedUnit:IsRealHero() then
		--print("Hero has been killed")
		if killedUnit:IsReincarnating() == false then
			--print("Setting time for respawn")
			if (killedUnitTeam==DOTA_TEAM_GOODGUYS) and (attackUnitTeam==DOTA_TEAM_BADGUYS) then
				DireScore = DireScore+1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS,DireScore)
			end
			if (killedUnitTeam==DOTA_TEAM_BADGUYS) and (attackUnitTeam==DOTA_TEAM_GOODGUYS) then
				RadiantScore = RadiantScore+1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,RadiantScore)
			end
			local respawnTime = killedUnit:GetLevel()*2
			if inflictName=="necrolyte_reapers_scythe" then
				respawnTime = respawnTime + 15
			end
			if (TechiesSuicide == true) and (killedUnitName == "npc_dota_hero_techies") then
					respawnTime = respawnTime / 2
					TechiesSuicide = false
			end
			if killedUnitTeam==DOTA_TEAM_GOODGUYS then
				respawnTime = respawnTime*(RadiantPlayersNow/5)^0.5			
			end
			if killedUnitTeam==DOTA_TEAM_BADGUYS then
				respawnTime = respawnTime*(DirePlayersNow/5)^0.5			
			end
			respawnTime = math.floor(respawnTime)
			if respawnTime ==0 then
				respawnTime = 1
			end
			if killedUnit:HasOwnerAbandoned()==false then
				killedUnit:SetTimeUntilRespawn(respawnTime)
			else
				killedUnit:SetTimeUntilRespawn(300)		
			end
		end
		if MeatHookDead == true then
			PudgeHero:SetTimeUntilRespawn(0)
		end
	end
	if ((killedUnitName=="npc_dota_badguys_fort") or (killedUnitName=="npc_dota_goodguys_fort")) then
		if PudgeExist == true then
			GameRules:SendCustomMessage("Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%".." (on scoreboard deduct "..PudgeHookSum.." from pudge's deaths)", 0, 1)
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%".." (on scoreboard deduct "..PudgeHookSum.." from pudge's deaths)", false)
		end
		if MiranaExist == true then
			GameRules:SendCustomMessage("Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", 0, 1)
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", false)
		end
	end
	if killedUnitName=="npc_dota_badguys_fort" then
		--print("radiant win")
		_G.GAME_WINNER_TEAM = "Radiant"
		if WinStreakRecord then
			for i = 0,31 do
				if PlayerTeam[i+1]==2 then
					CagsGameMode:WinStreakChange(i,true)
				elseif PlayerTeam[i+1]==3 then
					CagsGameMode:WinStreakChange(i,false)
				end
			end
			--WinStreakRecord = false
		end
	elseif killedUnitName=="npc_dota_goodguys_fort" then
		--print("dire win")
		_G.GAME_WINNER_TEAM = "Dire"																										
		if WinStreakRecord then
			for i = 0,31 do
				if PlayerTeam[i+1]==2 then
					CagsGameMode:WinStreakChange(i,false)
				elseif PlayerTeam[i+1]==3 then
					CagsGameMode:WinStreakChange(i,true)
				end
			end
			--WinStreakRecord = false
		end
	end
end

function CagsGameMode:GetWinTeam()
	return WinTeam
end

function CagsGameMode:OnScoreChanged(event)
end

function CagsGameMode:OnPlayerDisconnect( event )
end

function CagsGameMode:OnGameEnd( event )
end