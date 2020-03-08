-- Requirements --
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local keyboard = require("keyboard")
local computer = require("computer")
local thread = require("thread")
local gpu = require("component").gpu
local colors = require("colors")

-- Global variables --
local running = false
local width = 80
local height = 21
local ded = false
local fruit = {x=13,y=5}
local score = 0
local tick_time = 0.05
local DEFAULT_TICK = 0.05
local OLD_X, OLD_Y = gpu.getResolution()
gpu.setResolution(80, 25)

function unknownEvent() end
local event_handlers = setmetatable({}, {__index = function() return unknownEvent end})

local directions = {
  up={x=0, y=-1}, 
  down={x=0, y=1},
  left={x=-1, y=0},
  right={x=1, y=0}
}

local current_dir = directions.right


local player = {}
player[1] = {x=13, y=5}
player[2] = {x=12, y=5}
player[3] = {x=11, y=5}

--Event handlers
function event_handlers.key_down(address, char, code, playerName)
 
  if code == keyboard.keys.up and current_dir ~= directions.down then
    current_dir = directions.up
	DEFAULT_TICK = 0.075
  elseif code == keyboard.keys.down and current_dir ~= directions.up then
    current_dir = directions.down
	DEFAULT_TICK = 0.075
  elseif code == keyboard.keys.right and current_dir ~= directions.left then
    current_dir = directions.right
	DEFAULT_TICK = 0.05
  elseif code == keyboard.keys.left and current_dir ~= directions.right then
    current_dir = directions.left
	DEFAULT_TICK = 0.05
  end

  if not running then
    current_direction = directions.right
  end
    
  if code == keyboard.keys.q then
    running = false
  end  
end


function handleEvent(eventID, ...)
  if (eventID) then
    event_handlers[eventID](...)
  end
end


-- Functions --
-- Section 1: Helper functions
function contains_pos(xpos, ypos)
  local to_check = {x=xpos, y=ypos}
  for index, value in ipairs(player) do
    if to_check.x == value.x and to_check.y == value.y then
      return true
    end
  end
  return false
end

function is_head(xpos, ypos) 
  local head = player[1]
  return (head.x == xpos and head.y == ypos)
end

-- Section 2: Game functions

function spawn_fruit()
	local old_color = gpu.setForeground(0xFF0000)
    fruit.x = player[1].x
    fruit.y = player[1].y
    while contains_pos(fruit.x, fruit.y) do
      fruit.x = math.random(2, width-1)
      fruit.y = math.random(3, height+2)
    end
    term.setCursor(fruit.x, fruit.y)
    print("O")
	gpu.setForeground(old_color)
end


function display(width, height)
  term.setCursor(1,2)
  local hline = ""
  for i = 1,width,1
  do
     hline = hline .. "_"
  end
  print(hline)
  for y = 3, height+2 do
    for x = 1, width do
      term.setCursor(x, y)
      if (x==1) or (x==width) then
        print("|")
      end

      if is_head(x, y) then      
        print("H")
      elseif contains_pos(x, y) then
        print("=")
      end

    end
  end
  print(hline)

end

function initialize()
  term.setCursorBlink(false)
  term.clear()
  term.setCursor(30,1)
  math.randomseed(os.clock())
  print("~~~~SNAK THE GEEM~~~~")
  term.setCursor(70, 1)
  print("Score: 0")
  display(width, height)
  running = true
  spawn_fruit()
end

function update_player()
  new_head = {
   x=player[1].x + current_dir.x,
   y=player[1].y + current_dir.y
  }
  
  if new_head.x >= width then
    new_head.x = 2
  elseif new_head.x == 1 then
    new_head.x = width -1
  end

  if new_head.y > height+2 then
    new_head.y = 3
  elseif new_head.y < 3 then
    new_head.y = height + 2
  end 

  -- remove tail
  tail = table.remove(player, #player)
  term.setCursor(tail.x, tail.y)
  print(" ")

  -- add new head
  term.setCursor(player[1].x, player[1].y)
  print("o")
  if contains_pos(new_head.x, new_head.y) then
    ded = true
    running = false
  end

  table.insert(player, 1, new_head)
  term.setCursor(new_head.x, new_head.y)
  if current_dir == directions.UP or current_dir == directions.down then
	print("∞")
  else
	print("8")
  end

  if new_head.x == fruit.x and new_head.y == fruit.y then
    computer.beep()
    term.setCursor(player[2].x, player[2].y)
    table.insert(player, 1, new_head)
    print("O")
    score = score + 1
    term.setCursor(77, 1)
    print(score)
    spawn_fruit()
	tick_time = 0
    end
end


--Function to handle dead screen
function ded_screen(address, char, code, playerName) 
  return code == 13
end


-- Game loop --
function game_loop()
  update_player()
end


-- Startpoint of program --

initialize()
t = thread.create(function() while running do handleEvent(event.pull(0)) end end)
local reset_color = gpu.setForeground(0x32A852)
while running do
  --handleEvent(event.pull(0))
  game_loop()
  os.sleep(tick_time)	--To prevent lag
  tick_time = DEFAULT_TICK
end
t:kill()

gpu.setForeground(reset_color)

if ded == true then
  local msg = "DED LMAO, SCORE: "
  msg = msg .. #player
  term.setCursor(width/2 - #msg/2, height/2)
  print(msg)
  while ded_screen(event.pull("key_down")) ~= true do end
end


-- Cleanup and set values back to inital values
gpu.setResolution(OLD_X, OLD_Y)
term.clear()
os.exit()