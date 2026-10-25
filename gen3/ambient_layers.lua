-- Presentation-only layers 2, 3 and 7. Assets stay isotropic in the visible central square.
return function(R)
 local A={cache={},quads={}}
 local catalog=R.load('gen3/ambient_catalog.lua')
 function A.has(scene)return catalog.scenes[scene=='wallace'and'pond'or scene]~=nil end
 function A.safe(w,h,field)
  local f=field or {x=0,y=0,w=w,h=h};local u=math.min(f.w,f.h)
  return {x=f.x+(f.w-u)/2,y=f.y,w=u,h=f.h,unit=u}
 end
 local function image(path)
  if A.cache[path]==nil then
   local ok,img=pcall(R.mod.assets.image,R.mod.assets,path);A.cache[path]=ok and img or false
   if img and ok and img.setFilter then img:setFilter('nearest','nearest')end
   if not ok then R.warn('ambient asset '..path,img)end
  end
  return A.cache[path]or nil
 end
 local function quad(img,key,x,y,w,h)
  if not A.quads[key] then local iw,ih=img:getDimensions();A.quads[key]=love.graphics.newQuad(x,y,w,h,iw,ih)end
  return A.quads[key]
 end
 local function draw(img,q,x,y,k,qx,qy)
  local g=love.graphics;local L=R.lighting
  if L and L.frame then
   local f=L.frame;local iw,ih=img:getDimensions()
   return L.arenaBackground({iw*k/f.w,ih*k/f.h,(x-qx*k-f.x)/f.w,(y-qy*k-f.y)/f.h},g.draw,img,q,x,y,0,k,k)
  end
  return g.draw(img,q,x,y,0,k,k)
 end
 function A.parts(layer,scene,safe)
  local e=catalog.scenes[scene=='wallace'and'pond'or scene];e=e and e[layer];if not e then return end
  local img=image(e.path);if not img then return end
  local g=love.graphics;local u=safe.unit
  for i,b in ipairs(e.parts)do
   -- Each disconnected half is translated into the square; no image squeezing.
   local k=math.min(u*.31/b[3],u*(layer=='front'and .18 or .23)/b[4])
   local x=safe.x+u*(i==1 and .18 or .82)-b[3]*k/2
   local y=layer=='front'and safe.y+safe.h-b[4]*k or safe.y+safe.h*.53-b[4]*k
   g.setColor(1,1,1,layer=='front'and math.min(1,tonumber(R.option('foreground',.65))or .65)or 1)
   draw(img,quad(img,e.path..i,b[1],b[2],b[3],b[4]),x,y,k,b[1],b[2])
  end
 end
 local sizes={wind=.075,dust=.045,butterfly=.022,pond_ripple=.055,magikarp=.045,seafoam=.09,tentacool=.045,leaf=.022,tumbleweed=.04,diglett=.04}
 local function noise(n)return (math.sin(n*127.1+311.7)*43758.5453)%1 end
 function A.sprites(scene,safe,time)
  if scene=='wallace'then scene='pond'end
  local ids={};for id,t in pairs(catalog.sprites)do for _,s in ipairs(t.scenes)do if s==scene or (scene=='forest'or scene=='tall_grass')and(id=='wind'or id=='leaf'or id=='butterfly')then ids[#ids+1]=id;break end end end;table.sort(ids)
  for n,id in ipairs(ids)do
   local t=catalog.sprites[id];local period=t.seconds+(t.pause[1]+t.pause[2])/2
   local cycle=math.floor((time+n*7)/period);local phase=(time+n*7)%period
   local delay=noise(cycle+n*13)*(t.pause[2]-t.pause[1])*.45
   if phase>=delay and phase<delay+t.seconds then
    local img=image(t.path)
    if img then
     local iw,ih=img:getDimensions();local cw,ch=iw/4,ih/2;local frame=math.min(7,math.floor((phase-delay)/t.seconds*8));local qx,qy=frame%4*cw,math.floor(frame/4)*ch
     local k=safe.unit*(sizes[id]or .04)/ch
     local x=safe.x+safe.unit*(.12+.76*noise(n*3+cycle*7))-cw*k/2
     local y=safe.y+safe.h*(scene=='water'and .46 or scene=='pond'and .42 or .53)-ch*k*.80
     if id=='wind'or id=='leaf'or id=='tumbleweed'or id=='butterfly'then x=x+((phase-delay)/t.seconds-.5)*safe.unit*.12 end
     love.graphics.setColor(1,1,1,1);draw(img,quad(img,t.path..frame,qx,qy,cw,ch),x,y,k,qx,qy)
    end
   end
  end
 end
 function A.draw(layer,scene,w,h,field,time)
  if R.option('environment_details',true)==false or layer~='animated'and not A.has(scene)then return false end
  local g=love.graphics;local safe=A.safe(w,h,field)
  g.push('all');g.origin();g.setShader();g.setScissor(safe.x,safe.y,safe.w,safe.h)
  local ok,err=pcall(function()if layer=='animated'then A.sprites(scene,safe,time or 0)else A.parts(layer,scene,safe)end end)
  g.pop();if not ok then R.warn('ambient '..layer,err)end
  return true
 end
 function A.shutdown()for _,q in pairs(A.quads)do if q.release then q:release()end end;A.quads={};A.cache={}end
 return A
end
