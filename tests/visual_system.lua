-- New production modules, simulated graphics. No GPU, ROM or animation clock.
local Rec=dofile('tests/svg_recorder.lua');local root='floating_glass_frlg/'
local function part(p) return assert(loadfile(root..p))() end
local n=0
local function check(v,m) assert(v,m);n=n+1 end
local function near(a,b,m) check(math.abs(a-b)<.00001,m) end
local opts={};local pres={};local R={option=function(k,v) if opts[k]~=nil then return opts[k] end;return v end,warn=function(_,e) error(e) end,module=function() return {present=function() return pres end} end}
local g=Rec.new(1600,900).graphics;love={graphics=g}
local C=part('gen3/camera.lua')(R)
local st={double=true};local previous=st.double
for _,mode in ipairs({'current','native_depth'}) do
 opts.battle_camera=mode
 local p=C.plan(st,'forest',8);g.push('all');C.apply(p)
 local x,y=g.transformPoint(176,40);local fx,fy=g.transformPoint(180,44)
 near(fx-x,4*p.k,'particles share native scene scale x');near(fy-y,4*p.k,'particles share native scene scale y')
 g.pop();check(st.double==previous,'camera never mutates battle state')
end
opts.battle_camera='native_depth'
for _,size in ipairs({{1920,1080},{800,600},{720,1280},{3440,1440}}) do
 local boxes={}
 for id=0,3 do
  local x,y=C.hud(id,size[1],size[2],size[1]*.23,size[2]*.10,true)
  check(x>=0 and y>=0 and x+size[1]*.23<=size[1] and y+size[2]*.10<=size[2],'four HUDs remain inside window')
  boxes[id]={x=x,y=y};
 end
 check(boxes[0].y<boxes[2].y and boxes[3].y>boxes[1].y,'HUDs use distinct stacked slots')
end
local catalog=part('gen3/arena_catalog.lua');local count=0
for id,entry in pairs(catalog) do
 count=count+1;local img=Rec.image(root..entry.path);local render=part('gen3/arena_renderer.lua')(R,entry.shapes)
 for _,side in ipairs({'player','enemy'}) do
  local box=render.draw(img,side,700,500,330);near(box.width,330,'arena width independent of source sheet')
  local shape=entry.shapes[side];near(box.height/box.width,(shape.b-shape.t)/(shape.r-shape.l),'arena preserves proportions')
  for _,v in ipairs(render.cache[img][side].mesh.vertices) do
   local x,y=v[1]+shape.l,v[2]+shape.t
   check(shape.sign*(x-shape.slope*y-shape.intercept)>=-.001,'source polygons keep the other arena out')
  end
 end
end
check(count==9,'exactly nine supplied matching arenas')
for _,id in ipairs({'blue','wallace','ice','ghost','dragon','sidney','rocky','gym','virtual'}) do check(catalog[id]==nil,'missing arena remains absent: '..id) end
local S=part('gen3/shadows.lua')(R);local img=Rec.image(root..'gen3/assets/pokemon/front/5/normal/rattata.png')
S.reset({});S.register({image=img,w=64,h=64,lru=true});check(S.enabled('enemy') and not S.enabled('player'),'native auto shadows only enemy')
S.register({image={getDimensions=function() return 128,128 end},sheetH=128});check(S.enabled('player'),'actual replacement metadata enables both sides')
opts.shadows='enemies';check(not S.enabled('player') and S.enabled(3),'manual enemies works with replacement and double IDs')
opts.shadows='both';check(S.enabled(0) and S.enabled(2),'both includes both allied battlers')
opts.shadows='off';check(not S.enabled('enemy'),'off suppresses all shadows')
opts.shadows='auto';S.reset({});S.register({image=img,lru=true});check(not S.enabled('player'),'new battle clears replacement observation')
local nativeFrame=Rec.image(root..'gen3/assets/pokemon/front/5/normal/rattata.png');S.register({image=nativeFrame},'frame');check(not S.enabled('player'),'native animation frame is not mistaken for external sprite')
local external64=Rec.image(root..'gen3/assets/pokemon/front/5/normal/rattata.png');S.register({image=external64});check(S.enabled('player'),'unknown provider replacement also detected at native dimensions')
opts.shadows='enemies'
local A={fixed={enemy={l=10,t=10,r=46,b=53}},bounds={}}
local q=g.newQuad(0,0,64,64,64,64);local seen={};local oldShader={native=true};g.setShader(oldShader);g.setColor(1,1,1,.8)
local function draw(...)
 seen[#seen+1]={args={...},shader=g.getShader(),color={g.getColor()},point={g.transformPoint(32,32)}}
end
S.beginFrame();S.draw(draw,img,'enemy',A,q,32,32,0,1,1,32,32)
check(#seen==1 and seen[1].args[1]==img and seen[1].args[2]==q,'shadow reuses exact image and frame quad')
near(seen[1].color[1],0,'shadow red is black');near(seen[1].color[2],0,'shadow green is black');near(seen[1].color[3],0,'shadow blue is black');near(seen[1].color[4],.24,'shadow opacity follows native alpha')
check(seen[1].shader.source:find('Texel(tex, uv).a',1,true)~=nil,'shader follows sprite silhouette alpha')
check(g.getShader()==oldShader,'native shader restored');local _,_,_,alpha=g.getColor();near(alpha,.8,'native color restored')
S.beginFrame();S.draw(draw,img,'enemy',A,32,32,0,1,1,32,32);local calls=#seen;S.draw(draw,img,'enemy',A,32,32,0,1,1,32,32);check(#seen==calls,'stat-mask redraw does not add duplicate shadow')
pres.visible=false;S.beginFrame();S.draw(draw,img,'enemy',A,q,32,32);check(#seen==calls,'hidden native sprite has no shadow')
pres={};opts.shadow_anchor='knees';S.beginFrame();S.draw(draw,img,'enemy',A,q,32,32);check(#seen==calls+1,'knee anchor uses same animated silhouette')
local rec=Rec.new(1200,800);love.graphics=rec.graphics;local originalDraw=rec.graphics.draw
R.shadows=S;opts.shadows='off';local Anchors=part('gen3/anchors.lua')(R)
local double={double=true,player={mon={}},enemy={mon={}},battlers={[2]={mon={}},[3]={mon={}}}}
Anchors.prepare(double,{[0]=true,[1]=true,[2]=true,[3]=true},'double')
for id=0,3 do
 local image=Rec.image(root..'gen3/assets/pokemon/front/5/normal/rattata.png');Anchors.register({image=image},id)
 Anchors.begin();rec.graphics.draw(image,40+40*id,70,0,1,1,32,32);Anchors.finish();check(Anchors.fixed[id]~=nil,'per-battler anchor for double slot '..id)
end
check(rec.graphics.draw==originalDraw and #rec.stack==0,'observer and graphics state restored')
print(n..' visual system checks passed; production arenas/camera/silhouette projection, simulated host only.')
