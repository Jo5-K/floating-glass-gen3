-- Presentation-only layers 2, 3 and 7. Assets stay isotropic in the visible central square.
return function(R)
 local A={cache={},quads={},time=0,pulse=-100,active=false}
 local cues=R.load('gen3/ambient_cues.lua');A.cues=cues
 local catalog=R.load('gen3/ambient_catalog.lua')
 function A.has(scene)return catalog.scenes[scene]~=nil end
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
 function A.partLayout(layer,b,safe,side)
  local front=layer=='front';local u=safe.unit
  -- Occupancy is relative to the visible battle field, including portrait's inset.
  -- Keep each original group's proportions and move it to the square's edge.
  -- The wider foreground leaves a small opening instead of an empty middle third.
  local k=math.min(u*(front and .48 or .44)/b[3],safe.h*(front and .26 or .30)/b[4])
  local width,height=b[3]*k,b[4]*k
  return {x=safe.x+(side==1 and 0 or u-width),y=safe.y+safe.h*(front and 1 or .55)-height,w=width,h=height,k=k}
 end
 function A.parts(layer,scene,safe)
  local e=catalog.scenes[scene];e=e and e[layer];if not e then return end
  local img=image(e.path);if not img then return end
  local g=love.graphics
  for i,b in ipairs(e.parts)do
   local p=A.partLayout(layer,b,safe,i)
   g.setColor(1,1,1,layer=='front'and math.min(1,tonumber(R.option('foreground',.65))or .65)or 1)
   draw(img,quad(img,e.path..i,b[1],b[2],b[3],b[4]),p.x,p.y,p.k,b[1],b[2])
  end
 end
 local native={geodude='gen3/assets/pokemon/front/3/normal/geodude.png'}
 -- Transparency 20–75% means alpha 0.80–0.25. Independent of the 8 FPS atlas.
 function A.ghostAlpha(time)return .525+.275*math.cos((time or 0)*math.pi*2/12)end
 function A.started()A.time=0;A.pulse=-100;A.lastTrigger=-100;A.active=true;A.scene=nil;A.sceneStart=0 end
 function A.update(dt)if A.active then A.time=A.time+math.max(0,math.min(tonumber(dt)or 0,.15))end end
 function A.trigger()if A.active and A.time-(A.lastTrigger or -100)>1.5 then A.lastTrigger=A.time;A.pulse=A.time-(A.sceneStart or 0)+.2 end end
 function A.ended()A.active=false;A.time=0;A.scene=nil;A.pulse=-100 end
 function A.phase(c,time)
  if c.id=='gastly_g9'then if time>=c.at then return ((time-c.at)%(55/8))/(55/8)end;return end
  local seconds=(catalog.sprites[c.id]and catalog.sprites[c.id].seconds)or 4.8
  local start=c.at
  if time>=start then start=start+math.floor((time-start)/(seconds+4.5))*(seconds+4.5)end
  local elapsed=time-start
  if elapsed>=0 and elapsed<seconds then return elapsed/seconds end
  if A.active and c.at<1.6 and A.pulse>=0 and time>=A.pulse and time<A.pulse+seconds then return (time-A.pulse)/seconds end
 end
 function A.sprites(scene,safe,time)
  if R.option('environment_sprites',true)==false then return end
  if A.active then
   if A.scene~=scene then A.scene=scene;A.sceneStart=A.time;A.pulse=-100 end
   time=A.time-A.sceneStart
  end
  for n,c in ipairs(cues[scene]or {})do
   local phase=A.phase(c,time or 0)
   local pokemon=native[c.id]or c.id=='gastly_g9'or c.id=='diglett'or c.id=='magikarp'or c.id=='tentacool'
   if phase and (not pokemon or R.option('environment_pokemon',true)~=false)then
    local x=safe.x+safe.unit*c.x;local y=safe.y+safe.h*c.y;local envelope=c.size*safe.unit
    if c.id=='ice_motes'then
     local g=love.graphics
     for i=1,3 do
      local px=x+math.sin(i*2.1)*envelope*.45;local py=y+(phase-.5)*envelope*.5+i*envelope*.12
      local r=math.max(1,safe.unit*.003)*(1+.25*math.sin(phase*math.pi*2+i))
      g.setColor(.65,.88,1,.8*math.sin(phase*math.pi));g.polygon('fill',px,py-r*2,px+r,py,px,py+r*2,px-r,py)
     end
    elseif c.id=='gastly_g9'then
     local path='assets/scenery/ambient/sprites/gastly-g9.png';local img=image(path)
     if img then
      local elapsed=math.max(0,time-c.at);local frame=math.floor(elapsed*8)%55;local k=envelope/75
      local g=love.graphics;local alpha=A.ghostAlpha(elapsed)
      y=y+math.sin(elapsed*math.pi*2/9)*safe.unit*.006
      g.setColor(.48,.25,.8,alpha*.15);g.ellipse('fill',x,y-envelope*.4,envelope*.55,envelope*.38)
      g.setColor(1,1,1,alpha)
      g.draw(img,quad(img,path..frame,frame%8*75,math.floor(frame/8)*75,75,75),x-envelope/2,y-envelope,0,k,k)
     end
    elseif native[c.id]then
     local img=image(native[c.id]);if img then
      local iw,ih=img:getDimensions();local k=envelope/ih
      local g=love.graphics;local alpha=math.min(1,phase*8,(1-phase)*8)
      y=y+math.sin(phase*math.pi*2)*safe.unit*.006
      g.setColor(1,1,1,alpha);draw(img,quad(img,native[c.id],0,0,iw,ih),x-iw*k/2,y-ih*k,k,0,0)
     end
    else
     local t=catalog.sprites[c.id];local img=t and image(t.path)
     if img then
      local iw,ih=img:getDimensions();local cw,ch=iw/4,ih/2;local frame=math.min(7,math.floor(phase*8));local qx,qy=frame%4*cw,math.floor(frame/4)*ch;local k=envelope/ch
      if c.id=='wind'or c.id=='leaf'or c.id=='tumbleweed'or c.id=='butterfly'then x=x+(phase-.5)*safe.unit*.16 end
      love.graphics.setColor(1,1,1,1);draw(img,quad(img,t.path..frame,qx,qy,cw,ch),x-cw*k/2,y-ch*k*.82,k,qx,qy)
     end
    end
   end
  end
 end
 function A.draw(layer,scene,w,h,field,time)
  if (layer=='animated'and R.option('environment_sprites',true)==false)or (layer~='animated'and(R.option('environment_details',true)==false or not A.has(scene)))then return false end
  local g=love.graphics;local safe=A.safe(w,h,field)
  g.push('all');g.origin();g.setShader();g.setScissor(safe.x,safe.y,safe.w,safe.h)
  local ok,err=pcall(function()if layer=='animated'then A.sprites(scene,safe,time or 0)else A.parts(layer,scene,safe)end end)
  g.pop();if not ok then R.warn('ambient '..layer,err)end
  return true
 end
 function A.shutdown()A.ended();for _,q in pairs(A.quads)do if q.release then q:release()end end;A.quads={};A.cache={}end
 return A
end
