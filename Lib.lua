local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Safely retrieve the current game's official name
local success, productInfo = pcall(function()
   return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local currentGameName = success and productInfo.Name or "Unknown Game"

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Nacoms Lib",
   Icon = 0, 
   LoadingTitle = "Nacoms Library",
   LoadingSubtitle = "V1.0",
   ShowText = "Rayfield", 
   Theme = "Amethyst", 

   ToggleUIKeybind = "K", 

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, 

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, 
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = false, 
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", 
      FileName = "Key", 
      SaveKey = true, 
      GrabKeyFromSite = false, 
      Key = {"Hello"} 
   }
})

-- Global registry to hold elements for unified real-time searching
local searchableElements = {
   Premade = {},
   Universal = {},
   Freaky = {},
   Backdoor = {}
}

-- Native unified engine that filters grouped items together
local function connectNativeSearch(tabKey, searchString, dividerList)
   local query = searchString:lower()
   
   -- Toggle structural divider lines safely
   for _, divider in pairs(dividerList) do
      if divider and type(divider.Set) == "function" then
         divider:Set(query == "")
      end
   end

   -- Filter registered features
   for _, item in pairs(searchableElements[tabKey]) do
      local isMatch = (query == "" or item.SearchTitle:lower():find(query))
      
      -- Set visibility on all physical elements assigned to this feature group
      for _, guiElement in pairs(item.GuiObjects) do
         if guiElement and guiElement:IsA("GuiObject") then
            guiElement.Visible = isMatch
         end
      end
   end
end

-- Safely extracts the physical Roblox Frame associated with a Rayfield object table
local function getPhysicalFrame(rayfieldObject)
   if not rayfieldObject then return nil end
   if typeof(rayfieldObject) == "Instance" then return rayfieldObject end
   
   if type(rayfieldObject) == "table" then
      if rayfieldObject.Frame and typeof(rayfieldObject.Frame) == "Instance" then
         return rayfieldObject.Frame
      elseif rayfieldObject.Instance and typeof(rayfieldObject.Instance) == "Instance" then
         return rayfieldObject.Instance
      else
         -- Look through the dictionary for an implicit internal frame instance
         for _, v in pairs(rayfieldObject) do
            if v and typeof(v) == "Instance" and v:IsA("GuiObject") then
               if v.Name ~= "Title" and v.Name ~= "ImageLabel" and v.Name ~= "UIStroke" then
                  return v
               end
            end
         end
      end
   end
   return nil
end

-- Group multiple interactive items under a single searchable group
local function registerGroupedElement(tabKey, searchTitle, objectsList)
   local framesCollection = {}
   for _, obj in pairs(objectsList) do
      local frame = getPhysicalFrame(obj)
      if frame then
         table.insert(framesCollection, frame)
      end
   end
   
   table.insert(searchableElements[tabKey], {
      SearchTitle = searchTitle,
      GuiObjects = framesCollection
   })
end

-- Tracking system registry for automatic environment handling
local executionRegistry = {}

-- Hitbox Logic Shared Variables
local hitboxSize = 10
local hitboxEnabled = false
local trackedHitboxPlayers = {}

-- Periodic updater for player cache used by hitbox mechanisms
local function updateHitboxCache()
   trackedHitboxPlayers = {}
   local localPlayer = Players.LocalPlayer
   for _, p in ipairs(Players:GetPlayers()) do
      if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
         table.insert(trackedHitboxPlayers, p)
      end
   end
end

-- Continuous hitbox manipulation processing loop
RunService.RenderStepped:Connect(function()
   if hitboxEnabled then
      for _, p in ipairs(trackedHitboxPlayers) do
         if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            hrp.Transparency = 0.7
            hrp.BrickColor = BrickColor.new("Really blue")
            hrp.Material = Enum.Material.Neon
            hrp.CanCollide = false
         end
      end
   end
end)

task.spawn(function()
   while true do
      updateHitboxCache()
      task.wait(1)
   end
end)

-- ==================== THIS GAME TAB ====================
local ThisGameTab = Window:CreateTab("This Game", "gamepad-2")

ThisGameTab:CreateParagraph({
   Title = "Detected Environment",
   Content = "Targeting elements matching: " .. currentGameName
})

-- ==================== PREMADE TAB ====================
local PremadeTab = Window:CreateTab("Premade", "badge-check")
local premadeDividers = {}

local PremadeSearch = PremadeTab:CreateInput({
   Name = "Search Premade Items...", 
   PlaceholderText = "Type keyword here to filter...", 
   RemoveTextAfterFocusLost = false,
   Interact = true,
   Callback = function(Text) 
      connectNativeSearch("Premade", Text, premadeDividers)
   end,
})

local Div1 = PremadeTab:CreateDivider(); table.insert(premadeDividers, Div1)

-- FEATURE 1: Violence District
local currentSelection = "Full"
local ViolenceDropdown = PremadeTab:CreateDropdown({
   Name = "Violence District",
   Options = {"Full", "No Noclip", "Skillcheck", "GenTP"},
   CurrentOption = {"Full"}, 
   MultipleOptions = false, 
   Flag = "Dropdown1", 
   Callback = function(Options)
      currentSelection = Options[1]
   end,
})

local function loadViolenceDistrict()
   if currentSelection == "Full" then
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/Full.lua"))()
   elseif currentSelection == "No Noclip" then
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/NoNoClip.lua"))()
   elseif currentSelection == "Skillcheck" then
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/SkillCheck.lua"))()
   elseif currentSelection == "GenTP" then
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/GenTp.lua"))()
   end
end

local ViolenceButton = PremadeTab:CreateButton({
   Name = "Load Violence District",
   Callback = loadViolenceDistrict,
})

registerGroupedElement("Premade", "Violence District", {ViolenceDropdown, ViolenceButton})

executionRegistry["Violence District"] = function(targetTab)
   local internalSelection = "Full"
   targetTab:CreateDropdown({
      Name = "Violence District",
      Options = {"Full", "No Noclip (F)", "Skillcheck", "GenTP"},
      CurrentOption = {"Full"},
      MultipleOptions = false,
      Callback = function(Options) internalSelection = Options[1] end,
   })
   targetTab:CreateButton({
      Name = "Load",
      Callback = function()
         if internalSelection == "Full" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/Full.lua"))()
         elseif internalSelection == "No Noclip (F)" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/NoNoClip.lua"))()
         elseif internalSelection == "Skillcheck" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/SkillCheck.lua"))()
         elseif internalSelection == "GenTP" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Violence%20District/GenTp.lua"))()
         end
      end,
   })
end

local Div2 = PremadeTab:CreateDivider(); table.insert(premadeDividers, Div2)

-- FEATURE 2: Airsoft Battles
local function loadAirsoftBattles()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/AirsoftBattles/KillAll.lua"))()
end
local AirsoftButton = PremadeTab:CreateButton({
   Name = "Airsoft Battles Kill All",
   Callback = loadAirsoftBattles,
})
registerGroupedElement("Premade", "Airsoft Battles Kill All", {AirsoftButton})

executionRegistry["Airsoft Battles Kill All"] = function(targetTab)
   targetTab:CreateButton({
      Name = "Airsoft Battles Kill All",
      Callback = loadAirsoftBattles,
   })
end

local Div3 = PremadeTab:CreateDivider(); table.insert(premadeDividers, Div3)

-- FEATURE 3: Encounters Inf Energy
local function loadEncountersEnergy(Value)
   _G.InfEnergy = Value
   if _G.InfEnergy then
      task.spawn(function()
         local player = Players.LocalPlayer
         local runService = game:GetService("RunService")
         local loopConnection
         
         local function startEnergyLoop(character)
            if loopConnection then loopConnection:Disconnect() end
            if not character then return end
            
            local energyValue = character:WaitForChild("Energy", 2)
            if energyValue then
               loopConnection = runService.Heartbeat:Connect(function()
                  if not _G.InfEnergy then
                     if loopConnection then loopConnection:Disconnect() end
                     return
                  end
                  energyValue.Value = 97
               end)
            end
         end

         if player.Character then startEnergyLoop(player.Character) end
         player.CharacterAdded:Connect(function(newCharacter)
            startEnergyLoop(newCharacter)
         end)
      end)
   end
end

local EncountersToggle = PremadeTab:CreateToggle({
   Name = "Encounters Infinite Energy",
   CurrentValue = false,
   Flag = "InfEnergyToggle", 
   Callback = loadEncountersEnergy,
})
registerGroupedElement("Premade", "Encounters Infinite Energy", {EncountersToggle})

executionRegistry["Encounters Infinite Energy"] = function(targetTab)
   targetTab:CreateToggle({
      Name = "Encounters Infinite Energy",
      CurrentValue = false,
      Callback = loadEncountersEnergy,
   })
end

local Div4 = PremadeTab:CreateDivider(); table.insert(premadeDividers, Div4)

-- FEATURE 4: Five Nights: Hunted
local function loadFNH()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/FiveNightsHunted/Iliankytb.lua"))()
end
local NFHButton = PremadeTab:CreateButton({
   Name = "Five Nights: Hunted",
   Callback = loadFNH,
})
registerGroupedElement("Premade", "Five Nights: Hunted", {NFHButton})

executionRegistry["Five Nights: Hunted"] = function(targetTab)
   targetTab:CreateButton({
      Name = "Five Nights: Hunted",
      Callback = loadFNH,
   })
end

local Div5 = PremadeTab:CreateDivider(); table.insert(premadeDividers, Div5)

-- ==================== UNIVERSAL TAB ====================
local UniversalTab = Window:CreateTab("Universal", "usb")
local universalDividers = {}

local UniversalSearch = UniversalTab:CreateInput({
   Name = "Search Universal Items...", 
   PlaceholderText = "Type keyword here to filter...", 
   RemoveTextAfterFocusLost = false,
   Interact = true,
   Callback = function(Text) 
      connectNativeSearch("Universal", Text, universalDividers)
   end,
})

local UniDiv1 = UniversalTab:CreateDivider(); table.insert(universalDividers, UniDiv1)

-- FIXED: Replaced Min/Max syntax with Rayfield standard docs layout requirements
local HitboxSlider = UniversalTab:CreateSlider({
   Name = "Hitbox Expander Size",
   Range = {2, 200},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 10,
   Flag = "HitboxSizeSlider",
   Callback = function(Value)
      hitboxSize = Value
   end,
})

local HitboxToggle = UniversalTab:CreateToggle({
   Name = "Enable Universal Hitbox",
   CurrentValue = false,
   Flag = "UniversalHitboxToggle",
   Callback = function(Value)
      hitboxEnabled = Value
      if not hitboxEnabled then
         -- Gracefully reset positions back to default parameters instantly on disable
         for _, p in ipairs(trackedHitboxPlayers) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
               local hrp = p.Character.HumanoidRootPart
               hrp.Size = Vector3.new(2, 2, 1)
               hrp.Transparency = 0
               hrp.BrickColor = BrickColor.new("Medium stone grey")
               hrp.Material = Enum.Material.Plastic
               hrp.CanCollide = true
            end
         end
      end
   end,
})
registerGroupedElement("Universal", "Hitbox Expander", {HitboxSlider, HitboxToggle})

local UniDiv2 = UniversalTab:CreateDivider(); table.insert(universalDividers, UniDiv2)

local UniBtn1 = UniversalTab:CreateButton({
   Name = "Esp",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/Esp.lua"))() end,
})
registerGroupedElement("Universal", "Esp", {UniBtn1})

local UniBtn2 = UniversalTab:CreateButton({
   Name = "Esp V2 (Buggy)",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/ESPv2.lua"))() end,
})
registerGroupedElement("Universal", "Esp V2 (Buggy)", {UniBtn2})

local UniBtn3 = UniversalTab:CreateButton({
   Name = "Aimbot",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/Aimbot.lua"))() end,
})
registerGroupedElement("Universal", "Aimbot", {UniBtn3})

local UniBtn4 = UniversalTab:CreateButton({
   Name = "Dex++",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/Dexpp.lua"))() end,
})
registerGroupedElement("Universal", "Dex++", {UniBtn4})

local UniBtn5 = UniversalTab:CreateButton({
   Name = "FPS Games",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/FullFps.lua"))() end,
})
registerGroupedElement("Universal", "FPS Games", {UniBtn5})

local UniBtn6 = UniversalTab:CreateButton({
   Name = "NoClip",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/NoClip.lua"))() end,
})
registerGroupedElement("Universal", "NoClip", {UniBtn6})

local UniBtn7 = UniversalTab:CreateButton({
   Name = "First Person to Third Person",
   Callback = function() 
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/FP_to_TP.lua"))() end,
})
registerGroupedElement("Universal", "First Person to Third Person", {UniBtn7})

local UniBtn8 = UniversalTab:CreateButton({
   Name = "Spinbot",
   Callback = function() 
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/Spinbot.lua"))() end,
})
registerGroupedElement("Universal", "Spinbot", {UniBtn8})

local UniBtn9 = UniversalTab:CreateButton({
   Name = "FE Animations",
   Callback = function() 
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/EzHubAnims.lua"))() end,
})
registerGroupedElement("Universal", "FE Animations", {UniBtn9})

local UniBtn10 = UniversalTab:CreateButton({
   Name = "SeluwiaUI (Gamepass Spoofer)",
   Callback = function() 
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/SeluwiaUI.lua"))() end,
})
registerGroupedElement("Universal", "SeluwiaUI", {UniBtn10})

local UniBtn11 = UniversalTab:CreateButton({
   Name = "Infinite Yield",
   Callback = function() 
      loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/InfiniteYield.lua"))() end,
})
registerGroupedElement("Universal", "Infinite Yield", {UniBtn11})

-- ==================== FREAKY TAB ====================
local FreakyTab = Window:CreateTab("Freaky", "eye-off")
local freakyDividers = {}

local FreakySearch = FreakyTab:CreateInput({
   Name = "Search Freaky Items...", 
   PlaceholderText = "Type keyword here to filter...", 
   RemoveTextAfterFocusLost = false,
   Interact = true,
   Callback = function(Text) 
      connectNativeSearch("Freaky", Text, freakyDividers)
   end,
})

local FreDiv1 = FreakyTab:CreateDivider(); table.insert(freakyDividers, FreDiv1)

local FreBtn1 = FreakyTab:CreateButton({
   Name = "Jerk Tool",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Freaky/Jerk.lua"))() end,
})
registerGroupedElement("Freaky", "Jerk", {FreBtn1})

local FreDiv2 = FreakyTab:CreateDivider(); table.insert(freakyDividers, FreDiv2)

local FreBtn2 = FreakyTab:CreateButton({
   Name = "Bang Gui",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Freaky/Bang.lua"))() end,
})
registerGroupedElement("Freaky", "Bang Gui", {FreBtn2})


-- ==================== BACKDOORS TAB ====================
local BackdTab = Window:CreateTab("Backdoor", "shield-alert")
local backdDividers = {}

local BackdSearch = BackdTab:CreateInput({
   Name = "Search Backdoors...", 
   PlaceholderText = "Type keyword here to filter...", 
   RemoveTextAfterFocusLost = false,
   Interact = true,
   Callback = function(Text) 
      connectNativeSearch("Backdoor", Text, backdDividers)
   end,
})

local BacDiv1 = BackdTab:CreateDivider(); table.insert(backdDividers, BacDiv1)

local BacBtn1 = BackdTab:CreateButton({
   Name = "Protogen Backdoor",
   Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Backdoors/Protogen.lua"))() end,
})
registerGroupedElement("Backdoor", "Protogen", {BacBtn1})


-- ==================== AUTOMATED TARGET GENERATION FOR "THIS GAME" ====================
task.spawn(function()
   task.wait(0.5) 
   
   local gameWords = {}
   for word in currentGameName:lower():gmatch("%w+") do
      if #word > 2 then
         gameWords[word] = true
      end
   end
   
   local matchesFound = 0
   for name, generatorFunction in pairs(executionRegistry) do
      local isMatch = false
      local scriptNameLower = name:lower()
      
      for word in pairs(gameWords) do
         if scriptNameLower:find(word) then
            isMatch = true
            break
         end
      end
      
      if isMatch then
         matchesFound = matchesFound + 1
         generatorFunction(ThisGameTab)
         ThisGameTab:CreateDivider()
      end
   end
   
   if matchesFound == 0 then
      ThisGameTab:CreateParagraph({
         Title = "No Custom Scripts",
         Content = "No custom premade entries found matching keyword segments of: " .. currentGameName
      })
   end
end)
