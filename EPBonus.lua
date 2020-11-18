-- todo: change order: /epbonus warrior guild

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
  |cFFFF0000EP Bonus usage:|r
  |cFF00FF00/epbonus [<command>] [<class> || target]|r
  Examples:
    |cFF00FF00/epbonus help|r - show this message
    |cFF00FF00/epbonus|r - show bonus of all players in default chat frame 
    |cFF00FF00/epbonus raid warrior|r - announce bonus of warriors in raid chat
    |cFF00FF00/epbonus warrior|r - show bonus of warriors  in default chat frame
    |cFF00FF00/epbonus guild|r - announce bonus of all players in guild chat
    |cFF00FF00/epbonus guild target|r - announce bonus of target player in guild chat]]
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
    class = "ALL"
  }

  if command == "help" then
    show_help()
    return
  end

  if command == "raid" or command == "guild" then
    config.announce = command
    config.color_name = ""
    config.color_buffs = ""
    config.color_offline = ""
    config.color_reset = ""
    command = arg1
    arg1 = nil
  end

  if arg1 then
    log("invalid command1: "..command.." "..arg1)
    return
  end

  if command == nil or command == "" then
  elseif command == "target" then
    config.show_buff_bonus = true
    config.show_buff_abbrev = true
    local message = ep_for_target("target", config)
    show_message(message, config)
    return
  elseif command == "warrior" or command == "paladin" or command == "hunter" or command == "rogue"
    or command == "priest" or command == "deathknight" or command == "shaman" or command == "mage"
    or command == "warlock" or command == "monk" or command == "druid" or command == "demonhunter"
    then
    config.class = command:upper()
  else
    log("invalid command2: "..command)
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

