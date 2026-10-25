-- Authored transparent studies, animated gently in independent quadrants.
-- No native actors, actions, saves or global RNG are accessed.
return function(R)
 local E={cache={},failed=false}
 local assets={cave_ice='caverna-gelo',forest='floresta',tall_grass='grama-alta',plain='planicie',beach='praia',pond='lagoa',water='mar',desert='deserto',mountain='montanha-rochas',rocky='montanha-rochas',cave='caverna',virtual='virtual',wallace='cachoeiras'}
 E.assets=assets
 function E.draw(ctx)
  local L=R.lighting
  if E.failed or not L or not L.enabled() or R.option('lighting_local',true)==false or R.option('environment_details',true)==false then return end
  if R.ambient and R.ambient.has(ctx.scene)then return end
  local id=assets[ctx.scene]
  if ctx.scene=='lavender' then
   local g=love.graphics
   if g.getShader and g.getShader() then return end
   if E.ghost==nil then
    local ok,img=pcall(R.mod.assets.image,R.mod.assets,'gen3/assets/pokemon/front/3/normal/gastly.png');E.ghost=ok and img or false
   end
   if E.ghost then
    local iw,ih=E.ghost:getDimensions();local k=ctx.artHeight*.07/ih
    local t=ctx.time or 0
    local x=ctx.artWidth*.10-iw*k/2+math.sin(t*.17)*ctx.artWidth*.002
    local y=ctx.artHeight*.43-ih*k/2+math.sin(t*.23)*ctx.artHeight*.004
    g.setColor(1,1,1,.82);g.draw(E.ghost,x,y,0,k,k)
   end
   return
  end
  if not id then return end
  local g=love.graphics;if not (g.newQuad and g.setColor) or g.getShader and g.getShader() then return end
  if g.getBlendMode then local blend,alpha=g.getBlendMode();if blend~='alpha' or alpha and alpha~='alphamultiply' then return end end
  local entry=E.cache[id]
  if entry==nil then
   local ok,img=pcall(R.mod.assets.image,R.mod.assets,'assets/scenery/details/'..id..'.png')
   if not ok or not img then E.cache[id]=false;R.warn('environment detail unavailable: '..id,img);return end
   local iw,ih=img:getDimensions();entry={image=img,quads={}}
   for row=0,1 do for col=0,1 do
    local x,y=col*iw/2,row*ih/2
    entry.quads[#entry.quads+1]={quad=g.newQuad(x,y,iw/2,ih/2,iw,ih),x=x,y=y,row=row,col=col}
   end end
   E.cache[id]=entry
  end
  if not entry then return end
  local iw,ih=entry.image:getDimensions();local sx,sy=ctx.artWidth/iw,ctx.artHeight/ih
  local t=ctx.time or 0;local seed=(L.seed or 0)*.017
  for i,part in ipairs(entry.quads)do
   local dx,dy=0,0
   -- Do not make shells, logs, rocks or crystal bases float with the effects.
   local movable=(id=='floresta' and part.row==0) or (id=='praia' and part.row==0) or id=='deserto' or id=='virtual' or id=='lagoa' or id=='mar' or id=='cachoeiras'
   if movable then dx=math.sin(t*.19+seed+i)*1.5;dy=math.sin(t*.13+seed+i*1.7)*.7 end
   local alpha=(id=='virtual' or id=='cachoeiras') and .38 or .62
   if (id=='caverna' and part.row==0) or (id=='floresta' and part.row==0) then
    local life=((t+seed+i*3)/(id=='caverna' and 12 or 18))%1
    dy=dy+life*ctx.artHeight*.025
    alpha=alpha*math.sin(life*math.pi)^2
   elseif id=='grama-alta' or id=='planicie' then
    -- Fine bounded breeze; the copied source texture itself remains untouched.
    dx=math.sin(t*.7+seed+i)*.8
   end
   g.setColor(1,1,1,alpha)
   ctx.drawQuad(entry.image,part.quad,part.x*sx+dx,part.y*sy+dy,sx,sy,part.x,part.y)
  end
 end
 function E.shutdown()
  for _,entry in pairs(E.cache)do if entry then for _,part in ipairs(entry.quads)do if part.quad.release then part.quad:release()end end end end
  E.cache={};E.ghost=nil;E.failed=false
 end
 return E
end
