local root='floating_glass_frlg/'
local Recorder=dofile('tests/svg_recorder.lua')
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function near(a,b,msg) check(math.abs(a-b)<.0001,msg) end
local rec=Recorder.new(1920,1080);local g=rec.graphics;local clears=0;local calls={}
g.clear=function() clears=clears+1 end
local oldDraw=g.draw;g.draw=function(...) calls[#calls+1]={...};return oldDraw(...) end
love={graphics=g}
local terrain='grass';local delegate=0
local Bg={terrainId=function() return 0 end,sheetKey=function() return terrain end,draw=function() delegate=delegate+1;return true end}
local options={};local R={load=function(p) return assert(loadfile(root..p))() end,
 option=function(k,v) if options[k]~=nil then return options[k] end;return v end,
 module=function() return Bg end,warn=function() end,battle={scene=true},
 framing={ratio=function() return 16/9 end,drop=function() return 8 end,wideReady=true},
 mod={assets={image=function(_,p) return Recorder.image(root..p) end}}}
function R.wrap(t,k,fn) local old=t[k];t[k]=function(...) return fn(old,...) end end
local S=R.load('gen3/scenery.lua')(R);S.installLoaded()
Bg.draw();check(S.wideActive and clears==1,'grass makes native background transparent')
check(#calls==0,'HD bases are not baked into the 240x160 canvas')
S.drawWide(1920,1080,{x=0,y=0,w=1920,h=1080})
check(#calls==3,'background followed by two separately sized arenas')
local c=calls[1];local iw,ih=c[1]:getDimensions()
check(math.abs(iw/ih-21/9)<.01,'supplied camera art is approximately 21:9')
near(c[5],1080/ih,'height-fit horizontal scale');near(c[6],1080/ih,'uniform image scale')
near(c[2],(1920-iw*1080/ih)/2,'centered horizontal overflow');near(c[3],0,'top aligned')
near(ih*c[6],1080,'fills exact window height')
for _,size in ipairs({{800,600},{240,160},{2560,1080},{3840,1080},{720,1280}}) do
 S.drawWide(size[1],size[2]);local d=calls[#calls]
 near(d[5],d[6],'arena scale uniform at any window ratio')
 for _,side in ipairs({'player','enemy'}) do
  local box=S.arenaRects[side];local gx,gy=S.arenaGround(side,{x=0,y=0,w=size[1],h=size[2]})
  near(box.cx,gx,'arena under projected sprite x');near(box.cy,gy,'arena under projected feet')
  check(box.l>=-.01 and box.r<=size[1]+.01 and box.t>=-.01 and box.b<=size[2]+.01,'arena stays inside window')
  check(box.width<=size[2]*.51,'arena no longer scaled to full window')
 end
end
check(#rec.stack==0,'wide render restores graphics state')
options.scenery='native';Bg.draw();check(not S.wideActive,'native option delegates')
options.scenery='auto';terrain='cave';Bg.draw();check(S.wideActive and S.selected=='cave','cave uses its own wide artwork')
local before=#calls;S.drawWide(1920,1080);check(#calls==before+3,'cave uses only its own supplied circles')
terrain='grass';R.framing.wideReady=false;Bg.draw();check(not S.wideActive,'missing final renderer retains native scenery')
R.framing.wideReady=true;R.battle.scene=false;Bg.draw();check(not S.wideActive,'unowned scenes delegate')
R.battle.sceneryScene=true;Bg.draw();check(S.wideActive,'native special UI may retain custom scenery')
-- Preview is just the production full-window background, not a game capture.
rec=Recorder.new(1920,1080);love.graphics=rec.graphics;S.wideActive=true
S.drawWide(1920,1080);rec:save('preview_frames/30-Fundo-Ultrawide.svg')
print(count..' ultrawide checks passed; real 21:9 assets, simulated graphics.')
