-- One focus graph for all four moves and the three auxiliary actions.
local N={}
N.graph={
  [1]={left=1,right=2,up=1,down=3},
  [2]={left=1,right=5,up=2,down=4},
  [3]={left=3,right=4,up=1,down=3},
  [4]={left=3,right=7,up=2,down=4},
  [5]={left=2,right=5,up=5,down=6}, -- Bag
  [6]={left=2,right=6,up=5,down=7}, -- Party: intentionally returns to move 2
  [7]={left=4,right=7,up=6,down=7}, -- Run
}
function N.step(focus,direction,style,lastMove,moves)
  if style=='portrait_list' or style=='portrait_carousel' then
    local ids={};for i=1,4 do if moves==nil or moves[i] and moves[i]~=0 then ids[#ids+1]=i end end
    local remembered=ids[1] or 1;for _,i in ipairs(ids)do if i==lastMove then remembered=i end end
    if focus<=4 then
      if #ids==0 then return 5 end
      local n=1;for j,i in ipairs(ids)do if i==focus then n=j end end
      if style=='portrait_list' and direction=='down' then return ids[n+1]or 5 end
      if style=='portrait_list' and direction=='up' then return ids[n-1]or ids[1] end
      if direction=='left' or direction=='right' then return ids[(n-1+(direction=='left'and -1 or 1))%#ids+1]end
      if direction=='down'then return 5 end
      return focus
    end
    if direction=='up'then return remembered end
    if direction=='left'then return math.max(5,focus-1)end
    if direction=='right'then return math.min(7,focus+1)end
    return focus
  end
  if style=='list' or style=='layers' then
    local ids={}
    for i=1,4 do if moves==nil or (moves[i] and moves[i]~=0) then ids[#ids+1]=i end end
    local remembered=ids[1] or 5
    for _,i in ipairs(ids) do if i==lastMove then remembered=i end end
    if focus<=4 then
      if direction=='up' then return 5 end
      if direction=='down' then return 6 end
      if #ids==0 then return 5 end
      local n=1;for j,i in ipairs(ids) do if i==focus then n=j end end
      if direction=='left' or direction=='right' then return ids[(n-1+(direction=='left' and -1 or 1))%#ids+1] end
    elseif focus==5 then
      if direction=='down' then return remembered end
      if direction=='right' then return 7 end
    elseif focus==6 then
      if direction=='up' then return remembered end
      if direction=='right' then return 7 end
    elseif focus==7 then
      if direction=='left' then return 6 end
      if direction=='up' then return 5 end
    end
    return focus
  end
  local edges=N.graph[focus] or N.graph[1]
  local next=edges[direction] or focus
  if style=='journal' and moves then
    local seen={}
    while next<=4 and not moves[next] do
      if seen[next]then return focus end;seen[next]=true
      next=(N.graph[next]or N.graph[1])[direction]or focus
    end
  end
  return next
end
local commandEdges={
 [1]={left=1,right=2,up=1,down=3},[2]={left=1,right=2,up=2,down=4},
 [3]={left=3,right=4,up=1,down=3},[4]={left=3,right=4,up=2,down=4}}
function N.commandStep(focus,direction)
 return (commandEdges[focus] or commandEdges[1])[direction] or focus
end
function N.moveStep(focus,direction,moves)
 local next=N.commandStep(focus,direction)
 return moves and not moves[next] and focus or next
end
function N.selection(focus,lastMove)
  focus=N.graph[focus] and focus or 1
  return {focus=focus,move=focus<=4 and focus or (lastMove or 1),
    menu=focus<=4 and 1 or ({[5]=3,[6]=2,[7]=4})[focus]}
end
local owned=setmetatable({},{__mode='k'})
local masked={left=true,right=true,up=true,down=true,a=true,select=true}
local function inputProxy(real)
  return setmetatable({},{__index=function(_,key)
    if key=='wasPressed' or key=='isDown' then
      return function(_,button)
        if masked[button] then return false end
        return type(real[key])=='function' and real[key](real,button) or false
      end
    end
    local value=real[key]
    if type(value)=='function' then return function(_,...) return value(real,...) end end
    return value
  end})
end
function N.install(state,context)
  if type(state)~='table' or type(state.update)~='function' then return nil end
  if state.__johtoNavigation then return state.__johtoNavigation end
  local original=state.update
  local session={focus=1,lastMove=1,wasDecision=false}
  local remembered=setmetatable({},{__mode='k'})
  local function owner(self) return context.owner and context.owner(self) end
  local function restore(self)
    local current=owner(self)
    local keep=context.rememberMove and context.rememberMove()==true
    local slot=keep and ((current and remembered[current]) or (session.owner==current and session.lastMove) or 1) or 1
    if context.restoreMove then slot=context.restoreMove(self,slot) end
    session.focus=(type(slot)=='number' and slot>=1 and slot<=4) and slot or 1
    session.lastMove=session.focus;session.owner=current
  end
  local function sync(self)
    local selection=N.selection(session.focus,session.lastMove)
    if session.focus<=4 then
      session.lastMove=session.focus
      local current=owner(self);if current then remembered[current]=session.focus end
    end
    session.owner=owner(self)
    self.menuIndex=selection.menu;self.moveIndex=selection.move
    context.sync(selection)
  end
  function session:setFocus(focus)
    if N.graph[focus] then self.focus=focus;self.wasDecision=true;sync(state) end
  end
  local function wrapper(self,dt)
    local real=self.game and self.game.input
    local active=context.active(self) and real and type(real.wasPressed)=='function'
    if not active then
      session.wasDecision=false
      local result=original(self,dt)
      if context.active(self) then restore(self);session.wasDecision=true;sync(self) end
      return result
    end
    if not session.wasDecision or owner(self)~=session.owner then restore(self) end
    session.wasDecision=true
    -- Both axes may be pressed in one logic tick. Opposite presses cancel.
    local left,right=real:wasPressed('left'),real:wasPressed('right')
    local up,down=real:wasPressed('up'),real:wasPressed('down')
    if left~=right then session.focus=N.step(session.focus,left and 'left' or 'right') end
    if up~=down then session.focus=N.step(session.focus,up and 'up' or 'down') end
    sync(self)
    if real:wasPressed('a') then
      context.confirm(session.focus)
      if self.phase~='menu' and self.phase~='moveSelect' then session.wasDecision=false end
      return -- native choose/submit paths also end their tick on confirmation
    end
    -- Read semantic GB edges after Input:step, so remapped keyboards, pads,
    -- touch controls and scripted sources share exactly the same graph.
    self.game.input=inputProxy(real)
    local ok,result=pcall(original,self,dt)
    self.game.input=real
    if not ok then error(result,0) end
    if self.phase~='menu' and self.phase~='moveSelect' then session.wasDecision=false end
    return result
  end
  state.update=wrapper;state.__johtoNavigation=session
  owned[state]={original=original,wrapper=wrapper}
  return session
end
function N.uninstall()
  for state,rec in pairs(owned) do
    if state.update==rec.wrapper then state.update=rec.original end
    state.__johtoNavigation=nil;owned[state]=nil
  end
end
return N
