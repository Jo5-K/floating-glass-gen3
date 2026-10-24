-- Battle-only layout geometry. No global display or save-setting changes.
return function(R)
 local P={}
 local Layout=R.load('modules/ui/floating_battle/ui/layout.lua')
 function P.dimensions()
  local V=R.module('src.render.GameViewport');if V and V.dimensions then return V.dimensions()end
  return love.graphics.getDimensions()
 end
 function P.safe(w,h)
  local V=R.module('src.render.GameViewport');if V and V.active and V.active()then return end
  local S=R.module('src.core.SafeArea')
  if S and S.windowRect then local x,y,sw,sh=S.windowRect();if type(x)=='number' and type(y)=='number' and type(sw)=='number' and type(sh)=='number' and x>=0 and y>=0 and sw>0 and sh>0 and x+sw<=w+.01 and y+sh<=h+.01 then return {x=x,y=y,w=sw,h=sh}end end
 end
 function P.layout(w,h)
  if not w or not h or h<=w or not R.battle or not R.battle.owns or not R.battle.owns() then return nil end
  return Layout.portrait(w,h,R.option('portrait_layout','framed'),nil,nil,P.safe(w,h))
 end
 function P.field(w,h)local l=P.layout(w,h);return l and l.field end
 function P.hud(side,w,h,bw,bh)
  local f=P.field(w,h);if not f then return end
  local player=side=='player' or type(side)=='number' and side%2==0
  local slot=type(side)=='number' and math.floor(side/2) or 0
  local x=f.x+f.w*(player and .49 or .065)
  local y=f.y+f.h*(player and .78 or .29)+slot*(bh+4)
  return math.max(f.x,math.min(f.x+f.w-bw,x)),math.max(f.y,math.min(f.y+f.h-bh,y))
 end
 return P
end
