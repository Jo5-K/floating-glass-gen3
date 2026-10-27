-- Observe the rendered sprite, never mutate battlers or animation state.
return function(R)
  local A={images=setmetatable({},{__mode='k'}),pixels=setmetatable({},{__mode='k'}),bounds={},fixed={},owners={},ready={},rest={},fixedRest={},sources={},layouts={}}
  function A.register(entry,side,origin)
    local img=entry and entry.image
    if img then A.images[img]=side;if R.shadows then R.shadows.register(entry,origin) end end
    return entry
  end
  function A.alphaBounds(img)
    if A.pixels[img] then return A.pixels[img] end
    local iw,ih=img:getDimensions();local b={0,0,iw,ih}
    local g=love.graphics
    -- One readback per image, including replacements supplied by sprite mods.
    -- Unsupported/headless hosts use the image rectangle, explicitly a fallback.
    if g.newCanvas and g.getCanvas and g.setCanvas and iw<=2048 and ih<=2048 then
      local old=g.getCanvas();local canvas,data
      g.push('all')
      local ok=pcall(function()
        canvas=g.newCanvas(iw,ih,{dpiscale=1});g.setCanvas(canvas);g.origin();g.setShader();g.setScissor()
        g.clear(0,0,0,0);g.setColor(1,1,1,1)
        if g.setBlendMode then g.setBlendMode('alpha','alphamultiply') end
        -- Use the original draw function: the observer must not observe itself.
        (A.originalDraw or g.draw)(img,0,0)
        g.setCanvas(old);data=canvas:newImageData()
        local l,t,r,d=iw,ih,0,0
        for y=0,ih-1 do for x=0,iw-1 do
          local _,_,_,alpha=data:getPixel(x,y)
          if alpha>.02 then l=math.min(l,x);t=math.min(t,y);r=math.max(r,x+1);d=math.max(d,y+1) end
        end end
        if r>l and d>t then b={l,t,r,d} end
      end)
      g.setCanvas(old);g.pop()
      if data and data.release then data:release() end
      if canvas and canvas.release then canvas:release() end
      if not ok then A.fallback=true end
    else A.fallback=true end
    A.pixels[img]=b;return b
  end
  -- Render through already-installed draw wrappers, so origin corrections from
  -- sprite mods are measured without importing or depending on those mods.
  function A.probe(img,rot,sx,sy,ox,oy,kx,ky)
    local g=love.graphics
    if not (g.newCanvas and g.getCanvas and g.setCanvas and A.originalDraw) then return end
    local iw,ih=img:getDimensions()
    local extent=math.ceil(math.max(iw,ih,math.abs(ox),math.abs(oy))*math.max(math.abs(sx),math.abs(sy),1)*3+64)
    if extent>1024 then return end
    local old=g.getCanvas();local canvas,data,bounds;local mid=math.floor(extent/2)
    g.push('all')
    local ok=pcall(function()
      canvas=g.newCanvas(extent,extent,{dpiscale=1});g.setCanvas(canvas);g.origin();g.setShader();g.setScissor()
      g.clear(0,0,0,0);g.setColor(1,1,1,1)
      if g.setBlendMode then g.setBlendMode('alpha','alphamultiply') end
      A.originalDraw(img,mid,mid,rot,sx,sy,ox,oy,kx,ky)
      g.setCanvas(old);data=canvas:newImageData()
      local l,t,r,b=extent,extent,0,0
      for y=0,extent-1 do for x=0,extent-1 do
        local _,_,_,a=data:getPixel(x,y)
        if a>.02 then l=math.min(l,x);t=math.min(t,y);r=math.max(r,x+1);b=math.max(b,y+1) end
      end end
      if r>l and b>t then bounds={l-mid,t-mid,r-mid,b-mid} end
    end)
    g.setCanvas(old);g.pop()
    if data and data.release then data:release() end
    if canvas and canvas.release then canvas:release() end
    if ok then return bounds end
  end
  function A.prepare(state,ready,signature)
    if A.state~=state or A.signature~=signature then
      A.fixed={};A.owners={};A.fixedRest={};A.sources={};A.layouts={};A.cameraPlan=nil;A.state=state;A.signature=signature
    end
    A.ready=ready or {}
    local keys=state and state.double and {0,1,2,3} or {'player','enemy'}
    for _,side in ipairs(keys) do
      local battler=type(side)=='number' and (side==0 and state.player or side==1 and state.enemy or state.battlers and state.battlers[side]) or state and state[side]
      local mon=battler and battler.mon
      if A.owners[side]~=mon then A.fixed[side]=nil;A.fixedRest[side]=nil;A.bounds[side]=nil;A.rest[side]=nil;A.sources[side]=nil;A.layouts[side]=nil;A.owners[side]=mon end
    end
  end
  function A.reproject(plan)
    local old=A.cameraPlan
    if old then
      for _,b in pairs(A.fixed) do
        b.l=plan.x+(b.l-old.x)/old.k*plan.k
        b.r=plan.x+(b.r-old.x)/old.k*plan.k
        b.t=plan.y+((b.t-old.y)/old.k-old.drop+plan.drop)*plan.k
        b.b=plan.y+((b.b-old.y)/old.k-old.drop+plan.drop)*plan.k
      end
      for _,p in pairs(A.fixedRest) do
        p.x=plan.x+(p.x-old.x)/old.k*plan.k
        p.y=plan.y+((p.y-old.y)/old.k-old.drop+plan.drop)*plan.k
      end
    end
    A.cameraPlan=plan
  end
  function A.capture(img,...)
    local side=A.images[img];if not side then return end
    local args={...};local quad
    if type(args[1])~='number' then
      if not args[1] or not args[1].getViewport then return end
      quad=table.remove(args,1)
    end
    if quad and A.fixed[side] then return end
    local x,y,rot,sx,sy,ox,oy,kx,ky=(table.unpack or unpack)(args)
    if type(x)~='number' then return end
    local g=love.graphics;if not g.transformPoint then return end
    local tagged,foot,spec
    if R.compat then tagged,foot,spec=R.compat.geometry(img,quad) end
    -- Do not freeze the native send-out frame as the replacement's idle pose.
    local source=tagged and 'hd' or R.shadows and R.shadows.images and R.shadows.images[img] and 'replacement' or 'native'
    local layout=''
    if spec then
      local p=spec.pivot
      layout=table.concat({foot[1],foot[2],p[1],p[2],spec.scale or 1},':')
    end
    if A.sources[side]~=source or A.layouts[side]~=layout then
      A.fixed[side]=nil;A.fixedRest[side]=nil
    end
    A.sources[side]=source;A.layouts[side]=layout
    if A.fixed[side] then return end
    local b=tagged or A.alphaBounds(img)
    if quad and not tagged then
      local qx,qy,qw,qh=quad:getViewport()
      b={math.max(b[1],qx)-qx,math.max(b[2],qy)-qy,math.min(b[3],qx+qw)-qx,math.min(b[4],qy+qh)-qy}
      if b[3]<=b[1] or b[4]<=b[2] then return end
    end
    sx,sy=sx or 1,sy or sx or 1;ox,oy=ox or 0,oy or 0;rot=rot or 0
    local measured=not tagged and not quad and A.ready[side] and A.probe(img,rot,sx,sy,ox,oy,kx or 0,ky or 0)
    if measured then b=measured;ox,oy=0,0;sx,sy=1,1;rot=0;kx,ky=0,0 end
    local c,s=math.cos(rot),math.sin(rot)
    local l,t,r,d=math.huge,math.huge,-math.huge,-math.huge
    for _,v in ipairs({{b[1],b[2]},{b[3],b[2]},{b[1],b[4]},{b[3],b[4]}}) do
      local px,py=v[1]-ox,v[2]-oy
      local a,z=sx*(px+(kx or 0)*py),sy*(py+(ky or 0)*px)
      local tx,ty=g.transformPoint(x+c*a-s*z,y+s*a+c*z)
      l,t,r,d=math.min(l,tx),math.min(t,ty),math.max(r,tx),math.max(d,ty)
    end
    local previous=quad and A.bounds[side]
    if previous then l=math.min(l,previous.l);t=math.min(t,previous.t);r=math.max(r,previous.r);d=math.max(d,previous.b) end
    A.bounds[side]={l=l,t=t,r=r,b=d}
    if foot then
      local px,py=foot[1]-ox,foot[2]-oy
      local a,z=sx*(px+(kx or 0)*py),sy*(py+(ky or 0)*px)
      local fx,fy=g.transformPoint(x+c*a-s*z,y+s*a+c*z)
      A.rest[side]={x=fx,y=fy}
    else A.rest[side]={x=(l+r)/2,y=d} end
  end
  function A.begin()
    A.bounds={};A.rest={};if R.shadows then R.shadows.beginFrame() end;local g=love.graphics;local downstream=g.draw;local enabled=true
    A.originalDraw=downstream
    local observer=function(img,...)
      local observe=enabled and not (R.battle and (R.battle.particleDepth or 0)>0)
      if observe then
        local ok,err=pcall(A.capture,img,...)
        if not ok and not A.warned then A.warned=true;R.warn('sprite bounds fallback',err) end
      end
      local key=observe and A.images[img]
      local dx,dy=0,0
      if key~=nil and key~=false and R.camera then dx,dy=R.camera.activeOffset(A,key) end
      local function draw(...)
        if key~=nil and key~=false and R.shadows then R.shadows.draw(downstream,img,key,A,...) end
        if enabled and key~=nil and key~=false and R.lighting then return R.lighting.sprite(downstream,img,...) end
        return downstream(img,...)
      end
      if dx==0 and dy==0 then return draw(...) end
      -- Capture the unshifted pose above, then translate this draw only. Its
      -- alpha bounds and scale remain stable even for large replacement sprites.
      g.push();g.translate(dx,dy)
      local ok,err=pcall(draw,...);g.pop()
      if not ok then error(err,0) end
    end
    g.draw=observer
    A.stop=function()
      enabled=false
      -- Preserve a wrapper installed lazily by another mod during this pass.
      -- Our captured observer becomes a transparent delegate inside that chain.
      if g.draw==observer then g.draw=downstream end
    end
  end
  function A.finish()
    for side,b in pairs(A.bounds) do
      if A.ready[side] and not A.fixed[side] then A.fixed[side]={l=b.l,t=b.t,r=b.r,b=b.b} end
      if A.ready[side] and not A.fixedRest[side] then A.fixedRest[side]=A.rest[side] end
    end
    if A.stop then A.stop();A.stop=nil end
    A.originalDraw=nil
  end
  function A.project(side,frame)
    local b=A.displayBounds(side);if not b then return end
    return {l=frame.x+b.l*frame.w/240,r=frame.x+b.r*frame.w/240,
      t=frame.y+b.t*frame.h/160,b=frame.y+b.b*frame.h/160}
  end
  function A.displayBounds(side)
    local b=A.fixed[side] or A.bounds[side];if not b then return end
    local dx,dy=0,0
    if R.camera then dx,dy=R.camera.activeOffset(A,side) end
    local k=A.cameraPlan and A.cameraPlan.k or 1
    return {l=b.l+dx*k,r=b.r+dx*k,t=b.t+dy*k,b=b.b+dy*k}
  end
  function A.displayGround(side)
    local p=A.fixedRest[side] or A.rest[side];if not p then return end
    local dx,dy=0,0;if R.camera then dx,dy=R.camera.activeOffset(A,side) end
    local k=A.cameraPlan and A.cameraPlan.k or 1
    return p.x+dx*k,p.y+dy*k
  end
  function A.place(side,b,w,h,windowW,windowH)
    local x,y
    if side=='enemy' then x=b.l-8-w;y=b.t-8-h
    else x=b.r+5;y=b.b-h end
    -- Only window edges override requested spacing; keep the entire HUD usable.
    return math.max(0,math.min(windowW-w,x)),math.max(0,math.min(windowH-h,y))
  end
  return A
end
