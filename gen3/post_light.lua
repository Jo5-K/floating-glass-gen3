-- World rays after sprites/foreground; HUD gets only a separate small glint.
return function(R)
 local P={failed=false}
 local function base()
  local L=R.lighting
  return L and L.enabled() and R.option('lighting_local',true)~=false and L.frame and L.frame.scene==L.scene
 end
 function P.enabled()
  if not base() or P.failed or R.option('lighting_beams',true)==false then return false end
  local L=R.lighting;local s=L.spatial.resolve(L.scene,L.effectiveProfile())
  local effect=L.spatial.effect(L.scene,L.effectiveProfile())
  return effect~=nil and (not effect.solar or s.daylight>.20 and L.direction()[2]<-.1)
 end
 function P.vertices(w,h,f)
  return {{0,0,-f.x/f.w,-(f.y or 0)/f.h,1,1,1,1},{w,0,(w-f.x)/f.w,-(f.y or 0)/f.h,1,1,1,1},
   {w,h,(w-f.x)/f.w,(h-(f.y or 0))/f.h,1,1,1,1},{0,h,-f.x/f.w,(h-(f.y or 0))/f.h,1,1,1,1}}
 end
 function P.draw(w,h,detailStage)
  if not P.enabled() then return end
  local g=love.graphics;local L=R.lighting;local f=L.frame
  if not (g.newMesh and g.newShader) or g.getShader and g.getShader() then return end
  if g.getBlendMode then local mode,alpha=g.getBlendMode();if mode~='alpha' or alpha and alpha~='alphamultiply' then return end end
  g.push('all')
  local ok,err=pcall(function()
   if not P.shader then
    local source=R.load('gen3/post_light_shader.lua'):gsub('// SHARED_BEAM_FUNCTIONS',function()return L.sharedBeam end)
    P.shader=g.newShader(source)
   end
   local signature=table.concat({w,h,f.x,f.y or 0,f.w,f.h},':')
   if signature~=P.signature then
    if P.mesh and P.mesh.release then P.mesh:release() end
    P.mesh=g.newMesh(P.vertices(w,h,f),'fan','static');P.signature=signature
   end
   local layout=L.spatial.resolve(L.scene,L.effectiveProfile());local profile=L.profiles[L.effectiveProfile()]
   local effect=L.spatial.effect(L.scene,L.effectiveProfile())
   P.shader:send('reflectionArea',effect.reflection)
   P.shader:send('detailStage',detailStage and 1 or 0);P.shader:send('environmentStyle',effect.style);P.shader:send('battleSeed',L.seed or 0)
   P.shader:send('lightDirection',L.direction());P.shader:send('lightColor',effect.color or profile.light)
   P.shader:send('lightTime',L.time or 0);P.shader:send('artAspect',f.w/f.h)
   P.shader:send('daylightAmount',effect.solar and layout.daylight or 1);P.shader:send('lightIntensity',tonumber(R.option('lighting_intensity',.75)) or .75)
   for i=0,3 do
    -- Traditional cave has no crystal emitter in its existing art. Ambient only.
    local emitter=L.scene~='cave' and (effect.lights or layout.lights)[i+1] or nil
    if L.scene=='lavender'and L.ambientEmitter then emitter=i==0 and L.ambientEmitter or nil end
    P.shader:send('beam'..i,emitter or {0,0,1,0})
    P.shader:send('blocked'..i,layout.protected[i+1] or {0,0,0,0})
   end
   g.origin();local area=R.portrait and R.portrait.field(w,h);if area then g.setScissor(area.x,area.y,area.w,area.h)end;g.setColor(1,1,1,1);g.setBlendMode('alpha','alphamultiply');g.setShader(P.shader);g.draw(P.mesh)
  end)
  g.pop()
  if not ok then P.failed=true;R.warn('post-sprite light disabled',err) end
 end
 -- The incoming ray travels opposite to the vector pointing toward its source.
 -- This glint travels toward that source: at most six WINDOW pixels per sweep.
 function P.hudMotion()
  local d=R.lighting.direction();local len=math.sqrt(d[1]^2+d[2]^2)
  return d[1]/len*6,d[2]/len*6
 end
 function P.hud(rect,pixelScale)
  if not base() or R.option('lighting_hud_glint',true)==false or not rect or rect.w<=0 or rect.h<=0 then return end
  local g=love.graphics;if not (g.line and g.setLineWidth) or g.getShader and g.getShader() then return end
  local phase=((R.lighting.time or 0)%12)/12
  if phase>.25 then return end -- short gentle glint, with a long quiet interval
  local t=phase/.25;local opacity=math.sin(t*math.pi)*.18*(tonumber(R.option('lighting_intensity',.75)) or .75)
  local dx,dy=P.hudMotion();local unit=1/math.max(.01,pixelScale or 1)
  local x=rect.x+rect.w*.72+dx*(t-.5)*unit
  local y=rect.y+4*unit+dy*(t-.5)*unit
  g.push('all');g.setColor(1,1,.88,opacity);g.setLineWidth(unit)
  g.line(x-2*unit,y,x+2*unit,y);g.pop()
 end
 function P.shutdown()
  for _,key in ipairs({'shader','mesh'}) do local resource=P[key];if resource and resource.release then resource:release() end end
  P.shader=nil;P.mesh=nil;P.signature=nil;P.failed=false
 end
 return P
end
