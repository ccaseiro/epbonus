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


local function ep_for_target(target, config)
  local target_name = UnitName(target)

  if not target_name then
    return nil
  end

  local _, englishClass, _ = UnitClass(target);

  if config.class ~= "ALL" and config.class ~= englishClass then
    return nil
  end

  local isOnline = UnitIsConnected(target)
  if not isOnline then
    return config.color_name..target_name..config.color_reset..": "..config.color_offline.."OFFLINE"..config.color_reset
  end

  local buffs = {};
  local i = 1

  local buff,_,_,_,_,_,_,_,_,buffid = UnitBuff(target, i);
  local sum = 0
  local tmp = {}
  while buff do
    local buff_abbrev = abbrev[buffid]
    if buff_abbrev then
      tmp[buff_abbrev] = bonus[buff_abbrev]
    end
    i = i + 1;
    buff,_,_,_,_,_,_,_,_,buffid = UnitBuff(target, i);
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

  local message = config.color_name..target_name..config.color_reset..": " .. sum
  -- local message = string.format("%-20s: %5d", target_name, sum)
  if #buffs >= 1 and (config.show_buff_bonus or config.show_buff_abbrev) then
    buffs = table.concat(buffs, " + ");
    message = message .. config.color_buffs .." = "..buffs
  end;
  return message
end


local function log(message)
  DEFAULT_CHAT_FRAME:AddMessage(message)
end


local function show_message(message, config)
  if message then
    if config.announce == "guild" then
      SendChatMessage(message, "guild")
    elseif config.announce == "raid" then
      local raid_or_party = IsInRaid() and "raid" or "party"
      SendChatMessage(message, raid_or_party)
    else
      DEFAULT_CHAT_FRAME:AddMessage(message)
    end
  end
end

function show_help()
  message = [[
EPBonus usage: |cFF00FF00 /epbonus |cFFFFFF00[<unit>] [<chat>]|r
|cFFFFFF00<unit>|r (default: "|cFF00FF00all|r"):
  |cFF00FF00/epbonus all|r - show information for all players (|cFFFFFF00default|r)
  |cFF00FF00/epbonus target|r - show information for selected target
  |cFF00FF00/epbonus |cFFFFFF00<class>|r - show information for specified class
|cFFFFFF00<chat>|r (default: "|cFF00FF00show|r"):
  |cFF00FF00/epbonus show|r - show in default chat frame (|cFFFFFF00default|r)
  |cFF00FF00/epbonus raid|r - announce in raid channel
  |cFF00FF00/epbonus guild|r - announce in guild channel
Example: |cFF00FF00/epbonus mage raid|r - announce bonus of all mages in raid channel]]
  DEFAULT_CHAT_FRAME:AddMessage(message)
end


SlashCmdList["EPBONUS"] = function(args)
  local command, arg1 = strsplit(" ", args:lower())

  local config = {
    announce = nil,
    show_buff_bonus = false,
    show_buff_abbrev = true,
    color_name = "|cFFFFFF00",
    color_buffs = "|cFF888888",
    color_offline = "|cFFFF0000",
    color_reset = "|r",
    class = "ALL",
    target = false
  }

  if not command or command == "" or command == "all" or command == "show" then
    config.class = "ALL"
  elseif command == "help" then
    show_help()
    return
  elseif command == "raid" or command == "guild" then
    config.announce = command
    config.color_name = ""
    config.color_buffs = ""
    config.color_offline = ""
    config.color_reset = ""
  elseif command == "target" then
    config.show_buff_bonus = true
    config.show_buff_abbrev = true
    config.target = true
  elseif command == "warrior" or command == "paladin" or command == "hunter" or command == "rogue"
    or command == "priest" or command == "deathknight" or command == "shaman" or command == "mage"
    or command == "warlock" or command == "monk" or command == "druid" or command == "demonhunter"
    then
    config.class = command:upper()
  else
    log("|cFFFF0000invalid command: |cFF00FF00/epbonus "..args.."|r")
    show_help()
    return
  end

  command = arg1
  arg1 = nil

  if not command or command == "" or command == "all" or command == "show" then
  elseif not config.announce and command == "raid" or command == "guild" then
    config.announce = command
    config.color_name = ""
    config.color_buffs = ""
    config.color_offline = ""
    config.color_reset = ""
    command = arg1
    arg1 = nil
  elseif not config.target and command == "target" then
    config.show_buff_bonus = true
    config.show_buff_abbrev = true
    command = arg1
    arg1 = nil
    config.target = true
  elseif not config.class and (command == "warrior" or command == "paladin" or command == "hunter" or command == "rogue"
    or command == "priest" or command == "deathknight" or command == "shaman" or command == "mage"
    or command == "warlock" or command == "monk" or command == "druid" or command == "demonhunter")
    then
    config.class = command:upper()
  else
    log("|cFFFF0000invalid command: |cFF00FF00/epbonus "..args.."|r")
    show_help()
    return
  end

  if config.target then
    local message = ep_for_target("target", config)
    if message then
      show_message(message, config)
    else
      log("|cFFFF0000Need to select target first|r")
    end
    return
  end

  local raid_or_party = IsInRaid() and "raid" or "party"

  local number_of_members = GetNumGroupMembers()
  show_message(config.color_buffs.."== Class: "..config.class.." ==", config)
  if IsInRaid() then
    for p=1,number_of_members do
      local message = ep_for_target("raid"..p, config)
      show_message(message, config)
    end
  else
    -- "party" does not includes "player" (it's from 1..4), so we need to handle it manualy
    local message = ep_for_target("player", config)
    show_message(message, config)
    for p=1,number_of_members-1 do
      message = ep_for_target("party"..p, config)
      show_message(message, config)
    end
  end
  show_message(config.color_buffs.."==================", config)
end

