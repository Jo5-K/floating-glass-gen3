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
 L.profiles=profiles
 function L.profileForHour(hour)
  if hour<5 then return 'predawn' elseif hour<7 then return 'dawn'
  elseif hour<11 then return 'morning' elseif hour<16 then return 'noon'
  elseif hour<19 then return 'dusk' else return 'night' end
 end
 local environments=R.load('gen3/lighting_environments.lua')
 L.environments=environments
 function L.setScene(id) L.scene=id or 'unknown' end
 local source=R.load('gen3/lighting_shader.lua')
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
  L.hour=hour;L.profile=L.profileForHour(hour);L.active=true
  L.battle=event and event.battle;L.scene='unknown'
 end
 function L.ended() L.active=false;L.battle=nil;L.hour=nil;L.profile=nil;L.scene=nil end
 function L.enabled() return L.active and not L.failed and R.option('dynamic_lighting',true)==true end
 function L.effectiveProfile()
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
  local direction=dirs[R.option('lighting_direction','auto')] or p.direction
  local env=environments.resolve(L.scene,L.effectiveProfile())
  local ok,err=pcall(function()
   sh:send('ambientColor',p.ambient);sh:send('exposure',p.exposure)
   sh:send('lightDirection',direction);sh:send('directionStrength',p.strength)
   sh:send('lightColor',p.light);sh:send('lightIntensity',setting('lighting_intensity',.75))
   sh:send('ambientLevel',setting('lighting_ambient',.75))
   sh:send('rimStrength',setting('lighting_rim',.5));sh:send('reliefStrength',setting('lighting_relief',.5))
   sh:send('texelSize',rect and rect.texel or {0,0})
   if kind~='sprite' then
    sh:send('forestAnchor',rect and rect.anchor or {0,0,0})
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
  return (table.unpack or unpack)(result,2,result.n)
 end
 function L.arenaBackground(anchor,draw,...)
  L.arenaAnchor=anchor
  local function pack(...) return {n=select('#',...),...} end
  local result=pack(pcall(L.sceneryBackground,draw,...));L.arenaAnchor=nil
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
  local args={...};local img=args[1];local rect={0,0,1,1};rect.forest=L.forestPass;rect.anchor=L.arenaAnchor
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
