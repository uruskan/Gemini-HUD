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

--Solo remote controller
HUD_version = '1.0.0'

--LUA parameters

--vars
atlas = require("atlas")
stellarObjects = atlas[0]
shipPos = vec3(construct.getWorldPosition())
safeWorldPos = vec3({13771471,7435803,-128971})

AMstrokeWidth = 1
EMstrokeWidth = 1
THstrokeWidth = 1
KIstrokeWidth = 1

--shield
damageLine = ''
ccsLineHit = ''
damage = 0
maxSHP = 210 --svg shield X right side coordinate
shieldMaxHP = shield.getMaxShieldHitpoints()
last_shield_hp = shield.getShieldHitpoints()
HP = shield.getShieldHitpoints()/shieldMaxHP * 100
svghp = maxSHP * (HP * 0.01)

--CCS
ccshit = 0
maxCCS = 139.5
coreMaxStress = core.getmaxCoreStress()
last_core_stress = core.getCoreStress()
CCS = last_core_stress/coreMaxStress * 100
ccshp1 = maxCCS * (CCS * 0.01)
ccshp = ccshp1

--FUEL
maxFUEL = maxCCS
FUEL_svg = maxFUEL * (Fuel_lvl * 0.01)

AM_last_stress = 0
EM_last_stress = 0
TH_last_stress = 0
KI_last_stress = 0
AM_svg = 0
EM_svg = 0
TH_svg = 0
KI_svg = 0
AM_stroke_color = 'rgb(66, 167, 245)'
EM_stroke_color = 'rgb(66, 167, 245)'
TH_stroke_color = 'rgb(66, 167, 245)'
KI_stroke_color = 'rgb(66, 167, 245)'

local stress = shield.getStressRatioRaw()
AM_stress = stress[1]
EM_stress = stress[2]
KI_stress = stress[3]
TH_stress = stress[4]

function damage_SVG()
   if damage > 0 then
      damage = damage - 0.1
      damageLine = [[<rect x="]].. svghp + 145 ..[[" y="225" width="]]..damage..[[" height="50" style="fill: #de1656; stroke: #de1656;" bx:origin="0.5 0.5"/>]]
   end
   if damage <= 0 then
      damage = 0
      damageLine = ''
   end

   if ccshit > 0 then
      ccshp = ccshp + 0.25
      if ccshp >= ccshp1 then
         ccshp = ccshp1
         ccsLineHit = ''
         ccshit = 0
      end
   end
end

function ccs_SVG()
   --AM
   if AM_stress ~= AM_last_stress then
      AM_last_stress = AM_stress
   end
   if AM_svg < AM_last_stress then
      AM_svg = AM_svg + 0.01
      if AM_svg >= AM_stress then AM_svg = AM_stress
   end
end
if AM_svg > AM_last_stress then
   AM_svg = AM_svg - 0.01
   if AM_svg <= AM_stress then AM_svg = AM_stress end
end
--EM
if EM_stress ~= EM_last_stress then
   EM_last_stress = EM_stress
end
if EM_svg < EM_last_stress then
   EM_svg = EM_svg + 0.01
   if EM_svg >= EM_stress then EM_svg = EM_stress end
end
if EM_svg > EM_last_stress then
   EM_svg = EM_svg - 0.01
   if EM_svg <= EM_stress then EM_svg = EM_stress end
end
--TH
if TH_stress ~= TH_last_stress then
   TH_last_stress = TH_stress
end
if TH_svg < TH_last_stress then
   TH_svg = TH_svg + 0.01
   if TH_svg >= TH_stress then TH_svg = TH_stress end
end
if TH_svg > TH_last_stress then
   TH_svg = TH_svg - 0.01
   if TH_svg <= TH_stress then TH_svg = TH_stress end
end
--KI
if KI_stress ~= KI_last_stress then
   KI_last_stress = KI_stress
end
if KI_svg < KI_last_stress then
   KI_svg = KI_svg + 0.01
   if KI_svg >= KI_stress then KI_svg = KI_stress end
end
if KI_svg > KI_last_stress then
   KI_svg = KI_svg - 0.01
   if KI_svg <= KI_stress then KI_svg = KI_stress end
end
end

function setTag(tag)
local tag = tag:sub(5)
system.print('Activated new transponder tag "'..tag..'"')
tag = {tag}
transponder.setTags(tag)
end

function zeroConvertToWorldCoordinates(pos)
local num  = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}'
local systemId, bodyId, latitude, longitude, altitude = string.match(pos, posPattern)

if systemId==nil or bodyId==nil or latitude==nil or longitude==nil or altitude==nil then
   system.print("Invalid pos!")
   destination_bm=""
   return vec3()
end

if (systemId == "0" and bodyId == "0") then
   --convert space bm
   return vec3(latitude,
   longitude,
   altitude)
end
longitude = math.rad(longitude)
latitude = math.rad(latitude)
local planet = atlas[tonumber(systemId)][tonumber(bodyId)]
local xproj = math.cos(latitude);
local planetxyz = vec3(xproj*math.cos(longitude),
xproj*math.sin(longitude),
math.sin(latitude));
return vec3(planet.center) + (planet.radius + altitude) * planetxyz
end

if db.getStringValue(15) ~= "" then
asteroidPOS = db.getStringValue(15)
else
asteroidPOS = ''
end
markerName = "Asteroid" --export:
if markerName == "" then markerName = "Asteroid" end
asteroidcoord = {}
if asteroidPOS ~= "" then
asteroidcoord = zeroConvertToWorldCoordinates(asteroidPOS)
else
asteroidcoord = {0,0,0}
end

--icons
local icons = {}
function iconStatusCheck(status)
if status == 'on' or status == 1 then
   return 'on'
else
   return ''
end
end

function icons.space(status)
return [[<svg class="icon ]] .. iconStatusCheck(status) .. [[" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 197.6 107.43">
<path class="a" d="M197.19,25.35c-4.31-15-38.37-12.36-60-9.09A53.64,53.64,0,0,0,46.29,42.48C26.28,51.21-3.9,67.12.42,82.08,2.81,90.36,14.68,93.74,31.3,93.74a197.4,197.4,0,0,0,29.09-2.56A53.64,53.64,0,0,0,151.31,65C179.87,52.59,200.82,37.94,197.19,25.35Zm-98.38-16A44.44,44.44,0,0,1,143.2,53.71,45.3,45.3,0,0,1,143,58.4a363,363,0,0,1-38.9,13.51,361.77,361.77,0,0,1-40,9.27A44.32,44.32,0,0,1,98.81,9.32ZM9.37,79.5c-.83-2.89,7.34-13.18,35.74-26.27,0,.16,0,.32,0,.48a53.27,53.27,0,0,0,8.58,29C26.33,86.24,10.55,83.58,9.37,79.5ZM98.81,98.11a44.13,44.13,0,0,1-26.65-9c11.34-2.18,23.07-5,34.47-8.28s22.84-7.12,33.6-11.31A44.43,44.43,0,0,1,98.81,98.11ZM152.5,54.2c0-.16,0-.32,0-.49a53.34,53.34,0,0,0-8.56-29c31-4.05,43.45.32,44.28,3.2C189.42,32,177.43,42.64,152.5,54.2Z" />
</svg>
]]
end

function icons.marker(status)
return [[<svg class="icon ]] .. iconStatusCheck(status) .. [[" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 148.21 197.07">
<path class="a" d="M74.1,42.8a31.32,31.32,0,1,0,31.32,31.32A31.35,31.35,0,0,0,74.1,42.8Zm0,52A20.73,20.73,0,1,1,94.83,74.1,20.75,20.75,0,0,1,74.1,94.83Z" />
<path class="a" d="M74.12,0A74.21,74.21,0,0,0,0,74.13c0,18.39,6.93,32.36,18.88,50.26,12.45,18.7,49.42,68.42,51,70.54a5.28,5.28,0,0,0,8.49,0c1.57-2.11,38.53-51.84,51-70.53,11.95-17.9,18.88-31.87,18.88-50.26A74.18,74.18,0,0,0,74.12,0Zm46.42,118.51c-9.84,14.77-36.1,50.4-46.42,64.36-10.33-14-36.59-49.59-46.43-64.36-12.78-19.15-17.1-30.35-17.1-44.39a63.53,63.53,0,1,1,127,0C137.64,88.16,133.32,99.36,120.54,118.51Z" />
</svg>
]]
end

function icons.ship(status)
return [[<svg class="icon ]] .. iconStatusCheck(status) .. [[" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 196.27 188.83">
<path class="a" d="M183.91,132c-11.23-12.44-48.54-50.86-55.11-57.61V45.16C128.8,13.89,106.58,0,98.14,0S67.47,13.89,67.47,45.16V74.43C60.91,81.18,23.6,119.6,12.36,132-.2,146-.06,162.53,0,170.49v1.41a3.8,3.8,0,0,0,3.8,3.8H57.45a40.18,40.18,0,0,1-5.55,6.53,3.8,3.8,0,0,0,2.58,6.6H141.8a3.8,3.8,0,0,0,2.57-6.6,39.67,39.67,0,0,1-5.54-6.53h53.62a3.8,3.8,0,0,0,3.8-3.8v-1.41C196.33,162.53,196.47,146,183.91,132ZM98.14,7.61c3.91,0,23.06,10.23,23.06,37.55v90.08H75.08V45.16C75.08,17.84,94.22,7.61,98.14,7.61Zm8.8,135.23,7.14,38.39H82.19l7.14-38.39ZM7.61,168.1c0-7.87.84-20.37,10.4-31,9.31-10.31,36.81-38.75,49.46-51.79v60.27c0,7.76-2.34,15.68-5.64,22.48Zm67.47-22.48v-2.78H81.6l-7.14,38.39H62.86C69.54,172.09,75.08,158.76,75.08,145.62Zm46.73,35.6-7.14-38.38h6.53v2.78c0,13.14,5.53,26.47,12.22,35.6Zm12.64-13.12c-3.31-6.8-5.65-14.72-5.65-22.48V85.35c12.65,13,40.15,41.48,49.46,51.79,9.57,10.6,10.38,23.09,10.41,31Z" />
</svg>
]]
end

function icons.player(status)
return [[<svg class="icon ]] .. iconStatusCheck(status) .. [[" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 63.36 198">
<circle class="a" cx="31.68" cy="17.82" r="17.82" />
<path class="a" d="M43.56,41.58H19.8A19.86,19.86,0,0,0,0,61.38v45.54A19.85,19.85,0,0,0,11.88,125v57.12A15.89,15.89,0,0,0,27.72,198h7.92a15.89,15.89,0,0,0,15.84-15.84V125a19.85,19.85,0,0,0,11.88-18.12V61.38A19.86,19.86,0,0,0,43.56,41.58Z" />
</svg>
]]
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

function calcDistance(origCenter, destCenter, location)
local pipe = (destCenter - origCenter):normalize()
local r = (location-origCenter):dot(pipe) / pipe:dot(pipe)
if r <= 0. then
   return (location-origCenter):len()
elseif r >= (destCenter - origCenter):len() then
   return (location-destCenter):len()
end
local L = origCenter + (r * pipe)
pipeDistance =  (L - location):len()

return pipeDistance
end

function calcDistanceStellar(stellarObjectOrigin, stellarObjectDestination, currenLocation)
local origCenter = vec3(stellarObjectOrigin.center)
local destCenter = vec3(stellarObjectDestination.center)

return calcDistance(origCenter, destCenter, currenLocation)
end

function closestPipe()
while true do
   local smallestDistance = nil;
   local nearestPlanet = nil;
   local i = 0
   for obj in pairs(stellarObjects) do
      i = i + 1
      if (stellarObjects[obj].type[1] == 'Planet' or stellarObjects[obj].isSanctuary == true) then
         local planetCenter = vec3(stellarObjects[obj].center)
         local distance = vec3(shipPos - planetCenter):len()

         if (smallestDistance == nil or distance < smallestDistance) then
            smallestDistance = distance;
            nearestPlanet = obj;
         end
      end
      if i > 30 then
         i = 0
         coroutine.yield()
      end
   end
   i = 0
   closestPlanet = stellarObjects[nearestPlanet]
   nearestPipeDistance = nil
   nearestAliothPipeDistance= nil
   for obj in pairs(stellarObjects) do
      if (stellarObjects[obj].type[1] == 'Planet' or stellarObjects[obj].isSanctuary == true) then
         for obj2 in pairs(stellarObjects) do
            i = i + 1
            if (obj2 > obj and (stellarObjects[obj2].type[1] == 'Planet' or stellarObjects[obj2].isSanctuary == true)) then
               pipeDistance = calcDistanceStellar(stellarObjects[obj], stellarObjects[obj2], shipPos)
               if nearestPipeDistance == nil or pipeDistance < nearestPipeDistance then
                  nearestPipeDistance = pipeDistance;
                  sortestPipeKeyId = obj;
                  sortestPipeKey2Id = obj2;
               end
               if stellarObjects[obj].name[1] == "Alioth" and (nearestAliothPipeDistance == nil or pipeDistance < nearestAliothPipeDistance) then
                  nearestAliothPipeDistance = pipeDistance;
                  sortestAliothPipeKeyId = obj;
                  sortestAliothPipeKey2Id = obj2;
               end
            end
            if i > 30 then
               i = 0
               coroutine.yield()
            end
         end
      end
   end
end
end

--2D Planet radar and AR planets
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
DisplayRadar = false
function drawonradar(coordonate,PlaneteName)
local constructUp = vec3(construct.getWorldOrientationUp())
local constructForward = vec3(construct.getWorldOrientationForward())
local constructRight = vec3(construct.getWorldOrientationRight())
local ConstructWorldPos = shipPos
local ToCible=coordonate-ConstructWorldPos
local Xcoord = mySignedAngleBetween(ToCible, constructForward, constructUp)/math.pi --*RadarR
local Ycoord = mySignedAngleBetween(ToCible, constructForward, constructRight)/math.pi --*RadarR+RadarY
local XcoordR=Xcoord*math.sqrt(1-Ycoord*Ycoord/2)*RadarR+RadarX
local YcoordR=Ycoord*math.sqrt(1-Xcoord*Xcoord/2)*RadarR+RadarY
svgradar=svgradar..string.format([[
<circle cx="%f" cy="%f" r="4" fill="red" />
<text x="%f" y="%f" font-size="12px" fill="yellow">%s</text>
]],XcoordR,YcoordR,XcoordR+4,YcoordR,PlaneteName)
end

function mySignedAngleBetween(vecteur1, vecteur2, planeNormal)

local normVec1 = vecteur1:project_on_plane(planeNormal):normalize()
local normVec2 = vecteur2:normalize()

local angle = math.acos(normVec1:dot(normVec2))
local crossProduct = vecteur1:cross(vecteur2)

if crossProduct:dot(planeNormal) < 0 then
   return -angle
else
   return angle
end
end

playerName = system.getPlayerName(unit.getMasterPlayerId())
xDelta = -238
yDelta = -108
mapScale = .99999
planetScale = 1200
aliothsize = 8000
moonScale = 3000
map = 0
warpScan = 0
targetList = ''
altb=false
safew=''
function pD()
pipeD = ''
if nearestPipeDistance >= 100000 then
   pipeD = ''..string.format('%0.2f', nearestPipeDistance/200000)..' su'
elseif nearestPipeDistance >= 1000 and nearestPipeDistance < 100000 then
   pipeD = ''..string.format('%0.1f', nearestPipeDistance/1000)..' km'
else
   pipeD = ''..string.format('%0.0f', nearestPipeDistance)..' m'
end
if nearestPipeDistance >= 600000 then
   return closestPipeData.value.. '<br>' .. '<greencolor1>'..pipeD..'</greencolor1>'
elseif nearestPipeDistance >= 400000 and nearestPipeDistance <= 600000 then
   return closestPipeData.value.. '<br>' .. '<orangecolor>'..pipeD..'</orangecolor>'
elseif nearestPipeDistance < 400000 then
   return closestPipeData.value.. '<br>' .. '<redcolor1>'..pipeD..'<redcolor1>'
end
end

shipName = core.getConstructName()
conID = (""..core.getConstructId()..""):sub(-3)
bhelper = false
system.showHelper(0)
distS = ''
safetext=''
szsafe=true
tz1=0
tz2=0

function indexSort(tbl)
local idx = {}
for i = 1, #tbl do idx[i] = i end
table.sort(idx, function(a, b) return tbl[a] > tbl[b] end)
return (table.unpack or unpack)(idx)
end

function getResRatioBy2HighestDamage(stress)
local resRatio = {0,0,0,0}
local h1, h2 = indexSort(stress)
if stress[h2] > 0 then
   resRatio[h1] = resMAX/2
   resRatio[h2] = resMAX/2
else
   resRatio[h1] = resMAX
end
return resRatio
end

lalt=false
buttonC=false
buttonSpace=false
--stress = {0,0,0,0}
resMAX = shield.getResistancesPool()
function getRes(stress, resMAX)
local res = {0.15,0.15,0.15,0.15}
if stress[1] >= stress[2] and
stress[1] >= stress[3] and
stress[1] > stress[4] then
   res = {resMAX,0,0,0}
elseif stress[2] >= stress[1] and
   stress[2] >= stress[3] and
   stress[2] > stress[4] then
      res = {0,resMAX,0,0}
   elseif stress[3] >= stress[1] and
      stress[3] >= stress[2] and
      stress[3] > stress[4] then
         res = {0,0,resMAX,0}
      elseif stress[4] >= stress[1] and
         stress[4] >= stress[2] and
         stress[4] > stress[3] then
            res = {0,0,0,resMAX}
         else
            system.print("ERR1")
         end
         return res
      end
      shoteCount = 0
      lastShotTime = system.getTime()
      Shield_Auto_Calibration = true --export: (AUTO/MANUAL) shield mode
      Shield_Calibration_Max = true --export: (MAX/50) calibration of the entire shield power by the largest resist based on DPS
      Departure__Planet = 'Alioth' --export: Departure ID planet
      Destination_Planet = 'Jago' --export: Destination ID planet
      collectgarbages = true --export:
      local GHUD_Background_Color = "#142027" --export: Backgroung color CFCS system
      local GHUD_PipeText_Color = "#FFFFFF" --export: Pipe text color
      local GHUD_PipeY = -0.1 --export:
      local GHUD_PipeX = 15.5 --export:
      local GHUD_Y = 50 --export:
      local GHUD_TextY = 12 --export:
      local GHUD_RightBlock_X = 30 --export:
      local GHUD_LeftBlock_X = 12 --export:
      resCLWN = ""
      ventCLWN = ""
      if Shield_Auto_Calibration
      then
         if Shield_Calibration_Max then
            shieldText = "SHIELD (AUTO,MAX)"
         end
         if not Shield_Calibration_Max then
            shieldText = "SHIELD (AUTO,50)"
         end
      else
         if Shield_Calibration_Max then
            shieldText = "SHIELD (MANUAL,MAX)"
         end

         if not Shield_Calibration_Max then
            shieldText = "SHIELD (MANUAL,50)"
         end
      end

      brakeText = ""
      if shield.getState() == 0 then
         shieldColor = "#fc033d"
      else
         shieldColor = "#2ebac9"
      end

      resisttime = 0
      venttime = 0
      venttimemax = shield.getVentingMaxCooldown()
      resisttimemax = shield.getResistancesMaxCooldown()

      local data2=shield.getResistances()
      AMres = math.floor(data2[1]/resMAX*100)
      EMres = math.floor(data2[2]/resMAX*100)
      KIres = math.floor(data2[3]/resMAX*100)
      THres = math.floor(data2[4]/resMAX*100)
--needs nil check (planet)
      DepartureCenter = vec3(stellarObjects[Departure_export].center)
      DestinationCenter = vec3(stellarObjects[Destination_export].center)
      DepartureCenterName = stellarObjects[Departure_export].name[1]
      DestinationCenterName = stellarObjects[Destination_export].name[1]
      mybr=false
--needs redesign
      html1 = [[
      <style>
      .main1 {
         position: fixed;
         width: 11em;
         padding: 1vh;
         top: 1vh;
         left: 50%;
         transform: translateX(-50%);
         text-align: center;
         background: #142027;
         color: white;
         font-family: "Lucida" Grande, sans-serif;
         font-size: 1.5em;
         border-radius: 5vh;
         border: 0.2vh solid;
         border-color: #fca503;
         </style>
         <div class="main1">BRAKE ENGAGED</div>]]
         dis=0
         accel=0
         resString = ""
         throttle1=0
         fuel1=0

         blink=1
         shieldAlarm = false
         alarmTimer = false
         t2=nil

         main1 = coroutine.create(closestPipe)

         transponder.deactivate() --transponder server bug fix
         unit.setTimer('tr',2)

         unit.setTimer("hud",0.02)
