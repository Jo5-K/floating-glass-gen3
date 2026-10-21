-- Rendered alpha bounds, transform and pixel spacing, with simulated graphics.
local n=0
local function eq(a,b,msg) assert(math.abs(a-b)<.00001,msg..': '..tostring(a)..' ~= '..b);n=n+1 end
local function check(v,msg) assert(v,msg);n=n+1 end
local calls=0;local canvas='original';local depth=0
local g={getCanvas=function() return canvas end,setCanvas=function(c) canvas=c end,
 push=function() depth=depth+1 end,pop=function() depth=depth-1 end,
 origin=function() end,setShader=function() end,setScissor=function() end,clear=function() end,setColor=function() end,
 draw=function() calls=calls+1 end,transformPoint=function(x,y) return x,y+8 end,
 newCanvas=function() return {newImageData=function() return {getPixel=function(_,x,y)
  return 1,1,1,(x>=10 and x<50 and y>=12 and y<61) and 1 or 0 end} end} end}
love={graphics=g}
local R={warn=function(_,e) error(e) end}
local A=dofile('floating_glass_frlg/gen3/anchors.lua')(R)
local img={getDimensions=function() return 64,64 end}
A.register({image=img},'player');local draw=g.draw
A.begin();g.draw(img,72,80,0,1,1,32,32);A.finish()
check(g.draw==draw,'draw observer restored');check(canvas=='original' and depth==0,'alpha readback restores canvas/state')
local b=A.bounds.player;eq(b.l,50,'alpha left');eq(b.r,90,'alpha right');eq(b.t,68,'alpha top plus drop');eq(b.b,117,'alpha bottom plus drop')
local p=A.project('player',{x=100,y=20,w=1440,h=960})
eq(p.l,400,'fitted left');eq(p.b,722,'fitted bottom')
local x,y=A.place('player',p,300,100,1920,1080);eq(y+100,p.b,'ally HUD aligned with base');eq(x,p.r+5,'ally five pixels right of sprite')
x,y=A.place('enemy',{l=1300,r=1500,t=300,b=500},300,100,1920,1080)
eq(x+300,1292,'eight window pixels left');eq(y+100,292,'eight window pixels above')
x,y=A.place('enemy',{l=2,r=20,t=3,b=30},300,100,1920,1080);eq(x,0,'left clamp');eq(y,0,'top clamp')
x,y=A.place('player',{l=1700,r=1900,t=900,b=1080},300,100,1920,1080);eq(y,980,'bottom clamp')
A.begin();g.draw(img,72,80,math.pi/2,-2,2,32,32);A.finish();b=A.bounds.player
eq(b.r-b.l,98,'rotated flipped sprite width');eq(b.b-b.t,80,'rotated flipped sprite height')
local count=calls;A.alphaBounds(img);eq(calls,count,'readback cached per texture')
local hd={getDimensions=function() return 256,256 end};A.register({image=hd},'enemy');A.pixels[hd]={0,0,256,256}
A.begin();g.draw(hd,176,40,0,.25,.25,128,128);A.finish()
eq(A.bounds.enemy.r-A.bounds.enemy.l,64,'mod image dimensions and draw scale used')
A.begin();local ok=pcall(function() error('native scene error') end);A.finish();check(not ok and g.draw==draw,'observer restored after scene failure')
A.begin()
for row=12,60 do
 local q={getViewport=function() return 0,row,64,1 end}
 g.draw(img,q,72,48+row,0,1,1,32,0)
end
A.finish();eq(A.bounds.player.t,68,'strip effect union top');eq(A.bounds.player.b,117,'strip effect union bottom')
local small={getDimensions=function() return 32,16 end};local saved=g.newCanvas;g.newCanvas=nil
A.register({image=small},'enemy');A.begin();g.draw(small,20,30);A.finish();g.newCanvas=saved
eq(A.bounds.enemy.r-A.bounds.enemy.l,32,'unsupported readback uses texture bounds');check(A.fallback,'fallback recorded')
-- Stable anchors survive animation, but refresh on a new battler or layout.
local probe=A.probe;A.probe=function() end
local st={player={mon={}},enemy={mon={}}}
A.prepare(st,{player=true},'drop8');A.begin();g.draw(img,72,80,0,1,1,32,32);A.finish()
local fixed=A.fixed.player;check(fixed~=nil,'first settled sprite freezes anchor')
A.begin();g.draw(img,90,60,0,1,1,32,32);A.finish()
check(A.fixed.player==fixed,'animation does not move fixed HUD')
local resized=A.project('player',{x=0,y=0,w=480,h=320});eq(resized.r,fixed.r*2,'fixed anchor responds to resize')
st.player.mon={};A.prepare(st,{player=true},'drop8');check(A.fixed.player==nil,'switch releases old anchor')
A.begin();g.draw(img,100,90,0,1,1,32,32);A.finish();check(A.fixed.player.r~=fixed.r,'new battler gets new anchor')
A.prepare(st,{player=false},'drop9');check(A.fixed.player==nil,'layout drop resets anchor')
A.begin();g.draw(img,100,90);A.finish();check(A.fixed.player==nil,'entry animation cannot freeze HUD')
-- Another mod may install its draw wrapper lazily inside the observed pass.
local wrappedCalls=0
A.begin();local observed=g.draw
local outer=function(...) wrappedCalls=wrappedCalls+1;return observed(...) end
g.draw=outer;g.draw(img,72,80);A.finish()
check(g.draw==outer,'late third-party wrapper preserved')
g.draw(img,72,80);eq(wrappedCalls,2,'retired observer safely delegates')
A.begin();g.draw(img,72,80);A.finish();check(g.draw==outer,'subsequent pass preserves chain')
A.probe=probe
print(n..' sprite anchor checks passed; simulated readback, no GPU/ROM.')
