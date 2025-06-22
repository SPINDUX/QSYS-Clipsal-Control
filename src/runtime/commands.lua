-- C-BUS command builders

local function computeChecksum(data)
  local sum = 0
  for _, b in ipairs(data) do
    sum = (sum + b) % 256
  end
  return (256 - sum) % 256
end

local function buildCommand(opcode, group, level, ramp)
  local ack = math.random(0, 255)
  local bytes = {
    0x05,     -- header
    0xFF,     -- header
    opcode,
    group or 0x00,
    level or 0x00,
    ramp or 0x00,
    ack
  }
  table.insert(bytes, computeChecksum(bytes))
  return bytes
end

function BuildOn(group)
  -- opcode 0x79 represents ON in common C-BUS lighting messages
  return buildCommand(0x79, group, 0xFF, 0x00)
end

function BuildOff(group)
  -- opcode 0x78 represents OFF in common C-BUS lighting messages
  return buildCommand(0x78, group, 0x00, 0x00)
end

function BuildRamp(group, level, rate)
  -- opcode 0x00 is ramp to level with rate
  return buildCommand(0x00, group, level, rate or 0x00)
end
