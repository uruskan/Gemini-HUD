local data = weapon_1.getData()
zone = data:match('"outOfZone":(.-),')
local hitP = tonumber(data:match('"hitProbability":(.-),'))
probil = math.floor(hitP * 100)