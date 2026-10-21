-- FRLG bridge. The native BattleAPI is the only command submission path.
-- Native scene rendering owns battlers, trainers, animation timing and FX.
return function(R)
  local function part(path) return R.load('modules/ui/floating_battle/'..path) end
  local Layout=part('ui/layout.lua');local Types=part('ui/types.lua')
  local Model=part('systems/model.lua');local Navigation=part('systems/navigation.lua')
  local Art=part('ui/reference_art.lua')({
    assetPath=function(path) return 'modules/ui/'..path end,
    assets={image=function(_,path) return R.mod.assets:image(path) end},
  })
  local Skin=R.load('gen3/emerald_ivory.lua')()
  local View=part('ui/view.lua')(Types,Model,Layout,part('ui/icons.lua'),Art,part('ui/status.lua'),R.theme,Skin)
  local API=require('src.battle.game3.BattleAPI')
  local Anchors=R.load('gen3/anchors.lua')(R)
  local B={anchors=Anchors,failed=false,serial=0,scene=false,registerType=Types.register}
  function B.endSceneTransform()
    if B.sceneTransform then love.graphics.pop();B.sceneTransform=false end
    B.sceneDrop=0
  end
  local backgrounds=R.load('gen3/background_catalog.lua')
  local backgroundValues={'auto'};local backgroundLabels={'Automático por jogo'}
  for _,e in ipairs(backgrounds.entries) do backgroundValues[#backgroundValues+1]=e.id;backgroundLabels[#backgroundLabels+1]=e.label end
  local translate=R.load('gen3/settings_language.lua')(R)
  local settings={
    {key='battle_layout',label='Golpes',values={'layers','list'},labels={'Cartas em camadas','Lista flutuante'}},
    {key='battle_opacity',label='Opacidade',values={.70,.55,.85},labels={'70%','55%','85%'}},
    {key='battle_scale',label='Tamanho',values={.68,.58,.78},labels={'Normal','Menor','Maior'}},
    {key='battle_position',label='Posição',values={'left','right'},labels={'Esquerda','Direita'}},
    {key='battle_aspect',label='Formato',values={'window','native','4:3','16:9'},labels={'Janela','Nativa (3:2)','4:3','16:9'}},
    {key='battle_drop',label='Pokémon mais baixos',values={8,12,16,20,0},labels={'+8 px','+12 px','+16 px','+20 px','Original'}},
    {key='camera_background',label='Fundo 21:9',values=backgroundValues,labels=backgroundLabels},
    {key='scenery',label='Cenário',values={'auto','native'},labels={'Automático','Original / mods'}},
    {key='button_palette',label='Cores dos botões',values={'pastel','metal'},labels={'Pastel neutro','Metálico'}},
    {key='lens_size',label='Tamanho da vegetação',values={.65,.8,1},labels={'Reduzido','Médio','Original'}},
    {key='lens_motion',label='Movimento da lente',values={true,false},labels={'Suave','Desligado'}},
    {key='battle_camera',label='Câmera',values={'native','current','g9_compat','native_depth'},labels={'Nativa','Original','Compatibilidade G9/HD','Primeiro plano'}},
    {key='shadows',label='Sombras',values={'auto','enemies','both'},labels={'Auto: pela câmera','Inimigos','Ambos'}},
    {key='shadow_anchor',label='Apoio da sombra',values={'feet','knees'},labels={'Pés','Joelhos'}},
    {key='battle_skin',label='Visual da interface',values={'current','emerald_ivory'},labels={'Atual','Emerald Green & Ivory'}},
    {key='settings_language',label='Idioma / Language',values={'pt-BR','en'},labels={'PT-BR','English'}},
    {key='foreground',label='Primeiro plano',values={.65,0,1},labels={'65%','Desligado','100%'}},
  }
  local function settingIndex(row)
    local value=R.option(row.key,row.values[1])
    for i,v in ipairs(row.values) do if v==value then return i end end
    return 1
  end
  local function changeSetting(index,delta)
    local row=settings[index];if not row then return end
    local i=(settingIndex(row)-1+delta)%#row.values+1
    return R.setOption(row.key,row.values[i])
  end
  local function presentation()
    return {emeraldIvory=R.option('battle_skin','current')=='emerald_ivory',translate=translate,nativeHud=true,nativePalette=true,pastel=R.option('button_palette','pastel')=='pastel',style=settings[1].values[settingIndex(settings[1])],
      opacity=settings[2].values[settingIndex(settings[2])],
      scale=settings[3].values[settingIndex(settings[3])],position=settings[4].values[settingIndex(settings[4])]}
  end
  local records=setmetatable({},{__mode='k'})
  local apis=setmetatable({},{__mode='k'})
  local seen=setmetatable({},{__mode='k'})
  local allowed={none=true,menu=true,moves=true,selmsg=true}
  local typeNames={[0]='NORMAL',[1]='FIGHTING',[2]='FLYING',[3]='POISON',[4]='GROUND',
    [5]='ROCK',[6]='BUG',[7]='GHOST',[8]='STEEL',[9]='MYSTERY',[10]='FIRE',
    [11]='WATER',[12]='GRASS',[13]='ELECTRIC',[14]='PSYCHIC',[15]='ICE',[16]='DRAGON',[17]='DARK'}
  local function modules()
    return R.module('src.core.game3.battle.init') or R.module('src.core.game3.battle'),
      R.module('src.core.game3.battle.ui'),R.module('src.ui.game3.message')
  end
  function B.context()
    local native,U,M=modules()
    if not native or not U or not native.isActive or not native.isActive() then return end
    local st=native.getState and native.getState()
    if not st or not st.player or not st.enemy or not st.player.mon or not st.enemy.mon then return end
    return st,native,U,M
  end
  function B.sceneryOwns()
    return not R.unloaded and R.glass() and R.option('battle',true) and B.context()~=nil
  end
  function B.owns()
    if R.unloaded or B.failed or not R.glass() or not R.option('battle',true) then return false end
    local st,native,U=B.context()
    if not st or st.double or st.safari or st.link or st.oldManTutorial or native._auto
      or U._wally or U._caughtDexScene or not allowed[U._mode or 'none'] then return false end
    local Stack=R.module('src.ui.game3.stack')
    if Stack and Stack.busy and Stack.busy() then return false end
    local Choice=R.module('src.ui.game3.choice')
    if Choice and Choice.active then return false end
    local Fade=R.module('src.ui.game3.fade')
    if Fade and Fade.lockInput then return false end
    return true
  end
  function B.elevation(key)
    local player=key=='player' or type(key)=='number' and key%2==0
    if player then return 0 end
    local st=B.context();if not st then return 0 end
    local b=type(key)=='number' and (key==1 and st.enemy or st.battlers and st.battlers[key]) or st.enemy
    if not b or not b.mon then return 0 end
    local P=R.module('src.core.game3.pokemon');local Pic=R.module('src.core.game3.battle.pic_coords')
    local sp=b.species or (P and P.speciesOf and P.speciesOf(b.mon)) or b.mon.species or b.mon.speciesId
    local Anim=R.module('src.core.game3.battle.anim');local pr=Anim and Anim.present and Anim.present(key)
    if pr and pr.transformSpecies then sp=pr.transformSpecies end
    local ok,value=pcall(function() return Pic and Pic.elev and Pic.elev[tonumber(sp)] or 0 end)
    return ok and tonumber(value) or 0
  end
  function B.visualOwns()
    if B.owns() then return true end
    if R.unloaded or B.failed or not R.glass() or not R.option('battle',true) then return false end
    local st,native,U=B.context()
    if not st or not st.double or st.safari or st.link or st.oldManTutorial or native._auto or U._wally or U._caughtDexScene then return false end
    if not allowed[U._mode or 'none'] and U._mode~='target' then return false end
    local Stack=R.module('src.ui.game3.stack');if Stack and Stack.busy and Stack.busy() then return false end
    local Choice=R.module('src.ui.game3.choice');if Choice and Choice.active then return false end
    local Fade=R.module('src.ui.game3.fade');if Fade and Fade.lockInput then return false end
    return true
  end
  function B.decision()
    local st,native,U=B.context()
    return B.owns() and native._phase=='command' and (U._mode=='menu' or U._mode=='moves')
      and (not U.waitingForCommand or U.waitingForCommand()) and (st.player.mon.hp or 0)>0
  end
  local function api(game)
    game=game or R.game
    if not game then return end
    if not apis[game] then apis[game]=API.new(game) end
    return apis[game]
  end
  function B.record()
    local st,_,U=B.context();if not st then return end
    local rec=records[st]
    if not rec then rec={focus=1,lastMove=1,memory=setmetatable({},{__mode='k'})};records[st]=rec end
    local mon=st.player.mon
    if B.decision() and (not rec.decision or rec.owner~=mon or rec.turn~=st.turn) then
      rec.focus=R.option('remember_move',true) and (rec.memory[mon] or 1) or 1
      if not mon.moves or not mon.moves[rec.focus] or mon.moves[rec.focus]==0 then rec.focus=1 end
      rec.lastMove=rec.focus
      rec.error=nil
    end
    rec.owner=mon;rec.turn=st.turn;rec.decision=B.decision()
    return rec
  end
  local function sync(rec)
    if rec.focus<=4 then rec.lastMove=rec.focus;rec.memory[rec.owner]=rec.focus end
    return Navigation.selection(rec.focus,rec.lastMove)
  end
  function B.snapshot(game)
    local st,native,U,M=B.context();if not st then return end
    local facade=api(game);local raw=facade and facade:snapshot();if not raw then return end
    local snap={};for k,v in pairs(raw) do snap[k]=v end
    snap.prompt=B.decision() and 'moves' or 'locked'
    -- Dialogue is drawn separately with the native TextPrinter, limitChars and
    -- token scanner. Never use BattleAPI's complete line as revealed text.
    snap.message='';snap.dialogueActive=M and M.isOpen() and M._frame=='battle' or false
    -- Read the same native text and translation hook as game3 battle/ui.lua.
    -- Resolve on each snapshot so a translation change cannot leave stale labels.
    local RomText=R.module('src.core.game3.rom_text')
    local Strings=R.module('src.core.Strings')
    local NativeTypes=R.module('src.core.game3.battle.types')
    local Progression=R.module('src.core.game3.progression')
    snap.labels={};snap.typeLabels={}
    if RomText and RomText.ir then
      local labels,buf={},{}
      local function flush()
        if #buf>0 then
          local label=table.concat(buf)
          labels[#labels+1]=Strings and Strings(label,'gText_BattleMenu') or label
          buf={}
        end
      end
      for _,seg in ipairs(RomText.ir('gText_BattleMenu')) do
        if seg.t=='text' then buf[#buf+1]=seg.s
        elseif seg.t=='tag' and seg.tag then buf[#buf+1]=seg.tag
        elseif seg.t=='nl' or (seg.t=='ext' and seg.cmd==19) then flush() end
      end
      flush()
      -- Overlay action IDs differ from native menu indices.
      snap.labels={[2]=labels[3],[3]=labels[2],[4]=labels[4]}
      snap.ppLabel=RomText.plain('gText_MoveInterfacePP')
    end
    snap.moves={}
    for _,entry in ipairs(raw.moves or {}) do
      local copy={};for k,v in pairs(entry) do copy[k]=v end
      local nativeType=tonumber(copy.type)
      local registered=nativeType and Progression and Progression.typeIdFor and Progression.typeIdFor(nativeType)
      local typeKey=registered and tostring(registered):upper()
      copy.type=(typeKey and Types[typeKey] and typeKey) or typeNames[nativeType] or copy.type
      if NativeTypes and NativeTypes.name and nativeType then snap.typeLabels[copy.type]=NativeTypes.name(nativeType) end
      snap.moves[copy.slot or #snap.moves+1]=copy
    end
    local Anim=R.module('src.core.game3.battle.anim')
    local P=R.module('src.core.game3.pokemon')
    local Healthbox=R.module('src.core.game3.battle.healthbox')
    for _,side in ipairs({'player','enemy'}) do
      local battler=st[side]
      battler=Anim and Anim.shownBattler and Anim.shownBattler(side,battler) or battler
      local mon=battler and battler.mon
      local out={};for k,v in pairs(raw[side] or {}) do out[k]=v end
      snap[side]=out
      if mon then
        local sp=tonumber(mon.species or mon.speciesId)
        local gender=mon.gender
        if sp==29 then gender='F' elseif sp==32 then gender='M'
        elseif gender~='M' and gender~='F' and gender~='U' and P and P.gender then gender=P.gender(sp,mon.personality) end
        out.name=mon.nickname or (P and P.name and P.name(sp)) or out.name
        if out.name=='' then out.name=out.species end
        if gender=='M' or gender=='F' then
          out.name=tostring(out.name):gsub('♂',''):gsub('♀','')..(gender=='M' and '♂' or '♀')
        end
        if Anim and Anim.displayHpRatio then
          local _,hp,max=Anim.displayHpRatio(side,battler);out.hp=math.floor(hp+.5);out.maxHp=max
        end
        local present=Anim and Anim.present and Anim.present(side)
        if Healthbox and Healthbox.shownAilment then
          local ailment=Healthbox.shownAilment(present,battler)
          out.status=({[1]='PSN',[2]='PAR',[3]='SLP',[4]='FRZ',[5]='BRN'})[ailment]
          local rawStatus=present and present.displayStatus
          if rawStatus==nil then rawStatus=battler.status or mon.status or mon.status1 end
          out.statusToxic=out.status=='PSN' and ((type(rawStatus)=='string' and rawStatus:upper():find('TOX')~=nil)
            or (type(rawStatus)=='number' and math.floor(rawStatus/128)%2==1))
        end
        if side=='player' and Anim and Anim.displayExpRatio then
          out.expFraction,out.level=Anim.displayExpRatio(side,battler);out.expAtMax=(out.level or 1)>=100
        end
        local stage=Anim and Anim.stage and Anim.stage()
        local hb=stage and stage.healthbox and stage.healthbox[side]
        if hb and hb.visible==false then snap[side]=nil end
      end
      if side=='enemy' then
        out.caught=R.option('caught',true) and st.wild and Healthbox and Healthbox.shouldShowCaughtMarker(st,battler)==true or false
      end
    end
    return snap
  end
  local function submit(kind,fields)
    if not B.decision() then return nil,'Menu indisponível.' end
    local facade=api();local raw=facade and facade:snapshot();if not raw then return end
    B.serial=B.serial+1
    local intent={id=B.serial,revision=raw.revision,kind=kind}
    for k,v in pairs(fields or {}) do intent[k]=v end
    B.submitting=true
    local ok,result,err=pcall(facade.submit,facade,intent)
    B.submitting=false
    if not ok then error(result,0) end
    return result,err
  end
  function B.confirm(focus)
    if not B.decision() then return false end
    local rec=B.record();rec.focus=focus;sync(rec)
    local _,_,U=B.context()
    local ok,err
    if focus<=4 then
      if U._mode=='menu' then
        ok,err=submit('menu',{choice='fight'})
        if not ok or U._mode~='moves' then return ok,err end
      end
      ok,err=submit('move',{slot=focus})
    else
      if U._mode=='moves' then
        ok,err=submit('back');if not ok then rec.error=err;return ok,err end
      end
      ok,err=submit('menu',{choice=({[5]='item',[6]='party',[7]='run'})[focus]})
    end
    rec.error=not ok and err or nil
    return ok,err
  end
  function B.settingsDecision()
    if B.decision() then return true end
    local st,native,U=B.context()
    return B.visualOwns() and st and st.double and native._phase=='command' and (U._mode=='menu' or U._mode=='moves')
      and (not U.waitingForCommand or U.waitingForCommand())
  end
  local function settingsInput(input)
    if input:wasPressed('select') then B.settingsOpen=not B.settingsOpen;B.settingsIndex=1;return true end
    if not B.settingsOpen then return false end
    if input:wasPressed('a') or input:wasPressed('b') then B.settingsOpen=false
    elseif input:wasPressed('up') then B.settingsIndex=(B.settingsIndex-2)%#settings+1
    elseif input:wasPressed('down') then B.settingsIndex=B.settingsIndex%#settings+1
    elseif input:wasPressed('left') then changeSetting(B.settingsIndex,-1)
    elseif input:wasPressed('right') then changeSetting(B.settingsIndex,1) end
    return true
  end
  local function input(next,input)
    if B.submitting then return next(input) end
    if not B.decision() then
      if B.settingsDecision() and settingsInput(input) then return true end
      B.settingsOpen=false;return next(input)
    end
    local rec=B.record()
    if input:wasPressed('select') then
      B.settingsOpen=not B.settingsOpen;B.settingsIndex=1;B.drawStamp=nil
      return true
    end
    if B.settingsOpen then
      if input:wasPressed('b') or input:wasPressed('a') then B.settingsOpen=false;B.drawStamp=nil
      elseif input:wasPressed('up') then B.settingsIndex=(B.settingsIndex-2)%#settings+1
      elseif input:wasPressed('down') then B.settingsIndex=B.settingsIndex%#settings+1
      elseif input:wasPressed('left') then changeSetting(B.settingsIndex,-1);B.drawStamp=nil
      elseif input:wasPressed('right') then changeSetting(B.settingsIndex,1);B.drawStamp=nil end
      local _,_,U=B.context();if U.tick then U.tick() end
      return true
    end
    local snap=B.snapshot();local opts=presentation()
    for _,dir in ipairs({'left','right','up','down'}) do
      if input:wasPressed(dir) then rec.focus=Navigation.step(rec.focus,dir,opts.style,rec.lastMove,snap and snap.moves) end
    end
    sync(rec)
    if input:wasPressed('a') then B.confirm(rec.focus);return true end
    if input:wasPressed('b') then
      local _,_,U=B.context()
      if U._mode=='moves' then submit('back') end
      return true
    end
    local _,_,U=B.context();if U.tick then U.tick() end
    return true
  end
  local function stamp()
    local st,native,U,M=B.context()
    if not st then return '' end
    return table.concat({tostring(st),tostring(st.turn),tostring(st.player.mon),
      tostring(native._phase),tostring(U._mode),tostring(M and M.open),tostring(M and M._page),
      tostring(B.settingsOpen),tostring(records[st] and records[st].focus),
      tostring(R.option('battle_aspect','native')),tostring(R.option('battle_drop',8)),presentation().style,presentation().position,tostring(presentation().opacity),tostring(presentation().scale)},'|')
  end
  function B.pointer(game,x,y,button)
    if B.settingsOpen and B.visualOwns() and not B.owns() then
      if button~=1 then return true end
      local targets=B.settingsTargets
      if targets and B.viewport and B.settingsViewport==tostring(B.viewport.width)..':'..tostring(B.viewport.height) then
        if Layout.contains(targets.close,x,y) then B.settingsOpen=false
        else for _,r in ipairs(targets.rows) do if Layout.contains(r,x,y) then B.settingsIndex=r.index;changeSetting(r.index,x<r.x+r.w*.7 and -1 or 1) end end end
      end
      return true
    end
    if button~=1 or not B.owns() or not B.viewport or B.drawStamp~=stamp() then return false end
    local frame=B.frame or {x=0,y=0}
    local g=love and love.graphics
    if frame.w and g and g.getDimensions then
      local w,h=g.getDimensions()
      if w~=frame.w or h~=frame.h then return false end
    end
    x,y=x-frame.x,y-frame.y
    if B.decision() then
      local rec=B.record()
      if B.settingsOpen then
        local overlay=B.settingsTargets
        if not overlay then return true end
        if Layout.contains(overlay.close,x,y) then B.settingsOpen=false;B.drawStamp=nil;return true end
        for _,r in ipairs(overlay.rows) do
          if Layout.contains(r,x,y) then
            B.settingsIndex=r.index;changeSetting(r.index,x<r.x+r.w*.7 and -1 or 1);B.drawStamp=nil;return true
          end
        end
        return true -- modal blocks underlying commands
      end
      local hit=Layout.hit(B.layout,x,y)
      if not hit then return false end
      if hit.kind=='settings' then B.settingsOpen=true;B.settingsIndex=1;B.drawStamp=nil;return true end
      if hit.kind=='move' and rec.focus~=hit.index then
        rec.focus=hit.index;sync(rec);B.drawStamp=nil;return true
      end
      return B.confirm(hit.kind=='move' and hit.index or ({[3]=5,[2]=6,[4]=7})[hit.index])~=false
    end
    local _,_,_,M=B.context()
    local r=B.messageRect
    if r and M and M.isWaiting() and x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h then
      -- Only an already revealed native battle message is clickable. Do not
      -- turn clicks on move slots during animation into A presses.
      M.pressAB();return true
    end
    return false
  end
  function B.drawHealthboxes(frame)
    local g=love.graphics
      local sx,sy=frame.w/240,frame.h/160
      local sizeFactor,raise=R.camera.hudAdjustment()
      local hudScale=math.min(sx,sy)*.65*sizeFactor
      g.push('all');g.scale(hudScale,hudScale)
      local unpackArgs=table.unpack or unpack
      local skinSnapshot=R.option('battle_skin','current')=='emerald_ivory' and B.snapshot()
      B.hudDrawing=true
      local hudOk,hudErr=pcall(function()
        for _,box in ipairs(B.healthboxes or {}) do
          -- Move the boxes as whole objects when the command deck is on the
          -- right; never mirror glyphs, reskin bars or recompute their contents.
          local shift=0
          if presentation().position=='right' then shift=box.args[1]=='enemy' and 114 or -114 end
          local cx=box.args[1]=='enemy' and 44 or 158
          local cy=box.args[1]=='enemy' and 30 or 88
          local dx=(cx+shift)*sx/hudScale-cx
          local dy=cy*sy/hudScale-cy
          local side=box.args[1]
          local isPlayer=side=='player' or type(side)=='number' and side%2==0
          if type(side)=='number' then
            local H=R.module('src.core.game3.battle.healthbox');local center=H and H.center and H.center(B.context(),side)
            if center then cx,cy=center.x,center.y;dx=cx*sx/hudScale-cx;dy=cy*sy/hudScale-cy end
          end
          local D=R.module('src.core.game3.display')
          local projection={x=0,y=0,w=frame.w,h=frame.h}
          if D and D.fit then
            local ps,px,py,pw,ph,psy=D.fit(frame.w,frame.h)
            projection={x=px,y=py,w=pw or 240*ps,h=ph or 160*(psy or ps)}
          end
          local bounds=Anchors.project(side,projection)
          if bounds or R.camera.depth() then
            local C=R.module('src.ui.game3.battle_chrome')
            local img=C and (type(side)=='number' and (isPlayer and C._doublesPlayerBox or C._doublesOpponentBox) or isPlayer and C._playerBox or C._enemyBox)
            local hb=img and Anchors.alphaBounds(img) or {0,0,104,isPlayer and 37 or 29}
            local width,height=(hb[3]-hb[1])*hudScale,(hb[4]-hb[2])*hudScale
            local hx,hy
            if R.camera.depth() then hx,hy=R.camera.hud(side,frame.w,frame.h,width,height,B.context().double)
            -- Keep the prior top edge as reference, then raise it five window
            -- pixels. Shrinking the box must not accidentally move it downward.
            else hx,hy=Anchors.place(side,bounds,width,height/sizeFactor,frame.w,frame.h) end
            hy=math.max(0,hy+raise)
            dx=hx/hudScale-(cx-32)-hb[1];dy=hy/hudScale-(cy-16)-hb[2]
          else dy=dy+raise/hudScale end
          local args=box.args
          if (Anchors.fixed[side] or R.camera.depth()) and args[3] then
            local opts={};for k,v in pairs(args[3]) do opts[k]=v end;opts.oy=0
            args={args[1],args[2],opts}
          end
          g.translate(dx,dy)
          local mon=skinSnapshot and type(side)=='string' and skinSnapshot[side]
          if mon then
            local C=R.module('src.ui.game3.battle_chrome')
            local img=C and (isPlayer and C._playerBox or C._enemyBox)
            local hb=img and Anchors.alphaBounds(img) or {0,0,104,isPlayer and 37 or 29}
            Skin.hud(mon,isPlayer,cx-32+hb[1],cy-16+hb[2],hb[3]-hb[1],hb[4]-hb[2],part('ui/icons.lua'))
          else box.draw(unpackArgs(args)) end
          g.translate(-dx,-dy)
        end
      end)
      B.hudDrawing=false
      g.pop();if not hudOk then error(hudErr,0) end
  end
  function B.draw(game,viewport)
    B.viewport=viewport
    if not B.owns() then
      B.drawStamp=nil;B.layout=nil
      if not B.settingsDecision() then B.settingsOpen=false end
      if B.visualOwns() and (R.camera.depth() and B.healthboxes or B.settingsOpen) then
        local g=love.graphics;g.push('all');g.origin();g.setScissor(0,0,viewport.width,viewport.height)
        local ok,err=pcall(function()
          if R.camera.depth() then R.scenery.foreground(viewport.width,viewport.height);B.drawHealthboxes({x=0,y=0,w=viewport.width,h=viewport.height}) end
          if B.settingsOpen then
            local rows={};for _,row in ipairs(settings) do rows[#rows+1]={label=translate(row.label),value=translate(row.labels[settingIndex(row)])} end
            B.settingsTargets=View.settings({width=viewport.width,height=viewport.height,scale=1,neutral=true,emeraldIvory=R.option('battle_skin','current')=='emerald_ivory',translate=translate},rows,B.settingsIndex or 1)
            B.settingsViewport=tostring(viewport.width)..':'..tostring(viewport.height)
          else B.settingsTargets=nil end
        end)
        g.pop();if not ok then error(err,0) end
      end
      return
    end
    local snap=B.snapshot(game);if not snap then return end
    local rec=B.record();local g=love.graphics
    local frame={x=0,y=0,w=viewport.width,h=viewport.height}
    B.frame=frame
    g.push('all');g.origin();g.setScissor(frame.x,frame.y,frame.w,frame.h);g.translate(frame.x,frame.y)
    local ok,err=pcall(function()
      R.scenery.foreground(frame.w,frame.h)
      if not B.decision() then B.settingsOpen=false end
      -- Replay the exact family healthbox renderer in the final overlay, at
      -- native coordinates scaled to the fitted viewport. No parallel HP model.
      B.drawHealthboxes(frame)
      local layout=View.draw(snap,sync(rec),presentation(),frame.w,frame.h,rec.error)
      B.layout=layout
      if B.settingsOpen then
        local rows={}
        for _,row in ipairs(settings) do rows[#rows+1]={label=translate(row.label),value=translate(row.labels[settingIndex(row)])} end
        layout.translate=translate
        B.settingsTargets=View.settings(layout,rows,B.settingsIndex or 1)
      else B.settingsTargets=nil end
      B.messageRect=layout.message
      local _,_,_,M=B.context()
      if snap.dialogueActive and M then
        local F=R.module('src.ui.game3.frlg_font')
        local r=layout.message;local k=layout.scale*1.2
        g.push('all');g.translate(r.x+16*layout.scale,r.y+12*layout.scale);g.scale(k,k)
        local opts={maxWidth=(r.w-32*layout.scale)/k,limitChars=M._revealed,colors=F.COLOR.WHITE,linePitch=16}
        F.draw(M.currentPage() or '',0,0,opts)
        if M.isWaiting() then
          local C=R.module('src.ui.game3.chrome')
          if C and C.promptArrow then C.promptArrow((r.w-50*layout.scale)/k,45,0) end
        end
        g.pop()
      end
      B.drawStamp=stamp()
    end)
    g.pop();if not ok then error(err,0) end
  end
  function B.installLoaded()
    R.camera.installLoaded()
    local _,U,M=modules()
    if U and not seen[U] then
      seen[U]=true
      R.wrap(U,'levelUpSpriteSnapshot',function(next,st,id,...)
        local value=next(st,id,...)
        if not value or (id~=0 and id~=1) or st.double then return value end
        local dx,dy=R.camera.activeOffset(Anchors,id==0 and 'player' or 'enemy')
        local result={};for k,v in pairs(value) do result[k]=v end
        result.x,result.y=value.x+dx,value.y+dy
        return result
      end)
      R.wrap(U,'sidePic',function(next,back,...)
        local key=B.visualScene and type(B.spriteKey)=='number' and B.spriteKey or (back and 'player' or 'enemy')
        return Anchors.register(next(back,...),key)
      end)
      R.wrap(U,'handleInput',input)
      R.wrap(U,'drawOverlay',function(next,...) B.endSceneTransform();return next(...) end)
      R.wrap(U,'draw',function(next,...)
        local owned=B.owns();local visual=B.visualOwns();local st=B.context()
        if not st then local native=modules();if native and native.isActive and native.isActive() and native.getState then st=native.getState() end end
        local shadowOnly=not owned and not visual
        if shadowOnly and not (st and st.enemy and R.glass() and R.option('battle',true) and not B.failed) then
          B.sceneryScene=B.sceneryOwns()
          local ok,a,b=pcall(next,...);B.sceneryScene=false
          if not ok then error(a,0) end;return a,b
        end
        local mode=U._mode
        local Anim=R.module('src.core.game3.battle.anim');local ready={}
        local keys=st and st.double and {0,1,2,3} or {'player','enemy'}
        for _,side in ipairs(keys) do
          local pr=Anim and Anim.present and Anim.present(side) or {}
          ready[side]=pr.visible~=false and not pr.blinkHidden and (pr.alpha or 1)>=.99
            and (pr.scale or 1)==1 and (pr.sx or 1)==1 and (pr.sy or 1)==1
            and (pr.ox or 0)==0 and (pr.oy or 0)==0
        end
        B.anchorReady=ready;R.shadows.reset(st)
        if owned then U._mode='none' end;B.scene=owned;B.visualScene=not owned;B.sceneryScene=not owned;B.captureHud=owned or visual and R.camera.depth();B.shadowOnly=shadowOnly;B.rawState=st;B.healthboxes={};B.foregroundDrawn=false;B.sceneDrop=0
        love.graphics.push('all');Anchors.begin()
        local ok,a,b=pcall(next,...)
        B.endSceneTransform();Anchors.finish();love.graphics.pop();B.sceneDrop=0
        U._mode=mode;B.scene=false;B.visualScene=false;B.sceneryScene=false;B.spriteKey=nil;B.shadowOnly=false;B.rawState=nil
        if not ok then
          B.failed=true;R.warn('battle scene; native UI restored',a)
          return next(...)
        end
        return a,b
      end)
    end
    local Anim=R.module('src.core.game3.battle.anim')
    if Anim and not seen[Anim] then
      seen[Anim]=true
      R.wrap(Anim,'drawParticles',function(next,...)
        -- Particle positions already come from the adapted native coordinate
        -- service. Sprite echoes must not receive the body offset a second time.
        B.particleDepth=(B.particleDepth or 0)+1
        local ok,a,b=pcall(next,...)
        B.particleDepth=B.particleDepth-1
        if not ok then error(a,0) end
        return a,b
      end)
      R.wrap(Anim,'present',function(next,key,...)
        local p=next(key,...)
        if (B.scene or B.visualScene) and not B.hudDrawing and (not B.visualScene or type(key)=='number') then B.spriteKey=key end
        return p
      end)
      R.wrap(Anim,'substituteImage',function(next,side,...)
        local img=next(side,...);Anchors.register({image=img},side,'substitute');return img
      end)
      R.wrap(Anim,'beginParticleFrame',function(next,...)
        local result=next(...)
        if (B.scene or B.visualScene) and not B.sceneTransform then
          B.sceneDrop=R.framing.drop()
          local plan=R.camera.plan(B.rawState or B.context(),R.scenery.replaced and R.scenery.selected or nil,(R.scenery.replaced or R.scenery.current or R.camera.depth()) and B.sceneDrop or 0)
          if B.shadowOnly then plan={x=0,y=0,k=1,drop=0,signature='native-shadow-only'} end
          Anchors.prepare(B.rawState or B.context(),B.anchorReady,tostring(B.sceneDrop)..':'..tostring(R.scenery.selected)..':'..plan.signature)
          Anchors.reproject(plan)
          -- Transform the complete native sprite/particle/ball layer together.
          -- Only the transform is restored: retain native shader/color cleanup.
          love.graphics.push();B.sceneTransform=true
          R.camera.apply(plan)
        end
        return result
      end)
    end
    local P=R.module('src.core.game3.pokemon')
    if P and not seen[P] then
      seen[P]=true
      R.wrap(P,'ghostPic',function(next,...) return Anchors.register(next(...),B.visualScene and type(B.spriteKey)=='number' and B.spriteKey or 'enemy') end)
    end
    local MonAnim=R.module('src.core.game3.mon_anim')
    if MonAnim and not seen[MonAnim] then
      seen[MonAnim]=true
      R.wrap(MonAnim,'framePic',function(next,...) return Anchors.register(next(...),B.visualScene and type(B.spriteKey)=='number' and B.spriteKey or 'enemy','frame') end)
    end
    local H=R.module('src.core.game3.battle.healthbox')
    if H and not seen[H] then
      seen[H]=true
      R.wrap(H,'shouldShowCaughtMarker',function(next,...)
        if B.hudDrawing and not R.option('caught',true) then return false end
        return next(...)
      end)
      R.wrap(H,'draw',function(next,...)
        if B.scene or B.visualScene then
          if not B.foregroundDrawn then
            B.endSceneTransform()
            B.foregroundDrawn=true
          end
          if B.captureHud then B.healthboxes[#B.healthboxes+1]={draw=next,args={...}};return end
        end
        return next(...)
      end)
    end
    local C=R.module('src.ui.game3.battle_chrome')
    if C and not seen[C] then
      seen[C]=true
      R.wrap(C,'drawEntry',function(next,...)
        if R.scenery.replaced and (B.scene or B.sceneryScene) then return true end
        return next(...)
      end)
      local quads=setmetatable({},{__mode='k'})
      local failed=setmetatable({},{__mode='k'})
      R.wrap(C,'drawTerrain',function(next,key,enemyOx,playerOx,bgOx)
        local result=next(key,enemyOx,playerOx,bgOx)
        if not result or not B.scene or not R.option('battle_extend',true) or type(C.terrain)~='function' then return result end
        local entry=C.terrain(key or 'building') or C.terrain('building') or C.terrain('grass')
        local img=entry and entry.bgImage
        if not img or failed[img] then return result end
        -- The ROM panel occupied y=112..159. Continue clean wallpaper there
        -- before battlers/FX, never redraw mons or cover them in the HUD pass.
        local g=love.graphics
        g.push('all')
        local ok,err=pcall(function()
          local q=quads[img]
          if not q then
            local iw,ih=img:getDimensions()
            if iw<240 or ih<112 then return end
            q=g.newQuad(0,104,240,8,iw,ih);quads[img]=q
          end
          g.setColor(1,1,1,1)
          for y=112,152,8 do g.draw(img,q,0,y) end
        end)
        g.pop()
        if not ok then failed[img]=true;R.warn('battle terrain extension; native background retained',err) end
        return result
      end)
      for _,key in ipairs({'drawPanel','drawMenuFrames'}) do
        R.wrap(C,key,function(next,...) if B.scene then B.endSceneTransform();return end;if B.visualScene then B.endSceneTransform() end;return next(...) end)
      end
    end
    if M and not seen[M] then
      seen[M]=true
      R.wrap(M,'draw',function(next,...)
        if M._frame=='battle' and B.owns() then return end
        return next(...)
      end)
    end
    local Game=R.module('src.core.Game3')
    if Game and not seen[Game] then
      seen[Game]=true
      R.wrap(Game,'mousepressed',function(next,game,x,y,button,istouch)
        if not istouch and B.pointer(game,x,y,button) then return true end
        return next(game,x,y,button,istouch)
      end)
    end
  end
  function B.shutdown() Skin.shutdown() end
  return B
end
