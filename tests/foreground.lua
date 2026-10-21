-- Independent ally translation: simulated graphics, exact native .93 coordinate
-- service. These checks explicitly detect alpha.15's unwanted shared zoom.
local Rec=dofile('tests/svg_recorder.lua')
local n=0
local function check(v,msg) assert(v,msg);n=n+1 end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg..': '..tostring(a)..' ~= '..tostring(b)) end
local oldBit=package.loaded.bit
package.loaded.bit=oldBit or {bxor=function(a,b)
 local out,p=0,1
 while a>0 or b>0 do if a%2~=b%2 then out=out+p end;a=math.floor(a/2);b=math.floor(b/2);p=p*2 end
 return out
end}
local Coords=dofile('tests/fixtures/AnimCoords-0.3.93.lua')
local opts={battle_camera='native_depth'}
local state={player={mon={hp=413}},enemy={mon={hp=40}}}
local active=true;local height=900;local fittedHeight
local R={}
R.option=function(key,default) return opts[key]~=nil and opts[key] or default end
R.warn=function(_,err) error(err) end
R.module=function(name)
 if name=='src.core.game3.battle.anim_coords' then return Coords end
 if name=='src.core.game3.display' and fittedHeight then return {fit=function() return 1,0,0,240,fittedHeight,1 end} end
end
local patches={}
R.wrap=function(target,key,wrapper)
 local original=target[key];if type(original)~='function' then return end
 target[key]=function(...) return wrapper(original,...) end
 patches[#patches+1]={target,key,original}
end
R.battle={owns=function() return active end,context=function() return state end}
local root='floating_glass_frlg/'
local C=dofile(root..'gen3/camera.lua')(R);R.camera=C
local A=dofile(root..'gen3/anchors.lua')(R);R.battle.anchors=A
local rec=Rec.new(1600,height);local g=rec.graphics;love={graphics=g}
g.getDimensions=function() return 1600,height end
local originalDraw=g.draw
local renders={};local fail=false
local function spy(img,x,y,rotation,sx,sy,ox,oy)
 if fail then error('intentional draw failure') end
 local b=A.pixels[img];sx,sy=sx or 1,sy or sx or 1;ox,oy=ox or 0,oy or 0
 local l,t=g.transformPoint(x+(b[1]-ox)*sx,y+(b[2]-oy)*sy)
 local r,bottom=g.transformPoint(x+(b[3]-ox)*sx,y+(b[4]-oy)*sy)
 renders[#renders+1]={l=l,t=t,r=r,b=bottom}
end
g.draw=spy
-- Large transparent textures and different origins, at the same native size.
local textures={
 {w=64,h=64,b={5,8,61,64},s=1,ox=32,oy=32},
 {w=128,h=128,b={12,16,124,128},s=.5,ox=64,oy=64},
 {w=512,h=512,b={60,80,476,480},s=.125,ox=256,oy=256}
}
local enemy={getDimensions=function() return 64,64 end}
A.register({image=enemy},'enemy');A.pixels[enemy]={12,10,52,61}
local function nativeDraw(img,key,tex)
 A.register({image=img},key)
 g.draw(img,key=='player' and 72 or 176,key=='player' and 80 or 40,0,tex.s,tex.s,tex.ox,tex.oy)
end
for _,h in ipairs({320,600,900,1080,1440}) do
 height=h
 for _,tex in ipairs(textures) do
  state.player.mon={hp=413};state.enemy.mon={hp=40}
  local img={getDimensions=function() return tex.w,tex.h end}
  A.pixels[img]=tex.b
  local plan=C.plan(state,'forest',8)
  near(plan.k,1.05,'depth scale fixed, never derived from sprite dimensions')
  A.prepare(state,{player=true,enemy=true},'test');A.reproject(plan)
  g.push();C.apply(plan)
  A.begin();nativeDraw(enemy,'enemy',{s=1,ox=32,oy=32});nativeDraw(img,'player',tex);A.finish();g.pop()
  local ally=renders[#renders];local foe=renders[#renders-1]
  near(ally.b*h/160,h+1,'ally actual rendered alpha base one window pixel below edge')
  near((ally.l+ally.r)/2,84,'ally actual rendered alpha center at 35 percent')
  near(ally.r-ally.l,(tex.b[3]-tex.b[1])*tex.s*plan.k,'ally width unchanged')
  near(ally.b-ally.t,(tex.b[4]-tex.b[2])*tex.s*plan.k,'ally height unchanged')
  near(foe.r-foe.l,40*plan.k,'enemy width unchanged')
  near(foe.b-foe.t,51*plan.k,'enemy height unchanged')
  near(foe.l,plan.x+(176+12-32)*plan.k,'enemy x unchanged')
  near(foe.b,plan.y+(40+61-32+8)*plan.k,'enemy y unchanged')
  local projected=A.project('player',{x=10,y=20,w=1600,h=h})
  near(projected.b,20+h+1,'arena uses translated visible ground')
  near((projected.l+projected.r)/2,10+1600*.35,'arena follows translated horizontal anchor')
  local fixed=A.fixed.player
  local rawBottom=fixed.b
  for i=1,3 do
   g.push();C.apply(plan);A.begin();nativeDraw(img,'player',tex);A.finish();g.pop()
   near(renders[#renders].b*h/160,h+1,'repeat draw never accumulates translation')
  end
  check(A.fixed.player==fixed,'camera keeps original settled measurement')
  near(fixed.b,rawBottom,'camera never rewrites measured pose')
  -- Preserve native idle movement relative to the settled anchor.
  g.push();C.apply(plan);A.begin()
  g.draw(img,72,83,0,tex.s,tex.s,tex.ox,tex.oy);A.finish();g.pop()
  near(renders[#renders].b,160+160/h+3*plan.k,'native animation offset remains relative to anchored base')
  height=h*2
  g.push();C.apply(plan);A.begin();nativeDraw(img,'player',tex);A.finish();g.pop()
  near(renders[#renders].b*height/160,height+1,'resize keeps one window pixel without new zoom')
  near(renders[#renders].r-renders[#renders].l,ally.r-ally.l,'resize does not modify native sprite scale')
  height=h
  check(#rec.stack==0 and g.draw==spy,'draw observer and transform stack restored')
 end
end
-- A safe-area/game rectangle may be shorter than the full window.
fittedHeight=400
local dx,dy=C.activeOffset(A,'player')
near(A.fixed.player.b+dy*A.cameraPlan.k,160+160/400,'fitted game rectangle determines pixel conversion')
fittedHeight=nil
-- The exact native coordinate service returns copies for animation endpoints.
local original=Coords.SINGLES[0];local x,y=original.x,original.y
C.installLoaded();C.installLoaded();check(#patches==1,'native coordinate service wrapped only once')
dx,dy=C.activeOffset(A,'player')
local moved=Coords.coords(state,0)
check(moved~=original,'translated native animation endpoint is a copy')
near(moved.x,x+dx,'native particles receive ally x offset');near(moved.y,y+dy,'native particles receive ally y offset')
near(moved[1],moved.x,'native positional index x consistent');near(moved[2],moved.y,'native positional index y consistent')
near(original.x,x,'native base x untouched');near(original.y,y,'native base y untouched')
check(Coords.coords(state,1)==Coords.SINGLES[1],'enemy coordinate identity unchanged')
local override={x=90,y=100,90,100,vm=true};local overrides={[0]=override}
Coords.setCoordinateOverrides(overrides)
local shifted=Coords.coords(state,0)
near(shifted.x,90+dx,'VM coordinate override retained plus presentation offset')
check(shifted.vm and Coords._coordinateOverrides==overrides and overrides[0]==override,'VM override object never replaced')
near(override.y,100,'VM override never mutated')
Coords.setCoordinateOverrides(nil)
-- Disabling presentation, changing modes, switching or entering doubles must
-- delegate native endpoints unchanged and must not retain the previous ally.
active=false;check(Coords.coords(state,0)==original,'inactive overlay delegates original coordinate table');active=true
opts.battle_camera='current';check(Coords.coords(state,0)==original,'current camera unchanged');opts.battle_camera='native_depth'
state.double=true;check(Coords.coords(state,0)==Coords.DOUBLES[0],'double camera untouched');state.double=false
state.player.mon={};check(Coords.coords(state,0)==original,'switch immediately drops stale ally offset')
A.prepare(state,{player=false},'test');A.reproject(C.plan(state,'forest',8))
dx,dy=C.activeOffset(A,'player');near(dx,0,'unsettled new sprite x has native fallback');near(dy,0,'unsettled new sprite y has native fallback')
-- Shadow receives the translated ground under the same shifted transform.
A.ready.player=true
local img={getDimensions=function() return 64,64 end};A.pixels[img]={5,8,61,64};A.register({image=img},'player')
local shadow
R.shadows={register=function() end,beginFrame=function() end,draw=function(_,_,key,anchors)
 if key=='player' then
  local b=anchors.displayBounds(key);local gx,gy=g.inverseTransformPoint((b.l+b.r)/2,b.b)
  shadow={gx,gy,g.transformPoint(gx,gy)}
 end
end}
g.push();C.apply(A.cameraPlan);A.begin();nativeDraw(img,'player',{s=1,ox=32,oy=32});A.finish();g.pop()
near(shadow[3],84,'shadow projection uses translated ally center')
near(shadow[4]*height/160,height+1,'shadow projection uses translated ally base')
-- A particle echo using the same texture already carries native endpoint
-- displacement; the body observer must neither translate nor shadow it again.
R.battle.particleDepth=1
g.push();C.apply(A.cameraPlan);A.begin()
g.draw(img,72+dx,80+dy,0,1,1,32,32);A.finish();g.pop()
near(renders[#renders].l,A.cameraPlan.x+(72+dx+5-32)*A.cameraPlan.k,'particle echo not shifted twice')
R.battle.particleDepth=0
-- A throwing downstream draw must not leak the per-sprite transform.
fail=true;g.push();C.apply(A.cameraPlan);A.begin()
local ok=pcall(nativeDraw,img,'player',{s=1,ox=32,oy=32});A.finish();g.pop()
check(not ok and #rec.stack==0 and g.draw==spy,'failed downstream draw restores all camera transforms')
check(state.enemy.mon.hp==40,'rendering never changes enemy HP')
for i=#patches,1,-1 do local p=patches[i];p[1][p[2]]=p[3] end
check(Coords.coords(state,0)==original,'unload restores exact native coordinate function')
g.draw=originalDraw;package.loaded.bit=oldBit
print(n..' foreground checks passed; independent ally translation, native .93 animation coords, simulated graphics only.')
