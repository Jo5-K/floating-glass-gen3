-- Production final overlays + real assets on a graphics recorder, not a GPU test.
local root='floating_glass_frlg/'
local Rec=dofile('tests/svg_recorder.lua')
local function part(p) return assert(loadfile(root..p))() end
local options={};local time=0;local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function near(a,b,msg) check(math.abs(a-b)<.0001,msg) end
local R={load=part,module=function() end,warn=function(_,err) error(err) end,
 option=function(k,v) if options[k]~=nil then return options[k] end;return v end,
 mod={assets={image=function(_,p) return Rec.image(root..p) end}}}
local S=part('gen3/scenery.lua')(R);S.current=1
local function frame(w,h,t)
 time=t;local rec=Rec.new(w,h);local last
 love={graphics=rec.graphics,timer={getTime=function() return time end}}
 local draw=rec.graphics.draw
 rec.graphics.draw=function(...) last={...};return draw(...) end
 S.foreground(w,h)
 check(#rec.stack==0,'foreground restores graphics state')
 return last,rec
end
for _,size in ipairs({{1920,1080},{1280,1024},{600,1000},{3440,1440}}) do
 for _,t in ipairs({0,1,2,3,4}) do
  local c=frame(size[1],size[2],t);local iw,ih=c[1]:getDimensions()
  near(c[6],c[7],'lens scale remains uniform')
  near(c[3]+iw/2*c[6],size[1],'right half follows window edge')
  near(c[4]+ih*c[7],size[2],'foreground bottom follows window')
  local base=math.max(size[1]/iw,size[2]/ih)*.65
  check(c[6]/base>=1.0019 and c[6]/base<=1.0221,'elastic motion bounded')
 end
end
local a=frame(1920,1080,0);local b=frame(1920,1080,4)
near(a[6],b[6],'four-second loop continuous')
local c=frame(1920,1080,1/60);check(math.abs(c[6]-a[6])<.001,'motion small per-frame delta')
options.lens_motion=false;a=frame(1920,1080,0);b=frame(1920,1080,2);near(a[6],b[6],'motion disabled')
options.lens_size=1;local full=frame(1920,1080,0);near(a[6]/full[6],.65,'vegetation 35 percent smaller uniformly')
options.lens_size=nil;options.lens_motion=true
-- Use production controls to inspect the new palette with the new scene layers.
local rec=Rec.new(1280,720);love={graphics=rec.graphics,timer={getTime=function() return 2 end}}
S.selected='forest';S.activeImage=R.mod.assets:image(S.resolve('firered','grass').path)
S.wideActive=true
local g=love.graphics
local spriteSpecs={
 {side='enemy',path='gen3/assets/pokemon/front/5/normal/rattata.png',x=176,y=48,bbox={10,10,46,53}},
 {side='player',path='gen3/assets/pokemon/back/3/normal/bulbasaur.png',x=72,y=88,bbox={10,16,55,48}},
}
-- Simulated native pass with the production composition transform; not gameplay.
local boxes={}
local function stage()
 g.scale(1280/240,720/160);g.translate(24,32);g.scale(.8,.8);g.translate(0,8)
end
for _,sp in ipairs(spriteSpecs) do
 g.push('all');stage()
 local l,t=g.transformPoint(sp.x+sp.bbox[1]-32,sp.y+sp.bbox[2]-32)
 local r,b=g.transformPoint(sp.x+sp.bbox[3]-32,sp.y+sp.bbox[4]-32)
 boxes[sp.side]={l=l,t=t,r=r,b=b};g.pop()
end
R.battle={anchors={fixed={enemy=true,player=true},project=function(side) return boxes[side] end}}
S.drawWide(1280,720)
g.push('all');stage()
for _,sp in ipairs(spriteSpecs) do
 local img=R.mod.assets:image(sp.path);local iw,ih=img:getDimensions()
 local q=g.newQuad(0,0,64,64,iw,ih);g.setColor(1,1,1,1)
 g.draw(img,q,sp.x,sp.y,0,1,1,32,32)
end
g.pop()
S.foreground(1280,720)
local base='modules/ui/floating_battle/'
local Types=part(base..'ui/types.lua');local Model=part(base..'systems/model.lua');local Layout=part(base..'ui/layout.lua')
local View=part(base..'ui/view.lua')(Types,Model,Layout,part(base..'ui/icons.lua'),{
 badge=function() error('colored badge must not be used with native palette') end,
 psychic=function() error('colored psychic art must not override native palette') end},part(base..'ui/status.lua'))
local snap={prompt='moves',player={},enemy={},moves={{id=33,name='TACKLE',type='NORMAL',pp=32,maxPp=35},{id=45,name='GROWL',type='NORMAL',pp=40,maxPp=40}}}
View.draw(snap,{focus=1,move=1,menu=1},{nativeHud=true,nativePalette=true,pastel=true,style='layers',scale=.68,opacity=.70,position='left'},1280,720)
check(#rec.stack==0,'palette and controls restore graphics state')
rec:save('preview_frames/35-Floresta-Alinhada-alpha13.3.svg')
print(count..' responsive lens/palette checks passed; simulated graphics, real assets and production renderer.')
