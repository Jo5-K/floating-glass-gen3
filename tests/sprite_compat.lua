-- Optional public HD bridge and mode policies. Simulated renderer, no GPU/ROM.
local Rec=dofile('tests/svg_recorder.lua');local root='floating_glass_frlg/'
local n=0
local function check(v,msg) assert(v,msg);n=n+1 end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg..': '..tostring(a)..' ~= '..tostring(b)) end
local opts={};local state={player={mon={hp=20}},enemy={mon={hp=30}}};local active=true
local tags={};local fit=true;local enabled=true;local switches={};local present=true
local api={tagOf=function(img) return tags[img] end,enabled=function() return enabled end,
 fitEnabled=function() return fit end,setFit=function(value) fit=value;switches[#switches+1]=value end}
local R={mod={find=function(_,id) if present and id=='gen3-hd-sprites' then return {exports=api} end end}}
R.option=function(key,default) if opts[key]~=nil then return opts[key] end;return default end
R.module=function(name) if name=='src.core.game3.battle.anim' then return {present=function() return {} end} end end
R.warn=function(_,err) error(err) end
R.battle={owns=function() return active and not state.double end,context=function() return state end,elevation=function() return 0 end}
R.camera=dofile(root..'gen3/camera.lua')(R);local C=R.camera
R.compat=dofile(root..'gen3/sprite_compat.lua')(R);local X=R.compat
R.shadows=dofile(root..'gen3/shadows.lua')(R);local S=R.shadows
local A=dofile(root..'gen3/anchors.lua')(R);R.battle.anchors=A
local rec=Rec.new(1800,950);local g=rec.graphics;love={graphics=g};g.getDimensions=function() return 1800,950 end
check(C.native(),'unset camera defaults to native')
opts.shadows='both';check(not S.enabled('player') and not S.enabled('enemy'),'native camera never adds shadows, including stored both setting')
local plan=C.plan(state,'forest',12)
near(plan.x,0,'native camera has no scene x shift');near(plan.y,0,'native camera has no scene y shift');near(plan.k,1,'native camera has no scene zoom');near(plan.drop,0,'native camera has no added drop')
for _,mode in ipairs({'current','g9_compat','native_depth'}) do
 opts.battle_camera=mode;opts.shadows='auto'
 check(S.enabled('player') and S.enabled('enemy'),'non-native auto includes both sides: '..mode)
 local k,dy=C.hudAdjustment()
 if mode=='native_depth' then near(k,1,'foreground HUD scale preserved');near(dy,0,'foreground HUD height preserved')
 else near(k,.8,'Original/G9 HUD twenty percent smaller');near(dy,-5,'Original/G9 HUD five window pixels higher') end
end
opts.battle_camera='current';opts.shadows='off';check(S.enabled('player') and S.enabled('enemy'),'old saved off follows new non-native camera shadow policy')
opts.shadows='auto'
opts.battle_camera='native';local k,dy=C.hudAdjustment();near(k,1,'native HUD scale preserved');near(dy,0,'native HUD height preserved')
opts.battle_camera='current';check(C.mode()=='original','stored current value keeps Original meaning')
opts.battle_camera='native_depth';check(C.mode()=='foreground','old misleading native_depth value keeps foreground meaning')
opts.battle_camera='g9_compat'
-- Cooperative camera ownership, no writes to stored user preferences.
local token=X.begin();check(token==api and not fit,'compatibility pass suspends HD automatic refit')
X.finish(token);check(fit and #switches==2 and switches[1]==false and switches[2]==true,'public HD refit restored exactly')
fit=false;check(X.begin()==nil and not fit,'already-disabled HD refit is not enabled by bridge');X.finish(nil);check(not fit,'nil token does not modify HD state');fit=true
opts.battle_camera='current';check(X.begin()==nil and fit,'Original does not take HD camera ownership')
opts.battle_camera='g9_compat';state.double=true;check(X.begin()==nil and fit,'unsupported doubles retain HD camera ownership');state.double=false
active=false;check(X.begin()==nil,'inactive UI never changes another mod');active=true
present=false;check(X.begin()==nil,'missing optional HD mod is a native fallback');present=true
enabled=false;check(X.begin()==nil,'disabled HD pass is not acquired');enabled=true
local texture={getDimensions=function() return 1024,1024 end}
local quad=g.newQuad(200,300,80,96,1024,1024)
local player={getDimensions=function() return 64,64 end,typeOf=function(_,t) return t=='Canvas' end}
local enemy={getDimensions=function() return 64,64 end,typeOf=function(_,t) return t=='Canvas' end}
local ps={texture=texture,quad=quad,lowPivot={32,48},pivot={40,88},scale=.5,body={8,10,72,88},side='player'}
local es={texture=texture,quad=quad,lowPivot={32,44},pivot={40,80},scale=.5,top=6,side='enemy'}
tags[player]=ps;tags[enemy]=es
local box,foot,spec=X.geometry(player)
near(box[1],16,'HD body bounds transformed from frame pivot');near(box[4],48,'HD resting body ends on lowPivot')
near(foot[1],32,'HD rest foot x read from public metadata');near(foot[2],48,'HD rest foot y read from public metadata');check(spec==ps,'public tag is read, not replaced')
local image,args=X.shadowImage(player,{72,80,0,1,1,32,32})
check(image==texture and args[1]==quad,'shadow reuses exact current full-resolution texture and frame')
near(args[2],72,'HD shadow pivot x');near(args[3],96,'HD shadow pivot y');near(args[5],.5,'HD shadow retains provider scale');near(args[7],40,'HD shadow frame origin x');near(args[8],88,'HD shadow frame origin y')
local strip=g.newQuad(0,12,64,1,64,64);local stripArgs={strip,72,60,0,1,1,32,0}
image,args=X.shadowImage(player,stripArgs);check(image==player and args==stripArgs,'distortion strip stays cropped, never expanded to full HD sprite')
local renders={};local hdShadows={};local oldDraw=g.draw
local function downstream(img,...)
 local args={...};local q=type(args[1])~='number' and table.remove(args,1) or nil
 if img==texture then
  local x,y=g.transformPoint(args[1],args[2]);hdShadows[#hdShadows+1]={x=x,y=y,quad=q}
 end
 local b,f=X.geometry(img,q);b=b or A.pixels[img]
 if not b then return end
 local x,y,r,sx,sy,ox,oy=args[1],args[2],args[3] or 0,args[4] or 1,args[5] or args[4] or 1,args[6] or 0,args[7] or 0
 local l,t=g.transformPoint(x+(b[1]-ox)*sx,y+(b[2]-oy)*sy)
 local right,bottom=g.transformPoint(x+(b[3]-ox)*sx,y+(b[4]-oy)*sy)
 renders[#renders+1]={img=img,l=l,t=t,r=right,b=bottom}
end
g.draw=downstream
-- Native send-out pose is measured first; a tagged replacement must invalidate it.
local nativeImage={getDimensions=function() return 64,64 end};A.pixels[nativeImage]={8,8,56,60}
A.register({image=nativeImage,lru=true},'player')
plan=C.plan(state,'forest',8);A.prepare(state,{player=true,enemy=true},plan.signature);A.reproject(plan)
g.push();C.apply(plan);A.begin();g.draw(nativeImage,72,80,0,1,1,32,32);A.finish();g.pop()
check(A.sources.player=='native','native send-out source tracked')
local oldFixed=A.fixed.player
for _,height in ipairs({600,950,1440}) do
 g.getDimensions=function() return 1800,height end
 g.push();C.apply(plan);A.begin()
 A.register({image=player},'player');g.draw(player,72,80,0,1,1,32,32)
 A.register({image=enemy},'enemy');g.draw(enemy,176,40,0,1,1,32,32)
 A.finish();g.pop()
 check(A.sources.player=='hd' and A.sources.enemy=='hd','HD source discovered independently per battler')
 check(A.fixed.player~=oldFixed,'replacement does not inherit native send-out anchor')
 local px,py=A.displayGround('player');local ex,ey=A.displayGround('enemy')
 near(px,24+.8*72,'G9 ally ground x matches Original profile');near(py,32+.8*(108+8),'G9 ally ground y matches Original profile')
 near(ex,24+.8*176,'G9 enemy ground x matches Original profile');near(ey,32+.8*(64+8),'G9 enemy ground y matches Original profile')
 near(A.fixed.player.b-A.fixed.player.t,(88-10)*.5*.8,'HD geometry uses tagged body, not stand-in canvas dimensions')
 check(#hdShadows>=2,'both silhouettes draw from HD texture during actual observed body pass')
 local own,foe=hdShadows[#hdShadows-1],hdShadows[#hdShadows]
 near(own.x,px,'HD silhouette contact x follows translated ally');near(own.y,py,'HD silhouette contact y follows translated ally')
 near(foe.x,ex,'HD silhouette contact x follows translated enemy');near(foe.y,ey,'HD silhouette contact y follows translated enemy')
 -- Animation changes its atlas frame, preserving its resting-foot metadata.
 local prior=A.fixed.player;local nextQuad=g.newQuad(280,300,80,96,1024,1024);ps.quad=nextQuad
 image,args=X.shadowImage(player,{72,80,0,1,1,32,32});check(args[1]==nextQuad,'animated HD shadow follows the supplied frame without ticking animation')
 g.push();C.apply(plan);A.begin();g.draw(player,72,80,0,1,1,32,32);A.finish();g.pop()
 check(A.fixed.player==prior,'idle frame does not move fixed ground')
 near((select(2,A.displayGround('player'))),py,'idle frame keeps arena grounded')
 check(#rec.stack==0 and g.draw==downstream,'optional bridge restores drawing state')
end
-- A provider changing its resting-foot layout must be remeasured, unlike a frame.
local before=A.fixed.player;ps.lowPivot={32,40}
g.push();C.apply(plan);A.begin();g.draw(player,72,80,0,1,1,32,32);A.finish();g.pop()
check(A.fixed.player~=before,'changed provider foot layout refreshes the anchor')
near(select(2,A.displayGround('player')),32+.8*(108+8),'provider layout change still aligns ground')
-- No HD dependency: a widened G9 canvas uses measured alpha and draw origin.
present=false;local wide={getDimensions=function() return 128,96 end,typeOf=function(_,t) return t=='Canvas' end};A.pixels[wide]={8,12,120,90}
A.register({image=wide},'player')
g.push();C.apply(plan);A.begin();g.draw(wide,72,80,0,.5,.5,64,48);A.finish();g.pop()
check(A.sources.player=='replacement','wide replacement works with HD absent')
near(select(2,A.displayGround('player')),32+.8*(108+8),'wide replacement feet aligned without HD')
local fixed=A.fixed.player
A.capture(wide,strip,72,60,0,1,1,32,0);check(A.fixed.player==fixed,'native strip effect does not invalidate settled replacement layout')
-- A different Pokémon may not reuse the prior correction, even before new draw.
state.player.mon={hp=20};local dx,dy=C.activeOffset(A,'player');near(dx,0,'switch drops old x correction');near(dy,0,'switch drops old y correction')
-- Original does not inspect HD tags or apply compatibility offsets.
opts.battle_camera='current';present=true;check(X.tag(player)==nil,'Original never uses HD correction geometry')
dx,dy=C.activeOffset(A,'enemy');near(dx,0,'Original enemy x untouched');near(dy,0,'Original enemy y untouched')
check(tags[player]==ps and ps.texture==texture and ps.scale==.5,'bridge never rewrites third-party tags or scaling')
check(state.enemy.mon.hp==30,'presentation never changes battle data')
g.draw=oldDraw
print(n..' sprite compatibility checks passed; optional public HD tags, camera policies, source changes and grounded presentation; simulated renderer only.')
