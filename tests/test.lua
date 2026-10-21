-- Native 0.3.91 BattleAPI; simulated UI/ROM/render host. No claim of in-game QA.
local testGame=os.getenv('FRLG_TEST_GAME') or 'firered'
assert(({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[testGame])
local GV=dofile('tests/fixtures/GameVersion-0.3.91.lua')
GV.set(testGame);package.loaded['src.core.GameVersion']=GV
local passed=0
local function check(ok,message) assert(ok,message);passed=passed+1 end
local function eq(a,b,message) check(a==b,(message or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local calls={};local optionValues={};local eventHandlers={};local hooks={}
local function noop() end
local drawCalls={};local stateStack={};local font={}
function font:getWrap(text) return 100,{text} end
local graphics={}
for _,name in ipairs({'setColor','setLineWidth','rectangle','circle','polygon','line','arc','print','printf','draw','translate','rotate','scale','origin','setScissor','intersectScissor','setFont'}) do
  graphics[name]=function(...) drawCalls[#drawCalls+1]={name,...} end
end
graphics.newFont=function() return font end
graphics.newQuad=function(...) return {...} end
graphics.push=function() stateStack[#stateStack+1]=true end
graphics.pop=function() assert(table.remove(stateStack),'graphics stack underflow') end
graphics.getScissor=function() return nil end
graphics.transformPoint=function(x,y) return x,y end
love={graphics=graphics,timer={getTime=function() return 2 end}}
local M={open=false,_frame='battle',_revealed=0,_page=1,_text='Pikachu used Thunderbolt!'}
function M.isOpen() return M.open end
function M.isWaiting() return M.open and M._waiting==true end
function M.currentPage() return M._text end
function M.pressAB() calls.advance=(calls.advance or 0)+1 end
function M.draw() calls.nativeMessage=(calls.nativeMessage or 0)+1 end
local U={_mode='menu',_menuIndex=1,_moveIndex=1}
local sceneCase
U.drawOverlay=noop
local nativePics={}
U.sidePic=function(back) return {image=back and nativePics.player or nativePics.enemy,w=64,h=64,lru=true} end
local mon={species=25,nickname='Pikachu',level=20,hp=49,maxHp=60,gender='M',moves={85,98,45,86},pp={15,20,30,20}}
local enemy={species=29,nickname='Nidoran',level=18,hp=41,maxHp=50,moves={33},pp={35},status=8}
local st={player={mon=mon},enemy={mon=enemy},playerParty={mon},wild=true,turn=1}
local native={_phase='command',_active=true}
function native.isActive() return native._active end
function native.getState() return st end
function U.waitingForCommand() return native._phase=='command' end
function U.tick() end
function U.handleInput(input)
  calls.nativeInput=(calls.nativeInput or 0)+1
  if input:wasPressed('b') then U._mode='menu';calls.back=(calls.back or 0)+1
  elseif input:wasPressed('a') then
    if U._mode=='moves' then calls.move=U._moveIndex;U._mode='none';native._phase='execute'
    elseif U._mode=='menu' then
      calls.menu=U._menuIndex
      if U._menuIndex==1 then U._mode='moves'
      elseif U._menuIndex==2 then U._mode='bag'
      elseif U._menuIndex==3 then U._mode='party'
      else U._mode='none';native._phase='execute' end
    end
  end
  return true
end
local HP={draw=function(side) calls.hp=(calls.hp or 0)+1;if calls.hudProbe then calls.hudProbe(side) end end}
local function ailment(_,b)
  local s=b.mon.status
  return ({[8]=1,[64]=2,[1]=3,[32]=4,[16]=5,[128]=1})[s] or 0
end
HP.shownAilment=ailment
HP.shouldShowCaughtMarker=function() return true end
local terrainImage={getDimensions=function() return 256,160 end}
local terrainEntry={image=terrainImage,bgImage=terrainImage}
local BC={drawPanel=function() calls.panel=(calls.panel or 0)+1 end,drawMenuFrames=noop,
  terrain=function() return terrainEntry end,
  drawTerrain=function() calls.terrain=(calls.terrain or 0)+1;return true end}
local nativeTerrain=BC.drawTerrain
function U.draw()
  if sceneCase then return sceneCase() end
  eq(U._mode,'none','native scene temporarily suppresses menu')
  BC.drawTerrain('grass',0,0,0)
  local anim=package.loaded['src.core.game3.battle.anim'];if anim.beginParticleFrame then anim.beginParticleFrame() end
  HP.draw('player',st.player);BC.drawPanel();calls.scene=(calls.scene or 0)+1
end
local G={mousepressed=function() calls.mouse=(calls.mouse or 0)+1 end,draw=function() if calls.gameDraw then return calls.gameDraw() end end}
local F={COLOR={NORMAL={fg={.2,.2,.2}},WHITE={fg={1,1,1}}},draw=function(text,x,y,opts)
  calls.printText=text;calls.limit=opts and opts.limitChars;calls.colors=opts and opts.colors
  return 1,2,3
end,drawGlyph=function(_,_,_,opts) calls.glyphColor=opts.colors end}
local Chrome={stdFrame=function() return 'native' end,dialogueFrame=function() return 'dialogue-native' end,
  fixedStdFrame=noop,userFrame=noop,signFrame=noop}
local PartyChrome={drawBg=noop,drawSlot=noop,drawCancelButton=noop,drawConfirmButton=noop,textColors=noop}
local PcChrome={drawBackground=noop,drawInterfaceFrame=noop,textColors=function() return 1,2,3 end}
local fakeMenu={draw=function() Chrome.stdFrame(1,1,8,4);F.draw('text',0,0);return 'native menu data' end}
local OptionMenu={draw=noop}
OptionMenu.show=function() OptionMenu._pages={{title='OPTIONS',rows={},index=1,scroll=0}} end
local SummaryChrome={drawMoveSelectionCursor=noop,drawBg3=noop,drawLayer=noop}
local gc={speciesName=function(sp) return ({[25]='PIKACHU',[29]='NIDORAN_F',[252]='TREECKO'})[sp] or tostring(sp) end}
package.loaded['src.mods.Gen3Compat']=gc
package.loaded['src.mods.Semver']=dofile('tests/fixtures/Semver-0.3.93.lua')
package.loaded['src.core.Version']={engine='0.3.93'}
package.loaded['src.core.game3.battle']=native
package.loaded['src.core.game3.battle.ui']=U
package.loaded['src.core.game3.battle.healthbox']=HP
package.loaded['src.ui.game3.battle_chrome']=BC
package.loaded['src.ui.game3.message']=M
package.loaded['src.core.Game3']=G
package.loaded['src.ui.game3.chrome']=Chrome
package.loaded['src.ui.game3.frlg_font']=F
package.loaded['src.ui.game3.party_chrome']=PartyChrome
package.loaded['src.ui.game3.pc_chrome']=PcChrome
package.loaded['src.ui.game3.start_menu']=fakeMenu
package.loaded['src.ui.game3.option_menu']=OptionMenu
package.loaded['src.ui.game3.summary_chrome']=SummaryChrome
package.loaded['src.core.game3.rom_text']={plain=function(key) return key end}
package.loaded['src.ui.game3.stack']={busy=function() return calls.covered==true end}
package.loaded['src.core.game3.runtime']={getSession=function() return {bag={}} end}
package.loaded['src.core.game3.pokemon']={name=function(sp) return tostring(sp) end,gender=function() return 'U' end}
package.loaded['src.core.game3.bag']={listPocket=function() return {} end}
package.loaded['src.core.game3.battle.moves']={get=function(id) return {pp=20,type=id==85 and 13 or 0} end,displayName=function(id) return ({[85]='Thunderbolt',[98]='Quick Attack',[45]='Growl',[86]='Thunder Wave'})[id] end}
local stage={healthbox={player={},enemy={}}}
package.loaded['src.core.game3.battle.anim']={beginParticleFrame=function() calls.particleFrame=(calls.particleFrame or 0)+1 end,shownBattler=function(_,b) return b end,
  displayHpRatio=function(_,b) return .5,b.mon.hp-1,b.mon.maxHp end,
  present=function() return {} end,displayExpRatio=function() return .35,20 end,stage=function() return stage end}
package.loaded['src.battle.game3.BattleAPI']=dofile('tests/fixtures/BattleAPI-0.3.91.lua')
local originalUiDraw,originalInput,originalMouse=U.draw,U.handleInput,G.mousepressed
local function read(path)
  local file=io.open('floating_glass_frlg/'..path,'r')
  assert(file,'Source must be owned by the independent mod: '..path)
  local text=file:read('*a');file:close();return text
end
local mod={id='floating_glass_frlg',exports={},log={warn=noop,info=function(_,fmt,version,game) calls.started=version..':'..game end},options={
  define=function(_,specs) for _,s in ipairs(specs) do optionValues[s.key]=s.default end end,
  get=function(_,key) return optionValues[key] end},events={on=function(_,name,fn) eventHandlers[name]=fn end},
  hooks={wrap=function(_,name,fn) hooks[name]=fn end},read=function(_,path) return read(path) end,
  assets={path=function(_,path) return path end,image=function() error('not available') end}}
package.loaded['src.mods.SafePath']=dofile('tests/fixtures/SafePath-0.3.91.lua')
package.loaded['src.mods.Runtime']=dofile('tests/fixtures/Runtime-0.3.91.lua')
local Sandbox=dofile('tests/fixtures/Sandbox-0.3.91.lua')
local bare=Sandbox.envFor({modId=mod.id,permissions={engine_internals=true}})
eq(bare.package,nil,'bare 0.3.91 sandbox does not expose package')
package.loaded['src.core.Logger']={warn=noop,info=noop,error=noop}
local Compat=dofile('tests/fixtures/LegacyCompat-0.3.91.lua')
local compat=Compat.new({modId=mod.id,modPath='floating_glass_frlg',fs={},game=function() return {} end})
local env=Sandbox.envFor({modId=mod.id,permissions={engine_internals=true},compat=compat})
check(type(env.package.loaded)=='table','actual Loader compat provides an isolated package.loaded')
eq(next(env.package.loaded),nil,'compat loaded table contains no engine modules')
package.loaded['src.core.Version'].engine='0.3.93'
GV.set(testGame)
-- The real Loader rolls back subscriptions after entry failure. Reset the
-- simulated host journal before initializing the corrected entry.
hooks={};eventHandlers={};optionValues={}
local entry=assert(Sandbox.compile(read('main.lua'),'@floating_glass_frlg/main.lua',env))()
local R=entry(mod)
check(R and R.version=='1.2.0-beta.1','corrected main and all child chunks initialize inside native sandbox')
for _,name in ipairs({'journal','journal_draw','journal_views','menus','options','surface'}) do
 local f=io.open('floating_glass_frlg/gen3/'..name..'.lua','r');if f then f:close() end
 check(f==nil,'inactive KRS menu module physically absent: '..name)
end
eq(calls.started,'1.2.0-beta.1:'..testGame,'successful initialization logs actual version and game')
local managerFile=assert(io.open('tests/fixtures/ManagerState-0.3.91.lua'));local managerSource=managerFile:read('*a');managerFile:close()
local managerEnv=setmetatable({require=function(name) return package.loaded[name] or {} end},{__index=_G})
package.loaded['src.mods.ManagerState']=assert(Sandbox.compile(managerSource,'@native-ManagerState',managerEnv))()
local game={save={options={}},mods={modOptions={[mod.id]=optionValues},events={emit=function(_,name,e)
  calls.savedOption=e.key;calls.optionEvent=name
end}},writeOptions=function() calls.optionWrites=(calls.optionWrites or 0)+1 end}
check(mod.options.set==nil,'real public options contract has no invented set method')
eventHandlers['game.ready']({game=game})
eq(optionValues.gen3_battle_camera,'native','new profiles default to native camera')
check(R.camera.native(),'native camera is the default mode')
optionValues.gen3_battle_camera='current' -- explicit Original regression scenarios
check(R.battle.owns(),'ordinary single battle supported')
check(R.battle.decision(),'native command phase available')
local snap=R.battle.snapshot(game)
eq(snap.moves[1].type,'ELECTRIC','numeric type resolved')
eq(snap.enemy.name,'Nidoran♀','fixed Nidoran gender')
eq(snap.enemy.hp,40,'animated HP, not final HP')
eq(snap.player.expFraction,.35,'animated experience')
eq(snap.enemy.status,'PSN','poison status')
check(snap.enemy.caught,'owned Pokédex indicator')
eq(enemy.hp,41,'presentation never mutates HP')
for value,expected in pairs({[64]='PAR',[1]='SLP',[32]='FRZ',[16]='BRN',[128]='PSN',[0]='NONE'}) do
  enemy.status=value;local now=R.battle.snapshot(game)
  eq(now.enemy.status or 'NONE',expected,'native ailment '..value)
  if value==128 then check(now.enemy.statusToxic,'toxic distinguished') end
end
stage.healthbox.enemy.visible=false
eq(R.battle.snapshot(game).enemy,nil,'intro visibility follows native healthbox')
stage.healthbox.enemy.visible=true
for _,field in ipairs({'double','safari','link','oldManTutorial'}) do
  st[field]=true;check(not R.battle.owns(),'native fallback '..field);st[field]=nil
end
calls.covered=true;check(not R.battle.owns(),'modal blocks overlay');calls.covered=false
U._caughtDexScene={};check(not R.battle.owns(),'registration blocks overlay');U._caughtDexScene=nil
U._mode='target';check(not R.battle.owns(),'target selection stays native');U._mode='menu'
R.scenery.current=1
local transformStart=#drawCalls
U.draw();eq(U._mode,'menu','drawing restores mode');eq(calls.hp,nil,'native HUD suppressed only inside scene')
HP.draw();eq(calls.hp,1,'normal HUD still callable outside scene')
local dropped,restored=false,false
for i=transformStart+1,#drawCalls do
 local c=drawCalls[i]
 if c[1]=='translate' and c[2]==0 and c[3]==8 then dropped=true end
 if c[1]=='translate' and c[2]==0 and c[3]==-8 then restored=true end
end
check(dropped and not R.battle.sceneTransform,'native battler/particle stage drops eight pixels and closes its transform scope')
R.scenery.current=nil
eq(#stateStack,0,'balanced graphics scopes')
local beforeHud=calls.hp
R.battle.draw(game,{width=1280,height=720})
eq(calls.hp,beforeHud+1,'native healthbox drawing is replayed in final overlay')
local smallHud=false
for _,c in ipairs(drawCalls) do if c[1]=='scale' and math.abs(c[2]-2.34)<.0001 and math.abs(c[3]-2.34)<.0001 then smallHud=true end end
check(smallHud,'Original HUD is twenty percent smaller than prior 65 percent scale')
local function reset()
  U._mode='menu';native._phase='command';M.open=false;st.turn=st.turn+1
end
check(R.battle.confirm(4),'move selected through native API')
eq(calls.move,4,'requested move slot is not reset')
reset();eq(R.battle.record().focus,4,'last move remembered between turns')
optionValues.gen3_remember_move=false;reset();eq(R.battle.record().focus,1,'remember off resets first slot')
optionValues.gen3_remember_move=true
reset();check(R.battle.confirm(5),'bag submitted');eq(calls.menu,2,'Gen3 bag maps to native index 2')
reset();check(R.battle.confirm(6),'party submitted');eq(calls.menu,3,'Gen3 party maps to native index 3')
reset();check(R.battle.confirm(7),'run submitted');eq(calls.menu,4,'run maps to index 4')
reset();U._mode='moves';check(R.battle.confirm(5),'bag from move menu');check(calls.back>0,'native cancel before bag')
reset();mon.pp[2]=0;local ok=R.battle.confirm(2);check(not ok,'zero PP rejected by actual BattleAPI');mon.pp[2]=20
reset();local input={wasPressed=function(_,key) return key=='right' end};U.handleInput(input)
check(R.battle.record().focus~=1,'semantic keyboard/controller direction used')
native._phase='execute';U._mode='none'
local before=calls.advance or 0
R.battle.draw(game,{width=1280,height=720})
check(not R.battle.pointer(game,100,600,1),'move-region click ignored during animation')
eq(calls.advance or 0,before,'animation click never advances text')
M.open=true;M._waiting=false;M._revealed=3
R.battle.draw(game,{width=1280,height=720})
eq(calls.limit,3,'native typewriter character limit preserved')
check(not R.battle.pointer(game,R.battle.messageRect.x+20,R.battle.messageRect.y+20,1),'typing message does not become advance')
M._waiting=true
check(R.battle.pointer(game,R.battle.messageRect.x+20,R.battle.messageRect.y+20,1),'finished message accepts click')
reset()
check(not R.battle.pointer(game,100,600,1),'stale dialogue click cannot confirm a move')
eq(fakeMenu.draw(),'native menu data','menu data path remains native')
eq(R.depth,0,'menu scope restored')
eq(calls.colors,nil,'outside-menu text retains native colors')
local a,b,c
R.scope(function() a,b,c=PcChrome.textColors() end)
check(a and b and c,'all three native PC color return values preserved')
optionValues.gen3_theme='native'
eq(Chrome.stdFrame(),'native','native theme restores original frame')
fakeMenu.draw();eq(calls.colors,nil,'native font options preserved')
check(not R.battle.owns(),'original theme disables overlay suppression')
optionValues.gen3_theme='floating_glass'
local spriteHook=hooks['pokemon.sprite'];local forwarded=0
local function nextSprite(path) forwarded=forwarded+1;return path end
eq(spriteHook(nextSprite,'native',{species='PIKACHU'}),'native','default sprite source delegates')
optionValues.gen3_sprite_source='krs'
local art=spriteHook(nextSprite,'native',{species='PIKACHU',side='front'})
check(art:find('gen3/assets/pokemon/front/5/normal/pikachu.png',1,true)~=nil,'KRS frame path')
eq(spriteHook(nextSprite,'native',{species='TREECKO'}),'native','missing KRS species keeps native art')
eq(spriteHook(nextSprite,'native',{species='UNOWN',letter=2}),'native','Unown letters preserved')
eq(spriteHook(nextSprite,'native',{species='SPINDA'}),'native','Spinda personality spots preserved')
eq(spriteHook(nextSprite,'native',{species='PIKACHU',form=2}),'native','mod form preserved')
-- Production bootstrap leaves all non-battle UI modules uninstalled.
check(R.outsideBattleUI==false,'battle-only scope is explicit')
for _,name in ipairs({'journal','options','menus','surface'}) do eq(R[name],nil,'outside renderer not loaded: '..name) end
OptionMenu.show();eq(#OptionMenu._pages,1,'native Options pages unchanged');eq(#OptionMenu._pages[1].rows,0,'no custom option-page injection')
local stackFixture=package.loaded['src.ui.game3.stack']
stackFixture.top=function() return {mod=fakeMenu,id='start',isMenu=true} end
local beforeMenu=fakeMenu.draw;local beforeParty=PartyChrome.drawCancelButton;local beforeSummary=SummaryChrome.drawMoveSelectionCursor
local beforeColor=PcChrome.textColors
native._active=false
local writesBefore=calls.optionWrites or 0
hooks['render.hud'](noop,game,{width=1280,height=720})
eq(fakeMenu.draw,beforeMenu,'Start drawing untouched');eq(PartyChrome.drawCancelButton,beforeParty,'party drawing untouched')
eq(SummaryChrome.drawMoveSelectionCursor,beforeSummary,'summary drawing untouched');eq(PcChrome.textColors,beforeColor,'PC colors untouched')
eq(fakeMenu.draw(),'native menu data','native menu remains callable outside battle')
eq(calls.optionWrites or 0,writesBefore,'outside HUD writes no options')
eq(#stateStack,0,'outside HUD restores graphics state')
native._active=true;stackFixture.top=nil
-- Battle settings still use the native persistence path.
check(R.setOption('battle_opacity',.55),'battle setting writes through native manager')
eq(calls.savedOption,'gen3_battle_opacity','battle setting preserves native option key')
check(calls.optionWrites>0,'native options writer still available for battle')
R.setOption('battle_opacity',.70)
-- New layouts use native submissions and keep configuration modal.
local function key(k) U.handleInput({wasPressed=function(_,button) return button==k end}) end
optionValues.gen3_remember_move=false;reset()
R.battle.draw(game,{width=1280,height=720})
eq(R.battle.layout.style,'layers','new default uses layered concept')
local startLayout=R.battle.layout
key('select');check(R.battle.settingsOpen,'SELECT opens battle presentation settings')
R.battle.draw(game,{width=1280,height=720})
local oldMove=calls.move;local oldMenu=calls.menu
local covered=startLayout.rects[#startLayout.rects]
check(R.battle.pointer(game,covered.x+10,covered.y+10,1),'modal swallows underlying action click')
eq(calls.menu,oldMenu,'settings click cannot run or consume an item')
key('right');eq(optionValues.gen3_battle_layout,'list','layout persists through native mod option writer')
R.battle.draw(game,{width=1280,height=720})
eq(R.battle.layout.style,'list','settings change used by actual renderer')
key('down');key('right');eq(optionValues.gen3_battle_opacity,.55,'opacity setting persists')
key('down');key('right');eq(optionValues.gen3_battle_scale,.58,'UI size setting persists')
key('down');key('right');eq(optionValues.gen3_battle_position,'right','position setting persists')
key('a');check(not R.battle.settingsOpen,'A closes settings without choosing a move')
eq(calls.move,oldMove,'closing settings never submits attack')
eq(calls.menu,oldMenu,'closing settings never submits menu command')
R.battle.draw(game,{width=1280,height=720})
check(R.battle.pointer(game,R.battle.layout.settings.x+8,R.battle.layout.settings.y+8,1),'settings button opens modal')
check(R.battle.settingsOpen,'mouse settings owns input')
key('b');check(not R.battle.settingsOpen,'B closes settings')
-- Click a different move once to reveal it, then click selected to submit.
optionValues.gen3_battle_layout='layers';reset();R.battle.draw(game,{width=1280,height=720})
local exposed
for _,r in ipairs(R.battle.layout.rects) do if r.kind=='move' and r.depth==3 then exposed=r end end
check(exposed~=nil,'layered renderer returns real back-card targets')
local chosen=exposed.index;oldMove=calls.move
check(R.battle.pointer(game,exposed.x+exposed.w/2,exposed.y+2,1),'exposed card can be selected')
eq(R.battle.record().focus,chosen,'exposed card updates actual native slot focus')
eq(calls.move,oldMove,'first back-card click only selects')
R.battle.draw(game,{width=1280,height=720})
local front
for _,r in ipairs(R.battle.layout.rects) do if r.kind=='move' and r.index==chosen then front=r end end
check(R.battle.pointer(game,front.x+front.w/2,front.y+front.h-2,1),'selected card click uses native submit')
eq(calls.move,chosen,'native API receives original selected slot')
reset();R.battle.draw(game,{width=1280,height=720})
local stale=R.battle.layout.settings
optionValues.gen3_battle_layout='list'
check(not R.battle.pointer(game,stale.x+8,stale.y+8,1),'old geometry cannot act after option change')
-- HUD coordinates follow the window independently from the native game rectangle.
reset();R.battle.draw(game,{width=1280,height=800,gameX=160,gameY=80,gameWidth=960,gameHeight=640})
eq(R.battle.frame.x,0,'HUD starts at window edge')
eq(R.battle.layout.width,1280,'HUD uses full live window width')
local gear=R.battle.layout.settings
check(R.battle.pointer(game,gear.x+10,gear.y+10,1),'window pointer matches responsive HUD')
check(R.battle.settingsOpen,'window click reaches settings')
local previousDimensions=graphics.getDimensions
graphics.getDimensions=function() return 1400,800 end
check(not R.battle.pointer(game,gear.x+10,gear.y+10,1),'resize invalidates stale click geometry')
graphics.getDimensions=previousDimensions
key('b');reset()
-- Terrain extension runs once in the background stage and never in HUD draw.
local function drawnImages()
 local n=0;for _,c in ipairs(drawCalls) do if c[1]=='draw' and c[2]==terrainImage then n=n+1 end end;return n
end
local beforeImages=drawnImages();local beforeTerrain=calls.terrain or 0
U.draw()
eq(calls.terrain,beforeTerrain+1,'native terrain draw still executes once')
eq(drawnImages()-beforeImages,6,'wallpaper extends only under former native panel')
beforeImages=drawnImages();BC.drawTerrain('grass',0,0,0)
eq(drawnImages(),beforeImages,'outside native scene extension delegates unchanged')
optionValues.gen3_battle_extend=false;U.draw()
eq(drawnImages(),beforeImages,'terrain extension can be disabled for scenery mods')
optionValues.gen3_battle_extend=true;terrainEntry.bgImage=nil;U.draw()
eq(drawnImages(),beforeImages,'missing wallpaper retains native scene')
terrainEntry.bgImage=terrainImage
R.battle.draw(game,{width=1280,height=720})
eq(drawnImages(),beforeImages,'HUD pass never covers Pokémon with terrain')
eq(#stateStack,0,'settings and terrain restore graphics state')
-- Production scene bridge with affine graphics state. No GPU or native timeline replay.
do
 local saved={};for _,k in ipairs({'push','pop','translate','scale','origin','transformPoint','setShader','getShader'}) do saved[k]=graphics[k] end
 local matrix={sx=1,sy=1,x=0,y=0};local matrices={};local shader='native-start'
 graphics.push=function(mode)
  matrices[#matrices+1]={sx=matrix.sx,sy=matrix.sy,x=matrix.x,y=matrix.y,all=mode=='all',shader=shader}
  stateStack[#stateStack+1]=true
 end
 graphics.pop=function()
  local prev=assert(table.remove(matrices),'affine stack underflow');assert(table.remove(stateStack))
  matrix={sx=prev.sx,sy=prev.sy,x=prev.x,y=prev.y};if prev.all then shader=prev.shader end
 end
 graphics.translate=function(x,y) matrix.x=matrix.x+matrix.sx*x;matrix.y=matrix.y+matrix.sy*y end
 graphics.scale=function(x,y) matrix.sx=matrix.sx*x;matrix.sy=matrix.sy*(y or x) end
 graphics.origin=function() matrix={sx=1,sy=1,x=0,y=0} end
 graphics.transformPoint=function(x,y) return matrix.x+matrix.sx*x,matrix.y+matrix.sy*y end
 graphics.setShader=function(s) shader=s end;graphics.getShader=function() return shader end
 local function near(a,b,message) check(math.abs(a-b)<.000001,message..': '..tostring(a)..' ~= '..tostring(b)) end
 local Anim=package.loaded['src.core.game3.battle.anim'];local A=R.battle.anchors
 local pimg={getDimensions=function() return 64,64 end};local eimg={getDimensions=function() return 64,64 end}
 A.register({image=pimg},'player');A.register({image=eimg},'enemy')
 local oldScenery={selected=R.scenery.selected,replaced=R.scenery.replaced,current=R.scenery.current}
 local oldDrop=optionValues.gen3_battle_drop
 local actionsBefore={move=calls.move,menu=calls.menu,back=calls.back,hp=mon.hp,enemyHp=enemy.hp}
 local cases=0;local captured
 local function runScene(selected,finish,drop,special,repeatBegin,failFirst)
  reset();R.battle.failed=false;R.scenery.selected=selected;R.scenery.replaced=selected~=nil;R.scenery.current=nil
  optionValues.gen3_battle_drop=drop or 8;st.double=special=='double';st.safari=special=='safari'
  local attempts=0
  sceneCase=function()
   attempts=attempts+1;Anim.beginParticleFrame();if repeatBegin then Anim.beginParticleFrame() end
   graphics.draw(eimg,176,40,0,1,1,32,32);graphics.draw(pimg,72,80,0,1,1,32,32)
   local ex,ey=graphics.transformPoint(176,40);local px,py=graphics.transformPoint(72,80)
   local fx,fy=graphics.transformPoint(180,44);local bx,by=graphics.transformPoint(72,75)
   captured={ex=ex,ey=ey,px=px,py=py,fx=fx,fy=fy,bx=bx,by=by,sx=matrix.sx,sy=matrix.sy}
   if failFirst and attempts==1 then error('intentional scene fixture failure') end
   graphics.setShader(nil) -- native animation cleared its own shader
   if finish=='hp' then HP.draw('enemy',st.enemy);HP.draw('player',st.player)
   elseif finish=='panel' then BC.drawPanel()
   elseif finish=='overlay' then U.drawOverlay() end
   if finish then
    near(matrix.x,0,'native HUD/UI restores x');near(matrix.y,0,'native HUD/UI restores y')
    near(matrix.sx,1,'native HUD/UI restores scale');check(shader==nil,'inner pop does not revive native shader')
   end
  end
  U.draw();sceneCase=nil;cases=cases+1
  near(matrix.x,0,'frame restores x');near(matrix.y,0,'frame restores y');near(matrix.sx,1,'frame restores horizontal scale')
  near(matrix.sy,1,'frame restores vertical scale');eq(#matrices,0,'all scene transforms balanced');eq(#stateStack,0,'outer graphics state balanced')
  check(not R.battle.sceneTransform,'scene-transform marker cleared');eq(U._mode,'menu','native menu mode restored')
  st.double=false;st.safari=false
  return attempts
 end
 runScene('forest','hp',8)
 near(captured.ex,24+.8*176,'enemy shares scene translation');near(captured.ey,32+.8*(40+8),'enemy scene height')
 near(captured.px,24+.8*72,'ally shares scene translation');near(captured.py,32+.8*(80+8),'ally scene height')
 near(captured.fx-captured.ex,.8*4,'particle x remains aligned');near(captured.fy-captured.ey,.8*4,'particle y remains aligned')
 near(captured.by-captured.py,.8*(-5),'ball remains aligned with ally');near(captured.sx,captured.sy,'sprites keep proportions')
 near(A.fixed.player.b,32+.8*(80+32+8),'HUD anchor captures complete scene transform')
 local forestSignature=A.signature;runScene('cave','hp',8)
 near(captured.ex,176,'nonforest keeps native x');near(captured.ey,48,'nonforest keeps prior drop')
 check(A.signature~=forestSignature,'changing forest transform refreshes anchor signature')
 near(A.fixed.player.b,120,'anchor refreshes outside forest')
 runScene(nil,'hp',8);near(captured.ey,40,'native background has no custom shift')
 runScene('forest','panel',8);runScene('forest','overlay',8)
 runScene('forest',nil,8) -- status_hud_visible=false and no panel/overlay: final cleanup
 runScene('forest',nil,0,false,true);near(captured.ey,64,'zero-drop repeated begin applies transform once')
 runScene('forest',nil,8,'double');near(captured.ey,40,'double battle keeps native scene')
 runScene('forest',nil,8,'safari');near(captured.ey,40,'Safari keeps native scene')
 eq(runScene('forest',nil,8,false,false,true),2,'failed pass delegates once to native fallback')
 near(captured.ey,40,'fallback draws in original transform');check(R.battle.failed,'failed overlay stays disabled')
 eq(calls.move,actionsBefore.move,'scene composition never submits move');eq(calls.menu,actionsBefore.menu,'scene composition never submits menu action')
 eq(calls.back,actionsBefore.back,'scene composition never cancels action');eq(mon.hp,actionsBefore.hp,'ally HP unchanged');eq(enemy.hp,actionsBefore.enemyHp,'enemy HP unchanged')
 R.battle.failed=false;R.scenery.selected=oldScenery.selected;R.scenery.replaced=oldScenery.replaced;R.scenery.current=oldScenery.current
 optionValues.gen3_battle_drop=oldDrop
 for k,v in pairs(saved) do graphics[k]=v end
 -- Optional methods absent in the original host must not remain installed.
 if saved.setShader==nil then graphics.setShader=nil end;if saved.getShader==nil then graphics.getShader=nil end
end
-- Native double render order and healthbox signatures from the audited 0.3.93 UI.
do
 local Recorder=dofile('tests/svg_recorder.lua');local rec=Recorder.new(1280,720);local savedGraphics=love.graphics
 nativePics.player=Recorder.image('floating_glass_frlg/gen3/assets/pokemon/back/3/normal/bulbasaur.png')
 nativePics.enemy=Recorder.image('floating_glass_frlg/gen3/assets/pokemon/front/5/normal/rattata.png')
 love.graphics=rec.graphics;local g=rec.graphics;local setFont=g.setFont;g.setFont=function(f) return setFont(f.size and f or g.newFont(18)) end;local A=R.battle.anchors;local Anim=package.loaded['src.core.game3.battle.anim']
 reset();st.double=true;st.battlers={[2]={mon=mon},[3]={mon=enemy}};R.battle.failed=false
 local oldCam=optionValues.gen3_battle_camera;local oldShadows=optionValues.gen3_shadows
 optionValues.gen3_battle_camera='native_depth';optionValues.gen3_shadows='auto';R.scenery.selected='forest';R.scenery.replaced=true
 local beforeHp=calls.hp or 0;local beforeMove=calls.move;local beforeMenu=calls.menu
 sceneCase=function()
  eq(U._mode,'menu','double native command mode is never replaced')
  Anim.beginParticleFrame()
  for _,id in ipairs({3,1,0,2}) do
   if not (st.absent and st.absent[id]) then
    Anim.present(id);local pic=U.sidePic(id%2==0)
    local points={[0]={32,80},[1]={200,40},[2]={90,88},[3]={152,32}}
    g.draw(pic.image,points[id][1],points[id][2],0,1,1,32,32)
   end
  end
  for id=3,0,-1 do if not (st.absent and st.absent[id]) then HP.draw(id,id%2==0 and st.player or st.enemy,{st=st,oy=0}) end end
  BC.drawPanel()
 end
 U.draw();eq(calls.hp or 0,beforeHp,'new camera defers native double HUD without extra draws')
 eq(#R.battle.healthboxes,4,'all four native healthbox calls captured')
 for id=0,3 do check(A.fixed[id]~=nil,'four separate sprite identities captured '..id) end
 check(A.fixed[0].l~=A.fixed[2].l and A.fixed[1].l~=A.fixed[3].l,'same texture in two slots keeps independent anchors')
 R.battle.draw(game,{width=1280,height=720});eq(calls.hp,beforeHp+4,'native HUD replayed exactly once per battler')
 eq(calls.move,beforeMove,'double projection submits no move');eq(calls.menu,beforeMenu,'double projection submits no menu action')
 check(not R.battle.scene and not R.battle.visualScene and not R.battle.sceneTransform,'double render scopes restored')
 eq(#rec.stack,0,'double HUD balances graphics state')
 key('select');check(R.battle.settingsOpen,'SELECT opens presentation settings in doubles')
 R.battle.draw(game,{width=1280,height=720});check(R.battle.settingsTargets~=nil,'double settings modal rendered')
 check(R.battle.pointer(game,5,5,1),'modal consumes clicks before native commands')
 key('b');check(not R.battle.settingsOpen,'double settings close with native B semantics withheld from action')
 eq(calls.menu,beforeMenu,'opening settings never issues battle command')
 st.absent={[3]=true};U.draw();eq(#R.battle.healthboxes,3,'absent battler never receives invented HUD')
 st.absent=nil;optionValues.gen3_battle_camera='current';beforeHp=calls.hp or 0;U.draw();eq(calls.hp,beforeHp+4,'current double camera preserves native HUD path')
 eq(#R.battle.healthboxes,0,'current double camera does not duplicate HUD in overlay')
 U._mode='target';local beforeNativeInput=calls.nativeInput or 0;key('left');eq(calls.nativeInput,beforeNativeInput+1,'double target navigation delegates to native handler')
 sceneCase=nil;st.double=false;st.battlers=nil;U._mode='menu';optionValues.gen3_battle_camera=oldCam;optionValues.gen3_shadows=oldShadows
 R.battle.settingsOpen=false;R.scenery.replaced=false;R.scenery.selected=nil;love.graphics=savedGraphics
end
-- Single foreground camera: observe the actual wrapped native UI pass,
-- not only the camera's arithmetic. Regress alpha.15's scene zoom/left crop.
do
 local Recorder=dofile('tests/svg_recorder.lua');local rec=Recorder.new(1920,1080)
 local previousGraphics=love.graphics;love.graphics=rec.graphics;local g=rec.graphics
 g.getDimensions=function() return 1920,1080 end
 local Anim=package.loaded['src.core.game3.battle.anim'];local A=R.battle.anchors
 reset();R.battle.failed=false
 local oldCam=optionValues.gen3_battle_camera
 optionValues.gen3_battle_camera='native_depth';R.scenery.selected='forest';R.scenery.replaced=true
 nativePics.player=Recorder.image('floating_glass_frlg/gen3/assets/pokemon/back/3/normal/bulbasaur.png')
 nativePics.enemy=Recorder.image('floating_glass_frlg/gen3/assets/pokemon/front/5/normal/rattata.png')
 A.pixels[nativePics.player]={10,16,55,48};A.pixels[nativePics.enemy]={10,10,46,53}
 local beforeMove,beforeMenu=calls.move,calls.menu
 sceneCase=function()
  Anim.beginParticleFrame()
  Anim.present('enemy');local pic=U.sidePic(false);g.draw(pic.image,176,40,0,1,1,32,32)
  Anim.present('player');pic=U.sidePic(true);g.draw(pic.image,72,80,0,1,1,32,32)
  HP.draw('enemy',st.enemy);HP.draw('player',st.player)
 end
 U.draw()
 local function near(a,b,message) check(math.abs(a-b)<.000001,message) end
 local base=A.fixed.player;local width=base.r-base.l
 local rendered=A.project('player',{x=0,y=0,w=1920,h=1080})
 near(rendered.b,1081,'native UI pass anchors ally one window pixel below bottom')
 near((rendered.l+rendered.r)/2,1920*.35,'native UI pass centers foreground ally at 35 percent')
 near(rendered.r-rendered.l,width*1920/240,'native UI pass retains ally scale')
 near(A.cameraPlan.k,1.05,'native UI pass does not zoom whole scene')
 local foe=A.project('enemy',{x=0,y=0,w=1920,h=1080})
 near(foe.r-foe.l,36*1.05*1920/240,'native UI pass retains enemy scale')
 local foeX,foeY=foe.l,foe.b
 U.draw();rendered=A.project('player',{x=0,y=0,w=1920,h=1080})
 near(rendered.b,1081,'repeated native UI pass remains stable')
 foe=A.project('enemy',{x=0,y=0,w=1920,h=1080})
 near(foe.l,foeX,'enemy x unaffected by ally anchoring');near(foe.b,foeY,'enemy y unaffected by ally anchoring')
 eq(calls.move,beforeMove,'foreground correction issues no move');eq(calls.menu,beforeMenu,'foreground correction issues no menu action')
 eq(#rec.stack,0,'foreground correction restores native render stack')
 check(not R.battle.failed,'foreground pass does not trigger native fallback')
 sceneCase=nil;optionValues.gen3_battle_camera=oldCam;R.scenery.selected=nil;R.scenery.replaced=false;love.graphics=previousGraphics
end
-- Camera ownership is scoped through the real bootstrap's Game3.draw wrapper.
do
 local oldCamera=optionValues.gen3_battle_camera;local oldFind=mod.find
 local fit=true;local switches=0
 local hd={tagOf=function() end,enabled=function() return true end,fitEnabled=function() return fit end,setFit=function(value) fit=value;switches=switches+1 end}
 mod.find=function(_,id) if id=='gen3-hd-sprites' then return {exports=hd} end end
 optionValues.gen3_battle_camera='g9_compat'
 calls.gameDraw=function() check(not fit,'HD automatic refit suspended during compatibility Game3 pass');error('intentional Game3 draw failure') end
 local ok=pcall(G.draw,game)
 check(not ok and fit,'Game3 failure restores HD refit before propagating error')
 eq(switches,2,'HD refit disabled and restored exactly once')
 optionValues.gen3_battle_camera='current';calls.gameDraw=function() check(fit,'Original does not take over HD camera') end
 G.draw(game);eq(switches,2,'Original does not write HD refit state')
 calls.gameDraw=nil;mod.find=oldFind;optionValues.gen3_battle_camera=oldCamera
end
-- Native healthbox replay, not parallel HP content: Original and G9 are 20%
-- smaller and exactly five window pixels above the reduced-size placement.
do
 local Recorder=dofile('tests/svg_recorder.lua');local rec=Recorder.new(1280,720)
 local previousGraphics=love.graphics;love.graphics=rec.graphics;local g=rec.graphics
 local A=R.battle.anchors;local oldProject,oldPlace=A.project,A.place
 local oldCamera=optionValues.gen3_battle_camera;local oldBoxes=R.battle.healthboxes
 A.project=function() return {l=100,t=100,r=200,b=400} end
 A.place=function(_,_,_,height)
  check(math.abs(height-37*2.925)<.00001,'HUD rise measured from prior top edge, not lowered by shrink')
  return 200,300
 end
 local observed
 calls.hudProbe=function()
  local x,y=g.transformPoint(126,72);local x1,y1=g.transformPoint(127,73);observed={x=x,y=y,sx=x1-x,sy=y1-y}
 end
 for _,camera in ipairs({'current','g9_compat'}) do
  optionValues.gen3_battle_camera=camera
  R.battle.healthboxes={{draw=HP.draw,args={'player',st.player}}}
  R.battle.drawHealthboxes({x=0,y=0,w=1280,h=720})
  check(math.abs(observed.sx-2.925*.8)<.00001,'native HUD width shrinks twenty percent: '..camera)
  check(math.abs(observed.sy-2.925*.8)<.00001,'native HUD height shrinks twenty percent: '..camera)
  check(math.abs(observed.y-295)<.00001,'native HUD is raised five window pixels: '..camera)
  check(math.abs(observed.x-200)<.00001,'native HUD placement x retained: '..camera)
 end
 check(#rec.stack==0 and not R.battle.hudDrawing,'HUD replay restores render scopes')
 calls.hudProbe=nil;A.project,A.place=oldProject,oldPlace;R.battle.healthboxes=oldBoxes;optionValues.gen3_battle_camera=oldCamera;love.graphics=previousGraphics
end
GV.set('gold')
check(not R.battle.owns(),'runtime version switch disables the overlay')
eq(spriteHook(nextSprite,'native',{species='PIKACHU'}),'native','global sprite hook delegates after switching to Gen2')
eq(Chrome.stdFrame(),'native','wrapped native method delegates outside FRLG')
GV.set(testGame)
mod.exports.gen3.shutdown()
eq(U.draw,originalUiDraw,'unload restores native scene')
eq(BC.drawTerrain,nativeTerrain,'unload restores native terrain')
eq(U.handleInput,originalInput,'unload restores native input')
eq(G.mousepressed,originalMouse,'unload restores native mouse')
eq(Chrome.stdFrame(),'native','unload restores frames')
eq(#stateStack,0,'graphics stack balanced after dialogue and menus')
-- Main entrypoint routes each native game independently.
local GV=dofile('tests/fixtures/GameVersion-0.3.91.lua')
package.loaded['src.core.GameVersion']=GV
for _,version in ipairs({'red','blue','yellow','gold','silver','crystal','firered','leafgreen','ruby','sapphire','emerald'}) do
  GV.set(version)
  local chosen
  local entry=assert(Sandbox.compile(read('main.lua'),'@floating_glass_frlg/main.lua',env))()
  local routed=entry({read=function(_,path) chosen=path;return 'return function() return 37 end' end})
  local supported=({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[version]==true
  eq(routed,supported and 37 or nil,'only FRLG can initialize '..version)
  eq(chosen,supported and 'gen3/bootstrap.lua' or nil,'no bootstrap reads outside FRLG '..version)
  if not supported then eq(assert(Sandbox.compile(read('gen3/bootstrap.lua'),'@direct-bootstrap',env))()({}),nil,'direct bootstrap is inert '..version) end
end
local Targets=dofile('tests/fixtures/ModTargets-0.3.91.lua')
for _,version in ipairs({'red','blue','yellow','gold','silver','crystal','firered','leafgreen','ruby','sapphire','emerald'}) do
  eq(Targets.supports({games={'firered','leafgreen','ruby','sapphire','emerald'}},version),({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[version]==true,'native loader target restriction '..version)
end
print(testGame..': '..passed..' FRLG checks passed (native BattleAPI 0.3.91; simulated engine/render/ROM host).')
