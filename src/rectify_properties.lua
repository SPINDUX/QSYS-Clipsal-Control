props["Logical Channels"].IsHidden = props["Enable Logical Channels"].Value == "No"
props["Enable Polling"].IsHidden = props["Protocol"].Value == "DyNet Text"
props["Poll Rate (s)"].IsHidden = props["Enable Polling"].Value == "No" or props["Protocol"].Value == "DyNet Text"
props["Preset Recall Mode"].IsHidden = props["Protocol"].Value ~= "DyNet 1"
-- props["Connection Type"].IsHidden = props["DyNet Protocol"].Value == "Text"
-- if props["DyNet Protocol"].Value == "Text" then
--   props["Connection Type"].Value = "TCP"
-- end

-- ensure hex properties are valid two digit values
local function validate_hex(prop)
    local value = tostring(prop.Value or "00"):upper()
    local num = tonumber(value, 16)
    if not num then
        value = "00"
    else
        value = string.format("%02X", math.max(0, math.min(255, num)))
    end
    prop.Value = value
end

validate_hex(props["Application Hex"])
validate_hex(props["Address Hex"])

-- clamp ramp rate within range
local ramp = tonumber(props["Ramp Rate"].Value) or 0
if ramp < 0 then ramp = 0 end
if ramp > 255 then ramp = 255 end
props["Ramp Rate"].Value = ramp
