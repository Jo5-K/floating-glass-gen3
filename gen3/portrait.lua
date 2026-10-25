-- Battle-only layout geometry. No global display or save-setting changes.
return function(R)
 local P={}
 local Layout=R.load('modules/ui/floating_battle/ui/layout.lua')
 -- Follow the native window after SDL applies the app's orientation policy.
 -- A landscape render.viewport reservation must not hide portrait rotation.
 function P.viewport(requested,ctx)
  if type(ctx)=='table' and type(ctx.width)=='number' and type(ctx.height)=='number' and ctx.height>ctx.width
   and R.battle and R.battle.owns and R.battle.owns() then
   return {x=0,y=0,width=ctx.width,height=ctx.height}
  end
  return requested
 end
 function P.refresh(w,h)
  local key=tostring(w)..':'..tostring(h)
  if P.sizeKey==key then return false end
  P.sizeKey=key;P.regions=nil
  if R.battle then
   R.battle.drawStamp=nil;R.battle.layout=nil;R.battle.settingsTargets=nil;R.battle.settingsViewport=nil
  end
  local T=R.battleTouch
  if T then T.touches={};T.navigation=nil;T.footer=nil end
  return true
 end
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
 -- Decorations occupy only the complement of all battle/UI rectangles.
 local function subtract(parts,b)
  local out={}
  for _,a in ipairs(parts)do
   local x,y=math.max(a.x,b.x),math.max(a.y,b.y);local r,t=math.min(a.x+a.w,b.x+b.w),math.min(a.y+a.h,b.y+b.h)
   if r<=x or t<=y then out[#out+1]=a else
    if y>a.y then out[#out+1]={x=a.x,y=a.y,w=a.w,h=y-a.y}end
    if t<a.y+a.h then out[#out+1]={x=a.x,y=t,w=a.w,h=a.y+a.h-t}end
    if x>a.x then out[#out+1]={x=a.x,y=y,w=x-a.x,h=t-y}end
    if r<a.x+a.w then out[#out+1]={x=r,y=y,w=a.x+a.w-r,h=t-y}end
   end
  end
  return out
 end
 P.decorationRegions=function(w,h,l)
  local regions={{x=0,y=0,w=w,h=h}};local protected={l.field,l.message,l.settings}
  for _,r in ipairs(l.rects or {})do protected[#protected+1]=r end
  for _,r in ipairs(protected)do
   local pad=10*l.scale
   regions=subtract(regions,{x=r.x-pad,y=r.y-pad,w=r.w+2*pad,h=r.h+2*pad})
  end
  return regions
 end
 function P.decorate(w,h)
  local l=P.layout(w,h);if not l or P.decorationFailed then return end
  local g=love.graphics;local f=l.field;local rad=math.min(f.w*.025,12*l.scale)
  g.push('all')
  local ok,err=pcall(function()
  g.origin();g.setShader()
  -- Opaque corner caps trim all scene layers before the HUD is composed.
  g.setColor(.035,.08,.075,1)
  for _,corner in ipairs({{f.x,f.y,1,1},{f.x+f.w,f.y,-1,1},{f.x+f.w,f.y+f.h,-1,-1},{f.x,f.y+f.h,1,-1}})do
   local x,y,sx,sy=(table.unpack or unpack)(corner);local pts={x,y,x+sx*rad,y}
   for i=0,12 do local a=-math.pi/2-i/12*math.pi/2;pts[#pts+1]=x+sx*(rad+math.cos(a)*rad);pts[#pts+1]=y+sy*(rad+math.sin(a)*rad)end
   g.polygon('fill',pts)
  end
  g.setColor(.87,.89,.73,1);g.setLineWidth(math.max(1,2*l.scale));g.rectangle('line',f.x,f.y,f.w,f.h,rad,rad)
  local scene=R.scenery and R.scenery.selected
  scene=({forest='plain',tall_grass='plain',wallace='pond'})[scene]or scene
  if scene and ({mountain=true,rocky=true,plain=true,pond=true,water=true,beach=true,desert=true,cave=true})[scene]and R.option('environment_details',true)~=false then
   P.frames=P.frames or {};local img=P.frames[scene]
   if img==nil then local ok,v=pcall(R.mod.assets.image,R.mod.assets,'assets/scenery/ambient/portrait/'..scene..'.png');img=ok and v or false;P.frames[scene]=img end
   if img then
    local iw,ih=img:getDimensions();local k=h/ih;P.frameQuads=P.frameQuads or {}
    local q=P.frameQuads[scene];if not q then q={g.newQuad(0,0,iw/2,ih,iw,ih),g.newQuad(iw/2,0,iw/2,ih,iw,ih)};P.frameQuads[scene]=q end
    g.setColor(1,1,1,1)
    local regionKey=w..':'..h..':'..l.variant
    if not P.regions or P.regionKey~=regionKey then P.regions=P.decorationRegions(w,h,l);P.regionKey=regionKey end
    for _,r in ipairs(P.regions)do for side=1,2 do
     local left,right=math.max(r.x,side==1 and 0 or w/2),math.min(r.x+r.w,side==1 and w/2 or w)
     if right>left then g.setScissor(left,r.y,right-left,r.h);g.draw(img,q[side],side==1 and 0 or w-iw*k/2,0,0,k,k)end
    end end
   end
  end
  end)
  g.pop();if not ok then P.decorationFailed=true;R.warn('portrait decoration disabled',err)end
 end
 function P.shutdown()
  for _,q in pairs(P.frameQuads or {})do for _,v in ipairs(q)do if v.release then v:release()end end end
  P.frames={};P.frameQuads={};P.decorationFailed=nil
 end
 return P
end
