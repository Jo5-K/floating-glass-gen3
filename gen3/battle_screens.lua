-- Battle-origin menu presentation only. Native draw produces dynamic text/icons;
-- native input, list ordering, validation, callbacks and animations are retained.
return function(R)
 local S={seen=setmetatable({},{__mode='k'}),origins=setmetatable({},{__mode='k'}),depth=0,textDepth=0,paintDepth=0,skipArt=0}
 local Skin=R.load('gen3/emerald_ivory.lua')()
 local unpack=table.unpack or unpack
 local icons=setmetatable({},{__mode="k"})
 local catalog=R.load('gen3/ambient_catalog.lua')
 local artCache,artQuads={},{}
 local paths={
  party_menu='party',bag_menu='bag',summary_menu='summary',stat_growth='stats',
  evolution_scene='evolution',naming='naming',pokedex='dex',
  ['rse.bag_menu']='bag',['rse.summary_menu']='summary',['rse.pyramid_bag']='bag',
  choice='choice',message='message',['rse.pokedex']='dex',['rs.pokedex']='dex',
  ['rs.bag_menu']='bag',['rs.summary_menu']='summary',berry_pouch='bag',tm_case='bag',
 }
 function S.battleActive()
  if R.unloaded or not R.glass()or not R.option('battle',true)then return false end
  local b=R.module('src.core.game3.battle.init')or R.module('src.core.game3.battle')
  if b and b.isActive and b.isActive()then return true end
  local e=R.module('src.ui.game3.evolution_scene')
  return e and e._isBattle and e.isOpen and e.isOpen()or false
 end
 function S.allowed(m)
  return not R.unloaded and R.glass()and R.option('battle',true)and (S.battleActive()or S.origins[m]==true)
 end
 local function painted(fn,...)
  S.paintDepth=S.paintDepth+1
  local result={pcall(fn,...)};S.paintDepth=S.paintDepth-1
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end
 function S.panel(x,y,w,h,selected,role)
  return painted(function()
   local g=love.graphics;g.push('all')
   local ok,err=pcall(function()
    if Skin.crystal then
     g.setColor(0,.015,.035,.24);g.rectangle('fill',x+.7,y+1.2,w,h,2,2)
    end
    Skin.panel({x=x,y=y,w=w,h=h},.25,role or 'auxiliary',selected==true)
   end)
   g.pop();if not ok then error(err,0)end
  end)
 end
 function S.decorationScene()
  local id=R.scenery and R.scenery.selected
  id=({forest='plain',tall_grass='plain',cave_ice='cave'})[id]or id
  return id and catalog.scenes[id]and id or nil
 end
 local function image(path)
  if artCache[path]==nil then
   local assets=R.mod and R.mod.assets
   local ok,img=false,nil
   if assets and assets.image then ok,img=pcall(assets.image,assets,path)end
   artCache[path]=ok and img or false
   if ok and img and img.setFilter then img:setFilter('nearest','nearest')end
  end
  return artCache[path]or nil
 end
 function S.decorateBackground()
  local scene=S.decorationScene();if not scene then return end
  local frame=image('assets/scenery/ambient/portrait/rich/'..scene..'.png')
  local front=catalog.scenes[scene].front;front=front and image(front.path)
  if not frame and not front then return end
  local r={x=5,y=5,w=230,h=150,scale=.25}
  painted(function()
   local g=love.graphics
   local function draw(alpha)
    g.push('all')
    local ok,err=pcall(function()
     -- Scissors are in target pixels: account for native UI scaling and the
     -- opacity group's offscreen transform before clipping the inset rectangle.
     if g.transformPoint and g.intersectScissor then
      local x1,y1=g.transformPoint(r.x,r.y);local x2,y2=g.transformPoint(r.x+r.w,r.y+r.h)
      local x3,y3=g.transformPoint(r.x+r.w,r.y);local x4,y4=g.transformPoint(r.x,r.y+r.h)
      local x,y=math.ceil(math.min(x1,x2,x3,x4)),math.ceil(math.min(y1,y2,y3,y4))
      local right,bottom=math.floor(math.max(x1,x2,x3,x4)),math.floor(math.max(y1,y2,y3,y4))
      g.intersectScissor(x,y,math.max(0,right-x),math.max(0,bottom-y))
     end
     g.setColor(1,1,1,alpha)
     if frame then
      local iw,ih=frame:getDimensions();local k=r.h/ih
      local key=scene
      if not artQuads[key]then artQuads[key]={g.newQuad(0,0,iw/2,ih,iw,ih),g.newQuad(iw/2,0,iw/2,ih,iw,ih)}end
      g.draw(frame,artQuads[key][1],r.x,r.y,0,k,k)
      g.draw(frame,artQuads[key][2],r.x+r.w-iw*k/2,r.y,0,k,k)
     end
     if front then
      local iw,ih=front:getDimensions();local k=r.w/iw
      g.draw(front,r.x,r.y+r.h-ih*k,0,k,k)
     end
    end)
    g.pop();if not ok then error(err,0)end
   end
   -- Composite all overlapping decorations first; apply 50% to the group.
   if g.newCanvas and g.setCanvas and g.getCanvas and g.origin and g.clear and g.setBlendMode then
    Skin.group('menu-decoration-'..scene,r,.5,function()draw(1)end)
   else draw(.5)end
  end)
 end
 function S.background(kind)
  local g=love.graphics
  painted(function()
   -- Draw the live scene in this native UI plane; never call Battle.draw or
   -- advance battle logic from an auxiliary menu.
   local scene=R.scenery
   local img=scene and scene.activeImage or S.backdrop
   if img and not(R.framing and R.framing.wideReady)then
    local iw,ih=img:getDimensions();local k=math.max(240/iw,160/ih)
    g.setColor(1,1,1,1)
    if R.lighting and R.lighting.sceneryBackground then
     R.lighting.sceneryBackground(g.draw,img,(240-iw*k)/2,(160-ih*k)/2,0,k,k)
    else g.draw(img,(240-iw*k)/2,(160-ih*k)/2,0,k,k)end
   end
  end)
  S.panel(1,1,238,158,false)
  S.decorateBackground()
  if kind=='bag'then
   if S.rseBag then
    S.panel(3,4,102,97,false);S.panel(109,4,128,149,false);S.panel(3,104,102,51,false)
   else
    S.panel(3,4,80,103,false);S.panel(87,4,150,103,false);S.panel(3,112,234,44,false)
   end
  elseif kind=='summary'then
   S.panel(3,3,234,16,false);S.panel(3,23,75,129,false);S.panel(82,23,155,129,false)
  elseif kind=='naming'then
   S.panel(8,6,224,54,false);S.panel(8,65,224,89,false)
  elseif kind=='dex'then
   S.panel(3,3,234,18,false);S.panel(3,25,100,127,false);S.panel(107,25,130,127,false)
  end
 end
 -- Ignore only presentation textures too large to be icons. Animated sprite
 -- atlases are measured by the CURRENT QUAD, not by the whole sheet size.
 function S.iconFootprint(img,...)
  if icons[img]then return true end
  if not img or not img.getDimensions then return true end
  local args={...};local iw,ih=img:getDimensions();local off=0
  if args[1]and(type(args[1])=='userdata'or type(args[1])=='table')and args[1].getViewport then
   local _,_,w,h=args[1]:getViewport();iw,ih=w,h;off=1
  end
  local sx=tonumber(args[off+4])or 1;local sy=tonumber(args[off+5])or sx
  return math.abs(iw*sx)<=74 and math.abs(ih*sy)<=74
 end
 function S.rememberBackdrop()
  local scene=R.scenery
  if not scene or R.option('scenery','auto')~='auto'then return end
  if scene.activeImage then
   S.backdrop=scene.activeImage;S.backdropScene=scene.selected;S.backdropForeground=scene.current
  elseif S.backdrop then
   -- Native menus can suppress the battle terrain pass. Keep the same live
   -- compositor (lighting/details/animations), not a frozen screenshot.
   scene.activeImage=S.backdrop;scene.selected=S.backdropScene
   scene.current=S.backdropForeground;scene.wideActive=true
  end
 end
 function S.run(m,kind,next,...)
  if not S.allowed(m)or S.failed then return next(...)end
  S.rememberBackdrop()
  if S.depth>0 then
   local old=S.kind;S.kind=kind
   local args={...};local out={pcall(function()if old~=kind and kind~='stats'and kind~='choice'and kind~='message'then S.background(kind)end;return next(unpack(args))end)}
   S.kind=old;if not out[1]then error(out[2],0)end;return unpack(out,2)
  end
  local g=love.graphics
  local oldDraw,oldRectangle=g.draw,g.rectangle
  local oldPush,oldPop=g.push,g.pop
  local pushed=0;local canvas=g.getCanvas and {g.getCanvas()}or nil
  local previous=S.kind;S.kind=kind;S.depth=S.depth+1;S.slot=0
  local menuSkin=R.option('battle_menu_skin','crystal_glass')
  Skin.configure(menuSkin=='emerald_gba',menuSkin=='crystal_glass')
  oldPush('all')
  g.push=function(...)local out={oldPush(...)};pushed=pushed+1;return unpack(out)end
  g.pop=function(...)local out={oldPop(...)};pushed=pushed-1;return unpack(out)end
  g.draw=function(img,...)
   if S.paintDepth>0 or S.textDepth>0 or (S.skipArt==0 and(kind=='evolution'or S.iconFootprint(img,...)))then return oldDraw(img,...)end
  end
  g.rectangle=function(mode,x,y,w,h,...)
   if S.paintDepth>0 or S.textDepth>0 or kind=='evolution'or (w or 0)<=72 or(h or 0)<=6 then return oldRectangle(mode,x,y,w,h,...)end
   -- Preserve native transition fades as fades, never as new opaque windows.
   if mode=='fill'then
    if x<=0 and y<=0 and w>=240 and h>=160 then return oldRectangle(mode,x,y,w,h,...)end
    return S.panel(x,y,w,h,false)
   end
  end
  local args={...}
  local result={pcall(function()
   if kind~='stats'and kind~='choice'and kind~='message'then S.background(kind)end
   return next(unpack(args))
  end)}
  g.draw,g.rectangle=oldDraw,oldRectangle
  g.push,g.pop=oldPush,oldPop
  while pushed>0 do oldPop();pushed=pushed-1 end
  if canvas and g.setCanvas then g.setCanvas(unpack(canvas))end
  oldPop();S.depth=S.depth-1;S.kind=previous
  if not result[1]then
   S.failed=true;S.paintDepth=0;S.textDepth=0;S.skipArt=0
   R.warn('battle menus; native presentation restored',result[2])
   return next(unpack(args))
  end
  return unpack(result,2)
 end
 local function hook(m,key,fn)if m and type(m[key])=='function'then R.wrap(m,key,fn)end end
 local function contextual(m,key,fn)
  hook(m,key,function(next,...)if S.depth>0 then return fn(next,...)end;return next(...)end)
 end
 function S.installLoaded()
  for suffix,kind in pairs(paths)do
   local m=R.module('src.ui.game3.'..suffix)
   if m and not S.seen[m]then
    S.seen[m]=true
    for _,key in ipairs({'show','open','openMenu','start','begin','showRegistration','showCaughtMon','yesNo','multi'})do
     hook(m,key,function(next,...)
      S.origins[m]=S.battleActive()or S.depth>0 or nil
      if S.origins[m]then S.rememberBackdrop()end
      return next(...)
     end)
    end
    hook(m,'close',function(next,...)local out={next(...)};S.origins[m]=nil;return unpack(out)end)
    hook(m,'draw',function(next,...)
     local old=S.rseBag;S.rseBag=suffix=='rse.bag_menu' 
     local out={pcall(S.run,m,kind,next,...)};S.rseBag=old
     if not out[1]then error(out[2],0)end;return unpack(out,2)
    end)
    if kind=='party'then
     contextual(m,'hpBarColors',function(_,hp,max)
      local ratio=math.max(0,math.min(1,(tonumber(hp)or 0)/math.max(1,tonumber(max)or 1)))
      local c=ratio>.5 and Skin.colors.healthy or ratio>.2 and Skin.colors.mid or Skin.colors.critical
      return {top=c,bottom={c[1]*.8,c[2]*.8,c[3]*.8,1},emptyTop={.02,.07,.08,1},emptyBottom={.02,.07,.08,1}}
     end)
    end
   end
  end
  local Pokemon=R.module('src.core.game3.pokemon')
  if Pokemon and not S.seen[Pokemon]then
   S.seen[Pokemon]=true
   for _,key in ipairs({'monIcon','monFrontPic','monBackPic','monIconDontHandleDeoxys','monFrontPicDontHandleDeoxys','icon','iconDontHandleDeoxys','frontPic','dexFrontPic','dexIcon'})do
    hook(Pokemon,key,function(next,...)
     local out={next(...)};local value=out[1]
     if (S.depth>0 or S.battleActive())and type(value)=='table'and value.image then icons[value.image]=true end
     return unpack(out)
    end)
   end
  end
  for _,fontPath in ipairs({'src.ui.game3.frlg_font','src.ui.game3.rs.font'})do
  local F=R.module(fontPath)
  if F and not S.seen[F]then
   S.seen[F]=true
   contextual(F,'draw',function(next,text,x,y,opts)
    local args={};for k,v in pairs(opts or {})do args[k]=v end
    if S.kind=='bag'and S.rseBag and x==3 and y==105 then x=7;args.maxWidth=94 end
    -- Text stays native/translated; alter ink only, leaving IR and font metrics.
    if text=='♂'or text=='♀'then S.textDepth=S.textDepth+1;local out={pcall(next,text,x,y,opts)};S.textDepth=S.textDepth-1;if not out[1]then error(out[2],0)end;return unpack(out,2)end
    local fg=Skin.crystal and {.03,.08,.14,1}or {.96,.98,.94,1}
    args.colors={fg=fg,shadow=Skin.crystal and {.8,.88,.94,1}or {0,.02,.025,1},bg={0,0,0,0}}
    S.textDepth=S.textDepth+1
    local out={pcall(next,text,x,y,args)};S.textDepth=S.textDepth-1
    if not out[1]then error(out[2],0)end;return unpack(out,2)
   end)
  end
  end
  local W=R.module('src.ui.game3.window')
  if W and not S.seen[W]then
   S.seen[W]=true
   for _,key in ipairs({'stdFrame','fixedStdFrame','userFrame'})do
    contextual(W,key,function(_,t)return S.panel((t.left or t.tilemapLeft)*8,(t.top or t.tilemapTop)*8,(t.w or t.width)*8,(t.h or t.height)*8,false)end)
   end
   for _,key in ipairs({'cursor','cursorPx'})do
    contextual(W,key,function(_,x,y)
     if key=='cursor'then x,y=x*8,y*8 end
     return painted(function()local g=love.graphics;g.push('all');g.setColor(1,1,1,1);g.polygon('fill',x+1,y+1,x+6,y+5,x+1,y+9);g.pop()end)
    end)
   end
  end
  local C=R.module('src.ui.game3.chrome')
  if C and not S.seen[C]then
   S.seen[C]=true
   contextual(C,'dialogueFrame',function()return S.panel(4,112,232,46,false)end)
  end
  local P=R.module('src.ui.game3.party_chrome')
  if P and not S.seen[P]then
   S.seen[P]=true
   contextual(P,'drawBg',function()return true end)
   contextual(P,'drawSlot',function(_,kind,x,y,selected)
    S.panel(x*8,y*8,kind=='main'and 80 or 144,kind=='main'and 56 or 24,selected)
    return true
   end)
   contextual(P,'textColors',function()return {fg=Skin.crystal and {.03,.08,.14,1}or {1,1,.96,1},shadow={0,0,0,0},bg={0,0,0,0}}end)
   for _,key in ipairs({'drawCancelButton','drawConfirmButton'})do
    contextual(P,key,function(next,x,y,selected)
     S.panel(x or 184,y or 136,54,18,selected)
     S.skipArt=S.skipArt+1;local out={pcall(next,x,y,selected)};S.skipArt=S.skipArt-1
     if not out[1]then error(out[2],0)end;return unpack(out,2)
    end)
   end
  end
  local BattleChrome=R.module('src.ui.game3.battle_chrome')
  if BattleChrome and not S.seen[BattleChrome]then
   S.seen[BattleChrome]=true
   contextual(BattleChrome,'drawCleanBg',function(next,...)if S.kind=='evolution'then return true end;return next(...)end)
   contextual(BattleChrome,'drawPanel',function(next,...)if S.kind=='evolution'then return S.panel(4,112,232,46,false)end;return next(...)end)
  end
  local RB=R.module('src.ui.game3.rse.bag_chrome')
  if RB and not S.seen[RB]then
   S.seen[RB]=true
   contextual(RB,'drawFrame',function(next,entry,frame,x,y,opts)
    if S.kind=='bag'and S.rseBag and entry and entry.w==64 and entry.h==64 then x,y=x-16,y-4 end
    return next(entry,frame,x,y,opts)
   end)
   contextual(RB,'drawItemIcon',function(next,index,x,y,...)
    if S.kind=='bag'and S.rseBag then x,y=78,74 end
    return next(index,x,y,...)
   end)
  end
  local B=R.module('src.ui.game3.bag_chrome')
  if B and not S.seen[B]then
   S.seen[B]=true
   for _,key in ipairs({'drawBg','drawListFrame','drawDescSelected'})do contextual(B,key,function()return true end)end
  end
  local U=R.module('src.ui.game3.summary_chrome')
  if U and not S.seen[U]then
   S.seen[U]=true
   for _,key in ipairs({'drawBg3','drawLayer','drawProgress'})do contextual(U,key,function()return true end)end
   contextual(U,'drawHpBar',function(_,x,y,hp,max)
    local ratio=math.max(0,math.min(1,(tonumber(hp)or 0)/math.max(1,tonumber(max)or 1)))
    painted(function()local g=love.graphics;g.setColor(.02,.07,.08,1);g.rectangle('fill',x+16,y+2,48,4,2,2);g.setColor(ratio>.5 and Skin.colors.healthy or ratio>.2 and Skin.colors.mid or Skin.colors.critical);g.rectangle('fill',x+16,y+2,48*ratio,4,2,2)end)
   end)
   contextual(U,'drawExpBar',function(_,x,y,p)
    painted(function()local g=love.graphics;g.setColor(.02,.07,.08,1);g.rectangle('fill',x,y+2,88,4,2,2);g.setColor(Skin.colors.exp);g.rectangle('fill',x,y+2,88*math.max(0,math.min(1,tonumber(p)or 0)),4,2,2)end)
   end)
   contextual(U,'drawMoveSelectionCursor',function(_,x,y,w,h)
    if type(w)=='boolean'then w,h=128,32 end;w,h=w or 128,h or 32
    painted(function()local g=love.graphics;g.push('all');g.setColor(1,1,1,1);g.setLineWidth(.6);g.rectangle('line',x,y,w,h,2,2);g.pop()end)
   end)
  end
 end
 function S.shutdown()Skin.shutdown();for _,qs in pairs(artQuads)do for _,q in ipairs(qs)do if q.release then q:release()end end end;artQuads={};artCache={};S.origins={};S.backdrop=nil;S.backdropScene=nil;S.backdropForeground=nil;S.depth=0 end
 return S
end
