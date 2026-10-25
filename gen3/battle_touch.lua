-- Battle-only pointer routing. Native mod.input emits button edges; never actions.
return function(R)
 local T={seen=setmetatable({},{__mode='k'}),touches={}}
 function T.active()
  if T.failed or R.unloaded or not R.active() or R.glass and not R.glass() or not R.option('battle',true)then return false end
  local b=R.module('src.core.game3.battle.init') or R.module('src.core.game3.battle')
  if b and b.isActive and b.isActive()then T.continuation=true;return true end
  -- Preserve controls until a battle-origin evolution modal has really closed.
  if T.continuation then
   local E=R.module('src.ui.game3.evolution_scene')
   if E and E._isBattle and E.isOpen and E.isOpen()then return true end
   T.continuation=nil
  end
  return false
 end
 function T.nativeFallback()
  -- Our opaque battle-message panel remains directly tappable with a hidden pad.
  -- Other native screens (including evolution and level-up choices) restore it.
  local M=R.module('src.ui.game3.message')
  if R.battle.owns and R.battle.owns()and M and M.isOpen and M.isOpen()and M._frame=='battle'then return false end
  return T.active() and not R.battle.settingsOpen and type(R.battle.decision)=='function' and not R.battle.decision()
 end
 function T.mode(pad)
  local saved=R.option('battle_virtual_pad','auto')
  local os=love and love.system and love.system.getOS and love.system.getOS()
  if T.nativeFallback() and (os=='Android' or os=='iOS' or pad and pad.active==true)then return true end
  return saved
 end
 function T.pad(game)return game and game.touchControls or R.module('src.core.TouchControls')end
 function T.direct(game)
  if not T.active() then return false end
  if T.mode(T.pad(game))==false then return true end
  local pad=T.pad(game);return not (pad and pad.visible and pad:visible())
 end
 function T.tap(game,key)
  if R.mod.input and R.mod.input.tap then
   local ok,err=pcall(R.mod.input.tap,R.mod.input,game,key)
   if not ok then T.failed=true;if R.warn then R.warn('battle direct touch disabled; native controls restored',err)end;return false end
   return true
  end
  return false
 end
 local function menu()
  local choice=R.module('src.ui.game3.choice');if choice and choice.active then return choice,'choice'end
  local Stack=R.module('src.ui.game3.stack');local top=Stack and Stack.top and Stack.top()
  for _,name in ipairs({'party_menu','bag_menu'})do
   local m=R.module('src.ui.game3.'..name)
   if m and m.open==true and (not top or not top.mod or top.mod==m)then return m,name end
  end
  -- Unknown native submenus keep their own layout; use A/B and swipe inputs.
  if top and type(top.mod)=='table' and top.mod.handleInput then return top.mod,'other'end
  local U=R.module('src.core.game3.battle.ui');local N=R.module('src.core.game3.battle.init') or R.module('src.core.game3.battle')
  local st=N and N.getState and N.getState()
  if U and (U._mode=='menu' or U._mode=='moves' or U._mode=='target') and U.waitingForCommand and U.waitingForCommand() and not U._wally and not (st and st.oldManTutorial) and not (N and N._auto)then return U,U._mode=='target' and 'other' or 'battle_grid'end
 end
 function T.moveTo(game,m,key,target,grid)
  if target==m[key]then return T.tap(game,'a')end
  T.navigation={module=m,key=key,target=target,mode=grid and m._mode or m.mode,grid=grid,tries=0,wait=0};return true
 end
 function T.nativePointer(game,x,y)
  local m,name=menu();if not m then return false end
  local D=R.module('src.core.game3.display');if not D or not D.fit then return false end
  local scale,ox,oy,_,_,sy=D.fit();x,y=(x-ox)/scale,(y-oy)/(sy or scale)
  if x<0 or y<0 or x>240 or y>160 then return false end
  if name=='battle_grid' then
   if y>=114 and y<=158 then
    local moves=m._mode=='moves'
    local left=moves and 8 or 128;local split=moves and 80 or 184;local right=moves and 160 or 240
    if x>=left and x<right then return T.moveTo(game,m,moves and '_moveIndex' or '_menuIndex',(x>=split and 2 or 1)+(y>=134 and 2 or 0),true)end
   end
  elseif name=='bag_menu' then
   if m.mode=='list' and not m._switch then
    if x>=88 and y>=9 and y<105 then return T.moveTo(game,m,'cursor',(m.scroll or 0)+math.floor((y-9)/16)+1)end
    if x<84 and y<32 then return T.tap(game,x<40 and 'left' or 'right')end
   elseif m.mode=='action' and m.ACTIONS then
    local top=(19-#m.ACTIONS*2)*8
    if x>=176 and y>=top and y<top+#m.ACTIONS*16 then return T.moveTo(game,m,'actionCursor',math.floor((y-top)/16)+1)end
   end
  elseif name=='party_menu' then
   if m.mode=='action' and m.ACTIONS then
    local top=(19-#m.ACTIONS*2)*8
    if x>=152 and y>=top and y<top+#m.ACTIONS*16 then return T.moveTo(game,m,'actionCursor',math.floor((y-top)/16)+1)end
   elseif m.mode~='summary' and m.mode~='message' and m.mode~='stat_growth' then
    if y>142 and x>176 then return T.tap(game,'b')end
    if m._layout~='double' then
     local target=x<88 and y>=24 and y<80 and 1 or x>=96 and y>=8 and y<128 and math.floor((y-8)/24)+2
     if target and target<=6 and m._party and m._party[target]then return T.moveTo(game,m,'cursor',target)end
    end
   end
  elseif name=='choice' and m.options and (m.cols or 1)==1 then
   local top=(m.top or 9)*8;local left=(m.left or 21)*8
   if x>=left and y>=top and y<top+#m.options*16 then return T.moveTo(game,m,'cursor',math.floor((y-top)/16)+1)end
  end
  return false
 end
 function T.install(game)
  local pad=T.pad(game)
  if not pad or T.seen[pad]then return end;T.seen[pad]=true
  local function scoped(next,self,...)
   local active,enabled,hidden=self.active,self.enabled,self.controllerHidden
   if self.ensureImages then local ok=pcall(self.ensureImages,self);if not ok then return end end
   self.active,self.enabled,self.controllerHidden=true,true,false
   local function pack(...)return {n=select('#',...),...}end
   local result=pack(pcall(next,self,...))
   self.active,self.enabled,self.controllerHidden=active,enabled,hidden
   if not result[1]then error(result[2],0)end
   return (table.unpack or unpack)(result,2,result.n)
  end
  R.wrap(pad,'visible',function(next,self,...)
   if T.active()then
    local mode=T.mode(self)
    if mode==false then return false end
    if mode==true then return scoped(next,self,...)end
   end
   return next(self,...)
  end)
  for _,method in ipairs({'draw','touchpressed','touchmoved','touchreleased'})do
   local name=method
   R.wrap(pad,name,function(next,self,...)
    if T.active()then
     local mode=T.mode(self)
     if mode==false then return false end
     if mode==true then return scoped(next,self,...)end
     if name=='touchpressed' and self.visible and not self:visible()then return false end
    end
    return next(self,...)
   end)
  end
 end
 function T.update(game,dt)
  if not T.active()then
   if T.policy~=nil then local pad=T.pad(game);if pad and pad.reset then pad:reset()end end
   T.touches={};T.navigation=nil;T.footer=nil;T.policy=nil;return
  end
  local pad=T.pad(game);local policy=T.mode(pad)
  if policy~=T.policy then
   if pad and pad.reset then pad:reset()end
   T.policy=policy;T.touches={};T.navigation=nil
  end
  for _,p in pairs(T.touches)do
   p.age=p.age+math.max(0,math.min(.1,dt or 0))
   if p.recovery and not p.cancelled and p.age>=.7 and not p.opened then p.opened=R.battle.openSettings();p.cancelled=true end
  end
  local nav=T.navigation
  if nav then
   local m=menu();nav.wait=nav.wait+(dt or 0)
   if m~=nav.module or (nav.grid and m._mode or m.mode)~=nav.mode or not T.direct(game) or nav.tries>=12 then T.navigation=nil
   elseif m[nav.key]==nav.target then T.navigation=nil
   elseif nav.wait>=.10 then
    local key=m[nav.key]<nav.target and 'down' or 'up'
    if nav.grid then local col=(m[nav.key]-1)%2;local targetCol=(nav.target-1)%2;if col~=targetCol then key=col<targetCol and 'right' or 'left'end end
    T.tap(game,key);nav.tries=nav.tries+1;nav.wait=0
   end
  end
 end
 function T.pointer(game,ev)
  if type(ev)~='table' or ev.source~='touch' or not T.active()then return false end
  if not T.direct(game)then return true end -- virtual pad retains first refusal
  local x,y=ev.gameX or ev.x,ev.gameY or ev.y
  if ev.insideGame==false then T.touches[ev.id or 'touch']=nil;return false end
  local id=ev.id or 'touch'
  if ev.phase=='pressed'then
   local w,h=R.portrait.dimensions()
   local safe=R.portrait.safe and R.portrait.safe(w,h);local ax,ay,cw,ch=safe and safe.x or 0,safe and safe.y or 0,safe and safe.w or w,safe and safe.h or h
   local recovery=R.option('battle_settings_button',true)==false and x>ax+cw*.86 and y>=ay and y<ay+ch*.09
   local multiple=next(T.touches)~=nil;for _,other in pairs(T.touches)do other.cancelled=true end
   T.touches[id]={x=x,y=y,lastY=y,age=0,recovery=recovery,cancelled=multiple};return true
  end
  local p=T.touches[id];if not p then return false end
  if ev.phase=='cancelled'then T.touches[id]=nil;return true end
  if ev.phase=='moved'then
   if R.battle.settingsOpen and math.abs(y-p.lastY)>28 then R.battle.scrollSettings(y<p.lastY and 1 or -1);p.lastY=y;p.cancelled=true end
   return true
  end
  if ev.phase=='released'then
   T.touches[id]=nil
   if p.cancelled or p.recovery then return true end
   local dx,dy=x-p.x,y-p.y
   if dx*dx+dy*dy>144 then
    if not R.battle.settingsOpen then T.tap(game,math.abs(dx)>math.abs(dy) and (dx>0 and 'right' or 'left')or(dy>0 and 'down' or 'up'))end
    return true
   end
   if R.battle.pointer(game,x,y,1)then return true end
   if T.footer then
    for _,r in ipairs(T.footer)do if x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h then return T.tap(game,r.key)end end
   end
   if T.nativePointer(game,x,y)then return true end
   local Choice=R.module('src.ui.game3.choice')
   if Choice and Choice.active then return true end -- do not confirm outside choice targets
   local E=R.module('src.ui.game3.evolution_scene')
   if E and E.isOpen and E.isOpen() then
    -- Final acknowledgement can remain pending AFTER Message closes. Let the
    -- native scene consume A and run its completion/learn-move callbacks.
    if E._state=='congrats' or E._state=='cancel' or E._state=='learn_moves' then return T.tap(game,'a')end
    return true -- no advance/cancellation during the evolution animation
   end
   local M=R.module('src.ui.game3.message')
   if M and ((M.isWaiting and M.isWaiting()) or (M.isOpen and M.isOpen() and not (M.isHeld and M.isHeld())))then return T.tap(game,'a')end
   return true
  end
  return true
 end
 function T.draw(game,w,h)
  T.footer=nil
  if not T.direct(game) or R.battle.owns() or R.battle.settingsOpen then return end
  -- Compact A/B affordances for native submenus, not a virtual joystick.
  local m=menu();if not m then return end
  local g=love.graphics;local safe=R.portrait.safe and R.portrait.safe(w,h);local ax,ay,cw,ch=safe and safe.x or 0,safe and safe.y or 0,safe and safe.w or w,safe and safe.h or h;local unit=math.min(cw/480,ch/800);local rh=math.min(ch*.075,64*unit)
  local rows={{key='a',text='A',x=ax+cw*.12,y=ay+ch-rh-16*unit,w=cw*.34,h=rh},{key='b',text='B',x=ax+cw*.54,y=ay+ch-rh-16*unit,w=cw*.34,h=rh}}
  g.push('all');g.origin();g.setShader();g.setScissor(0,0,w,h);local size=math.max(14,math.floor(20*unit));if T.fontSize~=size and g.newFont then if T.font and T.font.release then T.font:release()end;T.font=g.newFont(size);T.fontSize=size end;if T.font then g.setFont(T.font)end
  for _,r in ipairs(rows)do g.setColor(.06,.16,.14,.95);g.rectangle('fill',r.x,r.y,r.w,r.h,8*unit,8*unit);g.setColor(1,1,.87,1);g.setLineWidth(unit);g.rectangle('line',r.x,r.y,r.w,r.h,8*unit,8*unit);g.print(r.text,r.x+r.w*.46,r.y+r.h*.25)end
  g.pop();T.footer=rows
 end
 function T.shutdown()T.touches={};T.navigation=nil;T.footer=nil;if T.font and T.font.release then T.font:release()end;T.font=nil;T.fontSize=nil end
 return T
end
