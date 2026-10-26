-- GPU-only presentation. Never change the battle clock, state, sprites or PNGs.
return function(R)
 local L={active=false,shaders={},failed=false}
 local profiles={
  predawn={ambient={.30,.48,1.10},exposure=.70,direction={-.65,-.75},strength=.28,light={.50,.72,1.12}},
  dawn={ambient={1.04,.87,.73},exposure=.90,direction={-.85,-.35},strength=.32,light={1.15,.82,.45}},
  morning={ambient={1.03,.97,.82},exposure=.97,direction={-.65,-.75},strength=.28,light={1.12,.99,.63}},
  noon={ambient={1.02,.98,.89},exposure=.98,direction={-.25,-.97},strength=.25,light={1.10,1.03,.76}},
  dusk={ambient={1.04,.79,.69},exposure=.83,direction={.85,-.35},strength=.32,light={1.16,.64,.37}},
  night={ambient={.36,.56,1.10},exposure=.75,direction={.65,-.75},strength=.28,light={.54,.77,1.15}},
 }
 profiles.cave_internal={ambient={.65,.67,.73},exposure=.84,direction={-.3,-.9},strength=.16,light={.95,.81,.60}}
 profiles.ice_internal={ambient={.57,.74,.88},exposure=.82,direction={-.3,-.9},strength=.17,light={.58,.86,1.05}}
 L.profiles=profiles
 function L.profileForHour(hour)
  if hour<5 then return 'predawn' elseif hour<7 then return 'dawn'
  elseif hour<11 then return 'morning' elseif hour<16 then return 'noon'
  elseif hour<19 then return 'dusk' else return 'night' end
 end
 local environments=R.load('gen3/lighting_environments.lua')
 L.environments=environments
 local spatial=R.load('gen3/lighting_scenes.lua');L.spatial=spatial
 function L.setScene(id) L.scene=id or 'unknown' end
 local sharedBeam=R.load('gen3/light_beams.lua');L.sharedBeam=sharedBeam
 local source=R.load('gen3/lighting_shader.lua'):gsub('// SHARED_BEAM_FUNCTIONS',function()return sharedBeam end)
 local spriteSource=R.load('gen3/lighting_sprite_shader.lua')
 local function fail(err)
  L.failed=true;R.warn('dynamic lighting unavailable; native rendering retained',err)
 end
 function L.started(event)
  -- Deliberately capture even when disabled. Never re-read the clock in draw.
  local ok,t=pcall(function() return os.date('*t') end)
  local hour=ok and type(t)=='table' and tonumber(t.hour)
  if not hour or hour<0 or hour>=24 then
   hour=12;R.warn('lighting local clock unavailable','Neutral midday fallback; game time unchanged')
  end
  -- Seed once per battle; no global RNG mutation and no per-draw randomness.
  local clock=type(t)=='table' and t or {}
  L.seed=((tonumber(clock.yday) or 1)*97+hour*31+(tonumber(clock.min) or 0)*13+(tonumber(clock.sec) or 0)*7)%997
  L.hour=hour;L.profile=L.profileForHour(hour);L.active=true
  L.battle=event and event.battle;L.scene='unknown';L.time=0;L.lastLocalScene=nil;L.frame=nil
 end
 function L.setFrame(frame) L.frame=frame end
 function L.direction()
  local dirs={left={-1,-.3},right={1,-.3},top={0,-1}}
  return dirs[R.option('lighting_direction','auto')] or profiles[L.effectiveProfile()].direction
 end
 function L.localStatus()
  if L.failed then return 'Indisponível' end
  if not L.enabled() or R.option('lighting_local',true)==false then return 'Desligada' end
  if L.lastLocalScene==L.scene and L.spatial.scenes[L.scene] then return 'Ativa' end
  return 'Aguardando desenho'
 end
 function L.update(dt)
  if not L.active then return end
  local step=tonumber(dt) or 0
  if step~=step or step<0 then return end
  L.time=math.min((L.time or 0)+math.min(step,.10),1000000)
 end
 function L.ended() L.active=false;L.battle=nil;L.hour=nil;L.profile=nil;L.scene=nil;L.time=0;L.frame=nil end
 function L.enabled() if (L.scene=='cave'or L.scene=='cave_ice')and R.option('cave_lighting',true)==false then return false end;return L.active and not L.failed and R.option('dynamic_lighting',true)==true end
 function L.effectiveProfile()
  if L.scene=='cave'then return 'cave_internal'elseif L.scene=='cave_ice'then return 'ice_internal'end
  local manual=R.option('lighting_profile','auto')
  return profiles[manual] and manual or L.profile or 'noon'
 end
 local function setting(key,default)
  local v=tonumber(R.option(key,default)) or default
  return math.max(0,math.min(1,v))
 end
 local function shader(kind)
  if L.shaders[kind] then return L.shaders[kind] end
  local g=love.graphics
  if not (g.newShader and g.getShader and g.setShader and g.push and g.pop) then
   fail('Required LÖVE shader API unavailable');return nil
  end
  local ok,value=pcall(g.newShader,kind=='sprite' and spriteSource or source)
  if not ok then fail(value);return nil end
  L.shaders[kind]=value;return value
 end
 function L.fxFallback(kind,draw,...)
  local g=love.graphics
  if not (g.getColor and g.setColor) then return draw(...) end
  local env=environments.resolve(L.scene,L.effectiveProfile())
  local p=profiles[L.effectiveProfile()];local amount=setting('lighting_intensity',.75)
  local r,b,c,alpha=g.getColor()
  local envExposure=kind=='sprite' and (.75+env.exposure*.25) or env.exposure
  local tone={};for i=1,3 do tone[i]=(1-amount)+amount*((.28+p.ambient[i]*.72)*p.exposure*envExposure) end
  g.push('all');g.setColor(r*tone[1],b*tone[2],c*tone[3],alpha)
  local function pack(...)return {n=select('#',...),...}end
  local result=pack(pcall(draw,...));g.pop()
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.scope(kind,rect,draw,...)
  if not L.enabled() then return draw(...) end
  local g=love.graphics
  -- Never replace a native flash/palette shader or another mod's shader.
  if g.getBlendMode then
   local mode,alpha=g.getBlendMode()
   if mode~='alpha' or alpha and alpha~='alphamultiply' then return draw(...) end
  end
  if g.getShader and g.getShader()~=nil then return L.fxFallback(kind,draw,...) end
  local sh=shader(kind);if not sh then return draw(...) end
  local p=profiles[L.effectiveProfile()]
  local dirs={left={-1,-.3},right={1,-.3},top={0,-1}}
  local direction=L.direction()
  local env=environments.resolve(L.scene,L.effectiveProfile())
  local ok,err=pcall(function()
   sh:send('ambientColor',p.ambient);sh:send('exposure',p.exposure)
   sh:send('lightDirection',direction);sh:send('directionStrength',p.strength)
   sh:send('lightColor',p.light);sh:send('lightIntensity',setting('lighting_intensity',.75))
   sh:send('ambientLevel',setting('lighting_ambient',.75))
   sh:send('rimStrength',setting('lighting_rim',.5));sh:send('reliefStrength',setting('lighting_relief',.5))
   sh:send('texelSize',rect and rect.texel or {0,0})
   if kind~='sprite' then
    local layout=spatial.resolve(L.scene,L.effectiveProfile())
    if L.scene=='lavender'and L.ambientEmitter then layout.lights={L.ambientEmitter};layout.color={.68,.40,1}end
    sh:send('sceneTransform',rect and rect.transform or {1,1,0,0})
    sh:send('foliageMode',rect and rect.foliage and 1 or 0)
    sh:send('artAspect',L.frame and L.frame.w/L.frame.h or 1916/821)
    sh:send('sceneLayoutEnabled',rect and rect.forest and R.option('lighting_local',true)~=false and 1 or 0)
    sh:send('localMode',layout.mode);sh:send('localLightColor',layout.color)
    sh:send('lightTime',L.time or 0);sh:send('lightMotion',layout.amplitude)
    sh:send('daylightAmount',layout.daylight)
    for i=1,4 do
     sh:send('localLight'..(i-1),layout.lights[i] or {0,0,1,0})
     sh:send('protectedRegion'..(i-1),layout.protected[i] or {0,0,0,0})
    end
    sh:send('forestMask',rect and rect.forest and L.scene=='forest' and 1 or 0)
    sh:send('sceneExposure',env.exposure);sh:send('sceneTint',env.tint)
    sh:send('sceneDirection',env.direction);sh:send('scenePool',env.pool)
   end
   sh:send('spriteMode',kind=='sprite' and 1 or 0)
   sh:send('uvRect',rect and {rect[1],rect[2],rect[3],rect[4]} or {0,0,1,1})
   sh:send('spriteFlip',rect and rect.flip or {0,0})
  end)
  if not ok then fail(err);return draw(...) end
  g.push('all')
  local bound,bindError=pcall(g.setShader,sh)
  if not bound then g.pop();fail(bindError);return draw(...) end
  local function pack(...) return {n=select('#',...),...} end
  local result=pack(pcall(draw,...))
  g.pop()
  if not result[1] then fail(result[2]);return draw(...) end
  if kind=='background' and rect and rect.forest then L.lastLocalScene=L.scene end
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.foliageBackground(transform,draw,...)
  L.foliagePass=true
  local function pack(...)return {n=select('#',...),...}end
  local result=pack(pcall(L.arenaBackground,transform,draw,...));L.foliagePass=false
  if not result[1]then error(result[2],0)end
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.arenaBackground(transform,draw,...)
  L.arenaTransform=transform
  local function pack(...) return {n=select('#',...),...} end
  local result=pack(pcall(L.sceneryBackground,draw,...));L.arenaTransform=nil
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.sceneryBackground(draw,...)
  L.forestPass=true
  local function pack(...) return {n=select('#',...),...} end
  local result=pack(pcall(L.background,draw,...));L.forestPass=false
  if not result[1] then error(result[2],0) end
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.background(draw,...)
  if not L.enabled() then return draw(...) end
  local args={...};local img=args[1];local rect={0,0,1,1};rect.forest=L.forestPass;rect.transform=L.arenaTransform;rect.foliage=L.foliagePass
  if img and (type(img)=='table' or type(img)=='userdata') and img.getDimensions then
   local iw,ih=img:getDimensions();rect.texel={1/iw,1/ih}
  else rect.texel={1/240,1/160} end
  return L.scope('background',rect,draw,...)
 end
 function L.sprite(draw,img,...)
  if not L.enabled() then return draw(img,...) end
  local args={...};local rect={0,0,1,1}
  local iw,ih=img:getDimensions()
  local q=type(args[1])~='number' and args[1]
  if q and q.getViewport then
   local x,y,w,h=q:getViewport()
   rect={x/iw,y/ih,w/iw,h/ih}
  end
  local offset=q and 1 or 0
  local sx=tonumber(args[offset+4]) or 1;local sy=tonumber(args[offset+5]) or sx
  rect.flip={sx<0 and 1 or 0,sy<0 and 1 or 0}
  rect.texel={1/iw,1/ih}
  return L.scope('sprite',rect,draw,img,...)
 end
 function L.shutdown()
  L.ended()
  for _,sh in pairs(L.shaders) do if sh.release then pcall(sh.release,sh) end end
  L.shaders={}
 end
 return L
end
