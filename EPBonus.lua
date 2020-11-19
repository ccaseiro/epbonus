-- TODO: option to filter/show by time remaining
local DEBUG = false

SLASH_EPBONUS1 = "/epbonus"

local bonus = {
  SF = 4,
  DMT = 3,
  HOH = 2,
  ONY = 1,
  DMF = 1,
  WAR = 0
}

local abbrev = {
  [15366] = "SF",  -- Songflower Serenade
  [22818] = "DMT", -- Mol'dar's Moxie
  [22817] = "DMT", -- Fengus' Ferocity
  [22820] = "DMT", -- Slip'kik's Savvy
  [24425] = "HOH", -- Spirit of Zandalar
  [22888] = "ONY", -- Rallying Cry of the Dragonslayer
  [23735] = "DMF", -- Sayge's Dark Fortune of Strength
  [23736] = "DMF", -- Sayge's Dark Fortune of Agility
  [23737] = "DMF", -- Sayge's Dark Fortune of Stamina
  [23738] = "DMF", -- Sayge's Dark Fortune of Spirit
  [23766] = "DMF", -- Sayge's Dark Fortune of Intelligence
  [23767] = "DMF", -- Sayge's Dark Fortune of Armor
  [23768] = "DMF", -- Sayge's Dark Fortune of Damage
  [23769] = "DMF", -- Sayge's Dark Fortune of Resistance
  [16609] = "WAR", -- Warchief's Blessing
}

local function debug(message)
  if DEBUG then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r "..message)
  end
end

local function log(message)
  DEFAULT_CHAT_FRAME:AddMessage(message)
end


local function ep_for_target(unit, config)
  local target_name = UnitName(unit)

  if not target_name then
    return nil
  end

  local _, englishClass, _ = UnitClass(unit);

  if (config.unit == "<class>" and config.class ~= englishClass) then
    return nil
  end

  local isOnline = UnitIsConnected(unit)
  if not isOnline then
    -- local message = config.color_name..target_name..config.color_reset..": "..config.color_offline.."OFFLINE"..config.color_reset
    local reason = "OFFLINE"
    local message = config.color_offline.."OFFLINE"..config.color_reset
    return target_name, nil, reason, message
  end

  local buffs = {};
  local i = 1

  local buff,_,_,_,_,_,_,_,_,buffid = UnitBuff(unit, i);
  local sum = 0
  local tmp = {}
  while buff do
    local buff_abbrev = abbrev[buffid]
    if buff_abbrev then
      tmp[buff_abbrev] = bonus[buff_abbrev]
    end
    i = i + 1;
    buff,_,_,_,_,_,_,_,_,buffid = UnitBuff(unit, i);
  end;

  for k,v in pairs(tmp) do
    sum = sum + v
    if config.show_buff_abbrev and config.show_buff_bonus then
      buffs[#buffs + 1] = k.." ("..v..")"
    elseif config.show_buff_abbrev then
      buffs[#buffs + 1] = k
    else
      buffs[#buffs + 1] = v
    end
  end

  -- local message = config.color_name..target_name..config.color_reset..": " .. sum
  local message = ""
  -- local message = string.format("%-20s: %5d", target_name, sum)
  if #buffs >= 1 and (config.show_buff_bonus or config.show_buff_abbrev) then
    buffs = table.concat(buffs, " + ");
    -- message = message .. config.color_buffs .." = "..buffs
    message = message .. config.color_buffs..buffs
  end;
  return target_name, sum, "BUFF", message
  -- return message
end


local function show_message(message, config)
  if message then
    if config.action == "guild" or config.action == "add" then
      SendChatMessage(message, "guild")
    elseif config.action == "raid" then
      local raid_or_party = IsInRaid() and "raid" or "party"
      SendChatMessage(message, raid_or_party)
    else
      DEFAULT_CHAT_FRAME:AddMessage(message)
    end
  end
end

local function action_for(name, ep, reason, message, config)
  -- debug("Reason:"..reason.." message:"..message)
  if message then
    if config.action == "add" then
      local m = ""
      if reason == "OFFLINE" then
        m = "OFFLINE"
      elseif ep > 0 then
        m = "Buffs: "..message
      else
        m = "Buffs: None"
      end
      CEPGP_addEP(name, (ep or 0), m) 
    else
      local full_message = config.color_name..name..config.color_reset..": "..(ep or "")..config.color_buffs..((not ep or ep == 0) and "" or " = ")..message..config.color_reset
      show_message(full_message, config)
    end
  end
end

local function show_help()
  message = [[
EPBonus usage: |cFF00FF00 /epbonus |cFFFFFF00[<unit>] [<action>]|r
|cFFFFFF00<unit>|r (default: "|cFF00FF00all|r"):
    |cFF00FF00all|r - show information for all players (|cFFFFFF00default|r)
    |cFF00FF00target|r - show information for selected target
    |cFF00FF00|cFFFFFF00<class>|r - show information for specified class
|cFFFFFF00<action>|r (default: "|cFF00FF00show|r"):
    |cFF00FF00show|r - show in default chat frame (|cFFFFFF00default|r)
    |cFF00FF00raid|r - announce in raid channel
    |cFF00FF00guild|r - announce in guild channel
    |cFF00FF00add|r - update CEPGP (announce in CEPGP "Reporting Channel")
Example: |cFF00FF00/epbonus mage raid|r - announce bonus of all mages in raid channel]]
  DEFAULT_CHAT_FRAME:AddMessage(message)
end


local function epbonus(args)
  local command, arg1 = strsplit(" ", args:lower())

  local config = {
    show_buff_bonus = false,
    show_buff_abbrev = true,
    color_name = "|cFFFFFF00",
    color_buffs = "|cFF888888",
    color_offline = "|cFFFF0000",
    color_reset = "|r",
    class = nil,
    unit = nil,
    action = nil
  }

  if not command or command == "" then
  elseif command == "help" then
    show_help()
    return
  elseif not config.unit and command == "all" then
    config.unit = command
  elseif not config.action and command == "show" then
    config.action = command
  elseif not config.action and (command == "raid" or command == "guild" or command == "add") then
    config.action = command
    config.color_name = ""
    config.color_buffs = ""
    config.color_offline = ""
    config.color_reset = ""
  elseif not config.unit and (command == "target") then
    config.unit = command
  elseif not config.unit and (command == "warrior" or command == "paladin" or command == "hunter" or command == "rogue"
    or command == "priest" or command == "deathknight" or command == "shaman" or command == "mage"
    or command == "warlock" or command == "monk" or command == "druid" or command == "demonhunter")
    then
    config.unit = "<class>"
    config.class = command
  else
    log("|cFFFF0000invalid command: |cFF00FF00/epbonus "..args.."|r")
    show_help()
    return
  end

  command = arg1
  arg1 = nil

  if not command or command == "" then
  elseif command == "help" then
    show_help()
    return
  elseif not config.unit and command == "all" then
    config.unit = command
  elseif not config.action and command == "show" then
    config.action = command
  elseif not config.action and (command == "raid" or command == "guild" or command == "add") then
    config.action = command
    config.color_name = ""
    config.color_buffs = ""
    config.color_offline = ""
    config.color_reset = ""
  elseif not config.unit and (command == "target") then
    config.unit = command
    config.target = true
    config.show_buff_bonus = true
    config.show_buff_abbrev = true
  elseif not config.unit and (command == "warrior" or command == "paladin" or command == "hunter" or command == "rogue"
    or command == "priest" or command == "deathknight" or command == "shaman" or command == "mage"
    or command == "warlock" or command == "monk" or command == "druid" or command == "demonhunter")
    then
    config.unit = "<class>"
    config.class = command
  else
    log("|cFFFF0000invalid command: |cFF00FF00/epbonus "..args.."|r")
    show_help()
    return
  end


  config.unit = config.unit and config.unit:lower() or "all"
  config.action = config.action and config.action:lower() or "show"
  config.class = config.class and config.class:upper()

  debug("Unit: '"..config.unit.."'")
  debug("Action: '"..config.action.."'")
  debug("Class: '"..(config.class or "").."'")

  if config.unit == "target" then
    local name, ep, reason, message = ep_for_target("target", config)
    if message then
      action_for(name, ep, reason, message, config)
    else
      log("|cFFFF0000Need to select target first|r")
    end
    return
  end

  local raid_or_party = IsInRaid() and "raid" or "party"

  local number_of_members = GetNumGroupMembers()
  show_message(config.color_buffs.."== Class: "..(config.class or config.unit).." ==", config)
  if IsInRaid() then
    for p=1,number_of_members do
      local name, ep, reason, message = ep_for_target("raid"..p, config)
      action_for(name, ep, reason,message, config)
    end
  else
    -- "party" does not includes "player" (it's from 1..4), so we need to handle it manualy
    local name, ep, reason, message = ep_for_target("player", config)
    action_for(name, ep, reason, message, config)
    for p=1,number_of_members-1 do
      name, ep, reason, message = ep_for_target("party"..p, config)
      action_for(name, ep, reason, message, config)
    end
  end
  show_message(config.color_buffs.."==================", config)
end


SlashCmdList["EPBONUS"] = epbonus
