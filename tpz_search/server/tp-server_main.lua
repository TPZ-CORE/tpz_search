local TPZ    = exports.tpz_core:getCoreAPI()
local TPZInv = exports.tpz_inventory:getInventoryAPI()

local ProtectedPlayers = {}
local BlacklistedPlayers = {} -- returns the players who are already getting searched by other players.

-----------------------------------------------------------
--[[ Functions  ]]--
-----------------------------------------------------------

-----------------------------------------------------------
--[[ Base Events  ]]--
-----------------------------------------------------------

-- When resource starts, we load all the items from the database
-- The reason is that we want to get their data for displays such as labels.
AddEventHandler('onResourceStart', function(resourceName)
  if (GetCurrentResourceName() ~= resourceName) then
    return
  end
    
  ProtectedPlayers = nil
  BlacklistedPlayers = nil

end)


local ContainsValue = function(table, value)

  if table == nil or #table == 0 then 
    return false
  end

  for _, v in pairs (table) do 

    if v == value then 
      return true 
    end

  end

  return false

end

-----------------------------------------------------------
--[[ Events  ]]--
-----------------------------------------------------------

RegisterServerEvent("tpz_search:server:protect")
AddEventHandler("tpz_search:server:protect", function()
  local _source        = source
  local xPlayer        = TPZ.GetPlayer(_source)
  local charIdentifier = xPlayer.getCharacterIdentifier()

  if not ProtectedPlayers[charIdentifier] then 
    ProtectedPlayers[charIdentifier] = {}
    ProtectedPlayers[charIdentifier].char     = charIdentifier
    ProtectedPlayers[charIdentifier].duration = 0
  end

end)

RegisterServerEvent("tpz_search:server:reset_searched_target")
AddEventHandler("tpz_search:server:reset_searched_target", function(targetId)
  local _tsource = tonumber(targetId)
  BlacklistedPlayers[_tsource] = nil
end)

RegisterServerEvent("tpz_search:server:search")
AddEventHandler("tpz_search:server:search", function(targetId)
  local _source  = source
  local _tsource = tonumber(targetId)

  Wait(math.random(100, 1000))

  local xPlayer         = TPZ.GetPlayer(_source)
  local charIdentifier  = xPlayer.getCharacterIdentifier()
  local xJob            = xPlayer.getJob()

  local isAllowed       = true 

  if Config.SearchByJobsOnly ~= false and TPZ.GetTableLength(Config.SearchByJobsOnly) > 0 then
    isAllowed = ContainsValue(Config.SearchByJobsOnly, xJob)
  end

  if not isAllowed then 
    SendNotification(_source, Locales['NOT_REQUIRED_JOB'].text, 'error', Locales['NOT_REQUIRED_JOB'].duration)
    return 
  end

  local tPlayer         = TPZ.GetPlayer(_tsource)
  local tcharIdentifier = tPlayer.getCharacterIdentifier()
  local tJob            = tPlayer.getJob()

  if ProtectedPlayers[tcharIdentifier] then 

    local hasBypassJob = ContainsValue(Config.NewCharacterSafeDurationJobBypass, xJob)
    
    if not hasBypassJob then 
      SendNotification(_source, Locales['PLAYER_TARGET_UNDER_PROTECTION'].text, 'error', Locales['PLAYER_TARGET_UNDER_PROTECTION'].duration)
      return 
    end

  end

  local isBlacklistedTargetJob = ContainsValue(Config.BlacklistedJobs, tJob)

  if isBlacklistedTargetJob then 
    SendNotification(_source, Locales['PLAYER_TARGET_BLACKLISTED_JOB'].text, 'error', Locales['PLAYER_TARGET_BLACKLISTED_JOB'].duration)
    return 
  end

  if BlacklistedPlayers[_tsource] then 
    SendNotification(_source, Locales['CANNOT_SEARCH_PLAYER_IS_BUSY'].text, 'error', Locales['CANNOT_SEARCH_PLAYER_IS_BUSY'].duration)
    return
  end

  BlacklistedPlayers[_tsource] = 1

  local contents  = tPlayer.getInventoryContents()
  local maxWeight = tPlayer.getInventoryWeightCapacity()

  local new_contents = {}

  local cash, gold, blackmoney = tPlayer.getAccount(0), tPlayer.getAccount(1), tPlayer.getAccount(2)

  if cash > 0 then
    table.insert(new_contents, { type = 0, item = 'cash', label = Locales['CURRENCY_MONEY'], quantity = tPlayer.getAccount(0), weight = 0.0, metadata = {} })   
  end

  if gold > 0 then
    table.insert(new_contents, { type = 1, item = 'gold', label = Locales['CURRENCY_GOLD'], quantity = tPlayer.getAccount(1), weight = 0.0, metadata = {} })
  end
  
  if blackmoney > 0 then
    table.insert(new_contents, { type = 2, item = 'blackmoney', label = Locales['CURRENCY_BLACKMONEY'], quantity = tPlayer.getAccount(2), weight = 0.0, metadata = {} })
  end

  for _, content in pairs (contents) do 

    if Config.BlacklistedItems[content.item] == nil and Config.BlacklistedWeapons[content.item] == nil then 
      table.insert(new_contents, content)
    end

  end

  local data = {
    name      = tonumber(_tsource),
    inventory = new_contents,
    maxWeight = maxWeight,
    busy      = false,
  }

  TriggerClientEvent("tpz_search:client:setSearchingState", _source, true)
  TriggerClientEvent('tpz_inventory:openInventoryContainerByPlayerTarget', _source, _tsource, data, GetPlayerName(_tsource), false, "tpz_search:getPlayerInventoryData")

end)

-----------------------------------------------------------
--[[ Events  ]]--
-----------------------------------------------------------

if Config.NewCharacterSafeDuration > 0 then 

  Citizen.CreateThread(function()
  
    while true do 

      Wait(60000)

      if TPZ.GetTableLength(ProtectedPlayers) > 0 then

        for _, player in pairs (ProtectedPlayers) do 

          player.duration = player.duration + 1

          if player.duration >= Config.NewCharacterSafeDuration then 
            ProtectedPlayers[player.char] = nil
          end
    
        end

      end

    end

  end)

end

