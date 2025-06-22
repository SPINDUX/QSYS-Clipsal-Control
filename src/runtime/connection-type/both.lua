-------------------
----- Polling -----
-------------------
function Begin()

    Poll()

    queueTimer:Start(0)

    if Properties["Enable Polling"].Value == "Yes" then pollTimer:Start(Properties["Poll Rate (s)"].Value) end

end

function Poll()

    print("User.Info: Polling...")

    -- Enqueue('WhoAreYou')

    for i = 1, Properties["Area Slots"].Value do
        GetCurrentPresets(Controls['area_number'][i].String, i)

        GetChannelLevels(Controls['area_number'][i].String, i)
    end

end
pollTimer.EventHandler = Poll

function Enqueue(cmd, position)
    if not position then return table.insert(commandQueue, cmd) end
    table.insert(commandQueue, position, cmd)
    if (position == 1) then queueTimer:Start(0) end
end

----------------------------
----- Helper Functions -----
----------------------------

function SetStatus(value, string)

    Controls["device_status"].Value = value and value or Controls["device_status"].Value
    Controls["device_status"].String = string and string or Controls["device_status"].String

end

function GeneratePacket(tbl)

    local sum, command = 0, ""

    -- sum the table
    for i, byte in ipairs(tbl) do sum = sum + byte end

    -- pack to 8 bit signed integer
    sum = bitstring.pack("8:int", sum)

    -- convert to binary stream
    local bin = bitstring.binstream(sum)

    local new_bin = ""

    -- invert the binary stream
    for i = 1, bin:len() do

        local bit = bin:sub(i, i)
        local new_bit

        if bit == "0" then
            new_bit = "1"
        elseif bit == "1" then
            new_bit = "0"
        end

        new_bin = new_bin .. new_bit
    end

    -- add 1, then pack to 8 bit signed integer again
    local checksum = bitstring.pack("8:int", string.byte(bitstring.frombinstream(new_bin)) + 1)

    -- add it to the command
    table.insert(tbl, string.byte(checksum))

    -- print(require('rapidjson').encode(tbl, { pretty = true }))

    return tbl
end

function GetPositionsFromArea(area, join) -- update this to also accept a join value and match to that

    local tbl = {}

    -- bitmatch the join values
    local function matchJoinValues(configuredJoin, receivedJoin)
        if not receivedJoin then return true end -- if no received join, just return true so it only matches the area value
        local configuredJoinBits = bitstring.binstream(bitstring.pack('8:int', configuredJoin))
        local receivedJoinBits = bitstring.binstream(bitstring.pack('8:int', receivedJoin))
        print(string.format('Matching Join Bits: [%s] to [%s]', receivedJoinBits, configuredJoinBits))
        for i = 1, 8 do
            if string.sub(configuredJoinBits, i, i) == '1' and string.sub(receivedJoinBits, i, i) == '1' then
                print(string.format('Matched at Bit [%d]', i))
                return true
            end
        end
        return false
    end

    for i, ctl in ipairs(Controls["area_number"]) do

        if (math.floor(ctl.Value) == tonumber(area)) and matchJoinValues(area_props[i].join, join) then
            table.insert(tbl, i)
        end
    end

    return tbl

end

function SetPresetLEDs(preset, area, join)

    if (preset ~= 0) then print(string.format("Area [%s], is Updating to Preset [%d]", area, preset)) end

    -- get control positions for this area
    positions = GetPositionsFromArea(area, join)

    -- for all returned positons, do;
    for _, position in ipairs(positions) do

        -- iterate vertically through the preset LED controls
        for i = 1, Properties["Presets"].Value do

            -- set the preset true if it matches, else false
            Controls[string.format("preset_match_%d", i)][position].Boolean = ((i == tonumber(preset)) and
                                                                                  area_props[position].validPreset ==
                                                                                  true)

        end
    end
end

function UpdateActiveChannels(channel, area, target, current, join)

    if (Properties["Enable Logical Channels"].Value == "No") then return end

    -- get control positions for this area
    positions = GetPositionsFromArea(area, join)

    channel = tonumber(channel)

    -- for all returned positons, do;
    for _, position in ipairs(positions) do

        print(string.format("Area [%s], Channel [%d] is %s", area, channel,
            ((area_props[position].isMoving[channel] == false) and string.format("Updating to Target [%d]", target) or
                "Not Available for Updates")))

        if area_props[position].isMoving[channel] == false then

            -- set the channel level for the incoming channel
            Controls[string.format("channel_%d", channel)][position].String = target

        end
    end
end

function AreaIsDuplicate(area, position)
    matches = 0
    for i, c in ipairs(Controls['area_number']) do
        if (c.String == area and area_props[i].join == area_props[position].join) then matches = matches + 1 end
        if (matches > 1) then return true end
    end
    return false
end

------------------------
----- API Requests -----
------------------------

function GetCurrentPresets(area, position)

    Controls['area_status'][position].Value = (tonumber(area) == 0) and 3 or 0
    Controls['area_status'][position].String = (tonumber(area) == 0) and "Area Undefined" or ""

    if (tonumber(area) == 0) then

        Controls['area_status'][position].Value = 3
        Controls['area_status'][position].String = "Area Undefined"

        return

    elseif AreaIsDuplicate(area, position) then

        Controls['area_status'][position].Value = 1
        Controls['area_status'][position].String = "Area is Duplicate"

    end

    print(string.format("Getting Preset for Area [%s]", area and area or "-"))

    Enqueue(Protocol['RequestCurrentPresets'][Properties['Protocol'].Value](area, area_props[position].join))

end

function GetChannelLevels(area, position)

    if Properties["Enable Logical Channels"].Value == "No" then return end

    if (tonumber(area) == 0) then return end

    print(string.format("Getting Channel Levels for Area [%s]", area and area or "-"))

    for ch = 1, Properties["Logical Channels"].Value do

        Enqueue(Protocol['RequestCurrentLevels'][Properties['Protocol'].Value](ch, area, area_props[position].join))
    end

end

cbusRxBuffer = ""

function HandleCBusFrame(line)
    print(string.format("Data:%s", line))

    if line == string.char(0x06) or line == "ACK" then
        SetStatus(0, "ACK")
        return
    elseif line == string.char(0x15) or line == "NAK" then
        SetStatus(4, "NAK")
        return
    end

    local cmd, addr, param = line:match("(%w+)%s+([%d/]+)%s*(%d*)")
    if not cmd then return end

    if cmd == "ON" then
        OnCBusOn(addr)
    elseif cmd == "OFF" then
        OnCBusOff(addr)
    elseif cmd == "RAMP" then
        OnCBusRamp(addr, tonumber(param) or 0)
    elseif cmd == "MMI" then
        OnCBusMMI(addr, param)
    end
end

function ParseData(data)
    if not data then return end
    cbusRxBuffer = cbusRxBuffer .. data
    local pos = cbusRxBuffer:find("\r")
    while pos do
        local line = cbusRxBuffer:sub(1, pos - 1)
        cbusRxBuffer = cbusRxBuffer:sub(pos + 1)
        HandleCBusFrame(line)
        pos = cbusRxBuffer:find("\r")
    end
end
