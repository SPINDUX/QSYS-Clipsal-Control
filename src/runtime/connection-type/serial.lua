-- Services
serial = SerialPorts[1]
-- sock.ReadTimeout = 0
-- sock.ReconnectTimeout = 1

-----------------
----- Setup -----
-----------------

function Connect()
  
  ResetTimers()
  
  -- empty command queue
  commandQueue = {}
  
  if not Controls["connect"].Boolean then SetStatus(3, "Component Manually Disconnected") return serial:Close() end
  
  print("User.Info: Connecting Serial Port...")
  
  if not serial.IsOpen then
    serial:Open(9600, 8, 'N') --9600,N,8,1
  end
end

----------------------------
----- Queue Management -----
----------------------------

function Dequeue()
  
  queueTimer:Stop()
  
  if #commandQueue > 0 and serial.IsOpen then
      Send(table.remove(commandQueue, 1))
  end
  
  queueTimer:Start(0.1)
end

------------------------------------
----- Serial & Data Management -----
------------------------------------

serial.EventHandler = function(port, evt)

  if evt == SerialPorts.Events.Connected then

    SetStatus(0, "Connected")

    Begin()
    
  elseif evt == SerialPorts.Events.Data then
  
    SetStatus(0)
    
    local data = serial:Read(serial.BufferLength)
    
    ParseData(data)
    
    queueTimer:Start(0)
    
  else
  
    SetStatus(4, evt)
  
    Timer.CallAfter(Connect, 1)
    
  end
end

function Send(data)
  
  if not serial.IsOpen then return print("User.Warning: Serial Port not Connected") end
  
  local command = ""
  
  local hex = ""

  for i, byte in ipairs(data) do
    command = command .. string.char(byte)
    hex = hex .. string.format("[%02X]", byte)
  end

  print(string.format("Sending HEX:%s", hex))
  
  serial:Write(command)

end

-- Queue utilities for C-BUS commands
local function QueueCommand(cmd)
  table.insert(commandQueue, cmd)
  if #commandQueue == 1 then
    queueTimer:Start(0)
  end
end

function SendOn(group)
  QueueCommand(BuildOn(group))
end

function SendOff(group)
  QueueCommand(BuildOff(group))
end

function SendRamp(group, level, rate)
  QueueCommand(BuildRamp(group, level, rate))
end
