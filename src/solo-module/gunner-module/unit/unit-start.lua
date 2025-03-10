-- GEMINI FOUNDATION

-- Many thanks to:
--  W1zard for weapon and radar widgets
--  tiramon for closest pipe functions
--  SeM for the help with the coroutines
--  JayleBreak for planetref functions
--  Aranol for closest pos functions and 2D planet radar
--  Mistery for vector functions
--  Middings for brake distance function
--  IvanGrozny for Echoes widget, 3D space map, icons from his "Epic HUD"
--  Chelobek for target vector widget

-- Gemini HUD is the rebirth of the CFCS HUD (Custom Fire Control System)
-- Author: GeminiX (aka SneakySnake, DU Pirate)

--Solo gunner seat
HUD_version = '1.0.0'

--LUA parameters
friendly_IDs = {} -- put IDs here 34141,231231,31231 etc
exportMode = true --export: Coordinate export mode
targetSpeed = 29999 --export: Target speed
GHUD_AR_sight_color = "rgb(0, 191, 255)" --export:
GHUD_Weapons_Panels = 3 --export:
GHUD_log_stats = true --export: Send target statistics to LUA channel
GHUD_ShowAllies = true --export: Show allies
GHUD_ShowEcho = true --export: Show targets echo
GHUD_Notifications = true --export: LUA radar notifications
GHUD_SafeNotifications = false --export: Show notifications in the safe zone
GHUD_SelectBorder_Color = "#00b9c9" --export:
GHUD_Allies_Count = 5 --export: Count of displayed allies. Selected ally will always be displayed
GHUD_Allies_Color = "#0cf27b" --export:
GHUD_Allied_Names_Color = "#0cf27b" --export:
GHUD_AR_allies_border_size = 400 --export:
GHUD_AR_allies_border_color = "#0cf27b" --export:
GHUD_AR_allies_font_color = "#0cf27b" --export:
GHUD_AR_allies_hold_only = false --export:
GHUD_Targets_Color = "#fc033d" --export:
GHUD_Locked_Opacity = 1 --export: 0-1
GHUD_Target_Names_Color = "#fc033d" --export: Color for target names
GHUD_Chance_Color = "#0cf27b"
GHUD_Allies_Distance_Color = "#00b9c9" --export:
GHUD_Distance_Color = "#00b9c9" --export:
GHUD_Speed_Color = "#00b9c9" --export:
GHUD_Angular_Color = "#bccc06"
GHUD_Radial_Color = "#bccc06"
GHUD_Count_Color = "#00b9c9" --export:
GHUD_Yourship_ID_Color = "#fca503" --export:
GHUD_Border_Color = "black" --export:
GHUD_AlliesY = 0 --export: set to 0 if playing in fullscreen mode
GHUD_SelectedY = 50 --export:
GHUD_SelectedX = 37.4 --export:
GHUD_SelectedTextY = 12 --export:
GHUD_Windowed_Mode = false --export: adds 2 to the height GHUD_AlliesY
collectgarbages = true --export:

GHUD_Allies_Count1 = GHUD_Allies_Count + 1

if GHUD_Windowed_Mode then
   GHUD_AlliesY = 2
end

--vars
atlas = require("atlas")
shift = false
radarIDs = {}
idN = 0
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
lastHitTime = {}
lastMissTime = {}
hits = {}
misses = {}
hitAnimations = 0
missAnimations = 0
totalDamage = {}
dHint = ''
mRadar = {}
mWeapons = {}
size = {'XL','L','M','S','XS'}
defaultSize = 'ALL'
sizeState = 6
focus = ''
gunnerHUD = ''
vectorHUD = ''
sight = ''
buttonSpace = false
buttonC = false
atmovar = false
speedcolor = ""
endload = 0
lastspeed = 0
znak = '' --target speed icon
firstload = 0
firstload1 = 0
constructSelected = 0
probil = 0
playerName = system.getPlayerName(unit.getMasterPlayerId())
warpScan = 0 --for 3D map
t_radarEnter = {}
loglist = {}
radarTarget = nil
radarStatic = {}
radarDynamic = {}
radarStaticWidget = {}
radarStaticData = {}
radarDynamicWidget = {}
radarDynamicData = {}
radarWidget = ''
shipName = core.getConstructName()
conID = core.getConstructId()
system.print(''..shipName..': '..conID..'')
conID = (""..conID..""):sub(-3)

function checkWhitelist()
   local whitelist = friendly_IDs
   local set = {}
   for _, l in ipairs(whitelist) do set[l] = true end
   return set
end

whitelist = checkWhitelist() --load IDs
local pauseAfter = 500 --radar widget coroutine

--radar widget
function defaultRadar()
   sizeState = 6
   defaultSize = 'ALL'
   if mRadar.friendlyMode == true then mRadar.friendlyMode = false end
end

function mRadar:createWidget()
   self.dataID = self.system.createData(self.radar.getWidgetData())
   radarPanel = self.system.createWidgetPanel('')
   radarWidget = self.system.createWidget(radarPanel, self.radar.getWidgetType())
   self.system.addDataToWidget(self.dataID, radarWidget)
end

function mRadar:createWidgetNew()
   self.dataID = self.system.createData(self.radar.getWidgetData())
   radarWidget = self.system.createWidget(radarPanel, self.radar.getWidgetType())
   self.system.addDataToWidget(self.dataID, radarWidget)
end

function mRadar:deleteWidget()
   self.system.destroyData(self.dataID)
   self.system.destroyWidget(radarWidget)
end

function mRadar:updateLoop()
   while true do
      self:updateStep()
      coroutine.yield()
   end
end

function mRadar:updateStep()
   local resultList = {}
   local data = radar.getWidgetData()
   local constructList = data:gmatch('({"constructId":".-%b{}.-})')
   local isIDFiltered = next(self.idFilter) ~= nil
   local i = 0
   for str in constructList do
      i = i + 1
      -- if i%pauseAfter==0 then
      --    coroutine.yield()
      -- end
      local ID = tonumber(str:match('"constructId":"([%d]*)"'))
      local size = radar.getConstructCoreSize(ID)
      local locked = radar.isConstructIdentified(ID)
      local alive = radar.isConstructAbandoned(ID)
      local selectedTarget = radar.getTargetId(ID)
      if locked == 1 or alive == 0 or selectedTarget == ID then --show only locked or alive or selected targets
         if defaultSize == 'ALL' then --default mode
            if (self.friendList[ID]==true or self.radar.hasMatchingTransponder(ID)==1) ~= self.friendlyMode and self.radar.getThreatRateFrom(ID) ~= 5 then  --show attacking traitor on widget
               goto continue1
            end
            if isIDFiltered and self.idFilter[ID%1000] ~= true then
               goto continue1
            end
            resultList[#resultList+1] = str:gsub('"name":"(.+)"', '"name":"' .. string.format("%03d", ID%1000) .. ' - %1"')
            ::continue1::
         end
         if defaultSize ~= 'ALL' and size == defaultSize then --sorted
            if (self.friendList[ID]==true or self.radar.hasMatchingTransponder(ID)==1) ~= self.friendlyMode and self.radar.getThreatRateFrom(ID) ~= 5 then
               goto continue2
            end
            if isIDFiltered and self.idFilter[ID%1000] ~= true then
               goto continue2
            end
            resultList[#resultList+1] = str:gsub('"name":"(.+)"', '"name":"' .. string.format("%03d", ID%1000) .. ' - %1"')
            ::continue2::
         end
      end
      if i > 50 then
         i = 0
         coroutine.yield()
      end
   end
   local filterMsg = (isIDFiltered and ''..focus..' - FOCUS - ' or '') .. (self.friendlyMode and ''..defaultSize..' - Friends' or ''..defaultSize..' - Enemies')
   --local postData = data:match('"elementId":".+') --deprecated
   local postData = data:match('"currentTargetId":".+')
   postData = postData:gsub('"errorMessage":""', '"errorMessage":"' .. filterMsg .. '"') --filter data
   data = '{"constructsList":[' .. table.concat(resultList, ",") .. "]," .. postData --completed json radar data
   self.system.updateData(self.dataID, data)
end

function mRadar:onUpdate()
   coroutine.resume(self.updaterCoroutine)
end

function mRadar:clearIDFilter()
   self.idFilter = {}
end

function mRadar:addIDFilter(id)
   self.idFilter[id] = true
end

--pvp focus mode
function mRadar:onTextInput(text)
   self:clearIDFilter()
   focus = text:sub(-3)
   defaultRadar()
   for id in text:gmatch('%D(%d%d%d)') do
      self:addIDFilter(tonumber(id))
   end
end

function mRadar:toggleFriendlyMode()
   self.friendlyMode = not self.friendlyMode
end

function mRadar:new(sys, radar, friendList)
   local mRadar = {}
   setmetatable(mRadar, self)
   self.system = sys
   self.radar = radar
   self.friendlyMode = false
   self.friendList = friendList or {}
   self.onlyIdentified = false
   self.idFilter = {}
   self:createWidget()
   self.updaterCoroutine = coroutine.create(function() self:updateLoop() end)
   return self
end

function mRadar:stopC()
   self:clearIDFilter(self.system.print("FOCUS MODE DEACTIVATED"))
end

--weapon widgets
function mWeapons:createWidgets()
   if not (type(self.weapons) == 'table' and #self.weapons > 0) then
      return
   end
   local widgetPanelID
   for i, weap in ipairs(self.weapons) do
      if (i-1) % self.weaponsPerPanel == 0 then
         widgetPanelID = self.system.createWidgetPanel('')
      end
      local weaponDataID = self.system.createData(weap.getData())
      self.weaponData[weaponDataID] = weap
      oldAnimationTime[weaponDataID] = 0
      self.system.addDataToWidget(weaponDataID, self.system.createWidget(widgetPanelID, weap.getWidgetType()))
   end
end

function mWeapons:onUpdate()
   for weaponDataID, weap in pairs(self.weaponData) do
      local weaponData = weap.getWidgetData()
      local weaponStatus = weaponData:match('"weaponStatus":(%d+)')
      local animationTime = tonumber(weaponData:match('"cycleAnimationRemainingTime":(.-),'))
      local fireReady = weaponData:match('"fireReady":(.-),')
      local outOfZone = weaponData:match('"outOfZone":(.-),')
      local targetConstructID = weaponData:match('"constructId":"(.-)"')
      local animationChanged = animationTime > oldAnimationTime[weaponDataID]
      oldAnimationTime[weaponDataID] = animationTime

      if weaponStatus == oldWeaponStatus[weaponDataID] and oldTargetConstruct[weaponDataID] == targetConstructID and oldFireReady[weaponDataID] == fireReady and OldoutOfZone[weaponDataID] == outOfZone and not animationChanged then
         goto continue
      end
      oldWeaponStatus[weaponDataID] = weaponStatus
      oldFireReady[weaponDataID] = fireReady
      OldoutOfZone[weaponDataID] = outOfZone
      oldTargetConstruct[weaponDataID] = targetConstructID

      local ammoName = weaponData:match('"ammoName":"(.-)"')

      local ammoType1 = ""
      if ammoName:match("Antimatter") then
         ammoType1 = "AM"
      elseif ammoName:match("Electromagnetic") then
         ammoType1 = "EM"
      elseif ammoName:match("Kinetic") then
         ammoType1 = "KI"
      elseif ammoName:match("Thermic") then
         ammoType1 = "TH"
         --elseif ammoName:match("stasis string ammo name") then
         --ammoType1 = "Stasis"
      end

      local ammoType2 = ""
      if ammoName:match("Precision") then
         ammoType2 = "Prec"
      elseif ammoName:match("Heavy") then
         ammoType2 = "Heavy"
      elseif ammoName:match("Agile") then
         ammoType2 = "Agile"
      elseif ammoName:match("Defense") then
         ammoType2 = "Def"
      end

      --if ammoType1 == "Statis" then
      --weaponData = weaponData:gsub('"ammoName":"(.-)"', '"ammoName":"' .. ammoType1 .. '"')
      --else
      --weaponData = weaponData:gsub('"ammoName":"(.-)"', '"ammoName":"' .. ammoType2 .. ' ' .. ammoType1 .. '"')
      --end
      weaponData = weaponData:gsub('"ammoName":"(.-)"', '"ammoName":"' .. ammoType2 .. ' ' .. ammoType1 .. '"')
      weaponData = weaponData:gsub('"constructId":"(%d+(%d%d%d))","name":"(.?.?.?.?).-"', '"constructId":"%1","name":"%2 - %3"')
      if self.system.updateData(weaponDataID, weaponData) ~= 1 then
         self.system.print('update error')
      end

      ::continue::
   end
end

function mWeapons:new(sys, weapons, weaponsPerPanel)
   local mWeapons = {}
   setmetatable(mWeapons, self)
   self.system = sys
   self.weapons = weapons
   self.weaponsPerPanel = weaponsPerPanel or 3
   self.weaponData = {}
   self:createWidgets()
   return self
end

--local time
function seconds_to_clock(time_amount)
   local start_seconds = time_amount
   local start_minutes = math.modf(start_seconds/60)
   local seconds = start_seconds - start_minutes*60
   local start_hours = math.modf(start_minutes/60)
   local minutes = start_minutes - start_hours*60
   local start_days = math.modf(start_hours/24)
   local hours = start_hours - start_days*24
   local wrapped_time = {h=hours, m=minutes, s=seconds}
   return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
end

--weapon widget
local oldAnimationTime = {}
local oldWeaponStatus = {}
local oldFireReady = {}
local OldoutOfZone = {}
local oldTargetConstruct = {}
local lastData = {}
local timed = false

--radar slot configurator
for slot_name, slot in pairs(unit) do
   if
   type(slot) == "table"
   and type(slot.export) == "table"
   and slot.getElementClass
   then
      if string.find(slot.getElementClass(), 'Radar') ~= nil then
         if string.find(slot.getElementClass(), 'Space') ~= nil then
            radar_1 = slot
         else
            radar_2 = slot
         end
      end
   end
end

--debug coroutine
function coroutine.xpcall(co)
   local output = {coroutine.resume(co)}
   if output[1] == false then
      local tb = traceback(co)

      local message = tb:gsub('"%-%- |STDERROR%-EVENTHANDLER[^"]*"', 'chunk')
      system.print(message)

      message = output[2]:gsub('"%-%- |STDERROR%-EVENTHANDLER[^"]*"', 'chunk')
      system.print(message)
      return false, output[2], tb
   end
   return table.unpack(output)
end

function ConvertLocalToWorld(x,y,z)
   local xOffset = x * vec3(construct.getWorldRight())
   local yOffset = y * vec3(construct.getWorldForward())
   local zOffset = z * vec3(construct.getWorldUp())

   return xOffset + yOffset + zOffset + vec3(construct.getWorldPosition())
end

--Echoes startup configurator
if radar_1.isOperational() == 0 then
   radar=radar_2
   radarWidgetScale = 160
   radarWidgetScaleDisplay = '<div class="measures"><span>0 KM</span><span>2.5 KM</span><span>5 KM</span></div>'
else
   radar=radar_1
   radarWidgetScale = 2
   radarWidgetScaleDisplay = '<div class="measures"><span>0 SU</span><span>1 SU</span><span>2 SU</span></div>'
end

radar.setSortMethod(1) --set default radar range mode for constructIds list main function

mWeapons = mWeapons:new(system, weapon, GHUD_Weapons_Panels) --weapon widgets
mRadar = mRadar:new(system, radar, whitelist) --radar widget

system.showScreen(1)
unit.setTimer("radar",0.05)

--main gunner function
local function main()
   while true do
      local i = 0
      local htmltext = ""
      local hudver = ""
      local htmltext2 = ""
      local friendlies = 0
      local countLock = 0
      local countAttacked = 0
      local list, list2, lockList = "", "", ""
      local islockList = ""
      local caption = ""
      local captionL = ""
      local targetsele = ""
      local target = ""
      local locks = ""
      local statusSVG = ""
      local captionText = ""
      local okcolor = ""
      local captionLcolor = ""
      radarTarget = {}
      radarStatic = {}
      radarDynamic = {}
      radarDynamicData = radarDynamicWidget
      radarDynamicWidget = {}
      radarStaticData = radarStaticWidget
      radarStaticWidget = {}
      local worksInEnvironment = radar_1.isOperational()
      if worksInEnvironment == 0 and atmovar == false then
         mRadar:deleteWidget()
         atmovar=true
         radar=radar_2
         mRadar.radar=radar
         mRadar:createWidgetNew()
         radarWidgetScale = 160
         radarWidgetScaleDisplay = '<div class="measures"><span>0 KM</span><span>2.5 KM</span><span>5 KM</span></div>'
      end
      if worksInEnvironment == 1 and atmovar == true then
         mRadar:deleteWidget()
         atmovar=false
         radar=radar_1
         mRadar.radar=radar
         mRadar:createWidgetNew()
         radarWidgetScale = 2
         radarWidgetScaleDisplay = '<div class="measures"><span>0 SU</span><span>1 SU</span><span>2 SU</span></div>'
      end

      --local radarIDs = radar.getConstructIds()
      --local idN = #radarIDs
      for k,v in pairs(radarIDs) do
         i = i + 1
         local size = radar.getConstructCoreSize(v)
         local constructRow = {}
         if GHUD_log_stats then
            if t_radarEnter[v] ~= nil then
               if radar.hasMatchingTransponder(v) == 0 and not whitelist[v] and size ~= "" and radar.getConstructDistance(v) < 600000 then --do not show far targets during warp and server lag
                  local name = radar.getConstructName(v)
                  if radar.isConstructAbandoned(v) == 0 then
                     local msg = 'NEW TARGET: '..name..' - '..v..' - Size: '..size..' - Time: '..t_radarEnter[v].time1..'\n'..t_radarEnter[v].pos1..''
                     table.insert(loglist, msg)
                  else
                     local msg = 'NEW TARGET (abandoned): '..name..' - '..v..' - Size: '..size..' - Time: '..t_radarEnter[v].time1..'\n'..t_radarEnter[v].pos1..''
                     table.insert(loglist, msg)
                  end
               end
               t_radarEnter[v] = nil
            end
         end
         if GHUD_ShowEcho == true and size ~= "" then
            constructRow.widgetDist = math.ceil(radar.getConstructDistance(v) / 1000 * radarWidgetScale)
         end
         --radarlist
         if GHUD_ShowAllies == true and size ~= "" then
            if radar.hasMatchingTransponder(v) == 1 or whitelist[v] and radar.getThreatRateFrom(v) ~= 5 then  --remove attacking traitor from the allies HUD
               local name = radar.getConstructName(v)
               local dist = math.floor(radar.getConstructDistance(v))
               if dist >= 1000 then
                  dist = ''..string.format('%0.1f', dist/1000)..'km ('..string.format('%0.2f', dist/200000)..'SU)'
               else
                  dist = ''..dist..'m'
               end
               local allID = (""..v..""):sub(-3) --cut construct IDs
               local nameA = ''..allID..' '..name..''
               friendlies = friendlies + 1
               if radar.getTargetId(v) ~= v and friendlies < GHUD_Allies_Count1 then
                  list = list..[[
                  <div class="table-row3 th3">
                  <div class="table-cell3">
                  ]]..'['..size..'] '..nameA.. [[<br><distalliescolor>]] ..dist.. [[</distalliescolor>
                  </div>
                  </div>]]
               end
               if radar.getTargetId(v) == v and friendlies < GHUD_Allies_Count1 then
                  list = list..[[
                  <div class="table-row3 th3S">
                  <div class="table-cell3S">
                  ]]..'['..size..'] '..nameA.. [[<br><distalliescolor>]] ..dist.. [[</distalliescolor>
                  </div>
                  </div>]]
               end
               if radar.getTargetId(v) == v and friendlies >= GHUD_Allies_Count1 then
                  list = list..[[
                  <div class="table-row3 th3S">
                  <div class="table-cell3S">
                  ]]..'['..size..'] '..nameA.. [[<br><distalliescolor>]] ..dist.. [[</distalliescolor>
                  </div>
                  </div>]]
               end
            end
         end
         --targets
         local speed = 0
         local radspeed = 0
         local angspeed = 0
         if radar.isConstructIdentified(v) == 1 and size ~= "" then
            local name = radar.getConstructName(v)
            local dist = math.floor(radar.getConstructDistance(v))
            if dist >= 1000 then
               dist = ''..string.format('%0.1f', dist/1000)..'km ('..string.format('%0.2f', dist/200000)..'SU)'
            else
               dist = ''..dist..'m'
            end
            local IDT = (""..v..""):sub(-3)
            local nameIDENT = ''..IDT..' '..name..''
            local nameT = string.sub((""..nameIDENT..""),1,11)
            --table.insert(radarTarget, constructRow)
            isILock = true
            speed = math.floor(radar.getConstructSpeed(v) * 3.6)
            if radar.getTargetId(v) == v then
               islockList = islockList..[[
               <div class="table-row2 thS">
               <div class="table-cellS">
               ]]..'['..size..'] '..nameIDENT.. [[ <speedcolor> ]] ..speed.. [[km/h</speedcolor><br><distcolor>]] ..dist.. [[</distcolor>
               </div>
               </div>]]
            else
               islockList = islockList..[[
               <div class="table-row2 th2">
               <div class="table-cell2">
               ]]..'['..size..'] '..nameIDENT.. [[ <speedcolor> ]] ..speed.. [[km/h</speedcolor><br><distcolor>]] ..dist.. [[</distcolor>
               </div>
               </div>]]
            end
         else

            if GHUD_ShowEcho == true and size ~= "" then
               if radar.getConstructKind(v) == 5 then
                  table.insert(radarDynamic, constructRow)
                  if radarDynamicWidget[constructRow.widgetDist] ~= nil then
                     radarDynamicWidget[constructRow.widgetDist] = radarDynamicWidget[constructRow.widgetDist] + 1
                  else
                     radarDynamicWidget[constructRow.widgetDist] = 1
                  end
               else
                  table.insert(radarStatic, constructRow)
                  if radarStaticWidget[constructRow.widgetDist] ~= nil then
                     radarStaticWidget[constructRow.widgetDist] = radarStaticWidget[constructRow.widgetDist] + 1
                  else
                     radarStaticWidget[constructRow.widgetDist] = 1
                  end
               end
            end
         end
         --lockstatus
         if radar.getThreatRateFrom(v) ~= 1 and size ~= "" then
            countLock = countLock + 1
            local name = radar.getConstructName(v)
            local dist = math.floor(radar.getConstructDistance(v))
            if dist >= 1000 then
               dist = ''..string.format('%0.1f', dist/1000)..'km ('..string.format('%0.2f', dist/200000)..'SU)'
            else
               dist = ''..dist..'m'
            end
            local loclIDT = (""..v..""):sub(-3)
            local nameLOCK = ''..loclIDT..' '..name..''
            if radar.getThreatRateFrom(v) == 5 then
               countAttacked = countAttacked + 1
               lockList = lockList..[[
               <div class="table-row th">
               <div class="table-cell">
               <redcolor1>]]..'['..size..'] '..nameLOCK.. [[</redcolor1><br><distcolor>]] ..dist.. [[</distcolor>
               </div>
               </div>]]
            else
               lockList = lockList..[[
               <div class="table-row th">
               <div class="table-cell">
               <orangecolor>]]..'['..size..'] '..nameLOCK.. [[</orangecolor><br><distcolor>]] ..dist.. [[</distcolor>
               </div>
               </div>]]
            end
         end
         if i > 50 then
            i = 0
            coroutine.yield()
         end
      end
      if GHUD_ShowAllies == true then
         if friendlies > 0 then
            caption = "<alliescolor>Allies:</alliescolor><br><countcolor>"..friendlies.."</countcolor> <countcolor2>"..conID.."</countcolor2>"
         else
            caption = "<alliescolor>Allies:</alliescolor><br><countcolor>0</countcolor> <countcolor2>"..conID.."</countcolor2>"
         end
         htmltext = htmlbasic .. [[
         <style>
         .th3>.table-cell3 {
            color: ]]..GHUD_Allied_Names_Color..[[;
            font-weight: bold;
         }
         </style>
         <div class="table3">
         <div class="table-row3 th3">
         <div class="table-cell3">
         ]]..caption..[[
         </div>
         </div>
         ]]..list..[[
         </div>]]
      end
      caption = "<targetscolor>Targets:</targetscolor>"
      target = targetshtml .. [[
      <style>
      .th2>.table-cell2 {
         color: ]]..GHUD_Target_Names_Color..[[;
         font-weight: bold;
      }
      </style>
      <div class="table2">
      <div class="table-row2 th2">
      <div class="table-cell2">
      ]] .. caption .. [[<br><countcolor>]]..idN-friendlies..[[</colorcount>
      </div>
      </div>
      ]] .. islockList .. [[
      </div>]]
      --threat status
      if countLock == 0 then
         captionL = "LOCK"
         captionLcolor = "#6affb1"
         captionText = "OK"
         okcolor = captionLcolor
      else
         captionL = "LOCKED:"
         captionLcolor = "#fca503"
         captionText = countLock
         okcolor = "#2ebac9"
      end
      --attackers count
      if countAttacked > 0 then
         captionL = "ATTACKED:"
         captionLcolor = "#fc033d"
         captionText = countAttacked
         okcolor = "#2ebac9"
      end
      --threat icon
      statusSVG = [[<style>.radarLockstatus {
         position: fixed;
         background: transparent;
         width: 6em;
         padding: 1vh;
         top: 13.5vh;
         left: 50%;
         transform: translateX(-50%);
         text-align: center;
         fill: ]]..captionLcolor..[[;
      }
      svg text{
         text-anchor: middle;
         dominant-baseline: middle;
         font-size: 110px;
         font-weight: bold;
         fill: ]]..okcolor..[[;
      }
      </style>
      <div class="radarLockstatus">
      <svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" xmlns:xlink="http://www.w3.org/1999/xlink" enable-background="new 0 0 512 512">
      <g>
      <path d="m501,245.6h-59.7c-5.3-93.9-81-169.6-174.9-174.9v-59.7h-20.9v59.7c-93.8,5.3-169.5,81-174.8,174.9h-59.7v20.9h59.7c5.3,93.8 81,169.5 174.9,174.8v59.7h20.9v-59.7c93.9-5.3 169.6-80.9 174.8-174.8h59.7v-20.9zm-80.6,0h-48.1c-4.9-56.3-49.6-100.9-105.9-105.9v-48.1c82.5,5.2 148.8,71.5 154,154zm-69.1,20.8c-4.9,44.7-40.9,80-84.9,84.9v-31.7h-20.9v31.8c-44.8-4.8-80.1-40.1-84.9-84.9h31.8v-20.9h-31.7c4.9-44.7 40.9-80 84.9-84.9v31.7h20.9v-31.7c44,4.9 80,40.2 84.9,84.9h-31.7v20.9h31.6zm-105.7-174.9v48.1c-56.3,4.9-100.9,49.6-105.9,105.9h-48.1c5.2-82.5 71.5-148.8 154-154zm-154,174.8h48.1c4.9,56.3 49.6,100.9 105.9,105.9v48.1c-82.5-5.2-148.8-71.5-154-154zm174.8,154v-48.1c56.3-4.9 100.9-49.6 105.9-105.9h48.1c-5.2,82.5-71.5,148.8-154,154z"/>
      </g>
      <text x="50%" y="52%">]]..captionText..[[</text>
      </svg>
      </div>]]
      locks = lockhtml .. [[
      <style>
      .th>.table-cell {
         font-weight: bold;
      }
      </style>
      <div class="table">
      <div class="table-row th">
      <div class="table-cell">
      <rightlocked style="color: ]]..captionLcolor..[[;">]] .. captionL  .. [[</rightlocked>
      </div>
      </div>
      ]] .. lockList .. [[
      </div>]]
      --Echoes widget
      if GHUD_ShowEcho == true then
         local dynamic = ''
         for k,v in pairs(radarDynamicData) do
            dynamic = dynamic .. '<span style="left:'..k..'px;height:'..v..'px;"></span>'
         end
         local static = ''
         for k,v in pairs(radarStaticData) do
            static = static .. '<span style="left:'..k..'px;height:'..v..'px;"></span>'
         end
         local htmlRadar = htmlRadar .. [[
         <div class="radar-widget">
         <div class="d-widget">]] .. dynamic .. [[</div>
         <div class="s-widget">]] .. static .. [[</div>
         <div class="labels">
         <span style="color: #6fc9ff;">DYNAMIC</span>
         <span style="color: #ff8d00;">STATIC</span>
         </div>
         ]]..radarWidgetScaleDisplay..[[
         </div>
         ]]
         radarWidget = htmlRadar
      else
         radarWidget = ''
      end

      hudver = hudvers .. [[<div class="hudversion">Gemini v]]..HUD_version..[[</div>]]

      if GHUD_ShowEcho == true then
         if GHUD_ShowAllies == true then
            --system.setScreen(htmltext .. target .. locks .. hudver .. radarWidget ..targetsele ..statusSVG)
            gunnerHUD = htmltext .. target .. locks .. hudver .. radarWidget ..targetsele ..statusSVG
         else
            --system.setScreen(target .. locks .. hudver .. radarWidget ..targetsele ..statusSVG)
            gunnerHUD = target .. locks .. hudver .. radarWidget ..targetsele ..statusSVG
         end

      else

         if GHUD_ShowAllies == true then
            --system.setScreen(htmltext .. target .. locks .. hudver ..targetsele ..statusSVG)
            gunnerHUD = htmltext .. target .. locks .. hudver ..targetsele ..statusSVG
         else
            --system.setScreen(target .. locks .. hudver ..targetsele ..statusSVG)
            gunnerHUD = target .. locks .. hudver ..targetsele ..statusSVG
         end
      end
      coroutine.yield()
   end
end

--HUD design
lockhtml = [[<style>
.table {
   display: table;
   background: ]]..GHUD_Background_Color..[[;
   opacity: ]]..GHUD_Locked_Opacity..[[;
   left: 0;
   top: 5vh;
   position: fixed;
}
.table-row {
   display: table-row;
}
.table-cell {
   display: table-cell;
   padding: 6px;
   border: 1px solid ]]..GHUD_Border_Color..[[;
   color: white;
}
orangecolor {
   color: #fca503;
}
redcolor1 {
   color: #fc033d;
}
rightlocked {
}</style>]]
targetshtml = [[<style>
.table2 {
   display: table;
   background: ]]..GHUD_Background_Color..[[;
   position: fixed;
   top: 0;
   left: 0;
}
.table-row2 {
   display: table-row;
   float: left;
}
.table-cell2 {
   display: table-cell;
   padding: 6px;
   border: 1px solid ]]..GHUD_Border_Color..[[;
   color: white;
}
.table-cellS {
   display: table-cell;
   padding: 6px;
   border: 1px solid ]]..GHUD_SelectBorder_Color..[[;
   color: white;
}
.thS>.table-cellS {
   color: ]]..GHUD_Target_Names_Color..[[;
   font-weight: bold;
}
distcolor {
   font-weight: bold;
   color: ]]..GHUD_Distance_Color..[[;
}
distalliescolor {
   font-weight: bold;
   color: ]]..GHUD_Allies_Distance_Color..[[;
}
speedcolor {
   font-weight: bold;
   color: ]]..GHUD_Speed_Color..[[;
   outline: 1px inset black;
}
countcolor {
   font-weight: bold;
   color: ]]..GHUD_Count_Color..[[;
}
countcolor2 {
   font-weight: bold;
   color: ]]..GHUD_Yourship_ID_Color..[[;
   float: right;
}
chancecolor {
   color: #6affb1;
}
targetscolor {
   color: ]]..GHUD_Targets_Color..[[;
}
alliescolor {
   color: ]]..GHUD_Allies_Color..[[;
}
.txgrenright {
   font-weight: bold;
   text-align: right;
   color: #0cf27b;
}
</style>]]
htmlbasic = [[<style>
.table3 {
   display: table;
   background: ]]..GHUD_Background_Color..[[;
   font-weight: bold;
   position: fixed;
   bottom: ]]..GHUD_AlliesY..[[vh;
   left: 0;
}
.table-row3 {
   display: table-row;
   float: left;
}
.table-cell3 {
   display: table-cell;
   padding: 5px;
   border: 1px solid ]]..GHUD_Border_Color..[[;
   color: white;
   font-weight: bold;
}
.table-cell3S {
   display: table-cell;
   padding: 5px;
   border: 1px solid ]]..GHUD_SelectBorder_Color..[[;
   color: white;
}
.th3S>.table-cell3S {
   color: ]]..GHUD_Allied_Names_Color..[[;
   font-weight: bold;
}</style>]]
hudvers = [[
<style>
.hudversion {
   position: fixed;
   bottom: 2.7vh;
   color: white;
   right: 8.1vw;
   font-family: 'Open Sans';
   letter-spacing: 0.5px;
   font-size: 1.4em;
   font-weight: bold;
}</style>]]

htmlRadar = [[
<style>
.top-panel {
   position: absolute;
   top: 160px;
   left: 0;
   right: 0;
   height: 200px;
   transform: perspective(1920px) rotateX(-18deg);
   transform-origin: top;
   display: flex;
   justify-content: center;
}
.top-panel .screen-panel {
   transform-style: preserve-3d;
   transform-origin: top;
   transform: perspective(120px) rotateX(-4deg);
}
.screen {
   background: rgba(0, 0, 0, .5);
   border-radius: 6px;
   padding: 5px 10px 10px;
   box-sizing: border-box;
   position: relative;
}
.screen::after {
   content: '';
   position: absolute;
   top: -6px;
   left: -6px;
   bottom: -6px;
   right: -6px;
   background: radial-gradient(110% 160% at 50% -40%, transparent 62%, rgba(255, 255, 255, .23)), radial-gradient(100% 70% at 50% 50%, #094075 -70%, transparent);
   border-radius: 10px;
   border: 1px solid #b7b7b7;
}
.screen.left::after {
   background: radial-gradient(farthest-corner at -20% 100%, transparent 62%, rgba(255, 255, 255, .43)), radial-gradient(farthest-corner at 50% -250%, #094075, transparent);
}
.data {
   white-space: nowrap;
   text-align: right;
}
.screen.dividers .data:nth-child(1) {
   margin-top: 0;
   padding-top: 0;
   border-top: none;
}
.data {
   display: flex;
   justify-content: space-between;
   align-items: baseline;
   width: 100%;
}
.screen.dividers .data {
   margin-top: 4px;
   border-top: 1px solid #496d8c;
   padding-top: 4px;
}
.data-header {
   font-weight: bold;
   font-size: 14px;
   display: flex;
   align-items: baseline;
   justify-content: space-between;
}
.data-content {
   font-size: 20px;
   display: flex;
   justify-content: flex-end;
   align-items: baseline;
   font-weight: normal;
   color: #edf7ff;
   font-family: monospace;
   font-weight: bold;
}
.data-unit {
   font-size: 12px;
   margin-left: 2px;
   color: #94ceff;
   font-weight: bold;
}
.data.speed {
   position: absolute;
   top: 7px;
   left: -5px;
   z-index: 10;
   right: -5px;
   height: 100%;
}
.speed .data-header {
   display: flex;
   justify-content: space-between;
   margin-top: 5px;
   align-items: baseline;
}
.tr-mode {
   background: #e9f5ff;
   border-radius: 2px;
   font-size: 12px;
   color: black;
   padding: 1px 3px;
   font-weight: bold;
   margin-right: 5px;
   height: 14px;
}
.data-bar {
   height: 6px;
   background: #284965;
   margin-top: 4px;
   margin-bottom: 4px;
   overflow: hidden;
   border-radius: 10px;
}
.data-bar>span {
   background: linear-gradient(90deg, transparent calc(100% - 30px), #f1f9ff), repeating-linear-gradient(90deg, #82c5ff 0px, #82c5ff 2px, transparent 2px, transparent 4px);
   display: block;
   position: relative;
   width: 100%;
   height: 100%;
   border-radius: 10px;
}
.disabled {
   opacity: .3;
}
.icon {
   fill: #94ceff;
   width: 50px;
}
.flex {
   display: flex;
}
.flex.align-bottom {
   align-items: baseline;
}
.flex.down {
   flex-direction: column;
}
.flex.align-top {
   align-items: flex-start;
}
.flex.align-center {
   align-items: center;
}
.flex.justify-end {
   justify-content: flex-end;
}
.flex.space-between {
   justify-content: space-between;
}
.hologram {
   display: flex;
   flex-direction: column;
   align-items: flex-end;
   filter: drop-shadow(0px 0px 6px rgba(255, 255, 255, .23)) drop-shadow(0px 0px 20px rgba(0, 0, 0, .20));
   width: 100%;
}
.holo-wrap {
   transform-origin: center right;
   width: 100%;
   margin-top: 20px;
}
.holo-wrap .data {
   display: flex;
   justify-content: space-between;
   align-items: baseline;
}
.holo-wrap .data-content {
   font-size: 12px;
}
.fuel-tank {
   display: flex;
   justify-content: space-between;
   align-items: baseline;
}
.fuel-gauge {
   width: 160px;
   height: 5px;
   position: relative;
   background: rgba(255, 255, 255, .12);
   border-radius: 15px;
   overflow: hidden;
}
.fuel-gauge span {
   position: absolute;
   top: 0;
   bottom: 0;
   left: 0;
   background: #e7f4ff;
   border-radius: 10px;
}
.data.icon-panel {
   display: flex;
   align-items: center;
}
.icon-panel .icon {
   height: 20px;
   width: auto;
   margin: 0px 0px;
   fill: rgba(200, 230, 255, .16);
}
.icon-panel .icon.on {
   fill: #94ceff;
}
.top-panel .screen-panel {
   display: flex;
   align-items: flex-start;
}
.screen.top-left {
   width: 470px;
   border-radius: 0px 0px 0px 6px;
   margin-right: -40px;
   height: 90px;
   padding-right: 60px;
   z-index: 0;
}
.top-left::after {
   background: radial-gradient(110% 160% at 70% -40%, transparent 62%, rgba(255, 255, 255, .23)), radial-gradient(100% 70% at 50% 50%, #094075 -70%, transparent);
   z-index: -1;
}
.screen.logo-screen {
   width: 160px;
   height: 160px;
   border-radius: 100px;
   margin-top: -40px;
   display: flex;
   justify-content: center;
   align-items: center;
   background: black;
}
.logo-screen::after {
   border-radius: 120px;
   background: radial-gradient(90% 136% at 50% -37%, transparent 86%, rgba(255, 255, 255, .33)), radial-gradient(100% 70% at 50% 65%, #094075 0%, transparent);
}
.screen.top-right {
   width: 470px;
   border-radius: 0px 0px 6px 0px;
   margin-left: -40px;
   height: 90px;
   z-index: -1;
   padding-left: 60px;
}
.top-right::after {
   background: radial-gradient(110% 160% at 30% -40%, transparent 62%, rgba(255, 255, 255, .23)), radial-gradient(100% 70% at 50% 50%, #094075 -70%, transparent);
   z-index: -1;
}
.radar-widget {
   width: 800px;
   height: 50px;
   position: absolute;
   margin-left: auto;
   margin-right: auto;
   left: 0;
   right: 0;
   top: 8vh;
   background: radial-gradient(60% 50% at 50% 50%, rgba(60, 166, 255, .34), transparent);
   border-right: 1px solid;
   border-left: 1px solid;
   transform-style: preserve-3d;
   transform-origin: top;
   transform: perspective(120px) rotateX(-4deg);
}
.d-widget,
.s-widget {
   height: 25px;
   width: 100%;
   overflow: hidden;
   position: relative;
}
.s-widget {
   border-top: 1px solid;
}
.d-widget span {
   background: linear-gradient(0deg, #b6ddff, #3ea7ff 25px);
   width: 2px;
   bottom: 0;
   position: absolute;
}
.s-widget span {
   background: linear-gradient(180deg, #ffd322, #ff7600 25px);
   width: 2px;
   top: 0;
   position: absolute;
}
.measures {
   display: flex;
   justify-content: space-between;
   font-size: 20px;
}
.measures span:first-child {
   transform: translateX(-50%);
}
.measures span:last-child {
   transform: translateX(50%);
}
.labels {
   display: flex;
   flex-direction: column;
   position: absolute;
   right: -60px;
   top: 0;
   height: 100%;
   justify-content: space-evenly;
   font-size: 12px;
}
.needle {
   position: absolute;
   top: -6px;
   left: 50%;
   transform: translateX(-50%);
   width: 0px;
   height: 0px;
   border-left: 8px solid transparent;
   border-right: 8px solid transparent;
   border-bottom: 8px solid #ecf6ff;
   filter: drop-shadow(0px 0px 30px #94ceff) drop-shadow(0px 0px 30px #94ceff) drop-shadow(0px 0px 5px #94ceff);
   z-index: 1;
}
.compass {
   position: absolute;
   top: 0;
   left: 0;
   right: 0;
   bottom: 0;
   border-radius: 50%;
   border: 2px;
   border-style: solid;
   transform-origin: center;
   transform: rotate(0deg);
}
.compass span {
   font-size: 20px;
   position: absolute;
   top: 50%;
   left: 50%;
}
.left-panel {
   position: absolute;
   top: 300px;
   left: 50%;
   transform: perspective(1920px) translateX(-50%) translateX(-790px) rotateY(50deg) translateZ(20px);
   transform-origin: center right;
   display: flex;
   flex-direction: column;
   justify-content: flex-start;
   align-items: flex-start;
   bottom: 0;
   width: 200px;
}
.left-panel.extended {
   width: 330px;
   transform: perspective(1920px) translateX(-50%) translateX(-700px) rotateY(50deg) translateZ(20px);
   display: block;
   top: 200px;
}
.pitch-roll-panel {
   position: absolute;
   top: 330px;
   border-left: 2px solid;
   left: 50%;
   transform: translateX(-50%) translateX(-465px);
   height: 300px;
   overflow: hidden;
   width: 400px;
   font-family: monospace;
   font-weight: bold;
   filter: drop-shadow(0px 0px 6px rgba(255, 255, 255, .23)) drop-shadow(0px 0px 20px rgba(0, 0, 0, .20));
}
.pitch {
   position: absolute;
   top: 50%;
   left: 0;
   transform: translateY(-50%);
}
.pitch-line {
   display: block;
   position: relative;
   height: 30px;
}
.pitch-line span {
   position: absolute;
   top: 50%;
   transform: translateY(-50%);
   display: flex;
   justify-content: space-between;
   align-items: center;
   font-weight: bold;
}
.pitch-line span::before {
   content: '';
   margin-right: 10px;
   height: 1px;
   background: #94ceff;
   flex-grow: 1;
   width: 10px;
}
.pitch-roll {
   position: absolute;
   top: 50%;
   left: 0;
   transform: translateY(-50%);
   display: flex;
   flex-wrap: nowrap;
   align-items: center;
}
.line {
   height: 2px;
   background: #c8e6ff;
   width: 90px;
}
.number-display {
   width: 50px;
   font-size: 16px;
   text-align: center;
   font-weight: bold;
   color: #c8e6ff;
   border: 2px solid;
   height: 21px;
   margin: 0px 8px;
   position: relative;
}
.number-head {
   font-size: 11px;
   position: relative;
   top: -37px;
   font-weight: bold;
}
.roll-lines {
   position: absolute;
   top: 50%;
   left: 50%;
   transform: translate(-50%, -50%) rotate(55deg);
   width: 80px;
   height: 80px;
   border: 14px dashed rgba(200, 230, 255, .08);
   border-radius: 100px;
   border-style: dashed;
}
.roll-lines span {
   width: 50px;
   height: 0;
   border-bottom: 3px dashed rgba(147, 205, 254, .50);
   position: absolute;
   top: 50%;
   left: 50%;
   transform: translate(-50%, -50%) rotate(-90deg) translateX(95px);
   z-index: -1;
}
.roll-lines span:nth-child(2) {
   transform: translate(-50%, -50%) rotate(0deg) translateX(95px);
}
.roll-lines span:nth-child(3) {
   transform: translate(-50%, -50%) rotate(90deg) translateX(95px);
}
.roll-lines span:nth-child(4) {
   transform: translate(-50%, -50%) rotate(180deg) translateX(95px);
}
.ship-orientation {
   width: 100px;
   height: 100px;
   position: relative;
   margin: 30px auto 0;
   border-radius: 50%;
   border: 1px solid;
}
.ship-orientation-gimbal {
   width: 100px;
   height: 100px;
   position: relative;
   transform-style: preserve-3d;
   transform: rotateX(0deg) rotateY(0deg) rotateZ(0deg);
}
.plane-z,
.plane-y,
.plane-x {
   position: absolute;
   top: 0;
   left: 0;
   right: 0;
   bottom: 0;
   border-radius: 50%;
   /*background: repeating-linear-gradient(0deg, rgba(148,206,255, .28) 0px, rgba(148,206,255, .28) 1px, transparent 1px, transparent 5px);
   border: 4px solid #94ceff;*/
   transform-style: preserve-3d;
}
.plane-z {
   transform: rotateY(90deg);
}
.plane-y {
   transform: rotateX(90deg);
   border: 2px solid #9dffab;
}
.plane-x {
   transform: rotateZ(90deg);
}
.plane-z::after {
   content: '';
   position: absolute;
   top: -30px;
   bottom: -30px;
   left: 50%;
   transform: translateX(-50%);
   width: 2px;
   background: #94ceff;
   border-radius: 10px;
}
.orient-z-axis {
   position: absolute;
   top: -30px;
   bottom: -30px;
   width: 2px;
   background: #cce8ff;
   left: 50%;
   transform: translateX(-50%);
}
.orient-z-axis::before,
.orient-z-axis::after {
   content: 'S';
   position: absolute;
   bottom: -16px;
   left: 50%;
   transform: translate(-50%, 0px);
   font-size: 13px;
   color: #c8e6ff;
}
.orient-z-axis::before {
   content: 'N';
   bottom: auto;
   top: -16px;
}
.plane-x span {
   position: absolute;
   top: 0;
   left: 0;
   bottom: 0;
   right: 0;
   border: 1px solid;
   border-radius: 50%;
}
.orient-x-axis {
   position: absolute;
   height: 2px;
   top: 50%;
   transform: translateY(-50%);
   left: -30px;
   right: -30px;
   background: #cce8ff;
}
.orient-x-axis::before,
.orient-x-axis::after {
   content: 'W';
   position: absolute;
   left: -16px;
   top: 50%;
   transform: translate(0%, -50%);
   font-size: 13px;
   color: #c8e6ff;
}
.orient-x-axis::after {
   content: 'E';
   right: -16px;
   left: auto;
}
.ui {
   position: absolute;
   bottom: 0;
   left: 50%;
   transform: translateX(-50%);
   height: 300px;
   width: 900px;
   background: rgb(0 0 0 / 53%);
   border-radius: 5px;
}
.ui::before {
   content: '';
   position: absolute;
   top: -6px;
   left: -6px;
   bottom: -6px;
   right: -6px;
   background: radial-gradient(110% 160% at 50% -40%, transparent 62%, rgba(255, 255, 255, .23)), radial-gradient(100% 70% at 50% 50%, #094075 -70%, transparent);
   border-radius: 10px;
   border: 1px solid #b7b7b7;
   pointer-events: none;
}
.top-bar {
   height: 25px;
   background: radial-gradient(50% 150% at 50% 160%, #007ae2, transparent);
   border-bottom: 1px solid rgba(148, 206, 255, .16);
   padding: 0px 10px;
   font-style: italic;
}
.ui-menu,
.ui-content {
   height: 100%;
   padding: 10px;
   box-sizing: border-box;
   font-family: monospace;
}
.ui-content {
   width: 800px;
}
.ui-menu {
   width: 100px;
   background: radial-gradient(80% 120% at 50% 0%, rgba(0, 122, 226, .30), transparent);
   border-right: 1px solid rgba(148, 206, 255, .16);
   padding: 0;
}
.ui-menu>div {
   padding: 20px 20px 20px;
   font-size: 16px;
   text-align: left;
   border-bottom: 1px solid rgba(148, 206, 255, .20);
}
.ui-menu>div.active {
   background: radial-gradient(70% 50% at 100% 50%, rgba(0, 134, 247, .95), transparent);
   color: #87c8ff;
}
span.query {
   padding: 2px 4px;
   background: #294256;
}
.system-map {
   position: absolute;
   top: 0;
   width: 100%;
   height: 100%;
   background: rgba(7, 44, 82, .81);
   left: 0;
}
.planet {
   width: 20px;
   height: 20px;
   border-radius: 50%;
   border: 2px solid;
   box-sizing: border-box;
   background: rgba(148, 206, 255, .29);
}
.map-actual {
   position: absolute;
   width: 100%;
   height: 100%;
   top: 0;
   left: 0;
   transform-style: preserve-3d;
}
.map-center {
   position: absolute;
   content: '';
   width: 2000px;
   height: 2000px;
   top: 50%;
   left: 50%;
   background: repeating-radial-gradient(rgba(0, 17, 35, .23), transparent 112px), repeating-radial-gradient(rgba(148, 206, 255, .34), transparent 75%);
   border-radius: 50%;
}
.map-pin {
   position: absolute;
   top: 50%;
   left: 50%;
}
.map-pin .icon,
.map-pin .planet {
   height: 30px;
   width: 30px;
}
.pin-data {
   position: absolute;
   bottom: 100%;
   margin-bottom: 10px;
   white-space: nowrap;
   text-align: center;
   width: 200px;
   left: 50%;
   transform: translateX(-50%);
}
.pin-data .name {
   font-size: 16px;
   color: white;
   line-height: 16px;
}
.pin-data .units {
   font-family: monospace;
   font-size: 14px;
   font-weight: bold;
   line-height: 14px;
}
.map-pin.player {
   filter: drop-shadow(0px 0px 20px #edf7ff);
}
.map-pin.player .icon {
   fill: #ffde56;
}
.con-size {
   width: 20px;
   text-align: center;
   background: #235f92;
   margin-right: 4px;
   color: white;
   height: 18px;
}
.warp-scan {
   width: 15px;
   height: 15px;
   border-radius: 50%;
   box-sizing: border-box;
   background: #ff3a56;
}
</style>]]
targetstyle = [[<style> .telemetry {
   margin: 0;
   padding: 0;
   background: transparent;
   width: 100vw;
   height: 100vh;
   position: fixed;
   top: ]]..GHUD_SelectedY..[[vh;
   right: ]]..GHUD_SelectedX..[[vw;
   white-space:nowrap;
   width: 400px;
}
.telemetry > div.numbers {
   margin-bottom: 10px;
   display: flex;
   width: 100%;
   justify-content: flex-end;
   margin-bottom: 0px;
}
.telemetry > div.numbers > h2 {
   font-size: 10px;
   font-weight: 900;
   margin-bottom:-3px;
   text-align: left;
   width: 60px;
}
.telemetry > div.numbers > div {
   font-weight: 500;
   font-size: 26px;
   text-align: right;
   color: #6affb1;
   margin-right: 4px;
   margin-top: ]]..GHUD_SelectedTextY..[[px;
}
.telemetry > div.numbers > h2 > span {
   display:block;
   font-size: 20px;
}
tran {
   color: transparent;
}
orangecolor {
   color: orange;
}
redcolor {
   font-weight: bold;
   font-family: Helvetica, sans-serif;
   font-size: 12px;
   color: ]]..GHUD_Target_Names_Color..[[;
   text-transform: none;
}
greencolor {
   color: #2ebac9;
}
powercolor {
   font-size: 15px;
   color: #b6dfed;
}
</style>]]

main1 = coroutine.create(main)

--interception concept
function zeroConvertToWorldCoordinates(pos, system) -- Many thanks to SilverZero for this.
   local num = " *([+-]?%d+%.?%d*e?[+-]?%d*)"
   local posPattern = "::pos{" .. num .. "," .. num .. "," .. num .. "," .. num .. "," .. num .. "}"
   local systemId, bodyId, latitude, longitude, altitude = string.match(pos, posPattern)

   if systemId == nil or bodyId == nil or latitude == nil or longitude == nil or altitude == nil then
      system.print("Invalid POS!")
      return vec3()
   end

   if (systemId == "0" and bodyId == "0") then
      --convert space bm
      return vec3(latitude, longitude, altitude)
   end
   longitude = math.rad(longitude)
   latitude = math.rad(latitude)
   local planet = atlas[tonumber(systemId)][tonumber(bodyId)]
   local xproj = math.cos(latitude)
   local planetxyz = vec3(xproj * math.cos(longitude), xproj * math.sin(longitude), math.sin(latitude))
   return vec3(planet.center) + (planet.radius + altitude) * planetxyz
end

function getPipeD(system)
   if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
      local distanceS = ""

      local length1 = -700 * 200000
      local length2 = 800 * 200000

      local pos123 = pos1
      local pos234 = pos2

      local pos111 = zeroConvertToWorldCoordinates(pos123, system)
      local pos222 = zeroConvertToWorldCoordinates(pos234, system)

      local DestinationCenter = vectorLengthen(pos111, pos222, length1)
      local DepartureCenter = vectorLengthen(pos111, pos222, length2)

      local worldPos = vec3(core.getConstructWorldPos())
      local pipe = (DestinationCenter - DepartureCenter):normalize()
      local r = (worldPos - DepartureCenter):dot(pipe) / pipe:dot(pipe)
      if r <= 0. then
         return (worldPos - DepartureCenter):len()
      elseif r >= (DestinationCenter - DepartureCenter):len() then
         return (worldPos - DestinationCenter):len()
      end
      local L = DepartureCenter + (r * pipe)
      local distance = (L - worldPos):len()
      if distance < 1000 then
         distanceS = "" .. string.format("%0.0f", distance) .. " m"
      elseif distance < 100000 then
         distanceS = "" .. string.format("%0.1f", distance / 1000) .. " km"
      else
         distanceS = "" .. string.format("%0.2f", distance / 200000) .. " su"
      end
      return distanceS
   end
end

function getPipeW(system)
   if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
      showMarker = false

      local length1 = -700 * 200000
      local length2 = 800 * 200000

      local pos123 = pos1
      local pos234 = pos2

      local pos111 = zeroConvertToWorldCoordinates(pos123, system)
      local pos222 = zeroConvertToWorldCoordinates(pos234, system)

      local DestinationCenter = vectorLengthen(pos111, pos222, length1)
      local DepartureCenter = vectorLengthen(pos111, pos222, length2)

      local worldPos = vec3(core.getConstructWorldPos())
      local pipe = (DestinationCenter - DepartureCenter):normalize()
      local r = (worldPos - DepartureCenter):dot(pipe) / pipe:dot(pipe)
      if r <= 0. then
         return (worldPos - DepartureCenter):len()
      elseif r >= (DestinationCenter - DepartureCenter):len() then
         return (worldPos - DestinationCenter):len()
      end
      local L = DepartureCenter + (r * pipe)
      local PipeWaypoint = "::pos{0,0," .. math.floor(L.x) .. "," .. math.floor(L.y) .. "," .. math.floor(L.z) .. "}"
      system.print("Pipe center")
      system.setWaypoint(PipeWaypoint)
   end
end

function getPos4Vector(coordinate)
   return "::pos{0,0," .. vec3(coordinate).x .. "," .. vec3(coordinate).y .. "," .. vec3(coordinate).z .. "}"
end

-- делает вектор из двух координат
function makeVector(coordinateBegin, coordinateEnd)
   local x = vec3(coordinateEnd).x - vec3(coordinateBegin).x
   local y = vec3(coordinateEnd).y - vec3(coordinateBegin).y
   local z = vec3(coordinateEnd).z - vec3(coordinateBegin).z
   return vec3(x, y, z)
end

function UTC()
   local T = curTime - timeZone * 3600
   return T
end

function UTCscaner(system)
   local T = system.getArkTime() - timeZone * 3600
   return T
end

-- прибавляет к вектору, из двух координат, кусочек длины
-- и воозращает координату окончания вектора, с учетом прибалвенной длины
function vectorLengthen(coordinateBegin, coordinateEnd, deltaLen)
   local vector = makeVector(coordinateBegin, coordinateEnd)
   --длина вектора
   local lenVector = vec3(vector):len()
   -- новая длина вектора
   local newLen = lenVector + deltaLen
   local factor = newLen / lenVector
   --новый вектор с удлиненной координатой
   local newVector = vector * factor
   -- надо прибавить к первой начальной координате полученый вектор
   local x = vec3(coordinateBegin).x + vec3(newVector).x
   local y = vec3(coordinateBegin).y + vec3(newVector).y
   local z = vec3(coordinateBegin).z + vec3(newVector).z
   -- итого координата окончания удлиненного вектора
   local resultCoordinate = vec3(x, y, z)
   return resultCoordinate
end

function start(unit, system, text)
   pos1time = 0
   pos2time = 0
   tspeed = 0
   tspeed1 = 0
   mmode = true
   lalt = false

   system.createWidgetPanel("Target Vector")
   deg2rad = math.pi / 180
   rad2deg = 180 / math.pi
   ms2kmh = 3600 / 1000
   kmh2ms = 1000 / 3600

   showMarker = true

   if exportMode == true then
      system.print("---------------")
      system.print("The export mode is enabled ALT+G")
   else
      system.print("---------------")
      system.print("The export mode is disabled ALT+G")
   end

   SU = 10
   calcTargetSpeed = targetSpeed / 3.6
   meterMarker = 0

   if
   databank.getStringValue(1) ~= "" and databank.getFloatValue(2) ~= 0 and databank.getStringValue(3) ~= "" and
   databank.getFloatValue(4) ~= 0
   then
      system.print("Coordinates from DB are used!")

      pos1 = databank.getStringValue(1)
      pos2 = databank.getStringValue(3)
      pos1time = databank.getFloatValue(2)
      pos2time = databank.getFloatValue(4)

      pos11 = zeroConvertToWorldCoordinates(pos1, system)

      pos22 = zeroConvertToWorldCoordinates(pos2, system)

      Pos1 = pos1
      Pos2 = pos2

      privMySignAngleR = 0
      privMySignAngleUp = 0
      privTargetSignAngleR = 0
      privTargetSignAngleUp = 0
      targetVector = vec3.new(0, 0, 0)
      myAngleR = 0
      myAngleUp = 0
      targetAngleR = 0
      targetAngleUp = 0

      targetVector =
      makeVector(zeroConvertToWorldCoordinates(Pos1, system), zeroConvertToWorldCoordinates(Pos2, system))
      targetTracker = true

      curTime = system.getUtcTime()

      --local dt1 = math.floor(UTC() - pos1time)
      --local dt2 = math.floor(UTC() - pos2time)
      local lasttime = math.floor(curTime - pos2time)
      local dist1 = pos11:dist(pos22)
      local timeroute = pos2time - pos1time
      tspeed = dist1 / timeroute
      tspeed1 = math.floor((dist1 / timeroute) * 3.6)
      meterMarker1 = (lasttime * tspeed) + tspeed * 4

      --length = SU*200000
      length1 = meterMarker1
      --lengthSU1=math.floor((length1/200000) * 100)/100
      lengthSU1 = string.format("%0.2f", ((length1 / 200000) * 100) / 100)

      meterMarker = (lasttime * calcTargetSpeed) + calcTargetSpeed * 4

      --length = SU*200000
      length = meterMarker
      --lengthSU=math.floor((length/200000) * 100)/100
      lengthSU = string.format("%0.2f", ((length / 200000) * 100) / 100)

      resultVector1 = vectorLengthen(pos11, pos22, length1)
      Waypoint1 = getPos4Vector(resultVector1)

      system.setWaypoint(Waypoint1)

      system.print("The target flew 20 km " .. lengthSU1 .. " su, speed " .. tspeed1 .. " km/h")

      unit.setTimer("marker", 1)
      --system.showScreen(1)
      unit.setTimer("vectorhud", 0.02)
   else
      databank.clear()
      blockTime = 0
      databank.setFloatValue(2, blockTime)
      databank.setFloatValue(4, blockTime)
      pos1 = 0
      pos2 = 0
      lasttime = 0
      pos1time = 0
      pos2time = 0
      meterMarker = 0
      meterMarker1 = 0

      Pos1 = 0
      Pos2 = 0
      privMySignAngleR = 0
      privMySignAngleUp = 0
      privTargetSignAngleR = 0
      privTargetSignAngleUp = 0
      targetVector = vec3.new(0, 0, 0)
      targetTracker = false
      myAngleR = 0
      myAngleUp = 0
      targetAngleR = 0
      targetAngleUp = 0

      system.print("Coordinates are missing set new or export")
   end
end

function inTEXT(unit, system, text)
   if pos1 ~= 0 and string.find(text, "::pos") and pos2 == 0 and exportMode == false then
      --local lasttime = UTCscaner()

      pos2 = text
      databank.setStringValue(3, pos2)
      pos2time = math.floor(system.getUtcTime())
      databank.setFloatValue(4, pos2time)
      system.print(text .. " pos2 saved")

      pos11 = zeroConvertToWorldCoordinates(pos1, system)

      pos22 = zeroConvertToWorldCoordinates(pos2, system)

      local dist1 = pos11:dist(pos22)
      local timeroute = pos2time - pos1time
      tspeed = dist1 / timeroute
      tspeed1 = math.floor((dist1 / timeroute) * 3.6)
      Pos1 = pos1
      Pos2 = pos2

      targetVector =
      makeVector(zeroConvertToWorldCoordinates(Pos1, system), zeroConvertToWorldCoordinates(Pos2, system))
      targetTracker = true

      --length = SU*200000
      --meterMarker = meterMarker + 33333.32
      --meterMarker = meterMarker + calcTargetSpeed*4
      meterMarker1 = meterMarker1 + tspeed * 4
      length1 = meterMarker1

      resultVector1 = vectorLengthen(pos11, pos22, length1)
      Waypoint1 = getPos4Vector(resultVector1)

      system.setWaypoint(Waypoint1)
      meterMarker = meterMarker + calcTargetSpeed * 4
      length = meterMarker

      resultVector = vectorLengthen(pos11, pos22, length)
      Waypoint = getPos4Vector(resultVector)

      --system.setWaypoint(Waypoint)

      system.print("---------------")
      system.print("The coordinates are set manually!")
      posExport1 = databank.getStringValue(1)
      posExport2 = databank.getStringValue(3)
      timeExport1 = math.floor(databank.getFloatValue(2))
      timeExport2 = math.floor(databank.getFloatValue(4))

      system.print("The coordinates were exported to the screen")

      screen.setHTML(posExport1 .. "/" .. timeExport1 .. "/" .. posExport2 .. "/" .. timeExport2)
      system.print("Target speed: " .. tspeed1 .. " km/h")
      unit.setTimer("marker", 1)
      --system.showScreen(1)
      unit.setTimer("vectorhud", 0.02)
   end

   if pos1 == 0 and string.find(text, "::pos") and exportMode == false then
      pos1 = text
      databank.setStringValue(1, pos1)
      pos1time = math.floor(system.getUtcTime())
      databank.setFloatValue(2, pos1time)
      system.print(text .. " pos1 saved")
   end

   if text == "n" then
      unit.stopTimer("marker")
      databank.clear()
      showMarker = true
      blockTime = 0
      databank.setFloatValue(2, blockTime)
      databank.setFloatValue(4, blockTime)
      pos1 = 0
      pos2 = 0
      lasttime = 0
      pos1time = 0
      pos2time = 0
      meterMarker = 0
      meterMarker1 = 0
      SU = 10

      --system.showScreen(0)
      unit.stopTimer("vectorhud")
      vectorHUD = ''
      Pos1 = 0
      Pos2 = 0
      privMySignAngleR = 0
      privMySignAngleUp = 0
      privTargetSignAngleR = 0
      privTargetSignAngleUp = 0
      targetVector = vec3.new(0, 0, 0)
      targetTracker = false
      myAngleR = 0
      myAngleUp = 0
      targetAngleR = 0
      targetAngleUp = 0

      system.print("---------------")
      system.print("Coordinates have been deleted, set new coordinates")
   end

   if exportMode == true and string.find(text, "/") and not string.find(text, "/::pos") then
      unit.stopTimer("marker")
      databank.clear()
      showMarker = true
      blockTime = 0
      databank.setFloatValue(2, blockTime)
      databank.setFloatValue(4, blockTime)
      pos1 = 0
      pos2 = 0
      lasttime = 0
      pos1time = 0
      pos2time = 0
      meterMarker = 0
      meterMarker1 = 0
      SU = 10

      --system.showScreen(0)
      unit.stopTimer("vectorhud")
      vectorHUD = ''
      Pos1 = 0
      Pos2 = 0
      privMySignAngleR = 0
      privMySignAngleUp = 0
      privTargetSignAngleR = 0
      privTargetSignAngleUp = 0
      targetVector = vec3.new(0, 0, 0)
      targetTracker = false
      myAngleR = 0
      myAngleUp = 0
      targetAngleR = 0
      targetAngleUp = 0

      local start = 0
      local fin = string.find(text, "/", start) - 1
      pos1 = string.sub(text, start, fin)
      system.print(pos1)

      start = fin + 2
      fin = string.find(text, "/", start) - 1
      pos1time = tonumber(string.sub(text, start, fin))
      system.print(pos1time)

      start = fin + 2
      fin = string.find(text, "/", start) - 1
      pos2 = string.sub(text, start, fin)
      system.print(pos2)

      start = fin + 2
      fin = string.find(text, "/", start)
      pos2time = tonumber(string.sub(text, start, fin))
      system.print(pos2time)

      system.print("---------------")
      --system.print(pos1.."/"..pos2.."/"..oldTime)
      system.print("The coordinates have been loaded successfully!")
      databank.setStringValue(1, pos1)
      databank.setFloatValue(2, pos1time)
      databank.setStringValue(3, pos2)
      databank.setFloatValue(4, pos2time)

      pos11 = zeroConvertToWorldCoordinates(pos1, system)

      pos22 = zeroConvertToWorldCoordinates(pos2, system)

      Pos1 = pos1
      Pos2 = pos2

      targetVector =
      makeVector(zeroConvertToWorldCoordinates(Pos1, system), zeroConvertToWorldCoordinates(Pos2, system))
      targetTracker = true

      oldTime = tonumber(string.sub(text, start, fin))
      curTime = system.getUtcTime()

      --local dt1 = math.floor(UTC() - pos1time)
      --local dt2 = math.floor(UTC() - pos2time)
      local lasttime = math.floor(curTime - pos2time)
      local dist1 = pos11:dist(pos22)
      local timeroute = pos2time - pos1time
      tspeed = dist1 / timeroute
      tspeed1 = math.floor((dist1 / timeroute) * 3.6)
      meterMarker1 = (lasttime * tspeed) + tspeed * 4

      --length = SU*200000
      length1 = meterMarker1
      --lengthSU1=math.floor((length1/200000) * 100)/100
      lengthSU1 = string.format("%0.2f", ((length1 / 200000) * 100) / 100)

      meterMarker = (lasttime * calcTargetSpeed) + calcTargetSpeed * 4

      --length = SU*200000
      length = meterMarker
      --lengthSU=math.floor((length/200000) * 100)/100
      lengthSU = string.format("%0.2f", ((length / 200000) * 100) / 100)

      resultVector1 = vectorLengthen(pos11, pos22, length1)
      Waypoint1 = getPos4Vector(resultVector1)

      system.setWaypoint(Waypoint1)

      system.print("The target flew " .. lengthSU1 .. " su, speed " .. tspeed1 .. " km/h")

      system.setWaypoint(Waypoint1)
      unit.setTimer("marker", 1)
      --system.showScreen(1)
      unit.setTimer("vectorhud", 0.02)
   end
   if exportMode == true and string.find(text, "/::pos") then
      unit.stopTimer("marker")
      databank.clear()
      showMarker = true
      blockTime = 0
      databank.setFloatValue(2, blockTime)
      databank.setFloatValue(4, blockTime)
      pos1 = 0
      pos2 = 0
      lasttime = 0
      pos1time = 0
      pos2time = 0
      meterMarker = 0
      meterMarker1 = 0
      SU = 10

      --system.showScreen(0)
      unit.stopTimer("vectorhud")
      vectorHUD = ''
      Pos1 = 0
      Pos2 = 0
      privMySignAngleR = 0
      privMySignAngleUp = 0
      privTargetSignAngleR = 0
      privTargetSignAngleUp = 0
      targetVector = vec3.new(0, 0, 0)
      targetTracker = false
      myAngleR = 0
      myAngleUp = 0
      targetAngleR = 0
      targetAngleUp = 0

      local start = 0
      local fin = string.find(text, "/", start) - 1
      pos1 = string.sub(text, start, fin)
      system.print(pos1)

      start = fin + 2
      fin = string.find(text, "/", start) - 1
      pos1time = tonumber(string.sub(text, start, fin))
      system.print(pos1time)

      start = fin + 2
      fin = string.find(text, "/", start) - 1
      pos2 = string.sub(text, start, fin)
      system.print(pos2)

      start = fin + 2
      fin = string.find(text, "/", start)
      pos2time = tonumber(string.sub(text, start, fin))
      system.print(pos2time)

      system.print("---------------")
      --system.print(pos1.."/"..pos2.."/"..oldTime)
      system.print("The coordinates have been loaded successfully!")
      databank.setStringValue(1, pos1)
      databank.setFloatValue(2, pos1time)
      databank.setStringValue(3, pos2)
      databank.setFloatValue(4, pos2time)

      pos11 = zeroConvertToWorldCoordinates(pos1, system)

      pos22 = zeroConvertToWorldCoordinates(pos2, system)

      Pos1 = pos1
      Pos2 = pos2

      targetVector =
      makeVector(zeroConvertToWorldCoordinates(Pos1, system), zeroConvertToWorldCoordinates(Pos2, system))
      targetTracker = true

      oldTime = tonumber(string.sub(text, start, fin))
      curTime = system.getUtcTime()

      --local dt1 = math.floor(UTC() - pos1time)
      --local dt2 = math.floor(UTC() - pos2time)
      local lasttime = math.floor(curTime - pos2time)
      local dist1 = pos11:dist(pos22)
      local timeroute = pos2time - pos1time
      tspeed = dist1 / timeroute
      tspeed1 = math.floor((dist1 / timeroute) * 3.6)
      meterMarker1 = (lasttime * tspeed) + tspeed * 4

      --length = SU*200000
      length1 = meterMarker1
      --lengthSU1=math.floor((length1/200000) * 100)/100
      lengthSU1 = string.format("%0.2f", ((length1 / 200000) * 100) / 100)

      meterMarker = (lasttime * calcTargetSpeed) + calcTargetSpeed * 4

      --length = SU*200000
      length = meterMarker
      --lengthSU=math.floor((length/200000) * 100)/100
      lengthSU = string.format("%0.2f", ((length / 200000) * 100) / 100)

      resultVector1 = vectorLengthen(pos11, pos22, length1)
      Waypoint1 = getPos4Vector(resultVector1)

      system.setWaypoint(Waypoint1)

      system.print("The target flew " .. lengthSU1 .. " su, speed " .. tspeed1 .. " km/h")

      system.setWaypoint(Waypoint1)
      unit.setTimer("marker", 1)
      --system.showScreen(1)
      unit.setTimer("vectorhud", 0.02)
   end
   if string.find(text, "mar") then
      if showMarker == true then
         showMarker = false
         system.print("Current target position - OFF")
      end
      local mar = tonumber((text):sub(4))
      if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
         local length2 = mar * 200000

         local pos123 = databank.getStringValue(1)
         local pos234 = databank.getStringValue(3)

         pos111 = zeroConvertToWorldCoordinates(pos123, system)
         pos222 = zeroConvertToWorldCoordinates(pos234, system)

         local resultVector2 = vectorLengthen(pos111, pos222, length2)
         local Waypoint3 = getPos4Vector(resultVector2)

         system.print(Waypoint3 .. " waypoint " .. mar .. " su")
      end
   end
end

function tickVector(unit, system, text)
   if targetTracker == true and targetVector.x ~= 0 and targetVector.y ~= 0 and targetVector.z ~= 0 then
      local pipeDist = getPipeD(system)
      local worldOrintUp = vec3(core.getConstructWorldOrientationUp()):normalize()
      local worldOrintRight = vec3(core.getConstructWorldOrientationRight()):normalize()
      local worldOrintForw = vec3(core.getConstructWorldOrientationForward()):normalize()
      local mySpeedVectorNorm = vec3(core.getWorldVelocity()):normalize()
      local projectedWorldUp = mySpeedVectorNorm:project_on_plane(worldOrintUp)
      local projectedWorldR = mySpeedVectorNorm:project_on_plane(worldOrintRight)
      local projectedWorldF = mySpeedVectorNorm:project_on_plane(worldOrintForw)

      local myRotateDirR = projectedWorldF:cross(worldOrintUp):normalize()
      myAngleR = projectedWorldUp:angle_between(worldOrintForw)
      local mySignAngleR = utils.sign(myRotateDirR:angle_between(worldOrintForw) - math.pi / 2)
      if mySignAngleR ~= 0 then
         myAngleR = myAngleR * mySignAngleR
         privMySignAngleR = mySignAngleR
      else
         myAngleR = myAngleR * privMySignAngleR
      end

      local myRotateDirUp = projectedWorldR:cross(worldOrintUp):normalize()
      myAngleUp = projectedWorldR:angle_between(-worldOrintUp) - math.pi / 2
      local mySignAngleUp = utils.sign(myRotateDirUp:angle_between(worldOrintRight) - math.pi / 2)
      if mySignAngleUp ~= 0 then
         myAngleUp = myAngleUp * mySignAngleUp
         privMySignAngleUp = mySignAngleUp
      else
         myAngleUp = myAngleUp * privMySignAngleUp
      end
      local targetVectorNorm = targetVector:normalize()

      local targetProjectedWorldUp = targetVectorNorm:project_on_plane(worldOrintUp)
      local targetProjectedWorldR = targetVectorNorm:project_on_plane(worldOrintRight)
      local targetProjectedWorldF = targetVectorNorm:project_on_plane(worldOrintForw)
      local targetRotateDirR = targetProjectedWorldF:cross(worldOrintUp):normalize()
      targetAngleR = targetProjectedWorldUp:angle_between(worldOrintForw)
      local targetSignAngleR = utils.sign(targetRotateDirR:angle_between(worldOrintForw) - math.pi / 2)

      if targetSignAngleR ~= 0 then
         targetAngleR = targetAngleR * targetSignAngleR
         privTargetSignAngleR = targetSignAngleR
      else
         targetAngleR = targetAngleR * privTargetSignAngleR
      end
      local targetRotateDirUp = targetProjectedWorldR:cross(worldOrintUp):normalize()
      targetAngleUp = targetProjectedWorldR:angle_between(-worldOrintUp) - math.pi / 2
      local targetSignAngleUp = utils.sign(targetRotateDirUp:angle_between(worldOrintRight) - math.pi / 2)
      if targetSignAngleUp ~= 0 then
         targetAngleUp = targetAngleUp * targetSignAngleUp
         privTargetSignAngleUp = targetSignAngleUp
      else
         targetAngleUp = targetAngleUp * privTargetSignAngleUp
      end
      --system.print(targetAngleR*rad2deg.. [[ | ]].. targetAngleUp*rad2deg)
      targetVectorWidget =
      [[

      <div class='circle' style='position:absolute;top:85%;left:43%;'>
      <div style='transform: translate(0px, -16px);color:#ffb750;'>]] ..
      string.format("%0.1f", myAngleR * rad2deg) ..
      [[°</div>
      <div style='transform: translate(70px, -35px);color:#f54425;'>]] ..
      string.format("%0.1f", targetAngleR * rad2deg) ..
      [[°</div>
      <div style='transform: translate(20px, 70px);color:#f54425;'>Δ ]] ..
      string.format("%0.1f", myAngleR * rad2deg - targetAngleR * rad2deg) ..
      [[°</div>
      </div>
      <div class='vectorLine' style='top:89.65%;left:43%;background:#ffb750;z-index:30;transform:rotate(]] ..
      myAngleR * rad2deg + 90 ..
      [[deg)'></div>


      <div class='circle' style='position:absolute;top:85%;left:51%;'>
      <div style='transform: translate(0px, -16px);color:#ffb750;'>]] ..
      string.format("%0.1f", myAngleUp * rad2deg) ..
      [[°</div>
      <div style='transform: translate(70px, -35px);color:#f54425;'>]] ..
      string.format("%0.1f", targetAngleUp * rad2deg) ..
      [[°</div>
      <div style='transform: translate(20px, 70px);color:#f54425;'>Δ ]] ..
      string.format(
      "%0.1f",
      myAngleUp * rad2deg - targetAngleUp * rad2deg
      ) ..
      [[°</div>
      </div>
      <div class='vectorLine' style='top:89.65%;left:51%;background:#ffb750;z-index:30;transform:rotate(]] ..
      myAngleUp * rad2deg + 180 ..
      [[deg)'></div>


      <div class='vectorLine' style='top:89.65%;left:43%;background:#f54425;z-index:29;transform:rotate(]] ..
      targetAngleR * rad2deg + 90 ..
      [[deg)'></div>
      <div class='vectorLine' style='top:89.65%;left:51%;background:#f54425;z-index:29;transform:rotate(]] ..
      targetAngleUp * rad2deg + 180 ..
      [[deg)'></div>
      ]]

      html1 =
      [[
      <style>
      .main1 {
         position: fixed;
         width: auto;
         padding: 0.2vw;
         bottom: 3vh;
         left: 49.7%;
         transform: translateX(-50%);
         text-align: center;
         background: #142027;
         color: white;
         font-family: "Lucida" Grande, sans-serif;
         font-size: 1em;
         border-radius: 2vh;
         border: 0.2vh solid;
         border-color: #fca503;
         </style>
         <div class="main1">]] ..
         pipeDist .. [[</div>]]

         style =
         [[
         <style>
         .circle {
            height: 100px;
            width: 100px;
            background-color: #555;
            border-radius: 50%;
            opacity: 0.5
         }     .vectorLine{position:absolute;transform-origin: 100% 0%;width: 50px;height:0.15em;}</style>]]
         --system.setScreen([[<html><head>]] .. style .. [[</head><body>]] .. targetVectorWidget .. [[]] .. html1 .. [[</body></html>]])
         vectorHUD = [[<html><head>]] .. style .. [[</head><body>]] .. targetVectorWidget .. [[]] .. html1 .. [[</body></html>]]
      end
   end

   function tickMarker(unit, system, text)
      if databank.getStringValue(1) ~= "" or databank.getStringValue(3) ~= "" and databank.getFloatValue(2) == 0 or databank.getFloatValue(4) == 0 then

         pos11 = zeroConvertToWorldCoordinates(pos1, system)
         pos22 = zeroConvertToWorldCoordinates(pos2, system)

         meterMarker1 = meterMarker1 + tspeed
         length1 = meterMarker1
         --lengthSU1=math.floor((length1/200000) * 100)/100
         lengthSU1 = string.format("%0.2f", ((length1 / 200000) * 100) / 100)
         resultVector1 = vectorLengthen(pos11, pos22, length1)
         Waypoint1 = getPos4Vector(resultVector1)

         meterMarker = meterMarker + calcTargetSpeed
         length = meterMarker
         --lengthSU=math.floor((length/200000) * 100)/100
         lengthSU = string.format("%0.2f", ((length / 200000) * 100) / 100)
         resultVector = vectorLengthen(pos11, pos22, length)
         Waypoint = getPos4Vector(resultVector)

         if showMarker == true then
            if mmode == true then
               system.setWaypoint(Waypoint1)
               system.print("The target flew " .. lengthSU1 .. " su, speed " .. tspeed1 .. " km/h")
            else
               system.setWaypoint(Waypoint)
               system.print("The target flew " .. lengthSU .. " su, speed " .. targetSpeed .. " km/h")
            end
         end
      end
   end

   function altUP(unit, system, text)
      if lalt == true then
         if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
            showMarker = false
            SU = SU + 2.5
            length = SU * 200000

            pos11 = zeroConvertToWorldCoordinates(pos1, system)
            pos22 = zeroConvertToWorldCoordinates(pos2, system)

            resultVector = vectorLengthen(pos11, pos22, length)
            Waypoint = getPos4Vector(resultVector)

            system.setWaypoint(Waypoint)

            system.print(Waypoint .. " waypoint " .. SU .. " su")
         end
      end
   end

   function altDOWN(unit, system, text)
      if lalt == true then
         if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
            showMarker = false
            SU = SU - 2.5
            length = SU * 200000

            pos11 = zeroConvertToWorldCoordinates(pos1, system)
            pos22 = zeroConvertToWorldCoordinates(pos2, system)

            resultVector = vectorLengthen(pos11, pos22, length)
            Waypoint = getPos4Vector(resultVector)

            system.setWaypoint(Waypoint)

            system.print(Waypoint .. " waypoint " .. SU .. " su")
         end
      end
   end

   function altRIGHT(unit, system, text)
      if lalt == true then
         if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
            showMarker = false
            SU = SU + 10
            length = SU * 200000

            pos11 = zeroConvertToWorldCoordinates(pos1, system)
            pos22 = zeroConvertToWorldCoordinates(pos2, system)

            resultVector = vectorLengthen(pos11, pos22, length)
            Waypoint = getPos4Vector(resultVector)

            system.setWaypoint(Waypoint)

            system.print(Waypoint .. " waypoint " .. SU .. " su")
         end
      end
   end

   function altLEFT(unit, system, text)
      if lalt == true then
         if databank.getStringValue(1) ~= "" and databank.getStringValue(3) ~= "" then
            showMarker = false
            SU = SU - 10
            length = SU * 200000

            pos11 = zeroConvertToWorldCoordinates(pos1, system)
            pos22 = zeroConvertToWorldCoordinates(pos2, system)

            resultVector = vectorLengthen(pos11, pos22, length)
            Waypoint = getPos4Vector(resultVector)

            system.setWaypoint(Waypoint)

            system.print(Waypoint .. " waypoint " .. SU .. " su")
         end
      end
   end

   function GEAR(unit, system, text)
      posExport1 = databank.getStringValue(1)
      posExport2 = databank.getStringValue(3)
      --timeExport1 = tonumber(string.format('%0.0f',databank.getFloatValue(2)))
      --timeExport2 = tonumber(string.format('%0.0f',databank.getFloatValue(2)))
      timeExport1 = math.floor(databank.getFloatValue(2))
      timeExport2 = math.floor(databank.getFloatValue(4))

      system.print("The coordinates were exported to the screen")

      screen.setHTML(posExport1 .. "/" .. timeExport1 .. "/" .. posExport2 .. "/" .. timeExport2)
      --system.logInfo('testLua: ```'..posExport1..'/'..posExport2..'/'..timeExport..'```')
      --screen.activate()
   end

   function radarPos(system,radar)
      local id = radar.getTargetId()
      if id ~= 0 then
         local dist = radar.getConstructDistance(id)
         local forwvector = vec3(system.getCameraWorldForward())
         local worldpos = vec3(system.getCameraWorldPos())
         local p = (dist * forwvector + worldpos)

         if pos1 ~= 0 and pos2 == 0 and exportMode == false then

            pos2 = '::pos{0,0,'..p.x..','..p.y..','..p.z..'}'
            databank.setStringValue(3, pos2)
            pos2time = math.floor(system.getUtcTime())
            databank.setFloatValue(4, pos2time)
            system.print(pos2 .." pos2 saved")

            pos11 = zeroConvertToWorldCoordinates(pos1, system)

            pos22 = zeroConvertToWorldCoordinates(pos2, system)

            local dist1 = pos11:dist(pos22)
            local timeroute = pos2time - pos1time
            tspeed = dist1 / timeroute
            tspeed1 = math.floor((dist1 / timeroute) * 3.6)
            Pos1 = pos1
            Pos2 = pos2

            targetVector =
            makeVector(zeroConvertToWorldCoordinates(Pos1, system), zeroConvertToWorldCoordinates(Pos2, system))
            targetTracker = true

            meterMarker1 = meterMarker1 + tspeed * 4
            length1 = meterMarker1

            resultVector1 = vectorLengthen(pos11, pos22, 6000000)
            Waypoint1 = getPos4Vector(resultVector1)

            system.setWaypoint(Waypoint1)
            meterMarker = meterMarker + calcTargetSpeed * 4
            length = meterMarker

            resultVector = vectorLengthen(pos11, pos22, length)
            Waypoint = getPos4Vector(resultVector)

            system.print("---------------")
            system.print("The coordinates are set manually!")
            posExport1 = databank.getStringValue(1)
            posExport2 = databank.getStringValue(3)
            timeExport1 = math.floor(databank.getFloatValue(2))
            timeExport2 = math.floor(databank.getFloatValue(4))

            system.print("The coordinates were exported to the screen")

            screen.setHTML(posExport1 .. "/" .. timeExport1 .. "/" .. posExport2 .. "/" .. timeExport2)
            system.print("Target speed: " .. tspeed1 .. " km/h")
            --unit.setTimer("marker", 1)
            --system.showScreen(1)
            unit.setTimer("vectorhud", 0.02)
         end

         if pos1 == 0 and exportMode == false then
            pos1 = '::pos{0,0,'..p.x..','..p.y..','..p.z..'}'
            databank.setStringValue(1, pos1)
            pos1time = math.floor(UTCscaner(system))
            databank.setFloatValue(2, pos1time)
            system.print(pos1 .. " pos1 saved")
         end
      end
   end

   start(unit,system,text)

   unit.setTimer("data", 0.1)
   unit.setTimer("delay", 1)

   --clean performance
   if collectgarbages == true then
      unit.setTimer("cleaner",30)
   end
