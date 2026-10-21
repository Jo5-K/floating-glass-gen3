-- Real 0.3.91 terrain-family dispatch and production asset composition; no GPU/ROM.
local Recorder=dofile('tests/svg_recorder.lua')
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local root='floating_glass_frlg/'
local function part(path) return assert(loadfile(root..path))() end
local family='frlg'
package.loaded['src.core.game3.collision']={}
package.loaded['src.core.game3.mb']={}
package.loaded['src.core.game3.constants']={of=function() return {battle=dofile('tests/fixtures/EmeraldBattleConstants-0.3.91.lua')} end}
package.loaded['src.core.game3.battle.env_frlg']=dofile('tests/fixtures/EnvFrlg-0.3.91.lua')
package.loaded['src.core.game3.battle.env_rse']=dofile('tests/fixtures/EnvRse-0.3.91.lua')
package.loaded['src.core.game3.profile']={family=function() return family end}
package.loaded['src.core.game3.battle.profile']={get=function() return {} end}
local delegated=0
package.loaded['src.ui.game3.battle_chrome']={manifest=function() return {} end,drawTerrain=function() delegated=delegated+1;return true end}
local index=part('gen3/scenery_index.lua');local assetCount=0
for _,group in pairs(index) do for _,path in pairs(group) do
 local img=Recorder.image(root..path);check(img.w>0 and img.h>0,'readable PNG '..path);assetCount=assetCount+1
end end
check(assetCount==50,'20 backgrounds, 20 foregrounds, 10 separated pads')
for _,game in ipairs({'firered','leafgreen','ruby','sapphire','emerald'}) do
 family=(game=='firered' or game=='leafgreen') and 'frlg' or 'rse'
 local Bg=dofile('tests/fixtures/BattleBg-0.3.91.lua')
 local options={};local failedAsset=false
 local R={load=part,battle={scene=true},framing={wideReady=true},option=function(key,default) if options[key]~=nil then return options[key] end;return default end,
   module=function(name) if name=='src.core.game3.battle.bg' then return Bg elseif name=='src.core.GameVersion' then return {get=function() return game end} end end,warn=function() end,
   mod={assets={image=function(_,path) if failedAsset then error('missing fixture') end;return Recorder.image(root..path) end}}}
 function R.wrap(t,k,fn) local old=t[k];t[k]=function(...) return fn(old,...) end end
 local S=part('gen3/scenery.lua')(R);S.installLoaded()
 local rec=Recorder.new(1200,800);love={graphics=rec.graphics};rec.graphics.clear=function() end
 local previous=delegated
 local scenes={grass='forest',long_grass='tall_grass',cave='cave',water='water',pond='pond',plain='plain',gym='gym'}
 if family=='frlg' then scenes.lorelei='ice';scenes.bruno='bruno';scenes.agatha='ghost';scenes.lance='dragon';scenes.champion='blue'
 else scenes.sidney='sidney';scenes.phoebe='ghost';scenes.glacia='ice';scenes.drake='dragon';scenes.frontier='virtual'
   if game=='emerald' then scenes.champion='wallace' end
 end
 for key,id in pairs(scenes) do
  local terrain
  for k,v in pairs(Bg.env().TERRAIN_SHEET) do if v==key then terrain=k end end
  check(terrain~=nil,'native key '..key)
  local before=rec.images
  check(Bg.draw(terrain,7,-9,0)==true,'custom terrain succeeds '..game)
  check(S.replaced and S.selected==id,'correct game/theme '..game..' '..key)
  check(rec.images==before,'no native canvas art or pads')
  S.drawWide(1200,800);check(rec.images==before+(S.arenaCatalog[id] and 3 or 1),'forest review layer only; other terrains have no arenas')
 end
 Bg.draw(Bg.TERRAIN.GRASS);local before=rec.images;S.foreground()
 check(rec.images-before==2,'two foreground halves')
 check(delegated==previous,'supported scenery replaced once')
 options.foreground=0;local before=rec.images;S.foreground();check(rec.images==before,'foreground off')
 options.scenery='native';Bg.draw(Bg.TERRAIN.GRASS);check(S.current==nil and delegated==previous+1,'native scenery option delegates')
 options.scenery='auto';R.battle.scene=false;Bg.draw(Bg.TERRAIN.GRASS);check(S.current==nil,'special battles preserve native scene')
 R.battle.scene=true
 if game=='ruby' or game=='sapphire' then
  Bg.draw(Bg.TERRAIN.CHAMPION);check(not S.replaced,'Steven has no Wallace art')
 end
 local none=S.resolve(game,'unsupported_unique');check(none==nil,'unknown unique scene is native')
 for _,entry in ipairs(S.catalog.entries) do
  options.camera_background=entry.id;check(S.resolve(game,'grass').id==entry.id,'manual selection '..entry.id)
 end
 options.camera_background='auto'
 S.cache={};failedAsset=true;previous=delegated;Bg.draw(Bg.TERRAIN.GRASS)
 check(delegated==previous+1 and S.current==nil,'missing assets fall back without hiding native background')
 check(#rec.stack==0,'graphics stack balanced')
 -- Preview of actual composition code only: deliberately no fake HP boxes.
 failedAsset=false;S.cache={};options.arena=1;options.foreground=.65
 rec=Recorder.new(1200,800);love.graphics=rec.graphics;rec.graphics.clear=function() end
 Bg.draw(Bg.TERRAIN.GRASS);S.drawWide(1200,800);S.foreground(1200,800)
 rec:save('preview_frames/29-Cenario-'..game..'.svg')
end
print(count..' scenery checks passed; actual native terrain modules, simulated graphics and no ROM.')
