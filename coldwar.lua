-- Cold War Simulator by Saldor010
local SoftwareVERSION = "Alpha 3.0"

local args = {...}
if not fs.exists("cobalt") and (not args[1] or not fs.exists(args[1])) then
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

-- PATCHING THE COBALT SURFACE FILE AUTOMAGICALLY
local surfaceFileToBeReadHANDLE = fs.open("cobalt-lib/surface","r")
local surfaceFileToBeRead = surfaceFileToBeReadHANDLE.readAll()
local newFile = nil
if not string.find(surfaceFileToBeRead,"local create = surface.create") then
	local ch = string.find(surfaceFileToBeRead,"function surface.load")
	local firstSub = string.sub(surfaceFileToBeRead,1,ch-1)
	local secondSub = string.sub(surfaceFileToBeRead,ch)
	newFile = firstSub.."local create = surface.create\n\n"..secondSub
end
surfaceFileToBeReadHANDLE.close()
if newFile then
	local surfaceFileToBeRewritten = fs.open("cobalt-lib/surface","w")
	surfaceFileToBeRewritten.write(newFile)
	surfaceFileToBeRewritten.close()
end
-- Done patching

local cobalt = dofile(args[1] or "cobalt")
cobalt.ui = dofile("cobalt-ui/init.lua")

local gameRunning = false
local game = nil -- I'll use this variable later for.. something?
local options = {
	["BeginnerAlerts"] = true
}

local StrategicCommandCenterPlaced = false
local StrategicCommandCenterPosition = {
	["X"] = 0,
	["Y"] = 0,
}
local marker = {["x"] = -10,["y"] = -10,["timer"] = 0}
local DEFCON = 5

local nations = {
	["United States"] = {
		["Population"] = 0,
		["Resources"] = 3000000, -- $3M
		["Image"] = "US.nfp",
		["Color"] = colors.blue,
		["Buildings"] = {},
		["Cities"] = {
			["Los Angeles"] = {
				["X"] = 8,
				["Y"] = 13,
				["Population"] = 500000, --500K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Seattle"] = {
				["X"] = 7,
				["Y"] = 4,
				["Population"] = 400000, --400K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Dallas"] = {
				["X"] = 29,
				["Y"] = 15,
				["Population"] = 300000, --300K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["New York"] = {
				["X"] = 45,
				["Y"] = 8,
				["Population"] = 1000000, --1M
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Wash D.C."] = {
				["X"] = 43,
				["Y"] = 9,
				["Population"] = 1000000, --1M
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Denver"] = {
				["X"] = 19,
				["Y"] = 10,
				["Population"] = 100000, --100K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Minneapolis"] = {
				["X"] = 30,
				["Y"] = 7,
				["Population"] = 100000, --100K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
		},
	},
	["China"] = {
		["Population"] = 0,
		["Resources"] = 3000000, -- $3M
		["Image"] = "China.nfp",
		["Color"] = colors.orange,
		["Buildings"] = {},
		["Cities"] = {
			["Beijing"] = {
				["X"] = 42,
				["Y"] = 7,
				["Population"] = 1000000, --1M
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Shanghai"] = {
				["X"] = 47,
				["Y"] = 12,
				["Population"] = 500000, --500K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Hong Kong"] = {
				["X"] = 43,
				["Y"] = 18,
				["Population"] = 1000000, --1M
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 1,
				["Icon"] = "$",
			},
			["Chengdu"] = {
				["X"] = 34,
				["Y"] = 13,
				["Population"] = 300000, --300K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Xi'an"] = {
				["X"] = 36,
				["Y"] = 11,
				["Population"] = 100000, --100K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Urumqi"] = {
				["X"] = 12,
				["Y"] = 5,
				["Population"] = 100000, --100K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
			["Guangzhou"] = {
				["X"] = 42,
				["Y"] = 17,
				["Population"] = 400000, --400K
				["Dead"] = 0,
				["Nukes"] = 0,
				["Cruise"] = 0,
				["Icon"] = "@",
			},
		},
	}
}

table.insert(nations["United States"]["Buildings"],{
	["X"] = 29,
	["Y"] = 13,
	["type"] = "command",
	["cruise"] = 0,
	["nukes"] = 0,
	["health"] = 3,
	["Icon"] = "A",
	["Work"] = false,
})

table.insert(nations["China"]["Buildings"],{
	["X"] = 36,
	["Y"] = 13,
	["type"] = "command",
	["cruise"] = 0,
	["nukes"] = 0,
	["health"] = 3,
	["Icon"] = "A",
	["Work"] = false,
})

-- Stole from here http://www.computercraft.info/forums2/index.php?/topic/10279-question-how-to-get-current-dir/
-- I doubt originalbit cares though, since he's been AFK for.. (checking his forum profile).. Yeah, pretty much a year now
local runningProgram = shell.getRunningProgram()
local programName = fs.getName(runningProgram)
local workingDirectory = runningProgram:sub( 1, #runningProgram - #programName )
print(workingDirectory)
for k,v in pairs(nations) do
	local Napop = 0
	
	if fs.exists(workingDirectory..v["Image"]) then
		v["Image"] = cobalt.surface.load(workingDirectory..v["Image"])
	else
		error("Missing image : "..workingDirectory..v["Image"])
	end
	
	for p,b in pairs(v["Cities"]) do
		b["DefaultIcon"] = b["Icon"]
		Napop = Napop + b["Population"]
	end
	v["Population"] = Napop -- The population that the nation was at when the game started E.G. Perfectly healthy nation
end

local worldMap = nil
if fs.exists(workingDirectory.."worldmap.nfp") then
	worldMap = cobalt.surface.load(workingDirectory.."worldmap.nfp")
else
	error("Missing image : "..workingDirectory.."worldmap.nfp")
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

local ContextPopUpBG = cobalt.ui.new({w="70%",h="70%",marginleft="15%",margintop="15%",backColour=colors.white,backColour=colors.white})
--local ContextPopUpBG2 = ContextPopUpBG:add("text",{w=ContextPopUpBG.w,h=ContextPopUpBG.h,x=0,y=0,text=string.rep(string.rep("-",ContextPopUpBG.w).."\n",ContextPopUpBG.h),wrap="left",foreColour=colors.white})

local ContextPopUpTOPLABEL = ContextPopUpBG:add("text",{w=99,h=1,x=0,y=1,text="== Command Center "..string.rep("=",30),foreColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpSTATUSLABEL = ContextPopUpBG:add("text",{w=15,h=7,x=1,y=2,text="Doing nothing this turn.",warp="left",foreColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpDIVIDER = ContextPopUpBG:add("text",{w=1,h=10,x=16,y=1,text=string.rep("| ",30),foreColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpSTATUS1 = ContextPopUpBG:add("text",{w=25,h=1,x=1,y=6,text="",warp="left",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpSTATUS2 = ContextPopUpBG:add("text",{w=25,h=1,x=1,y=8,text="",warp="left",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpSTATUS3 = ContextPopUpBG:add("text",{w=25,h=1,x=1,y=10,text="",warp="left",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpLabel1 = ContextPopUpBG:add("text",{w=25,h=1,x=35-13,y=2,text="Raise DEFCON",wrap="left",foreColour=nations[nationSelectedForGUI]["Color"],backColour=colors.white})
local ContextPopUpButton1 = ContextPopUpBG:add("button",{w=10,h=1,x=22,y=3,text="Activate",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpHelp1 = ContextPopUpBG:add("button",{w=0,h=1,x=34,y=3,text="?",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpLabel2 = ContextPopUpBG:add("text",{w=25,h=1,x=35-14,y=5,text="Spy Satellite",wrap="left",foreColour=nations[nationSelectedForGUI]["Color"],backColour=colors.white})
local ContextPopUpButton2 = ContextPopUpBG:add("button",{w=10,h=1,x=22,y=6,text="Activate",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpHelp2 = ContextPopUpBG:add("button",{w=0,h=1,x=34,y=6,text="?",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpLabel3 = ContextPopUpBG:add("text",{w=25,h=1,x=35-16,y=8,text="Lobby for Funds",wrap="left",foreColour=nations[nationSelectedForGUI]["Color"],backColour=colors.white})
local ContextPopUpButton3 = ContextPopUpBG:add("button",{w=10,h=1,x=22,y=9,text="Activate",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpHelp3 = ContextPopUpBG:add("button",{w=0,h=1,x=34,y=9,text="?",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpLabel4 = ContextPopUpBG:add("text",{w=25,h=1,x=35-14,y=11,text="UNUSED",wrap="left",foreColour=nations[nationSelectedForGUI]["Color"],backColour=colors.white})
local ContextPopUpButton4 = ContextPopUpBG:add("button",{w=10,h=1,x=22,y=12,text="Activate",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})
local ContextPopUpHelp4 = ContextPopUpBG:add("button",{w=0,h=1,x=34,y=12,text="?",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

local ContextPopUpEXIT = ContextPopUpBG:add("button",{w=6,h=1,x=2,y="90%",text="Exit",foreColour=colors.white,backColour=nations[nationSelectedForGUI]["Color"]})

ContextPopUpEXIT.onclick = function()
	ContextDisabled = false
	ContextPopUpBG.state = false
end

ContextPopUpBG.state = false

local function ContextPopUp(context)
	ContextDisabled = true
	ContextPanel.x = -100
	ContextPanel.y = -100
	
	ContextPopUpTOPLABEL.text = "== "..context["topLabel"].." "..string.rep("=",30)
	
	if context["info"] then
		ContextPopUpSTATUSLABEL.text = context["info"]
	else
		ContextPopUpSTATUSLABEL.text = ""
	end
	
	if context["status1"] then
		ContextPopUpSTATUS1.text = context["status1"]
	else
		ContextPopUpSTATUS1.text = ""
	end
	
	if context["status2"] then
		ContextPopUpSTATUS2.text = context["status2"]
	else
		ContextPopUpSTATUS2.text = ""
	end
	
	if context["status3"] then
		ContextPopUpSTATUS3.text = context["status3"]
	else
		ContextPopUpSTATUS3.text = ""
	end
	
	if context["button1"] then
		ContextPopUpLabel1.text = context["button1"]["label1"]
		ContextPopUpLabel1.x = 34-string.len(context["button1"]["label1"])
		ContextPopUpButton1.text = context["button1"]["label2"]
		ContextPopUpButton1.onclick = function() context["button1"]["function"]() end
		ContextPopUpHelp1.onclick = function() context["button1"]["help"]() end
		
		ContextPopUpLabel1.state = "game"
		ContextPopUpButton1.state = "game"
		ContextPopUpHelp1.state = "game"
	else
		ContextPopUpLabel1.state = false
		ContextPopUpButton1.state = false
		ContextPopUpHelp1.state = false
	end
	
	if context["button2"] then
		ContextPopUpLabel2.text = context["button2"]["label1"]
		ContextPopUpLabel2.x = 34-string.len(context["button2"]["label1"])
		ContextPopUpButton2.text = context["button2"]["label2"]
		ContextPopUpButton2.onclick = function() context["button2"]["function"]() end
		ContextPopUpHelp2.onclick = function() context["button2"]["help"]() end
		
		ContextPopUpLabel2.state = "game"
		ContextPopUpButton2.state = "game"
		ContextPopUpHelp2.state = "game"
	else
		ContextPopUpLabel2.state = false
		ContextPopUpButton2.state = false
		ContextPopUpHelp2.state = false
	end
	
	if context["button3"] then
		ContextPopUpLabel3.text = context["button3"]["label1"]
		ContextPopUpLabel3.x = 34-string.len(context["button3"]["label1"])
		ContextPopUpButton3.text = context["button3"]["label2"]
		ContextPopUpButton3.onclick = function() context["button3"]["function"]() end
		ContextPopUpHelp3.onclick = function() context["button3"]["help"]() end
		
		ContextPopUpLabel3.state = "game"
		ContextPopUpButton3.state = "game"
		ContextPopUpHelp3.state = "game"
	else
		ContextPopUpLabel3.state = false
		ContextPopUpButton3.state = false
		ContextPopUpHelp3.state = false
	end
	
	if context["button4"] then
		ContextPopUpLabel4.text = context["button4"]["label1"]
		ContextPopUpLabel4.x = 34-string.len(context["button4"]["label1"])
		ContextPopUpButton4.text = context["button4"]["label2"]
		ContextPopUpButton4.onclick = function() context["button4"]["function"]() end
		ContextPopUpHelp4.onclick = function() context["button4"]["help"]() end
		
		ContextPopUpLabel4.state = "game"
		ContextPopUpButton4.state = "game"
		ContextPopUpHelp4.state = "game"
	else
		ContextPopUpLabel4.state = false
		ContextPopUpButton4.state = false
		ContextPopUpHelp4.state = false
	end
	
	if not context["color"] then
		context["color"] = nations[nationSelectedForGUI]["Color"]
	end
	ContextPopUpTOPLABEL.foreColour = context["color"]
	ContextPopUpSTATUSLABEL.foreColour = context["color"]
	ContextPopUpDIVIDER.foreColour = context["color"]
	ContextPopUpSTATUS1.foreColour = colors.white
	ContextPopUpSTATUS2.foreColour = colors.white
	ContextPopUpSTATUS3.foreColour = colors.white
	ContextPopUpSTATUS1.backColour = context["color"]
	ContextPopUpSTATUS2.backColour = context["color"]
	ContextPopUpSTATUS3.backColour = context["color"]
	ContextPopUpLabel1.foreColour = context["color"]
	ContextPopUpButton1.foreColour = colors.white
	ContextPopUpButton1.backColour = context["color"]
	ContextPopUpHelp1.backColour = context["color"]
	ContextPopUpHelp1.foreColour = colors.white
	ContextPopUpLabel2.foreColour = context["color"]
	ContextPopUpButton2.foreColour = colors.white
	ContextPopUpButton2.backColour = context["color"] 
	ContextPopUpHelp2.backColour = context["color"]
	ContextPopUpHelp2.foreColour = colors.white
	ContextPopUpLabel3.foreColour = context["color"]
	ContextPopUpButton3.foreColour = colors.white
	ContextPopUpButton3.backColour = context["color"]
	ContextPopUpHelp3.backColour = context["color"]
	ContextPopUpHelp3.foreColour = colors.white
	ContextPopUpLabel4.foreColour = context["color"]
	ContextPopUpButton4.foreColour = colors.white
	ContextPopUpButton4.backColour = context["color"] 
	ContextPopUpHelp4.backColour = context["color"]
	ContextPopUpHelp4.foreColour = colors.white
	ContextPopUpEXIT.foreColour = colors.white
	ContextPopUpEXIT.backColour = context["color"]
	
	ContextPopUpBG.state = "game"
end

local function FlashContextPopUp()
	ContextPopUpBG.backColour = nations[nationSelectedForGUI]["Color"]
	ContextPopUpTOPLABEL.backColour = nations[nationSelectedForGUI]["Color"]
	ContextPopUpSTATUSLABEL.backColour = nations[nationSelectedForGUI]["Color"]
	ContextPopUpDIVIDER.backColour = nations[nationSelectedForGUI]["Color"]
	ContextPopUpLabel1.backColour = nations[nationSelectedForGUI]["Color"]
end

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

local AlertTimer = 0
local AlertPanel = cobalt.ui.new({w=51,h=3,x=1,y=math.floor(19/2),state=false})
local AlertText = AlertPanel:add("text",{w=51,h=1,y=2,text="",wrap="center"})
local function Alert(text,color,timer)
	if not timer then timer = 10 end
	if not color then color = nations[nationSelectedForGUI]["Color"] end
	AlertPanel.backColour = color
	AlertText.backColour = color
	AlertText.foreColour = colors.white
	AlertText.text = text
	AlertPanel.state = "game"
	AlertText.state = "game"
	AlertTimer = timer
end

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

--[[
	The ContextMenu table is quickly becoming outdated now that we don't have a context menu.
	I think cities still access from here, so I'm keeping ContextMenu intact until I migrate the useful parts somewhere else.
]]--
local ContextMenu = {
	["You"] = { -- Clicking on your own cities
		--[[[1] = {
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
		},]]--
		--[[[1] = {
			["Text"] = "Build..",
			["Function"] = function(city)
				city.Icon = "N"
				city.Work = "BuildNuke"
			end,
		},]]--
		[1] = {
			["Text"] = "View",
			["Function"] = function(cityName,city)
				ContextPopUp({
					["topLabel"] = cityName,
					["info"] = "The city bustles with life.",
					["status1"] = "Alive: "..renderPop(city.Population),
					["status2"] = "Dead: "..renderPop(city.Dead),
					["status3"] = "$/Turn: "..renderPop((city["Population"] /(DEFCON/5) ) /5),
					["color"] = nations[nationSelectedForGUI]["Color"],
				})
			end,
		},
		
		["command"] = {
			[1] = {
				["Text"] = "View",
				["Function"] = function(baseName,base)
					local t = {
						["topLabel"] = "Command Center",
						["button1"] = {
							["label1"] = "Lower DEFCON",
							["label2"] = "Activate",
							["function"] = function()
								if DEFCON > 1 then
									ContextPopUpSTATUSLABEL.text = "Lowering the DEFCON level.."
									base.Work = "RaiseDEFCON"
								else
									ContextPopUpSTATUSLABEL.text = "We're already in a nuclear war!"
								end
							end,
							["help"] = function()
							
							end,
						},
					}
					
					if base.Work == "RaiseDEFCON" then
						t["info"] = "Raising the DEFCON level.."
					else
						t["info"] = "Sitting idle. Assign work for us to do!"
					end
					ContextPopUp(t)
				end,
			},
		}
	},
	["Enemy"] = { -- Clicking on enemy cities
		[1] = {
			["Text"] = "Fire Nuke",
			["Function"] = function(cityName,city)
				ContextPanel.x = -100
				ContextPanel.y = -100
				ContextDisabled = true
				
				for k,v in pairs(nations[nationSelectedForPlaying]["Cities"]) do
					v["Icon"] = tostring(v["Nukes"])
				end
				
				if options["BeginnerAlerts"] then Alert("Select a friendly city to fire from.",nations[nationSelectedForPlaying]["Color"]) end
				
				ContextOverride = function(city2)
					if city2.Nukes > 0 then
						FireNuke(city2,city,true)
					end
				end
			end,
		}
	},
}

local insertBuilding = nil

local buildings = {
	[0] = { -- Not a legit building you can build.
		["Name"] = "https://youtu.be/dQw4w9WgXcQ",
		["Cost"] = 0,
		["Icon"] = "%",
		["Type"] = "construction",
		["mb1click"] = function(v,k,n) 
			local t = {
				["topLabel"] = "Construction Yard",
				["button1"] = {
					["label1"] = "Refund Bldg.",
					["label2"] = "+$"..renderPop(v["Cost"]),
					["function"] = function()
						n["Resources"] = n["Resources"] + v["Cost"]
						n["Buildings"][k] = nil
						ContextPopUpBG.state = false
					end,
					["help"] = function()
					
					end,
				},
				["status1"] = "Building "..v["Work"],
				["status2"] = "",
				["info"] = "The yard is filled with men busy at work.",
			}
			if v["Turns"] == 1 then
				t["status2"] = v["Turns"].." Turn Left"
			else
				t["status2"] = v["Turns"].." Turns Left"
			end
			
			ContextPopUp(t)
		end,
	},
	[1] = {
		["Name"] = "Missile Silo",
		["Cost"] = 1000000, -- 1M
		["Icon"] = "M",
		["Type"] = "silo",
		["Turns"] = 2,
		["Health"] = 2,
		["Nukes"] = 0,
		["Cruise"] = 0,
		["mb1click"] = function(v,k,n) 
			local t = {
				["topLabel"] = "Missile Silo",
				["button1"] = {
					["label1"] = "1 Nuke ($200K)",
					["label2"] = "Build",
					["function"] = function()
						if v["Work"] ~= "BuildNuke" then
							if n["Resources"] > 200000 then -- 200K
								n["Resources"] = n["Resources"] - 200000
								ContextPopUpSTATUSLABEL.text = "Building one nuke."
								v["Work"] = "BuildNuke"
							else
								ContextPopUpSTATUSLABEL.text = "Not enough money!"
							end
						end
					end,
					["help"] = function()
					
					end,
				},
				["status1"] = "Cond. ",
				["status2"] = "Nukes: ",
				["status3"] = "C.Missiles: ",
			}
			
			if v["Health"] == 2 then
				t["status1"] = t["status1"].." Working"
			else
				t["status1"] = t["status1"].." CRITICAL"
			end
			
			t["status2"] = t["status2"]..v["Nukes"]
			t["status3"] = t["status3"]..v["Cruise"]
			
			if v["Work"] == "BuildNuke" then
				t["info"] = "Building one nuke."
			else
				t["info"] = "Sitting idle. Assign work for us to do!"
			end
			ContextPopUp(t)
		end,
	},
}

local function insertBuilding(id,change,N)
	local bd = {}
	for k,v in pairs(buildings[id]) do
		bd[k] = v
	end
	for k,v in pairs(change) do
		bd[k] = v
	end
	local RandomID = math.random(1,9999) -- Idk, maybe this will fix the construction yard bug
	while N["Buildings"][RandomID] do
		RandomID = math.random(1,9999)
	end
	N["Buildings"][RandomID] = bd
end

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

local MainPanel = cobalt.ui.new({w=4,h=1,state="game"})

local SwapViewButton = MainPanel:add("button",{w=4,h=1,text="View",foreColour = colors.white,backColour = colors.grey})
SwapViewButton.onclick = function()
	if ContextPopUpBG.state == "game" then
		FlashContextPopUp()
	elseif StrategicCommandCenterPlaced then	
		ContextSelected = nil
		ContextPanel.x = -100
		ContextPanel.y = -100
		if nationSelectedForPlaying == nationSelectedForGUI then
			nationSelectedForGUI = nationSelectedForFighting
		else
			nationSelectedForGUI = nationSelectedForPlaying
		end
	else
		if options["BeginnerAlerts"] then
			AlertPanel.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.backColour = nations[nationSelectedForPlaying]["Color"]
			AlertText.foreColour = colors.white
			AlertText.text = "Build your strategic command center"
			AlertPanel.state = "game"
			AlertText.state = "game"
			AlertTimer = 10
		end
	end
end

local MX,MY = 0,0

local function checkLegalBuildingSite(x,y)
	if nations[nationSelectedForGUI] and nations[nationSelectedForGUI]["Color"] then
		if (cobalt.application.view.buffer[((y - 1) * 51 + x) * 3 - 1] == nations[nationSelectedForGUI]["Color"]) or (cobalt.application.view.buffer[((y - 1) * 51 + x) * 3 - 1] == colors.black) or (y >= 18 and x <= 14) or (y == 1) then
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

local NextTurnPanel = cobalt.ui.new({w = 14,h = 2, x = 1, y=18,backColour = colors.black,state="game"})
local NextTurnButton = NextTurnPanel:add("button",{w=9,h=1,y=2,text="Next Turn"})
NextTurnButton.onclick = function()
	if ContextPopUpBG.state == "game" then
		FlashContextPopUp()
	elseif StrategicCommandCenterPlaced then
		TURNOVER = true
	else
		Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"])
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

local function CommandCenterGUIUpdate(bool)
	if ContextPopUpBG.state == "game" then FlashContextPopUp()
	elseif bool then
		AlertPanel.state = false
		AlertText.state = false
		CommandCenterGUI = true
		ContextDisabled = true
		
		NextTurnPanel.state = false
		MainPanel.state = false
		
		CommandCenterPanel.state = "game"
		CommandCenterMapBackDrop.backColour = nations[nationSelectedForTurn]["Color"]
		CommandCenterMapBackDrop.state = "game"
		CommandCenterBack.state = "game"
		
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
		
		NextTurnPanel.state = "game"
		MainPanel.state = "game"
		
		CommandCenterPanel.state = false
		CommandCenterMapBackDrop.state = false
		CommandCenterBack.state = false
	end
end

CommandCenterBack.onclick = function()
	CommandCenterGUIUpdate(false)
end

local CommandCenterButton = NextTurnPanel:add("button",{w=14,h=1,text="Command Center",foreColour = colors.white,backColour = colors.grey})
CommandCenterButton.onclick = function()
	if StrategicCommandCenterPlaced then
		CommandCenterGUIUpdate(true)
	else
		Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"])
	end
end

local function checkBuildingDamage(N)
	local toRemove = {}
	for k,v in pairs(N["Buildings"]) do
		if v["Health"] == -1 then
			table.insert(toRemove,k)
		end
	end
	for k,v in pairs(toRemove) do
		N["Buildings"][v] = nil
	end
end

local function resolveTurn()
	nationSelectedForGUI = nationSelectedForTurn
	CommandCenterGUI = false
	local buildingsToAdd = {}
	for k,v in pairs(nations[nationSelectedForTurn]["Buildings"]) do
		if v["Turns"] then v["Turns"] = v["Turns"] - 1 end
		if v.Work == "BuildCruise" then
			if not v.Cruise then v.Cruise = 0 end
			v.Cruise = v.Cruise + 1
			v.Work = false
		elseif v.Work == "BuildNuke" then
			if not v.Nukes then v.Nukes = 0 end
			v.Nukes = v.Nukes + 1
			v.Work = false
		elseif v.Work == "RaiseDEFCON" then
			if DEFCON > 1 then
				CommandCenterGUI = true
				CommandCenterGUIUpdate(true)
				cobalt.application.view:clear(" ", cobalt.application.backColour, cobalt.application.foreColour );
				cobalt.draw()
				cobalt.application.view:render()
				sleep(0.5)
				DEFCON = DEFCON - 1
				CommandCenterGUIUpdate(true)
				cobalt.application.view:clear(" ", cobalt.application.backColour, cobalt.application.foreColour );
				cobalt.draw()
				cobalt.application.view:render()
				sleep(0.5)
				CommandCenterGUI = false
				CommandCenterGUIUpdate(false)
				cobalt.application.view:clear(" ", cobalt.application.backColour, cobalt.application.foreColour );
				cobalt.draw()
				cobalt.application.view:render()
				
				if DEFCON <= 1 then v.Work = false end
			elseif DEFCON <= 1 then
				v.Work = false
			end
		else
			for p,b in pairs(buildings) do
				if v.Work == b.Type and v["Turns"] <= 0 then -- We're a construction yard that's building something
					v.Health = -1 -- set the construction yard to be destroyed
					table.insert(buildingsToAdd,{["p"] = p,["changes"] = {
						["X"] = v["X"],
						["Y"] = v["Y"],
					}})
				end
			end
		end
	end
	
	for k,v in pairs(buildingsToAdd) do
		insertBuilding(v["p"],v["changes"],nations[nationSelectedForTurn])
	end

	checkBuildingDamage(nations[nationSelectedForTurn])
	local incomeThisTurn = 0
	for k,v in pairs(nations[nationSelectedForTurn]["Cities"]) do
		incomeThisTurn = incomeThisTurn + (v["Population"] /(DEFCON/5) ) /5
	end
	nations[nationSelectedForTurn]["Resources"] = nations[nationSelectedForTurn]["Resources"] + incomeThisTurn
end

local AISteps = {}
function cobalt.update( dt )
	if gameRunning then
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
				ContextPopUpBG.state = false
				nationSelectedForTurn = nationSelectedForFighting
			end
			
			if nationSelectedForTurn == nationSelectedForFighting and AIPaused == false then -- AI step
				nationSelectedForGUI = nationSelectedForFighting
				if #AISteps == 0 then
					resolveTurn()
					
					table.insert(AISteps,{}) -- To stop infinite turn cycles
					
					--[[for k,v in pairs(nations[nationSelectedForFighting]["Cities"]) do
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
						
						if v.Nukes > 0 then
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
						end
					end]]--
				else
					local WorkToDo = AISteps[1]
					--[[if WorkToDo["BuildCruise"] then
						WorkToDo["BuildCruise"].Work = "BuildCruise"
						WorkToDo["BuildCruise"].Icon = "C"
					elseif WorkToDo["BuildNuke"] then
						WorkToDo["BuildNuke"].Work = "BuildNuke"
						WorkToDo["BuildNuke"].Icon = "N"
					elseif WorkToDo["FireNuke"] then
						AIPaused = true
						FireNuke(WorkToDo["FireNuke"]["from"],WorkToDo["FireNuke"]["to"],false)
					end]]--
					
					
					
					table.remove(AISteps,1)
					if #AISteps == 0 then
						nationSelectedForGUI = nationSelectedForPlaying
						nationSelectedForTurn = nationSelectedForPlaying
						
						resolveTurn()
					end
				end
			end
		end
	end
end

function cobalt.draw()
	if gameRunning then
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
					cobalt.graphics.print(v["Icon"],v["X"],v["Y"],N["Color"],colors.white)
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
			
			if ContextPopUpBG.backColour == nations[nationSelectedForGUI]["Color"] then
				ContextPopUpBG.backColour = colors.white
				ContextPopUpTOPLABEL.backColour = colors.white
				ContextPopUpSTATUSLABEL.backColour = colors.white
				ContextPopUpDIVIDER.backColour = colors.white
				ContextPopUpLabel1.backColour = colors.white
			end
			
			cobalt.graphics.print(turnString,52-turnString:len(),1)
			
			marker["timer"] = marker["timer"] + 1
			if marker["timer"] > 4 then marker["timer"] = 0 end
			if marker["timer"] >= 0 and marker["timer"] <= 2 then
				cobalt.graphics.print("X",marker.x,marker.y,colors.white,colors.black)
			elseif marker["timer"] >= 3 and marker["timer"] <= 4 then
				cobalt.graphics.print("X",marker.x,marker.y,colors.black,colors.white)
			end
			
			--cobalt.graphics.print(MX..";"..MY,45,19)
		end
	else
		cobalt.ui.draw()
	end
end

function cobalt.mousepressed( x, y, button )
	MX,MY = x,y
	
	cobalt.ui.mousepressed(x,y,button)
	
	if gameRunning then
		if button == 1 then
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
								ContextPopUp({
									["topLabel"] = k,
									["info"] = "The city bustles with life.",
									["status1"] = "Alive: "..renderPop(v["Population"]),
									["status2"] = "Dead: "..renderPop(v["Dead"]),
									["status3"] = "$/Turn: "..renderPop((v["Population"] /(DEFCON/5) ) /5),
								})
								--[[if not ContextDisabled then
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
											ContextButtons[i].onclick = function() ContextMenu["Enemy"][i]["Function"](k,v) end
										end
									else
										for i=1,2 do
											ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
											if ContextMenu["You"][i] then
												ContextButtons[i]["text"] = ContextMenu["You"][i]["Text"]
											else
												ContextButtons[i]["text"] = ""
											end
											ContextButtons[i].onclick = function() ContextMenu["You"][i]["Function"](k,v) end
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
								end]]--
							end
						end
						if not cityFound then -- We didn't click on a city.. Maybe we clicked on a military building?
							for k,v in pairs(N["Buildings"]) do
								if v["X"] == x and v["Y"] == y then
									if v["mb1click"] then
										v["mb1click"](v,k,N) -- Pass the script our actual building, as well as our nation file
									end
									--[[if v["type"] == "command" then
										local t = {
											["topLabel"] = "Command Center",
											["button1"] = {
												["label1"] = "Raise DEFCON",
												["label2"] = "Activate",
												["function"] = function()
													if DEFCON > 1 then
														ContextPopUpSTATUSLABEL.text = "Raising the DEFCON level.."
														v["Work"] = "RaiseDEFCON"
													else
														ContextPopUpSTATUSLABEL.text = "We're already in a nuclear war!"
													end
												end,
												["help"] = function()
												
												end,
											},
											["status1"] = "Cond. ",
										}
										
										if v["health"] == 3 then
											t["status1"] = t["status1"].." Working"
										elseif v["health"] == 2 then
											t["status1"] = t["status1"].." Damaged"
										else
											t["status1"] = t["status1"].." CRITICAL"
										end
										
										if v["Work"] == "RaiseDEFCON" then
											t["info"] = "Raising the DEFCON level.."
										else
											t["info"] = "Sitting idle. Assign work for us to do!"
										end
										ContextPopUp(t)
									end]]--
									--[[if not ContextDisabled then
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
												ContextButtons[i].onclick = function() ContextMenu["Enemy"][ v["type"] ][i]["Function"](k,v) end
											end
										else
											for i=1,2 do
												ContextButtons[i]["backColour"] = nations[nationSelectedForGUI]["Color"]
												if ContextMenu["You"][ v["type"] ] and ContextMenu["You"][ v["type"] ][i] then
													ContextButtons[i]["text"] = ContextMenu["You"][ v["type"] ][i]["Text"]
												else
													ContextButtons[i]["text"] = ""
												end
												ContextButtons[i].onclick = function() ContextMenu["You"][ v["type"] ][i]["Function"](k,v) end
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
									end]]--
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
						Alert("You can't build in a city. Choose another site.",nations[nationSelectedForPlaying]["Color"],10)
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
							Alert("Please click the site again to confirm build.",nations[nationSelectedForPlaying]["Color"],10)
							marker.x = x
							marker.y = y
						end
					elseif (StrategicCommandCenterPosition["X"] == x) or (StrategicCommandCenterPosition["Y"] == y) then
						nations[nationSelectedForPlaying]["Buildings"][1] = {
							["X"] = x,
							["Y"] = y,
							["type"] = "command",
							["cruise"] = 0,
							["nukes"] = 0,
							["Health"] = 3,
							["Icon"] = "A",
							["Work"] = false,
							["mb1click"] = function(v)
								local t = {
									["topLabel"] = "Command Center",
									["button1"] = {
										["label1"] = "Lower DEFCON",
										["label2"] = "Activate",
										["function"] = function()
											if DEFCON > 1 then
												ContextPopUpSTATUSLABEL.text = "Scheming and bribing to lower DEFCON"
												v["Work"] = "RaiseDEFCON"
											else
												ContextPopUpSTATUSLABEL.text = "We're already in a nuclear war!"
											end
										end,
										["help"] = function()
										
										end,
									},
									["status1"] = "Cond. ",
								}
								
								if v["Health"] == 3 then
									t["status1"] = t["status1"].." Working"
								elseif v["Health"] == 2 then
									t["status1"] = t["status1"].." Damaged"
								else
									t["status1"] = t["status1"].." CRITICAL"
								end
								
								if v["Work"] == "RaiseDEFCON" then
									t["info"] = "Raising the DEFCON level.."
								else
									t["info"] = "Sitting idle. Assign work for us to do!"
								end
								ContextPopUp(t)
							end
						}
						marker.x = -10
						marker.y = -10
						StrategicCommandCenterPlaced = true
					end
				end
			end
		elseif button == 2 then
			if StrategicCommandCenterPlaced then
				if not constructionMarker then
					local cityFound = false
					for k,v in pairs(nations[nationSelectedForGUI]["Cities"]) do
						if v["X"] == x and v["Y"] == y then
							cityFound = true
						end
					end
					if not cityFound then
						local buildingFound = false
						for k,v in pairs(nations[nationSelectedForGUI]["Buildings"]) do
							if v["X"] == x and v["Y"] == y then
								buildingFound = true
							end
						end
						if not buildingFound then
							constructionMarker = true
							marker["x"] = x
							marker["y"] = y
						end
					end
				else
					if marker.x == x and marker.y == y then
						local popUpTable = {
							["topLabel"] = "Construction",
							["info"] = "Choose something to build.",
						}
						for i,v in ipairs(buildings) do
							popUpTable["button"..i] = {
								["label2"] = "Build $"..renderPop(v["Cost"]),
								["label1"] = v["Name"],
								["function"] = function()
									if nations[nationSelectedForPlaying]["Resources"] >= v["Cost"] then
										nations[nationSelectedForPlaying]["Resources"] = nations[nationSelectedForPlaying]["Resources"] - v["Cost"]
										insertBuilding(0,{
											["X"] = x,
											["Y"] = y,
											["Work"] = v["Type"],
											["Cost"] = v["Cost"],
											["Turns"] = v["Turns"],
										},nations[nationSelectedForPlaying])
										ContextPopUpBG.state = false
									else
										ContextPopUpSTATUSLABEL.text = "Not enough resources! We need to go cheaper."
									end
								end,
							}
						end
						
						ContextPopUp(popUpTable)
						
						constructionMarker = false
						marker.x = -10
						marker.y = -10
					else
						constructionMarker = false
						marker.x = -10
						marker.y = -10
					end
				end
			else
				Alert("Use the LMB to place your command center.",nations[nationSelectedForPlaying]["Color"],10)
			end
		end
	end
end

local _checkbox1 = nil
function cobalt.mousereleased( x, y, button )
	cobalt.ui.mousereleased(x,y,button)
	if _checkbox1 then options["BeginnerAlerts"] = _checkbox1.selected end
end

function cobalt.keypressed( keycode, key )
	if gameRunning then
		if string.lower(key) == "q" then
			if ContextPopUpBG.state == "game" then
				FlashContextPopUp()
			elseif StrategicCommandCenterPlaced then
				if CommandCenterGUI == false then
					CommandCenterGUIUpdate(true)
				else
					CommandCenterGUIUpdate(false)
				end
			else
				Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"])
			end
		end
		
		if keycode == 15 then -- tab
			if ContextPopUpBG.state == "game" then
				FlashContextPopUp()
			elseif StrategicCommandCenterPlaced then	
				ContextSelected = nil
				ContextPanel.x = -100
				ContextPanel.y = -100
				if nationSelectedForPlaying == nationSelectedForGUI then
					nationSelectedForGUI = nationSelectedForFighting
				else
					nationSelectedForGUI = nationSelectedForPlaying
				end
			else
				Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"])
			end
		end
		
		if keycode == 57 then -- spacebar
			if ContextPopUpBG.state == "game" then
				FlashContextPopUp()
			elseif StrategicCommandCenterPlaced then
				TURNOVER = true
			else
				Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"])
			end
		end
		
		if string.lower(key) == "v" then
			gridToggle = not gridToggle
		end
		
		if keycode == 197 then
			gameRunning = false
			cobalt.state = "pause"
		end
	elseif cobalt.state == "pause" then
		if keycode == 197 then
			gameRunning = true
			cobalt.state = "game"
		end
	end
end

function cobalt.keyreleased( keycode, key )

end

function cobalt.textinput( t )

end

if options["BeginnerAlerts"] then Alert("Build your strategic command center",nations[nationSelectedForPlaying]["Color"]) end

nations[nationSelectedForPlaying]["Buildings"] = {}

local pauseMenu = cobalt.ui.new({
	["x"] = 1,
	["y"] = 1,
	["w"] = 51,
	["h"] = 19,
	["backColour"] = colors.black,
	["foreColour"] = colors.blue,
	["state"] = "pause",
})
pauseMenu:add("text",{
	["text"] = "I M P E N D I N G",
	["foreColour"] = colors.blue,
	["wrap"] = "center",
	["y"] = 2,
})
pauseMenu:add("text",{
	["text"] = "D O O M",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 3,
})
pauseMenu:add("text",{
	["text"] = "Version - "..SoftwareVERSION,
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 19,
})
pauseMenu:add("text",{
	["text"] = "Created by Saldor010",
	["foreColour"] = colors.white,
	["wrap"] = "right",
	["y"] = 19,
})
pauseMenu:add("button",{
	["text"] = "Resume Game",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 7,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	gameRunning = true
	cobalt.state = "game"
end
pauseMenu:add("button",{
	["text"] = "Save Game",
	["foreColour"] = colors.black,
	["wrap"] = "center",
	["y"] = 9,
	["h"] = 1,
	["backColour"] = 128,
})
pauseMenu:add("button",{
	["text"] = "Options",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 11,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "options"
end
pauseMenu:add("button",{
	["text"] = "Exit Game",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 13,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "mainmenu"
end

local optionsMenu = cobalt.ui.new({
	["x"] = 1,
	["y"] = 1,
	["w"] = 51,
	["h"] = 19,
	["backColour"] = colors.black,
	["foreColour"] = colors.blue,
	["state"] = "options",
})
optionsMenu:add("text",{
	["text"] = "I M P E N D I N G",
	["foreColour"] = colors.blue,
	["wrap"] = "center",
	["y"] = 2,
})
optionsMenu:add("text",{
	["text"] = "D O O M",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 3,
})
optionsMenu:add("text",{
	["text"] = "Version - "..SoftwareVERSION,
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 19,
})
optionsMenu:add("text",{
	["text"] = "Created by Saldor010",
	["foreColour"] = colors.white,
	["wrap"] = "right",
	["y"] = 19,
})
optionsMenu:add("button",{
	["text"] = "Return",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 17,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	if game then
		cobalt.state = "pause"
	else
		cobalt.state = "mainmenu"
	end
end
_checkbox1 = optionsMenu:add("checkbox",{
	["label"] = "Beginner Alerts (Not implemented yet)",
	["foreColour"] = colors.white,
	["x"] = 3,
	["y"] = 5,
	["selected"] = true,
	["backColour"] = colors.blue,
})

local mainMenu = cobalt.ui.new({
	["x"] = 1,
	["y"] = 1,
	["w"] = 51,
	["h"] = 19,
	["backColour"] = colors.black,
	["foreColour"] = colors.blue,
	["state"] = "mainmenu",
})
mainMenu:add("text",{
	["text"] = "I M P E N D I N G",
	["foreColour"] = colors.blue,
	["wrap"] = "center",
	["y"] = 2,
})
mainMenu:add("text",{
	["text"] = "D O O M",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 3,
})
mainMenu:add("text",{
	["text"] = "Version - "..SoftwareVERSION,
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 19,
})
mainMenu:add("text",{
	["text"] = "Created by Saldor010",
	["foreColour"] = colors.white,
	["wrap"] = "right",
	["y"] = 19,
})
mainMenu:add("button",{
	["text"] = "Exit to OS",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 17,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.exit()
	term.clear()
	term.setCursorPos(1,1)
end
mainMenu:add("button",{
	["text"] = "Options",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 15,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "options"
end
mainMenu:add("button",{
	["text"] = "Credits",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 13,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "credits"
end
mainMenu:add("button",{
	["text"] = "Singleplayer",
	["foreColour"] = colors.white,
	["wrap"] = "center",
	["y"] = 7,
	["h"] = 1,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "game"
	game = {}
	gameRunning = true
end
mainMenu:add("button",{
	["text"] = "Multiplayer",
	["foreColour"] = colors.black,
	["wrap"] = "center",
	["y"] = 9,
	["h"] = 1,
	["backColour"] = 128,
})
mainMenu:add("button",{
	["text"] = "Load Game",
	["foreColour"] = colors.black,
	["wrap"] = "center",
	["y"] = 11,
	["h"] = 1,
	["backColour"] = 128,
})

local creditsMenu = cobalt.ui.new({
	["x"] = 1,
	["y"] = 1,
	["w"] = 51,
	["h"] = 19,
	["backColour"] = colors.black,
	["foreColour"] = colors.blue,
	["state"] = "credits",
})
creditsMenu:add("text",{
	["text"] = "= Impending Doom =",
	["foreColour"] = colors.blue,
	["wrap"] = "center",
	["y"] = 1,
})
creditsMenu:add("text",{
	["text"] = "- Programmed by Saldor010",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 3,
})
creditsMenu:add("text",{
	["text"] = "- Graphics by Saldor010",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 5,
})
creditsMenu:add("text",{
	["text"] = "- Cobalt 1.1_2* and CobaltUI 1.1_2* created by Computech",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 7,
})
creditsMenu:add("text",{
	["text"] = "- Surface 1.6.2* created by CrazedProgrammer",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 10,
})
creditsMenu:add("text",{
	["text"] = "- Special thanks to Luca0208 for debugging assistance",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 12,
})
creditsMenu:add("text",{
	["text"] = "- Rights are held under the MIT License, full license available in game folder",
	["foreColour"] = colors.blue,
	["wrap"] = "left",
	["y"] = 15,
})
creditsMenu:add("text",{
	["text"] = "*version numbers subject to change",
	["foreColour"] = colors.white,
	["wrap"] = "left",
	["y"] = 19,
})
creditsMenu:add("button",{
	["text"] = "Back",
	["foreColour"] = colors.white,
	["y"] = 19,
	["h"] = 1,
	["w"] = 4,
	["x"] = 51-4,
	["backColour"] = colors.blue,
}).onclick = function()
	cobalt.state = "mainmenu"
end

cobalt.state = "mainmenu"

cobalt.initLoop()