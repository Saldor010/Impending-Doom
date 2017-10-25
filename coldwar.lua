-- Cold War Simulator by Saldor010

local args = {...}
if not fs.exists("cobalt") and not fs.exists(args[1]) then
	 term.setTextColor(colors.red)
    print("Cobalt could not be found on this machine. Cobalt is required to run this game.")
    term.setTextColor(colors.lime)
    print("To download cobalt, please press the Y key now.")
    term.setTextColor(colors.blue)
    print("If you already have cobalt, and we just can't find it, please supply the path as the second argument.")
    local ev,p1,p2,p3,p4,p5 = os.pullEvent("char")
    if string.lower(p1) == "y" then
        shell.run("pastebin","run","h5h4fm3t")
    else
        term.setTextColor(colors.red)
        print("Cancelled installation of Cobalt.")
    end
    error()
end
local cobalt = dofile(args[1] or "cobalt")
cobalt.ui = dofile("cobalt-ui/init.lua")

local StrategicCommandCenterPlaced = false
local StrategicCommandCenterPosition = {
	["X"] = 0,
	["Y"] = 0,
}
local DEFCON = 5
local nations = {
	["United States"] = {
		["Population"] = 0,
		["Resources"] = 10000, -- $10K
		["Image"] = "US.nfp",
		["Color"] = colors.blue,
		["Buildings"] = {},
		["Cities"] = {
			["Los Angeles"] = {
				["X"] = 8,
				["Y"] = 13,
				["Population"] = 500000, --500K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Seattle"] = {
				["X"] = 7,
				["Y"] = 4,
				["Population"] = 400000, --400K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Dallas"] = {
				["X"] = 29,
				["Y"] = 15,
				["Population"] = 300000, --300K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["New York"] = {
				["X"] = 45,
				["Y"] = 8,
				["Population"] = 1000000, --1M
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Wash D.C."] = {
				["X"] = 43,
				["Y"] = 9,
				["Population"] = 1000000, --1M
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Denver"] = {
				["X"] = 19,
				["Y"] = 10,
				["Population"] = 100000, --100K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Minneapolis"] = {
				["X"] = 30,
				["Y"] = 7,
				["Population"] = 100000, --100K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
		},
	},
	["China"] = {
		["Population"] = 0,
		["Resources"] = 10000, -- $10K
		["Image"] = "China.nfp",
		["Color"] = colors.orange,
		["Buildings"] = {},
		["Cities"] = {
			["Beijing"] = {
				["X"] = 42,
				["Y"] = 7,
				["Population"] = 1000000, --1M
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Shanghai"] = {
				["X"] = 47,
				["Y"] = 12,
				["Population"] = 500000, --500K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Hong Kong"] = {
				["X"] = 43,
				["Y"] = 18,
				["Population"] = 1000000, --1M
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Chengdu"] = {
				["X"] = 34,
				["Y"] = 13,
				["Population"] = 300000, --300K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Xi'an"] = {
				["X"] = 36,
				["Y"] = 11,
				["Population"] = 100000, --100K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Urumqi"] = {
				["X"] = 12,
				["Y"] = 5,
				["Population"] = 100000, --100K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Guangzhou"] = {
				["X"] = 42,
				["Y"] = 17,
				["Population"] = 400000, --400K
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
		},
	}
}

for k,v in pairs(nations) do
	local Napop = 0
	
	if fs.exists(v["Image"]) then
		v["Image"] = cobalt.surface.load(v["Image"])
	else
		error("Missing image : "..v["Image"])
	end
	
	for p,b in pairs(v["Cities"]) do
		b["DefaultIcon"] = b["Icon"]
		Napop = Napop + b["Population"]
	end
	v["Population"] = Napop -- The population that the nation was at when the game started E.G. Perfectly healthy nation
end

local worldMap = nil
if fs.exists("worldmap.nfp") then
	worldMap = cobalt.surface.load("worldmap.nfp")
else
	error("Missing image : ".."worldmap.nfp")
end

local nationSelectedForPlaying = "United States"
local nationSelectedForFighting = "China"
local nationSelectedForGUI = "United States"
local nationSelectedForTurn = "United States"

local AIPaused = false
local turn = 1
local TURNOVER = false
local turnString = "Turn "..tostring(turn)
local turnStringTICK = 20
local tick = 0
local tickRate = 0.2

local gridToggle = false

local CommandCenterGUI = false
local ContextSelected = nil
local ContextDisabled = false
local ContextOverride = false
local ContextPanel = cobalt.ui.new({w = 14,h = 6, x = -100, y=-100})
local ContextLabels = {
	[1] = ContextPanel:add("text",{text="",wrap="center",foreColour = colors.white, backColour = colors.black,x=1,y=1}),
	[2] = ContextPanel:add("text",{text="",wrap="center",foreColour = colors.white, backColour = colors.black,x=1,y=2}),
	[3] = ContextPanel:add("text",{text="",wrap="left",foreColour = colors.white, backColour = colors.black,x=1,y=3}),
	[4] = ContextPanel:add("text",{text="",wrap="left",foreColour = colors.white, backColour = colors.black,x=1,y=4}),
}
local ContextButtons = {
	[1] = ContextPanel:add("button",{wrap="left",y=5,w=12,h=1,text=""}),
	[2] = ContextPanel:add("button",{wrap="left",y=6,w=12,h=1,text=""}),
}
local AlertTimer = 0
local AlertPanel = cobalt.ui.new({w=51,h=3,x=1,y=math.floor(19/2),state=false})
local AlertText = AlertPanel:add("text",{w=51,h=1,y=2,text="",wrap="center"})

local Animations = {}

local function FireNuke(from,to,playerControlled)
	from.Nukes = from.Nukes - 1
	ContextOverride = nil
	ContextDisabled = true
	
	if playerControlled then nationSelectedForGUI = nationSelectedForPlaying else nationSelectedForGUI = nationSelectedForFighting end
	table.insert(Animations,{
		["Type"] = "NukeAway",
		["X"] = from.X,
		["Y"] = from.Y,
		["step"] = 0,
		["stepLimit"] = 10,
		["Function"] = function()
			if playerControlled then nationSelectedForGUI = nationSelectedForFighting else nationSelectedForGUI = nationSelectedForPlaying end
			if to.Cruise > 0 then
				table.insert(Animations,{
					["Type"] = "NukeFailure",
					["X"] = to.X,
					["Y"] = to.Y,
					["step"] = 0,
					["stepLimit"] = 10,
					["Function"] = function()
						to.Cruise = to.Cruise - 1
						
						if playerControlled then ContextDisabled = false for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do v["Icon"] = v["DefaultIcon"] end end
						if not playerControlled then AIPaused = false end
					end
				})
			else
				table.insert(Animations,{
					["Type"] = "NukeSuccess",
					["X"] = to.X,
					["Y"] = to.Y,
					["step"] = 0,
					["stepLimit"] = 20,
					["Function"] = function()
						to.Population = to.Population / 2
						to.Nukes = math.floor(to.Nukes / 2)
						
						if playerControlled then ContextDisabled = false for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do v["Icon"] = v["DefaultIcon"] end end
						if not playerControlled then AIPaused = false end
					end
				})
			end
		end
	})
end

local ContextMenu = {
	["You"] = { -- Clicking on your own cities
		[1] = {
			["Text"] = "Build Nuke",
			["Function"] = function(city)
				city.Icon = "N"
				city.Work = "BuildNuke"
			end,
		},
		[2] = {
			["Text"] = "Build Cruise",
			["Function"] = function(city)
				city.Icon = "C"
				city.Work = "BuildCruise"
			end,
		},
		
		["command"] = {
			[1] = {
				["Text"] = "Raise DEFCON",
				["Function"] = function(city)
					if city.Work == "RaiseDEFCON" then
						city.Icon = "A"
						city.Work = false
					else
						city.Icon = "!"
						city.Work = "RaiseDEFCON"
					end
				end,
			},
		}
	},
	["Enemy"] = { -- Clicking on enemy cities
		[1] = {
			["Text"] = "Fire Nuke",
			["Function"] = function(city)
				ContextPanel.x = -100
				ContextPanel.y = -100
				ContextDisabled = true
				
				for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do
					v["Icon"] = tostring(v["Nukes"])
				end
				
				nationSelectedForGUI = nationSelectedForPlaying
				AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
				AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
				AlertText.foreColour = colors.white
				AlertText.text = "Select a friendly city to fire from."
				AlertPanel.state = "_ALL"
				AlertText.state = "_ALL"
				AlertTimer = 10
				
				ContextOverride = function(city2)
					if city2.Nukes > 0 then
						FireNuke(city2,city,true)
					end
				end
			end,
		}
	},
}

--[[for k,v in pairs(ContextButtons) do
	v.onclick = function()
		if nationSelectedForGUI == nationSelectedForPlaying then
			if ContextMenu["You"][k] then
				ContextMenu["You"][k]["Function"](ContextSelected)
			end
		else
			if ContextMenu["Enemy"][k] then
				ContextMenu["Enemy"][k]["Function"](ContextSelected)
			end
		end
	end
end]]--

local MainPanel = cobalt.ui.new({w=4,h=1})

local SwapViewButton = MainPanel:add("button",{w=4,h=1,text="View",foreColour = colors.white,backColour = colors.grey})
SwapViewButton.onclick = function()
	ContextSelected = nil
	ContextPanel.x = -100
	ContextPanel.y = -100
	if nationSelectedForPlaying == nationSelectedForGUI then
		nationSelectedForGUI = nationSelectedForFighting
	else
		nationSelectedForGUI = nationSelectedForPlaying
	end
end

local MX,MY = 0,0

local function renderPop(pop)
	if not pop then pop = 0 end
	if pop >= 1000 then -- K
		if pop >= 1000000 then -- M
			pop = math.floor(pop / 100000)/10
			pop = tostring(pop).."M"
			return pop
		else
			pop = math.floor(pop / 1000)
			pop = tostring(pop).."K"
			return pop
		end
	else
		return pop
	end
end

local function checkLegalBuildingSite(x,y)
	if nations[nationSelectedForGUI] and nations[nationSelectedForGUI]["Color"] then
		if (cobalt.application.view.buffer[((y - 1) * 51 + x) * 3 - 1] == nations[nationSelectedForGUI]["Color"]) or (cobalt.application.view.buffer[((y - 1) * 51 + x) * 3 - 1] == colors.black) then
			return false
		else
			return true
		end
	end
end

local AISteps = {}
--[[local function NextTurn()
	-- Enemy AI's turn
	AINotDone = true
	ContextDisabled = true
	nationSelectedForTurn = nationSelectedForFighting
	nationSelectedForGUI = nationSelectedForFighting
	for k,v in pairs(nations[nationSelectedForFighting]["Cities"]) do
		if v.Work == "BuildCruise" then
			v.Cruise = v.Cruise + 1
		elseif v.Work == "BuildNuke" then
			v.Nukes = v.Nukes + 1
		end
		
		if v.Cruise <= 0 then
			v.Work = "BuildCruise"
		elseif v.Cruise <= 1 and v.Population > 500000 then
			v.Work = "BuildCruise"
		else
			v.Work = "BuildNuke"
		end
		
		if v.Nukes > 0 then
			local highest = nil
			for p,b in pairs(nations[nationSelectedForPlaying]["Cities"]) do
				if highest == nil then highest = b else
					if b.Population > highest.Population then highest = b end
				end
			end
			FireNuke(v,b,false)
		end
		
		v.Icon = v.DefaultIcon
	end
	
	-- Enemy turn over
	turn = turn + 1
	nationSelectedForTurn = nationSelectedForPlaying
	nationSelectedForGUI = nationSelectedForPlaying
	ContextDisabled = false
	
	for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do
		if v.Work == "BuildCruise" then
			v.Cruise = v.Cruise + 1
		elseif v.Work == "BuildNuke" then
			v.Nukes = v.Nukes + 1
		end
		v.Icon = v.DefaultIcon
		v.Work = nil
	end
end]]--

local NextTurnPanel = cobalt.ui.new({w = 14,h = 2, x = 1, y=18,backColour = colors.black})
local NextTurnButton = NextTurnPanel:add("button",{w=9,h=1,y=2,text="Next Turn"})
NextTurnButton.onclick = function()
	if StrategicCommandCenterPlaced then
		TURNOVER = true
	else
		AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
		AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
		AlertText.foreColour = colors.white
		AlertText.text = "Build your strategic command center"
		AlertPanel.state = "_ALL"
		AlertText.state = "_ALL"
		AlertTimer = 10
	end
end

local CommandCenterPanel = cobalt.ui.new({w=51,h=19,backColour = colors.black,state=false})
local CommandCenterMapBackDrop = CommandCenterPanel:add("panel",{x=2,y=math.floor(19/2)-3,w=27,h=12,backColour=colors.black})

local CommandCenterDEFCON5 = CommandCenterPanel:add("panel",{w=3,h=2,x=3,y=3,foreColour = colors.white,backColour = colors.blue})
local CommandCenterDEFCON5Text = CommandCenterDEFCON5:add("text",{w=1,h=1,x=1,y=1,text="5",foreColour=colors.white})

local CommandCenterDEFCON4 = CommandCenterPanel:add("panel",{w=3,h=2,x=7,y=3,foreColour = colors.white,backColour = colors.green})
local CommandCenterDEFCON4Text = CommandCenterDEFCON4:add("text",{w=1,h=1,x=1,y=1,text="4",foreColour=colors.white})

local CommandCenterDEFCON3 = CommandCenterPanel:add("panel",{w=3,h=2,x=11,y=3,foreColour = colors.white,backColour = colors.orange})
local CommandCenterDEFCON3Text = CommandCenterDEFCON3:add("text",{w=1,h=1,x=1,y=1,text="3",foreColour=colors.white})

local CommandCenterDEFCON2 = CommandCenterPanel:add("panel",{w=3,h=2,x=15,y=3,foreColour = colors.white,backColour = colors.red})
local CommandCenterDEFCON2Text = CommandCenterDEFCON2:add("text",{w=1,h=1,x=1,y=1,text="2",foreColour=colors.white})

local CommandCenterDEFCON1 = CommandCenterPanel:add("panel",{w=3,h=2,x=19,y=3,foreColour = colors.white,backColour = colors.white})
local CommandCenterDEFCON1Text = CommandCenterDEFCON1:add("text",{w=1,h=1,x=1,y=1,text="1",foreColour=colors.black})

local CommandCenterDEFCONLabelPanel = CommandCenterPanel:add("panel",{w=19,h=1,x=3,y=2,foreColour=colors.white,backColour=colors.black})
local CommandCenterDEFCONLabel = CommandCenterDEFCONLabelPanel:add("text",{w=19,h=1,x=1,y=1,text="D E F C O N",foreColour=colors.white,backColour=colors.black,wrap="center"})

local CommandCenterBack = CommandCenterPanel:add("button",{w=10,h=1,y=19,text="Back to Map",foreColour = colors.white,backColour = colors.grey})
CommandCenterBack.onclick = function()
	CommandCenterGUI = false
	ContextDisabled = false
	
	NextTurnPanel.state = "_ALL"
	MainPanel.state = "_ALL"
	
	CommandCenterPanel.state = false
	CommandCenterBack.state = false
	CommandCenterMapBackDrop.state = false
end

local CommandCenterButton = NextTurnPanel:add("button",{w=14,h=1,text="Command Center",foreColour = colors.white,backColour = colors.grey})
CommandCenterButton.onclick = function()
	if StrategicCommandCenterPlaced then
		CommandCenterGUI = true
		ContextDisabled = true
		
		NextTurnPanel.state = false
		MainPanel.state = false
		
		CommandCenterPanel.state = "_ALL"
		CommandCenterBack.state = "_ALL"
		CommandCenterMapBackDrop.backColour = nations[nationSelectedForPlaying]["Color"]
		CommandCenterMapBackDrop.state = "_ALL"
		
		CommandCenterDEFCON5.backColour = colors.gray
		CommandCenterDEFCON4.backColour = colors.gray
		CommandCenterDEFCON3.backColour = colors.gray
		CommandCenterDEFCON2.backColour = colors.gray
		CommandCenterDEFCON1.backColour = colors.gray
		
		CommandCenterDEFCON5Text.backColour = colors.gray
		CommandCenterDEFCON4Text.backColour = colors.gray
		CommandCenterDEFCON3Text.backColour = colors.gray
		CommandCenterDEFCON2Text.backColour = colors.gray
		CommandCenterDEFCON1Text.backColour = colors.gray
		
		if DEFCON == 5 then
			CommandCenterDEFCON5.backColour = colors.blue
			CommandCenterDEFCON5Text.backColour = colors.blue
		elseif DEFCON == 4 then
			CommandCenterDEFCON4.backColour = colors.green
			CommandCenterDEFCON4Text.backColour = colors.green
		elseif DEFCON == 3 then
			CommandCenterDEFCON3.backColour = colors.orange
			CommandCenterDEFCON3Text.backColour = colors.orange
		elseif DEFCON == 2 then
			CommandCenterDEFCON2.backColour = colors.red
			CommandCenterDEFCON2Text.backColour = colors.red
		elseif DEFCON == 1 then
			CommandCenterDEFCON1.backColour = colors.white
			CommandCenterDEFCON1Text.backColour = colors.white
		end
	else
		AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
		AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
		AlertText.foreColour = colors.white
		AlertText.text = "Build your strategic command center"
		AlertPanel.state = "_ALL"
		AlertText.state = "_ALL"
		AlertTimer = 10
	end
end

local AISteps = {}
function cobalt.update( dt )
	tick = tick + dt
	if tick >= tickRate then
		tick = 0
		-- Do a game update
		
		turnStringTICK = turnStringTICK - 1
		if turnStringTICK <= 0 then
			turnStringTICK = 20
			if string.sub(turnString,1,1) == "T" then
				if nationSelectedForTurn == nationSelectedForPlaying then
					turnString = "Your turn"
				else
					turnString = "Enemy's turn"
				end
			else
				turnString = "Turn "..tostring(turn)
			end
		end
		
		AlertTimer = AlertTimer - 1
		if AlertTimer <= 0 then
			AlertPanel.state = false
			AlertText.state = false
		end
		
		local deleteAnim = {}
		for k,v in pairs(Animations) do
			v.step = v.step + 1
			if v.step >= v.stepLimit then
				v.Function()
				table.insert(deleteAnim,k)
			end
		end
		for k,v in pairs(deleteAnim) do
			Animations[v] = nil
		end
		
		if TURNOVER == true then -- Next turn
			TURNOVER = false
			nationSelectedForTurn = nationSelectedForFighting
		end
		
		if nationSelectedForTurn == nationSelectedForFighting and AIPaused == false then -- AI step
			nationSelectedForGUI = nationSelectedForFighting
			if #AISteps == 0 then
				for k,v in pairs(nations[nationSelectedForFighting]["Cities"]) do
					if v.Work == "BuildCruise" then
						v.Cruise = v.Cruise + 1
					elseif v.Work == "BuildNuke" then
						v.Nukes = v.Nukes + 1
					end
					
					if v.Cruise <= 0 then
						table.insert(AISteps,{
							["BuildCruise"] = v
						})
						--v.Work = "BuildCruise"
					elseif v.Cruise <= 1 and v.Population > 500000 then
						table.insert(AISteps,{
							["BuildCruise"] = v
						})
						--v.Work = "BuildCruise"
					else
						table.insert(AISteps,{
							["BuildNuke"] = v
						})
						--v.Work = "BuildNuke"
					end
					
					--[[if v.Nukes > 0 then
						local highest = nil
						for p,b in pairs(nations[nationSelectedForPlaying]["Cities"]) do
							if highest == nil then highest = b else
								if b.Population > highest.Population then highest = b end
							end
						end
						table.insert(AISteps,{
							["FireNuke"] = {
								["from"] = v,
								["to"] = highest
							}
						})
						--FireNuke(v,b,false)
					end]]--
				end
			else
				local WorkToDo = AISteps[1]
				if WorkToDo["BuildCruise"] then
					WorkToDo["BuildCruise"].Work = "BuildCruise"
					WorkToDo["BuildCruise"].Icon = "C"
				elseif WorkToDo["BuildNuke"] then
					WorkToDo["BuildNuke"].Work = "BuildNuke"
					WorkToDo["BuildNuke"].Icon = "N"
				elseif WorkToDo["FireNuke"] then
					AIPaused = true
					FireNuke(WorkToDo["FireNuke"]["from"],WorkToDo["FireNuke"]["to"],false)
				end
				table.remove(AISteps,1)
				if #AISteps == 0 then
					nationSelectedForGUI = nationSelectedForPlaying
					nationSelectedForTurn = nationSelectedForPlaying
					
					for k,v in pairs(nations[nationSelectedForPlaying]["Buildings"]) do
						if v.Work == "BuildCruise" then
							v.Cruise = v.Cruise + 1
						elseif v.Work == "BuildNuke" then
							v.Nukes = v.Nukes + 1
						elseif v.Work == "RaiseDEFCON" then
							if DEFCON > 1 then
								DEFCON = DEFCON - 1
							end
						end
					end
				end
			end
		end
	end
end

function cobalt.draw()
	if CommandCenterGUI then
		cobalt.ui.draw()
		
		cobalt.application.view:drawSurface(3,math.floor(19/2)-2,worldMap)
	else
		if nationSelectedForGUI and nations[nationSelectedForGUI] then
			local N = nations[nationSelectedForGUI]
			cobalt.application.view:drawSurface(1,1,N["Image"])
			
			if gridToggle then
				for i=1,51 do
					for j=1,19 do
						if checkLegalBuildingSite(i,j) then
							cobalt.graphics.print("+",i,j,nil,N["Color"])
						end
					end
				end
			end
			
			local Npop = 0
			for k,v in pairs(N["Cities"]) do
				cobalt.graphics.print(v["Icon"],v["X"],v["Y"],N["Color"],colors.white)
				Npop = Npop + v["Population"]
			end
			
			for k,v in pairs(N["Buildings"]) do
				if v["type"] == "command" then
					cobalt.graphics.print(v["Icon"],v["X"],v["Y"],N["Color"],colors.white)
				end
			end
			
			cobalt.graphics.center(nationSelectedForGUI.." - "..renderPop(Npop).." - "..renderPop(N["Resources"]).."$",1,0,51,colors.black,colors.white)
		end
		
		for k,v in pairs(Animations) do
			if v.Type == "NukeAway" then
				cobalt.graphics.print("^",v.X,v.Y-v.step)
				--[[for i=1,v.step do
					cobalt.graphics.print("@",v.X,v.Y-i+1,colors.black,colors.gray)
				end]]--
			elseif v.Type == "NukeSuccess" then
				if v.step <= 10 then
					cobalt.graphics.print("V",v.X,v.Y-10+v.step)
				end
				if v.step > 10 then cobalt.graphics.print("@",v.X,v.Y,colors.red,colors.orange) end
				if v.step > 12 then cobalt.graphics.print("@",v.X-1,v.Y,colors.red,colors.orange) cobalt.graphics.print("@",v.X+1,v.Y,colors.red,colors.orange) cobalt.graphics.print("@",v.X,v.Y-1,colors.red,colors.orange) end
				if v.step > 14 then cobalt.graphics.print("@",v.X,v.Y-2,colors.red,colors.orange) end
				if v.step > 16 then cobalt.graphics.print("@",v.X-1,v.Y-3,colors.red,colors.orange) cobalt.graphics.print("@",v.X,v.Y-3,colors.red,colors.orange) cobalt.graphics.print("@",v.X+1,v.Y-3,colors.red,colors.orange) end
				if v.step > 18 then cobalt.graphics.print("@",v.X-1,v.Y-4,colors.red,colors.orange) cobalt.graphics.print("@",v.X,v.Y-4,colors.red,colors.orange) cobalt.graphics.print("@",v.X+1,v.Y-4,colors.red,colors.orange) end
			elseif v.Type == "NukeFailure" then
				if v.step <= 6 then
					cobalt.graphics.print("V",v.X,v.Y-10+v.step)
				end
				if v.step > 2 and v.step <= 6 then
					cobalt.graphics.print("^",v.X,v.Y-v.step+2)
				end
				if v.step > 6 then
					cobalt.graphics.print("*",v.X,v.Y-4,colors.black,colors.orange)
				end
			end
		end
		
		cobalt.ui.draw()
		
		cobalt.graphics.print(turnString,52-turnString:len(),1)
		--cobalt.graphics.print(MX..";"..MY,1,19)
	end
end

function cobalt.mousepressed( x, y, button )
	MX,MY = x,y
	
	cobalt.ui.mousepressed(x,y,button)
	
	if StrategicCommandCenterPlaced then
		if nationSelectedForGUI and nations[nationSelectedForGUI] then
			local N = nations[nationSelectedForGUI]
			local clickOut = true
			if x >= ContextPanel.x and x <= ContextPanel.x+ContextPanel.w-1 and y >= ContextPanel.y and y <= ContextPanel.y+ContextPanel.h-1 then
				clickOut = false
			else
				local cityFound = false
				for k,v in pairs(N["Cities"]) do
					if v["X"] == x and v["Y"] == y then
						if not ContextDisabled then
							cityFound = true
							ContextSelected = v
							ContextPanel.backColour = nations[nationSelectedForGUI]["Color"]
							ContextLabels[1].text = k
							ContextLabels[2].text = "Pop: "..renderPop(v["Population"])
							ContextLabels[3].text = "Income: "..renderPop( (v["Population"] /(DEFCON/5) ) /5 )
							ContextLabels[4].text = ""
							
							ContextPanel.backColour = nations[nationSelectedForGUI]["Color"]
							ContextLabels[1].backColour = nations[nationSelectedForGUI]["Color"]
							ContextLabels[2].backColour = nations[nationSelectedForGUI]["Color"]
							ContextLabels[3].backColour = nations[nationSelectedForGUI]["Color"]
							ContextLabels[4].backColour = nations[nationSelectedForGUI]["Color"]
							
							--ContextLabels[3].text = "Nukes: "..v["Nukes"]
							--ContextLabels[4].text = "Cruise: "..v["Cruise"]
							if nationSelectedForGUI ~= nationSelectedForPlaying then
								for i=1,2 do
									ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
									if ContextMenu["Enemy"][i] then
										ContextButtons[i]["text"] = ContextMenu["Enemy"][i]["Text"]
									else
										ContextButtons[i]["text"] = ""
									end
									ContextButtons[i].onclick = function() ContextMenu["Enemy"][i]["Function"](v) end
								end
							else
								for i=1,2 do
									ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
									if ContextMenu["You"][i] then
										ContextButtons[i]["text"] = ContextMenu["You"][i]["Text"]
									else
										ContextButtons[i]["text"] = ""
									end
									ContextButtons[i].onclick = function() ContextMenu["You"][i]["Function"](v) end
								end
							end
						
							local xF = x+1
							local yF = y
							
							if x+ContextPanel.w >= 51 then xF = x-ContextPanel.w end
							if y+ContextPanel.h >= 19 then yF = y-ContextPanel.h end
							
							ContextPanel.x = xF
							ContextPanel.y = yF
							clickOut = false
						elseif ContextOverride then
							ContextOverride(v)
						end
					end
				end
				if not cityFound then -- We didn't click on a city.. Maybe we clicked on a military building?
					for k,v in pairs(N["Buildings"]) do
						if v["X"] == x and v["Y"] == y then
							if not ContextDisabled then
								cityFound = true
								ContextSelected = v
								ContextPanel.backColour = nations[nationSelectedForGUI]["Color"]
								if v["type"] == "command" then
									ContextLabels[1].text = "Command"
									ContextLabels[2].text = "Center"
									ContextLabels[3].text = "Health: "..tostring(v["health"])
									ContextLabels[4].text = ""
								end
								
								ContextPanel.backColour = nations[nationSelectedForGUI]["Color"]
								ContextLabels[1].backColour = nations[nationSelectedForGUI]["Color"]
								ContextLabels[2].backColour = nations[nationSelectedForGUI]["Color"]
								ContextLabels[3].backColour = nations[nationSelectedForGUI]["Color"]
								ContextLabels[4].backColour = nations[nationSelectedForGUI]["Color"]
								
								--ContextLabels[3].text = "Nukes: "..v["Nukes"]
								--ContextLabels[4].text = "Cruise: "..v["Cruise"]
								if nationSelectedForGUI ~= nationSelectedForPlaying then
									for i=1,2 do
										ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
										if ContextMenu["Enemy"][ v["type"] ] and ContextMenu["Enemy"][ v["type"] ][i] then
											ContextButtons[i]["text"] = ContextMenu["Enemy"][ v["type"] ][i]["Text"]
										else
											ContextButtons[i]["text"] = ""
										end
										ContextButtons[i].onclick = function() ContextMenu["Enemy"][ v["type"] ][i]["Function"](v) end
									end
								else
									for i=1,2 do
										ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
										if ContextMenu["You"][ v["type"] ] and ContextMenu["You"][ v["type"] ][i] then
											ContextButtons[i]["text"] = ContextMenu["You"][ v["type"] ][i]["Text"]
										else
											ContextButtons[i]["text"] = ""
										end
										ContextButtons[i].onclick = function() ContextMenu["You"][ v["type"] ][i]["Function"](v) end
									end
								end
							
								local xF = x+1
								local yF = y
								
								if x+ContextPanel.w >= 51 then xF = x-ContextPanel.w end
								if y+ContextPanel.h >= 19 then yF = y-ContextPanel.h end
								
								ContextPanel.x = xF
								ContextPanel.y = yF
								clickOut = false
							elseif ContextOverride then
								ContextOverride(v)
							end
						end
					end
				end
			end
			if clickOut then
				ContextSelected = nil
				ContextPanel.x = -100
				ContextPanel.y = -100
			end
		end
	else -- We need to place the strategic command center first
		if nationSelectedForPlaying == nationSelectedForGUI then
			local cityFound = false
			for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do
				if v["X"] == x and v["Y"] == y then cityFound = true end
			end
			
			if cityFound then
				AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
				AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
				AlertText.foreColour = colors.white
				AlertText.text = "You can't build in a city. Choose another site."
				AlertPanel.state = "_ALL"
				AlertText.state = "_ALL"
				AlertTimer = 10
			elseif (StrategicCommandCenterPosition["X"] ~= x) or (StrategicCommandCenterPosition["Y"] ~= y) then
				if checkLegalBuildingSite(x,y) then
					StrategicCommandCenterPosition = {
						["X"] = x,
						["Y"] = y,
					}
					--[[table.insert(nations[nationSelectedForPlaying]["Buildings"],{
						["X"] = x,
						["Y"] = y,
						["type"] = "command",
						["health"] = 3,
					})]]--
					AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
					AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
					AlertText.foreColour = colors.white
					AlertText.text = "Please click the location again to confirm."
					AlertPanel.state = "_ALL"
					AlertText.state = "_ALL"
					AlertTimer = 10
				end
			elseif (StrategicCommandCenterPosition["X"] == x) or (StrategicCommandCenterPosition["Y"] == y) then
				table.insert(nations[nationSelectedForPlaying]["Buildings"],{
					["X"] = x,
					["Y"] = y,
					["type"] = "command",
					["cruise"] = 0,
					["nukes"] = 0,
					["health"] = 3,
					["Icon"] = "A",
					["Work"] = false,
				})
				StrategicCommandCenterPlaced = true
			end
		end
	end
end

function cobalt.mousereleased( x, y, button )
	cobalt.ui.mousereleased(x,y,button)
end

function cobalt.keypressed( keycode, key )
	if string.lower(key) == "q" then
		if StrategicCommandCenterPlaced then
			if CommandCenterGUI == false then
				CommandCenterGUI = true
				ContextDisabled = true
				
				NextTurnPanel.state = false
				MainPanel.state = false
				
				CommandCenterPanel.state = "_ALL"
				CommandCenterBack.state = "_ALL"
				CommandCenterMapBackDrop.backColour = nations[nationSelectedForPlaying]["Color"]
				CommandCenterMapBackDrop.state = "_ALL"
				
				CommandCenterDEFCON5.backColour = colors.gray
				CommandCenterDEFCON4.backColour = colors.gray
				CommandCenterDEFCON3.backColour = colors.gray
				CommandCenterDEFCON2.backColour = colors.gray
				CommandCenterDEFCON1.backColour = colors.gray
				
				CommandCenterDEFCON5Text.backColour = colors.gray
				CommandCenterDEFCON4Text.backColour = colors.gray
				CommandCenterDEFCON3Text.backColour = colors.gray
				CommandCenterDEFCON2Text.backColour = colors.gray
				CommandCenterDEFCON1Text.backColour = colors.gray
				
				if DEFCON == 5 then
					CommandCenterDEFCON5.backColour = colors.blue
					CommandCenterDEFCON5Text.backColour = colors.blue
				elseif DEFCON == 4 then
					CommandCenterDEFCON4.backColour = colors.green
					CommandCenterDEFCON4Text.backColour = colors.green
				elseif DEFCON == 3 then
					CommandCenterDEFCON3.backColour = colors.orange
					CommandCenterDEFCON3Text.backColour = colors.orange
				elseif DEFCON == 2 then
					CommandCenterDEFCON2.backColour = colors.red
					CommandCenterDEFCON2Text.backColour = colors.red
				elseif DEFCON == 1 then
					CommandCenterDEFCON1.backColour = colors.white
					CommandCenterDEFCON1Text.backColour = colors.white
				end
			else
				CommandCenterGUI = false
				ContextDisabled = false
				
				NextTurnPanel.state = "_ALL"
				MainPanel.state = "_ALL"
				
				CommandCenterPanel.state = false
				CommandCenterBack.state = false
				CommandCenterMapBackDrop.state = false
			end
		else
			AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.foreColour = colors.white
			AlertText.text = "Build your strategic command center"
			AlertPanel.state = "_ALL"
			AlertText.state = "_ALL"
			AlertTimer = 10
		end
	end
	
	if keycode == 15 then -- tab
		ContextSelected = nil
		ContextPanel.x = -100
		ContextPanel.y = -100
		if nationSelectedForPlaying == nationSelectedForGUI then
			nationSelectedForGUI = nationSelectedForFighting
		else
			nationSelectedForGUI = nationSelectedForPlaying
		end
	end
	
	if keycode == 57 then -- spacebar
		if StrategicCommandCenterPlaced then
			TURNOVER = true
		else
			AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.foreColour = colors.white
			AlertText.text = "Build your strategic command center"
			AlertPanel.state = "_ALL"
			AlertText.state = "_ALL"
			AlertTimer = 10
		end
	end
	
	if string.lower(key) == "v" then
		gridToggle = not gridToggle
	end
end

function cobalt.keyreleased( keycode, key )

end

function cobalt.textinput( t )

end

AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
AlertText.foreColour = colors.white
AlertText.text = "Build your strategic command center"
AlertPanel.state = "_ALL"
AlertText.state = "_ALL"
AlertTimer = 10

cobalt.initLoop()