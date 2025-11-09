local TPZ = exports.tpz_core:getCoreAPI()

-----------------------------------------------------------
--[[ Functions  ]]--
-----------------------------------------------------------

exports.tpz_core:getCoreAPI().addNewCallBack("tpz_search:getPlayerInventoryData", function(source, cb, data)

  local target  = tonumber(data.target)
  local tPlayer = TPZ.GetPlayer(tonumber(target))
  
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

  return cb(data)

end)