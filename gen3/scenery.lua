-- Owned user assets; references remain untouched. Native battlers/FX stay native.
return function(R)
  local S={cache={},seen=setmetatable({},{__mode='k'})}
  local index=R.load('gen3/scenery_index.lua')
  local arenaCatalog=R.load('gen3/arena_catalog.lua');S.arenaCatalog=arenaCatalog
  local Arena=R.load('gen3/arena_renderer.lua');local arenaRenderers={}
  local camera=R.camera or R.load('gen3/camera.lua')(R)
  local catalog=R.load('gen3/background_catalog.lua');S.catalog=catalog
  local entries={}
  for _,e in ipairs(catalog.entries) do
    if e.path=='assets/scenery/camera21x9/'..e.id..'.png' then entries[e.id]=e end
  end
  local allowedArenas={beach=true,cave=true,desert=true,forest=true,mountain=true,plain=true,pond=true,tall_grass=true,water=true}
  for id,entry in pairs(arenaCatalog) do
    if not allowedArenas[id] or entry.path~='assets/scenery/arenas/'..id..'.png' then arenaCatalog[id]=nil end
  end
  local function path(group,number,side)
    for name,p in pairs(index[group]) do
      if tonumber(name:sub(1,2))==number and (not side or name:find(side,1,true)) then return p end
    end
  end
  local function image(p)
    if not p then return end
    if S.cache[p]==nil then
      local ok,img=pcall(R.mod.assets.image,R.mod.assets,p)
      S.cache[p]=ok and img or false
      if not S.cache[p] then R.warn('scenery '..p,img) end
    end
    return S.cache[p] or nil
  end
  function S.resolve(game,key,ghost)
    local manual=R.option('camera_background','auto')
    local id=manual~='auto' and entries[manual] and manual
    if not id then
      local family=(game=='firered' or game=='leafgreen') and catalog.firered or catalog.emerald
      id=(ghost and (game=='firered' or game=='leafgreen')) and 'lavender' or family[key] or catalog.common[key]
      -- Wallace is Emerald-only; no supplied Steven/Groudon/Kyogre/Rayquaza artwork.
      if (game=='ruby' or game=='sapphire') and key=='champion' then id=nil end
    end
    return id and entries[id]
  end
  -- Match the same projected native bounds used by the fixed healthboxes.
  function S.arenaGround(side,frame)
    local a=R.battle and R.battle.anchors
    local bounds=a and a.fixed[side] and a.project(side,frame)
    if bounds then
      local st=R.battle.context and R.battle.context();local plan=a.cameraPlan or camera.plan(st,S.selected,R.framing and R.framing.drop and R.framing.drop() or 8)
      local elev=R.battle.elevation and R.battle.elevation(side) or 0
      if a.displayGround then
        local gx,gy=a.displayGround(side)
        if gx then return frame.x+gx*frame.w/240,frame.y+(gy+elev*plan.k)*frame.h/160 end
      end
      return (bounds.l+bounds.r)/2,bounds.b+elev*plan.k*frame.h/160
    end
    local drop=R.framing and R.framing.drop and R.framing.drop() or 8
    local st=R.battle and R.battle.context and R.battle.context()
    local player=side=='player' or type(side)=='number' and side%2==0
    local x,y=player and 72 or 176,player and 120 or 72
    if type(side)=='number' then
      local points={[0]={32,112},[1]={200,72},[2]={90,120},[3]={152,64}}
      x,y=points[side][1],points[side][2]
    end
    local plan=a and a.cameraPlan or camera.plan(st,S.selected,drop)
    return frame.x+(plan.x+plan.k*x)*frame.w/240,frame.y+(plan.y+plan.k*(y+plan.drop))*frame.h/160
  end
  function S.drawWide(w,h,frame)
    if not S.wideActive or not S.activeImage then return false end
    local img=S.activeImage;local iw,ih=img:getDimensions();local scale=h/ih
    local g=love.graphics;g.push('all');g.origin();g.setShader();g.setScissor(0,0,w,h)
    local ok,err=pcall(function()
      -- Clear any previous native scene outside the fitted image as well.
      g.setColor(16/255,20/255,29/255,1);g.rectangle('fill',0,0,w,h)
      g.setColor(1,1,1,1)
      if R.lighting then R.lighting.sceneryBackground(g.draw,img,(w-iw*scale)/2,0,0,scale,scale) else g.draw(img,(w-iw*scale)/2,0,0,scale,scale) end
      -- Source circles are isolated from their sheet and sized independently.
      S.arenaRects={}
      local entry=arenaCatalog[S.selected]
      local permitted=not R.battle or not (R.battle.visualOwns or R.battle.owns) or (R.battle.visualOwns or R.battle.owns)()
      if entry and permitted then
        local arenas=image(entry.path)
        if arenas then
          frame=frame or {x=0,y=0,w=w,h=h}
          S.arenaRects={}
          local renderer=arenaRenderers[S.selected]
          if not renderer then renderer=Arena(R,entry.shapes);arenaRenderers[S.selected]=renderer end
          local st=R.battle and R.battle.context and R.battle.context()
          local keys=st and st.double and {3,1,0,2} or {'enemy','player'}
          for _,side in ipairs(keys) do
            local present=not (st and st.absent and st.absent[side])
            if type(side)=='number' then present=present and (side==0 and st.player or side==1 and st.enemy or st.battlers and st.battlers[side])~=nil end
            if present then
            local cx,cy=S.arenaGround(side,frame)
            local player=side=='player' or type(side)=='number' and side%2==0
            local kind=player and 'player' or 'enemy'
            local width=math.min(frame.w*(player and .29 or .24),frame.h*(player and .50 or .40))
            if st and st.double then width=width*.72 end
            -- Shrink at narrow window edges; never detach ground from its mon.
            local shape=entry.shapes[kind];local sw=shape.r-shape.l
            width=math.max(1,math.min(width,cx*sw/(shape.cx-shape.l),(w-cx)*sw/(shape.r-shape.cx),cy*sw/(shape.cy-shape.t),(h-cy)*sw/(shape.b-shape.cy)))
            if R.lighting then S.arenaRects[side]=R.lighting.arenaBackground({(cx-(w-iw*scale)/2)/(iw*scale),cy/h,1},renderer.draw,arenas,kind,cx,cy,width) else S.arenaRects[side]=renderer.draw(arenas,kind,cx,cy,width) end
            end
          end
        end
      end
    end)
    g.pop();if not ok then error(err,0) end
    return true
  end
  -- Old separate arenas stay disabled; the forest review layer is drawn above.
  function S.drawPads() end
  function S.foreground(w,h)
    if not S.current then return end
    local alpha=tonumber(R.option('foreground',.65)) or 0
    if alpha<=0 then return end
    local img=image(path('foregrounds',S.current));if not img then return end
    local g=love.graphics
    if not w or not h then
      if g.getDimensions then w,h=g.getDimensions() else w,h=240,160 end
    end
    if w<=0 or h<=0 then return end
    local iw,ih=img:getDimensions()
    local time=love.timer and love.timer.getTime and love.timer.getTime() or 0
    local breathing=R.option('lens_motion',true) and (1.012+.008*math.sin(time*math.pi/2)+.002*math.sin(time*math.pi)) or 1
    local size=math.max(.4,math.min(1,tonumber(R.option('lens_size',.65)) or .65))
    local k=math.max(w/iw,h/ih)*breathing
    k=k*size
    g.push('all');g.origin();g.setShader();g.setScissor(0,0,w,h)
    local ok,err=pcall(function()
      g.setColor(1,1,1,math.min(1,alpha))
      -- Keep foliage uniformly smaller and attach its halves to window edges.
      -- The transparent center opens up instead of stretching smaller plants.
      S.lensQuads=S.lensQuads or setmetatable({},{__mode='k'})
      local q=S.lensQuads[img]
      if not q then q={g.newQuad(0,0,iw/2,ih,iw,ih),g.newQuad(iw/2,0,iw/2,ih,iw,ih)};S.lensQuads[img]=q end
      g.setScissor(0,0,w/2,h)
      if R.lighting then R.lighting.background(g.draw,img,q[1],0,h-ih*k,0,k,k) else g.draw(img,q[1],0,h-ih*k,0,k,k) end
      g.setScissor(w/2,0,w/2,h)
      if R.lighting then R.lighting.background(g.draw,img,q[2],w-iw*k/2,h-ih*k,0,k,k) else g.draw(img,q[2],w-iw*k/2,h-ih*k,0,k,k) end
    end)
    g.pop();if not ok then R.warn('foreground draw',err) end
  end
  function S.installLoaded()
    local Bg=R.module('src.core.game3.battle.bg')
    if not Bg or S.seen[Bg] then return end;S.seen[Bg]=true
    R.wrap(Bg,'draw',function(next,id,enemyOx,playerOx,bgOx)
      S.current=nil;S.wideActive=false;S.pads=nil;S.replaced=false;S.activeImage=nil;S.selected=nil
      if not (R.battle.scene or R.battle.sceneryScene) then return next(id,enemyOx,playerOx,bgOx) end
      local terrain=id or Bg.terrainId()
      local key=Bg.env and Bg.env().TERRAIN_SHEET[terrain] or (Bg.sheetKey and Bg.sheetKey(terrain))
      local GV=R.module('src.core.GameVersion');local game=GV and GV.get and GV.get() or 'firered'
      local st=R.battle.context and R.battle.context()
      local entry=S.resolve(game,key,st and st.ghostBattle)
      if R.lighting then R.lighting.setScene(entry and entry.id or key) end
      if R.option('scenery','auto')~='auto' then return next(id,enemyOx,playerOx,bgOx) end
      if not entry then return next(id,enemyOx,playerOx,bgOx) end
      local bg=image(entry.path);if not bg then return next(id,enemyOx,playerOx,bgOx) end
      local g=love.graphics
      if not (R.framing and R.framing.wideReady and g.clear) then
        -- Never erase native graphics if this host cannot present our final layer.
        return next(id,enemyOx,playerOx,bgOx)
      end
      g.clear(0,0,0,0)
      S.activeImage=bg;S.selected=entry.id;S.replaced=true;S.wideActive=true
      S.current=catalog.foregrounds[entry.id]
      return true -- do not invoke native terrain or its original platforms
    end)
  end
  function S.shutdown()
    for _,renderer in pairs(arenaRenderers) do for _,sides in pairs(renderer.cache) do for _,res in pairs(sides) do
      if res.mesh and res.mesh.release then res.mesh:release() end
    end end end
    arenaRenderers={}
  end
  return S
end
