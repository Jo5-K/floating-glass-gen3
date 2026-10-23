-- Gen3 graphical integration, Gen1Recomp >=0.3.93.
return function(mod)
  local game=require('src.core.GameVersion').get()
  if not ({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[game] then return end
  local version=require('src.core.Version').engine
  assert(require('src.mods.Semver').satisfies(version,'>=0.3.93'),
    'Floating Glass Gen3 requires Gen1Recomp >=0.3.93; found '..tostring(version))
  local function loadPart(path)
    return assert(load(assert(mod:read(path)),'@floating_glass_frlg/'..path))()
  end
  local R={mod=mod,version='1.2.8',engine=version,depth=0,patches={},warnings={}}
  R.load=loadPart
  -- The bare sandbox omits package; Loader's legacy compat supplies only an
  -- isolated, empty package.loaded, never the engine's live module cache.
  -- Engine modules must be acquired through its permitted require function.
  local modules={}
  function R.module(name)
    if modules[name] then return modules[name] end
    local ok,value=pcall(require,name)
    if ok and type(value)=='table' then modules[name]=value;return value end
    R.warn('module '..name,ok and 'Module did not return a table' or value)
    return nil
  end
  function R.active()
    local id=require('src.core.GameVersion').get()
    return not R.unloaded and ({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[id]==true
  end
  function R.option(key,default)
    local value=mod.options:get('gen3_'..key)
    if value==nil then return default end
    return value
  end
  -- The public options handle exposes define/get only in v0.3.91.
  -- Use the same native writer as the mod manager, including persistence/events.
  function R.setOption(key,value)
    local game=R.game
    local Manager=R.module('src.mods.ManagerState')
    if not game or not game.mods or not game.save or not game.save.options
      or not Manager or type(Manager.new)~='function' then
      R.warn('settings unavailable','Native game/options manager is not ready');return false
    end
    local ok,result=pcall(function() return Manager.new(game):setOption(mod.id,'gen3_'..key,value) end)
    if not ok then R.warn('settings write',result);return false end
    return result~=false
  end
  function R.glass() return R.active() and R.option('theme','floating_glass')=='floating_glass' end
  function R.warn(key,err)
    if R.warnings[key] then return end
    R.warnings[key]=tostring(err)
    if mod.log then mod.log:warn('KRS Gen3 %s: %s',key,tostring(err)) end
  end
  function R.wrap(target,key,wrapper)
    if type(target)~='table' or type(target[key])~='function' then return false end
    local original=target[key]
    local fn=function(...)
      if not R.active() then return original(...) end
      return wrapper(original,...)
    end
    target[key]=fn;R.patches[#R.patches+1]={target,key,original,fn}
    return true
  end
  function R.scope(fn,...)
    R.depth=R.depth+1
    love.graphics.push('all')
    local ok,a,b,c=pcall(fn,...)
    love.graphics.pop();R.depth=R.depth-1
    if not ok then error(a,0) end
    return a,b,c
  end
  local cameraChoices={{'AUTO BY GAME','auto'}}
  for _,e in ipairs(loadPart('gen3/background_catalog.lua').entries) do cameraChoices[#cameraChoices+1]={e.label,e.id} end
  mod.options:define({
    {key='gen3_battle_camera',label='BATTLE CAMERA',type='choice',default='native',group='GEN 3 / BATTLE',choices={{'NATIVE','native'},{'ORIGINAL','current'},{'G9 / HD COMPATIBILITY','g9_compat'},{'FOREGROUND','native_depth'}}},
    {key='gen3_shadows',label='SPRITE SHADOWS',type='choice',default='auto',group='GEN 3 / BATTLE',choices={{'AUTO: CAMERA POLICY','auto'},{'ENEMIES','enemies'},{'BOTH','both'}}},
    {key='gen3_shadow_anchor',label='SHADOW CONTACT',type='choice',default='feet',group='GEN 3 / BATTLE',choices={{'FEET','feet'},{'KNEES','knees'}}},
    {key='gen3_camera_background',label='BACKGROUND 21:9',type='choice',default='auto',group='GEN 3 / SCENERY',choices=cameraChoices},
    {key='gen3_theme',label='BATTLE UI THEME',type='choice',default='floating_glass',group='GEN 3 / APPEARANCE',choices={{'FLOATING GLASS','floating_glass'},{'ORIGINAL','native'}}},
    {key='gen3_battle',label='GEN3 FLOATING BATTLE',type='toggle',default=true,group='GEN 3 / BATTLE',description='Floating overlay for single battles. Native screens handle double battles, tutorials and special choices.'},
    {key='gen3_battle_layout',label='BUTTON LAYOUT',type='choice',default='layers',group='GEN 3 / BATTLE',choices={{'CARTAS EM CAMADAS','layers'},{'LISTA FLUTUANTE','list'},{'COMMAND MENU (FIGHT)','commands'}}},
    {key='gen3_lighting_profile',label='LIGHT PROFILE',type='choice',default='auto',group='GEN 3 / LIGHTING',choices={{'LOCAL TIME','auto'},{'PREDAWN','predawn'},{'DAWN','dawn'},{'MORNING','morning'},{'NOON','noon'},{'DUSK','dusk'},{'NIGHT','night'}}},
    {key='gen3_lighting_intensity',label='LIGHT INTENSITY',type='choice',default=.75,group='GEN 3 / LIGHTING',choices={{'25%',.25},{'50%',.5},{'75%',.75},{'100%',1}}},
    {key='gen3_lighting_ambient',label='AMBIENT BRIGHTNESS',type='choice',default=.75,group='GEN 3 / LIGHTING',choices={{'50%',.5},{'75%',.75},{'100%',1}}},
    {key='gen3_lighting_rim',label='RIM LIGHT',type='choice',default=.5,group='GEN 3 / LIGHTING',choices={{'OFF',0},{'25%',.25},{'50%',.5},{'75%',.75}}},
    {key='gen3_lighting_relief',label='APPROXIMATE RELIEF',type='choice',default=.5,group='GEN 3 / LIGHTING',choices={{'OFF',0},{'25%',.25},{'50%',.5},{'75%',.75}}},
    {key='gen3_lighting_direction',label='LIGHT DIRECTION',type='choice',default='auto',group='GEN 3 / LIGHTING',choices={{'AUTO','auto'},{'LEFT','left'},{'RIGHT','right'},{'TOP','top'}}},
    {key='gen3_lighting_beams',label='POST-SPRITE LIGHT RAYS',type='toggle',default=true,group='GEN 3 / LIGHTING'},
    {key='gen3_lighting_hud_glint',label='HUD COUNTER-DIRECTION GLINT',type='toggle',default=true,group='GEN 3 / LIGHTING'},
    {key='gen3_lighting_local',label='LOCAL LIGHTING',type='toggle',default=true,group='GEN 3 / LIGHTING'},
    {key='gen3_dynamic_lighting',label='DYNAMIC LIGHTING',type='toggle',default=true,group='GEN 3 / BATTLE'},
    {key='gen3_dialogue_size',label='BATTLE MESSAGE SIZE',type='choice',default='medium',group='GEN 3 / BATTLE',choices={{'SMALL (PREVIOUS)','small'},{'MEDIUM','medium'},{'MEDIUM LARGE','medium_large'},{'LARGE','large'}}},
    {key='gen3_command_scale',label='COMMAND MENU SIZE',type='choice',default=1,group='GEN 3 / BATTLE',choices={{'75%',.75},{'100%',1},{'125%',1.25},{'150%',1.5},{'175%',1.75}}},
    {key='gen3_battle_opacity',label='MOVE CARD OPACITY',type='choice',default=.70,group='GEN 3 / BATTLE',choices={{'70%',.70},{'55%',.55},{'85%',.85}}},
    {key='gen3_battle_scale',label='BATTLE UI SIZE',type='choice',default=.68,group='GEN 3 / BATTLE',choices={{'NORMAL',.68},{'SMALL',.58},{'LARGE',.78}}},
    {key='gen3_battle_position',label='BATTLE UI POSITION',type='choice',default='left',group='GEN 3 / BATTLE',choices={{'LEFT','left'},{'RIGHT','right'}}},
    {key='gen3_scenery',label='LAYERED SCENERY',type='choice',default='auto',group='GEN 3 / SCENERY',choices={{'AUTO','auto'},{'NATIVE / OTHER MODS','native'}}},
    {key='gen3_button_palette',label='BUTTON PALETTE',type='choice',default='pastel',group='GEN 3 / BATTLE',choices={{'NEUTRAL PASTEL','pastel'},{'METAL','metal'}}},
    {key='gen3_lens_size',label='FOREGROUND SIZE',type='choice',default=.65,group='GEN 3 / SCENERY',choices={{'SMALL',.65},{'MEDIUM',.8},{'ORIGINAL',1}}},
    {key='gen3_lens_motion',label='GENTLE FOREGROUND MOTION',type='toggle',default=true,group='GEN 3 / SCENERY'},
    {key='gen3_foreground',label='FOREGROUND',type='choice',default=.65,group='GEN 3 / SCENERY',choices={{'65%',.65},{'OFF',0},{'100%',1}}},
    {key='gen3_battle_aspect',label='BATTLE ASPECT',type='choice',default='window',group='GEN 3 / BATTLE',choices={{'WINDOW','window'},{'NATIVE 3:2','native'},{'4:3','4:3'},{'16:9','16:9'}}},
    {key='gen3_battle_skin',label='BATTLE COLOR STYLE',type='choice',default='current',group='GEN 3 / BATTLE',choices={{'CURRENT','current'},{'EMERALD GREEN & IVORY','emerald_ivory'},{'CLASSIC COLORS','classic'}}},
    {key='gen3_settings_language',label='SETTINGS LANGUAGE / IDIOMA',type='choice',default='pt-BR',group='GEN 3 / BATTLE',choices={{'PT-BR','pt-BR'},{'English','en'},{'Français','fr'},{'Español','es'}}},
    {key='gen3_battle_drop',label='LOWER BATTLERS',type='choice',default=8,group='GEN 3 / BATTLE',choices={{'8 PX',8},{'12 PX',12},{'16 PX',16},{'20 PX',20},{'NATIVE',0}}},
    {key='gen3_battle_extend',label='EXTEND NATIVE BATTLE FIELD',type='toggle',default=true,group='GEN 3 / BATTLE',description='Continue native wallpaper under the former GBA command panel; disable if another scenery mod supplies that area.'},
    {key='gen3_caught',label='SHOW CAUGHT POKEMON',type='toggle',default=true,group='GEN 3 / BATTLE'},
    {key='gen3_remember_move',label='REMEMBER LAST MOVE',type='toggle',default=true,group='GEN 3 / BATTLE'},
    {key='gen3_sprite_source',label='GEN3 POKEMON SPRITES',type='choice',default='native',group='GEN 3 / GRAPHICS',choices={{'ORIGINAL / OTHER MODS','native'},{'KRS STATIC ART','krs'}},description='KRS uses individually cropped static frames, never full animation sheets. Missing species and special forms keep native art.'},
    {key='gen3_front_generation',label='KRS FRONT GENERATION',type='choice',default='5',group='GEN 3 / GRAPHICS',choices={{'GEN 1','1'},{'GEN 2','2'},{'GEN 3','3'},{'GEN 4','4'},{'GEN 5','5'}}},
    {key='gen3_back_generation',label='KRS BACK GENERATION',type='choice',default='5',group='GEN 3 / GRAPHICS',choices={{'GEN 1','1'},{'GEN 2','2'},{'GEN 3','3'},{'GEN 4','4'},{'GEN 5','5'}}},
  })
  -- Temporary battle-only scope requested by the user. Outside menus stay native.
  R.outsideBattleUI=false
  R.camera=loadPart('gen3/camera.lua')(R)
  R.compat=loadPart('gen3/sprite_compat.lua')(R)
  R.shadows=loadPart('gen3/shadows.lua')(R)
  R.theme=loadPart('gen3/theme.lua')()
  R.framing=loadPart('gen3/framing.lua')(R)
  R.lighting=loadPart('gen3/lighting.lua')(R)
  R.postLight=loadPart('gen3/post_light.lua')(R)
  R.details=loadPart('gen3/scene_details.lua')(R)
  R.scenery=loadPart('gen3/scenery.lua')(R)
  R.art=loadPart('gen3/art.lua')(R)
  R.battle=loadPart('gen3/battle.lua')(R)
  local drawWrapped=setmetatable({},{__mode='k'})
  local function install(game)
    if not R.active() then return end
    R.game=game or R.game
    R.art.installLoaded();R.battle.installLoaded();R.scenery.installLoaded();R.framing.installLoaded()
    local Game=R.module('src.core.Game3')
    if Game and not drawWrapped[Game] and type(Game.draw)=='function' then
      drawWrapped[Game]=true
      R.wrap(Game,'draw',function(next,self,...)
        -- Menus can be lazy-loaded during the preceding update. Install before
        -- the first actual draw, avoiding an initial frame with the old skin.
        install(self)
        local cameraToken=R.compat.begin()
        local ok,a,b=pcall(next,self,...)
        R.compat.finish(cameraToken)
        if not ok then error(a,0) end
        return a,b
      end)
    end
  end
  install()
  mod.events:on('battle.started',function(e) if R.active() then R.lighting.started(e) end end)
  mod.events:on('battle.ended',function() R.lighting.ended() end)
  mod.events:on('game.ready',function(event) install(event and event.game) end)
  mod.hooks:wrap('input.step',function(next,game,dt)
    install(game)
    if R.active() then R.lighting.update(dt) end
    return next(game,dt)
  end,250)
  mod.hooks:wrap('render.hud',function(next,game,viewport)
    local out=next(game,viewport)
    install(game)
    if R.unloaded then return out end
    local ok,err=pcall(R.battle.draw,game,viewport)
    if not ok then R.battle.failed=true;R.warn('battle renderer disabled; native UI restored',err) end
    return out
  end,250)
  local unloaded=false
  local function unload()
    if unloaded then return end;unloaded=true;R.unloaded=true
    R.postLight.shutdown();R.details.shutdown();R.lighting.shutdown();R.shadows.shutdown();R.scenery.shutdown();if R.battle.shutdown then R.battle.shutdown() end
    for i=#R.patches,1,-1 do
      local p=R.patches[i]
      if p[1][p[2]]==p[4] then p[1][p[2]]=p[3] end
    end
  end
  mod.events:on('mod.unload',function(e) if not e or not e.mod or e.mod==mod.id then unload() end end)
  mod.exports.gen3={version=R.version,engine=R.engine,shutdown=unload,
    registerType=R.battle.registerType,registerSceneLayer=R.details.register,removeSceneLayer=R.details.remove,diagnostics=function() return {warnings=R.warnings,battleFallback=R.battle.failed==true,lighting={active=R.lighting.active,enabled=R.lighting.enabled(),profile=R.lighting.profile,hour=R.lighting.hour,failed=R.lighting.failed,postRays=R.postLight.enabled(),postRaysFailed=R.postLight.failed}} end}
  if mod.log and mod.log.info then
    mod.log:info('Floating Glass Gen3 %s initialized for %s; native sandbox require bridge active.',R.version,game)
  end
  return R
end
