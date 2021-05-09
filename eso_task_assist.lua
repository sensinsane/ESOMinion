-- GrindMode Behavior
eso_task_assist = inheritsFrom(ml_task)
eso_task_assist.name = "AssistMode"
eso_task_assist.lastcast = 0
function eso_task_assist.Create()
	local newinst = inheritsFrom(eso_task_assist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
            
	newinst.lastTargetID = 0		
			
    return newinst
end

function eso_task_assist:Init()
	local ke_pickLocks = ml_element:create( "PickLocks", c_lockpick, e_lockpick, 25 )
    self:add(ke_pickLocks, self.process_elements)
	
	local ke_usePotion = ml_element:create( "UsePotion", c_usepotion, e_usepotion, 15 )
    self:add(ke_usePotion, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function eso_task_assist:Process()
	--d("AssistMode_Process->")
	
	if eso_skillmanager.lastskillidcheck ~= e("GetAbilityIdByIndex("..eso_skillmanager.lastskillindexcheck..")") or not table.valid(eso_skillmanager.skillsbyindex) then
		eso_skillmanager.BuildSkillsList()
	end
	
	if (Player.health.current > 0) then
		-- the client does not clear the target offsets since the 1.6 patch
		-- this is a workaround so that players can attack manually while the bot is running
		local target = Player:GetSoftTarget()
		--[[if ( gAssistTargetMode ~= "None" ) then
			local newTarget = eso_task_assist.GetTarget()
			if ( newTarget ~= nil and (not target or newTarget.id ~= target.id)) then
				target = newTarget
				Player:SetTarget(target.id)  
			end
		--end]]
		
		--if ( gAssistInitCombat == "1" or ml_global_information.Player_InCombat ) then
			--if ( target and target.attackable and target.health > 0 and not target.iscritter) then
			if ( target and target.hostile and target.health.current > 0) then
			
				local skillData = eso_skillmanager.skillsbyname["Light Attack"]
				if e("ArePlayerWeaponsSheathed()") then
					AbilityList:Cast(skillData.id)
					d("unsheathe weapon 1st")
					ml_global_information.Await(500,1000, function () return not e("ArePlayerWeaponsSheathed()") end)
					return false
				end
				--if (gPreventAttackingInnocents == "0" or target.hostile) then
					--d(TimeSince(eso_task_assist.lastcast))
					--if Now() >= eso_task_assist.lastcast then
						--if AbilityList:CanCast(skillData.id,target.id) == 10 then
							--local minDelay = math.max(skillData.casttime,400)
							--d(minDelay)
							--eso_task_assist.lastcast = Now() + minDelay
							--d("cast")
							--AbilityList:Cast(skillData.id,target.id)
							
						--end
					--end
					eso_skillmanager.Cast( target )
				--end
			end		
		--end
	end
	
	--[[if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		--ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end]]
end


function eso_task_assist.SelectTargetExtended(maxrange, los, aggro)
	--local filterstring = "attackable,targetable,alive,nocritter,maxdistance="..tostring(maxrange)
	--local filterstring = "attackable,targetable,maxdistance="..tostring(maxrange) -- attempt 1 no issues
	--local filterstring = "attackable,targetable,nocritter,maxdistance="..tostring(maxrange) -- attempt 2 crashed after a few mins
	local filterstring = "attackable,targetable,alive,maxdistance="..tostring(maxrange) -- attempt 3 
	if (los) then filterstring = filterstring..",los" end
	if (aggro) then filterstring = filterstring..",aggro" end
	--if (gAssistTargetType == "Players Only") then filterstring = filterstring..",player" end
	--if (gAssistTargetMode == "LowestHealth") then 
	--	filterstring = filterstring..",lowesthealth"
	--elseif (gAssistTargetMode == "Closest") then 
	--	filterstring = filterstring..",nearest" 
	--end
	
	--if (gAssistTargetMode == "Biggest Crowd") then filterstring = filterstring..",clustered=6" end
	--if (gPreventAttackingInnocents == "1") then filterstring = filterstring..",hostile" end
	local TargetList = EntityList(filterstring)
	if ( TargetList ) then
		local id,entry = next(TargetList)
		if (id and entry ) then
			ml_log("Attacking "..tostring(entry.id) .. " name "..entry.name)
			return entry
		end
	end	
	return nil
end

function eso_task_assist.GetTarget()
	local target = nil
	
	target = eso_task_assist.SelectTargetExtended(ml_global_information.AttackRange, true,true) -- check for aggro targets 1st
	if ( not ValidTable(target) ) then 
		target = eso_task_assist.SelectTargetExtended(ml_global_information.AttackRange, true) -- normal targets next
	end	
	if ( not ValidTable(target) ) then 
		target = eso_task_assist.SelectTargetExtended(ml_global_information.AttackRange, false) -- close but no los
	end
	if ( not ValidTable(target) ) then 
		target = eso_task_assist.SelectTargetExtended(ml_global_information.AttackRange + 5, false) -- slightly out of range
	end
	
	return target
end

function eso_task_assist:UIInit()
	if (Settings.ESOMinion.gAssistTargetMode == nil) then
		Settings.ESOMinion.gAssistTargetMode = "None"
	end
	if (Settings.ESOMinion.gAssistTargetType == nil) then
		Settings.ESOMinion.gAssistTargetType = "Everything"
	end
	if (Settings.ESOMinion.gAssistInitCombat == nil) then
		Settings.ESOMinion.gAssistInitCombat = "0"
	end
	if (Settings.ESOMinion.gAssistDoInterrupt == nil) then
		Settings.ESOMinion.gAssistDoInterrupt = "1"
	end
	if (Settings.ESOMinion.gAssistDoExploit == nil) then
		Settings.ESOMinion.gAssistDoExploit = "1"
	end
	if (Settings.ESOMinion.gAssistDoAvoid == nil) then
		Settings.ESOMinion.gAssistDoAvoid = "1"
	end
	if (Settings.ESOMinion.gAssistDoBlock == nil) then
		Settings.ESOMinion.gAssistDoBlock = "1"
	end
	if (Settings.ESOMinion.gAssistDoBreak == nil) then
		Settings.ESOMinion.gAssistDoBreak = "1"
	end
	if (Settings.ESOMinion.gAssistDoLockpick == nil) then
		Settings.ESOMinion.gAssistDoLockpick = "1"
	end
	if (Settings.ESOMinion.gAssistUsePotions == nil) then
		Settings.ESOMinion.gAssistUsePotions = "1"
	end
	
	
	--[=[GUI_NewComboBox(ml_global_information.MainWindow.Name,GetString("sMtargetmode"),"gAssistTargetMode",GetString("assistMode"),"None,LowestHealth,Closest,Biggest Crowd");
	GUI_NewComboBox(ml_global_information.MainWindow.Name,GetString("sMmode"),"gAssistTargetType",GetString("assistMode"),"Everything,Players Only")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,GetString("startCombat"),"gAssistInitCombat",GetString("assistMode"))
	
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Use Potions","gAssistUsePotions",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform Interrupts","gAssistDoInterrupt",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform Exploits","gAssistDoExploit",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform Dodges","gAssistDoAvoid",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform Blocks","gAssistDoBlock",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform CC Breaks","gAssistDoBreak",GetString("assistMode"))
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,"Perform Lockpicks","gAssistDoLockpick",GetString("assistMode"))
	
	gAssistTargetMode = Settings.ESOMinion.gAssistTargetMode
	gAssistTargetType = Settings.ESOMinion.gAssistTargetType
	gAssistInitCombat = Settings.ESOMinion.gAssistInitCombat
	gAssistDoInterrupt = Settings.ESOMinion.gAssistDoInterrupt
	gAssistDoExploit = Settings.ESOMinion.gAssistDoExploit
	gAssistDoAvoid = Settings.ESOMinion.gAssistDoAvoid
	
	gAssistDoBlock = Settings.ESOMinion.gAssistDoBlock
	gAssistDoBreak = Settings.ESOMinion.gAssistDoBreak
	gAssistDoLockpick = Settings.ESOMinion.gAssistDoLockpick]=]
end

-- Adding it to our botmodes
if ( ml_global_information.BotModes ) then
	ml_global_information.BotModes[GetString("assistMode")] = eso_task_assist
end 

function eso_task_assist.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if (k == "gAssistTargetMode" or
			k == "gAssistTargetType" or
			k == "gAssistInitCombat" or 
			k == "gAssistDoInterrupt" or 
			k == "gAssistDoExploit" or 
			k == "gAssistDoAvoid" or 
			k == "gAssistDoBlock" or 
			k == "gAssistDoBreak" or
			k == "gAssistDoLockpick" or
			k == "gAssistUsePotions"
		)						
		then
			Settings.ESOMinion[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

RegisterEventHandler("GUI.Update",eso_task_assist.GUIVarUpdate,"ESO GUIVarUpdate")