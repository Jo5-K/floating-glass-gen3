-- Actual Display.fit contract; simulated window, renderer and graphics.
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function near(a,b,msg) check(math.abs(a-b)<.0001,msg) end
local ww,wh=1920,1080
local safe,cut
local Safe={windowRect=function() if safe then return (table.unpack or unpack)(safe) end;return 0,0,ww,wh end}
local Play={cutout=function() if cut then return (table.unpack or unpack)(cut) end end}
package.loaded['src.render.GameViewport']={}
package.loaded['src.core.SafeArea']=Safe
package.loaded['src.render.Playfield']=Play
local depth=0;local painted=0;local drawn=0
love={graphics={getDimensions=function() return ww,wh end,push=function() depth=depth+1 end,
 pop=function() depth=depth-1 end,origin=function() end,setShader=function() end,
 setColor=function() end,draw=function() drawn=drawn+1 end}}
local D=dofile('tests/fixtures/Display-0.3.91.lua');local original=D.fit
local presented=0;D.present=function() presented=presented+1;return true end
local canvas={getDimensions=function() return 240,160 end}
local args;local Renderer={canvas=canvas,blitCanvas=function(_,...) args={...};return 'native-blit' end}
local options={};local owns=true
local modules={['src.core.game3.display']=D,['src.render.Renderer']=Renderer,['src.core.SafeArea']=Safe,['src.render.Playfield']=Play}
local R={module=function(n) return modules[n] end,option=function(k,v) if options[k]~=nil then return options[k] end;return v end,
 battle={owns=function() return owns end},scenery={wideActive=false,drawWide=function(w,h) near(w,ww,'wide uses full window width');near(h,wh,'wide uses full window height');painted=painted+1 end}}
function R.wrap(t,k,fn) if type(t[k])~='function' then return end;local next=t[k];t[k]=function(...) return fn(next,...) end end
local F=dofile('floating_glass_frlg/gen3/framing.lua')(R);F.installLoaded();F.installLoaded()
for _,size in ipairs({{1920,1080},{1280,1024},{480,270},{600,1000}}) do
 ww,wh=size[1],size[2]
 for _,mode in ipairs({'window','native','4:3','16:9'}) do
  options.battle_aspect=mode
  local a={D.fit(ww,wh)}
  if mode=='native' then local b={original(ww,wh)};for i=1,6 do near(a[i],b[i],'native fit is unchanged') end
  else
   near(a[4]/a[5],mode=='window' and ww/(wh>ww and wh*.48 or wh) or (mode=='4:3' and 4/3 or 16/9),'target aspect')
   check(a[2]>=0 and a[3]>=0 and a[2]+a[4]<=ww+.001 and a[3]+a[5]<=wh+.001,'frame fits window')
   near(a[1]*240,a[4],'horizontal native projection');near(a[6]*160,a[5],'vertical native projection')
   local zones={{colors=false}}
   check(Renderer:blitCanvas(canvas,3,3,zones,3,3,0,0,0,0,720,480,2,2)=='native-blit','native renderer called')
   near(args[2],a[1],'plane horizontal scale');near(args[3],a[6],'plane vertical scale')
   check(args[4]==zones,'palette zones retained');near(args[11],a[4],'clip width follows aspect');near(args[12],a[5],'clip height follows aspect')
  end
 end
end
ww,wh=1920,1080;safe={50,25,1800,1000};options.battle_aspect='16:9'
local a={D.fit()};check(a[2]>=50 and a[3]>=25 and a[2]+a[4]<=1850.001,'safe area preserved')
cut={200,100,800,600};a={D.fit()};check(a[2]>=200 and a[3]>=100 and a[2]+a[4]<=1000.001,'playfield cutout preserved')
cut=nil;safe=nil;owns=false;a={D.fit()};local b={original()};for i=1,6 do near(a[i],b[i],'outside overlay delegates') end
owns=true;R.scenery.wideActive=true
Renderer:blitCanvas(canvas,3,3,nil,3,3,0,0,0,0,720,480,1,1);check(painted==1,'wide background behind native canvas once')
D.planesBroken=true;D._canvas=canvas;D.present({},ww,wh)
check(painted==2 and drawn==1 and presented==1,'flat fallback redraws canvas without reexecuting native scene')
near(depth,0,'graphics stack restored');near(F.drop(),8,'default vertical drop');options.battle_drop=100;near(F.drop(),12,'drop clamped')
print(count..' framing checks passed; real Display.fit, simulated window/render host.')
