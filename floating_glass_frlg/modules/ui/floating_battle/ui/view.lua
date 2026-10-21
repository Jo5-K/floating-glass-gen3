return function(Types,Model,Layout,Icons,Art,Statuses,Theme)
  local V={fonts={}}
  local function font(size)
    size=math.max(8,math.floor(size+.5))
    if not V.fonts[size] then V.fonts[size]=love.graphics.newFont(size) end
    love.graphics.setFont(V.fonts[size]);return V.fonts[size]
  end
  local function text(str,x,y,w,size,color)
    local g=love.graphics;font(size);g.setColor(color or {.94,.97,1,1})
    local sx,sy,sw,sh=g.getScissor()
    -- LOVE scissors use window coordinates, not the active draw transform.
    -- KRS translates/scales the field; transform all corners before clipping.
    if type(g.transformPoint)=='function' then
      local h=math.max(12,size*1.6)
      local x1,y1=g.transformPoint(x,y)
      local x2,y2=g.transformPoint(x+w,y)
      local x3,y3=g.transformPoint(x,y+h)
      local x4,y4=g.transformPoint(x+w,y+h)
      local left,top=math.floor(math.min(x1,x2,x3,x4)),math.floor(math.min(y1,y2,y3,y4))
      local right,bottom=math.ceil(math.max(x1,x2,x3,x4)),math.ceil(math.max(y1,y2,y3,y4))
      g.intersectScissor(left,top,right-left,bottom-top)
    end
    -- Older hosts without transformPoint retain the existing parent clip.
    local ink=color or {.94,.97,1,1}
    g.setColor(.003,.01,.025,(ink[1]<.4 and 0 or .92)*(ink[4] or 1));g.print(tostring(str or ''),x+math.max(.7,size/18),y+math.max(.7,size/18))
    g.setColor(ink);g.print(tostring(str or ''),x,y);g.setScissor(sx,sy,sw,sh)
  end
  local function panel(r,s,accent,focused,alpha)
    local g=love.graphics
    g.setColor(48/255,59/255,80/255,1);g.rectangle('fill',r.x,r.y,r.w,r.h,12*s,12*s)
    g.setColor(16/255,20/255,29/255,1);g.setLineWidth(3*s)
    g.rectangle('line',r.x,r.y,r.w,r.h,12*s,12*s)
    if focused then
      g.setColor(1,211/255,107/255,1);g.setLineWidth(2*s)
      g.rectangle('line',r.x-2*s,r.y-2*s,r.w+4*s,r.h+4*s,12*s,12*s)
    end
  end
  -- One shared capsule and circle geometry for every action. Only the
  -- pictogram is sampled from the source artwork, always with uniform scale.
  local function metallic(r,s,c,selected,index,time,nativePalette)
    local g=love.graphics;local radius=r.h/2
    g.setColor(c[1]*.22,c[2]*.22,c[3]*.22,.96)
    g.rectangle('fill',r.x,r.y,r.w,r.h,radius,radius)
    local function band(y,h,color,left,right)
      local dy=y+h/2-r.h/2
      local inset=radius-math.sqrt(math.max(0,radius*radius-dy*dy))
      local x1=math.max(inset,left or 0);local x2=math.min(r.w-inset,right or r.w)
      if x2>x1 then g.setColor(color);g.rectangle('fill',r.x+x1,r.y+y,x2-x1,math.min(h+.2*s,r.h-y)) end
    end
    for j=0,59 do
      local t=j/59;local bright=.24+.34*math.abs(2*t-1)+.23*math.exp(-((t-.20)/.12)^2)
      band(r.h*j/60,r.h/60,{c[1]*bright,c[2]*bright,c[3]*bright,.96})
    end
    for edge=3,1,-1 do
      g.setColor(.70+(selected and .25 or 0),.84,.94,selected and .19 or .08)
      g.setLineWidth(edge*s)
      g.rectangle('line',r.x+edge*s/2,r.y+edge*s/2,r.w-edge*s,r.h-edge*s,radius,radius)
    end
    g.setColor(c[1],c[2],c[3],selected and .96 or .65);g.setLineWidth(1.3*s)
    g.rectangle('line',r.x+s,r.y+s,r.w-2*s,r.h-2*s,radius,radius)
    local badge=Layout.actionBadge(r,s);local d=badge.d;local bx=badge.x;local by=badge.y
    if nativePalette then
      g.setColor(1,1,27/31,1);g.circle('fill',bx+d/2,by+d/2,d/2)
      g.setColor(8/31,8/31,8/31,1);Icons.action(index,bx+d/2,by+d/2,d*.30)
    elseif not (Art and Art.badge(index,bx,by,d,1)) then
      g.setColor(c[1]*.38,c[2]*.38,c[3]*.38,1);g.circle('fill',bx+d/2,by+d/2,d/2)
      g.setColor(1,1,1,1);Icons.action(index,bx+d/2,by+d/2,d*.30)
    end
    g.setColor(nativePalette and .58 or .82,nativePalette and .64 or .94,nativePalette and .30 or 1,selected and .8 or .65);g.setLineWidth((selected and 1.6 or .8)*s)
    g.circle('line',bx+d/2,by+d/2,d/2-s)
    if selected then
      -- Sweep reflects across the metal, while the permanent bright rim
      -- keeps focus readable even between passes. No UI/input timers.
      local phase=(time*.65)%1
      for j=0,27 do
        local y=r.h*j/28;local at=(r.w+90*s)*phase-60*s+y*.5
        for k=0,3 do
          band(y,r.h/28,{.88,.96,1,.035*(4-k)},at+k*7*s,at+(8-k)*7*s)
        end
      end
      g.setColor(.93,1,1,.8);g.setLineWidth(1.8*s)
      g.arc('line','open',bx+d/2,by+d/2,d/2-2*s,-2.65,-.65)
    end
  end
  local function rgb(hex)
    return {tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255,1}
  end
  local neutral={outline=rgb('10141D'),ivory=rgb('FFF8E5'),gold=rgb('FFD36B'),
    ink=rgb('171F2E'),moves={rgb('303B50'),rgb('171F2E')},settings={rgb('3B4254'),rgb('1C2231')},
    [3]={rgb('E8C77D'),rgb('846A3B')},[2]={rgb('AFC9E8'),rgb('577AA3')},[4]={rgb('E7A6A0'),rgb('9D5555')}}
  if Theme then
    neutral={outline=Theme.outline,ivory=Theme.ivory,gold=Theme.gold,ink=Theme.ink,
      moves=Theme.roles.base,settings=Theme.roles.settings,
      [3]=Theme.roles.bag,[2]=Theme.roles.party,[4]=Theme.roles.exit}
  end
  local function solid(r,s,palette,selected,radius)
    local g=love.graphics;radius=radius or 12*s
    g.setColor(palette[1]);g.rectangle('fill',r.x,r.y,r.w,r.h,radius,radius)
    g.setColor(neutral.outline);g.setLineWidth(4*s)
    g.rectangle('line',r.x,r.y,r.w,r.h,radius,radius)
    g.setColor(palette[2]);g.setLineWidth(1.5*s)
    g.rectangle('line',r.x+s,r.y+s,r.w-2*s,r.h-2*s,radius,radius)
    if selected then
      g.setColor(neutral.gold);g.setLineWidth(2*s)
      g.rectangle('line',r.x-3*s,r.y-3*s,r.w+6*s,r.h+6*s,radius,radius)
    end
  end
  local function pastel(r,s,c,selected,index,time)
    local g=love.graphics
    solid(r,s,neutral[index],selected,r.h/2)
    local b=Layout.actionBadge(r,s)
    g.setColor(neutral.ivory);g.circle('fill',b.x+b.d/2,b.y+b.d/2,b.d/2)
    g.setColor(neutral.outline);g.setLineWidth(2*s);g.circle('line',b.x+b.d/2,b.y+b.d/2,b.d/2)
    g.setColor(neutral.ink);Icons.action(index,b.x+b.d/2,b.y+b.d/2,b.d*.25)
  end
  local function bar(x,y,w,h,ratio,color)
    local g=love.graphics
    g.setColor(.06,.16,.23,1);g.rectangle('fill',x,y,w,h,h/2,h/2)
    if ratio and ratio>0 then
      g.setColor(color[1],color[2],color[3],1)
      g.rectangle('fill',x,y,w*math.min(1,ratio),h,h/2,h/2)
    end
  end
  function V.draw(snapshot,selection,options,w,h,errorText)
    local g=love.graphics
    local l=Layout.compute(w,h,options.style,options.scale,selection.move,{moves=snapshot.moves,position=options.position,nativeHud=options.nativeHud})
    local s=l.scale
    l.neutral=options.pastel
    -- Interpolate presentation only. Returned rectangles are the mouse targets.
    local now=options.time or (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local signature=table.concat({w,h,options.style or '',options.scale or '',options.position or '',tostring(options.nativeHud)},':')
    if V.signature~=signature then V.motion={};V.signature=signature end
    V.motion=V.motion or {}
    for _,r in ipairs(l.rects) do
      if r.kind=='move' then
        local previous=V.motion[r.index]
        if previous and now>previous.time and now-previous.time<.3 then
          local k=1-math.exp(-18*(now-previous.time))
          for _,field in ipairs({'x','y','w','h','scale','alpha'}) do r[field]=previous[field]+(r[field]-previous[field])*k end
        end
        V.motion[r.index]={x=r.x,y=r.y,w=r.w,h=r.h,scale=r.scale,alpha=r.alpha,time=now}
      end
    end
    local function hud(mon,r,player)
      if not mon then return end
      panel(r,s,{.38,.75,.90},false,.9)
      local caught=not player and mon.caught==true
      local name=tostring(mon.name or mon.species or 'Pokémon')
      local gender=name:find('♀',1,true) and '♀' or (name:find('♂',1,true) and '♂' or nil)
      if gender then name=name:gsub('♀',''):gsub('♂',''):gsub('%s+$','') end
      text(name,r.x+14*s,r.y+10*s,r.w-((caught and 130 or 100)+(gender and 24 or 0))*s,18*s)
      if gender then Icons.gender(gender,r.x+r.w-(caught and 126 or 102)*s,r.y+22*s,8*s) end
      if caught then Icons.caught(r.x+r.w-102*s,r.y+22*s,8*s) end
      text('Nv. '..tostring(mon.level or '?'),r.x+r.w-84*s,r.y+12*s,72*s,15*s)
      local hp=tonumber(mon.hp) or 0;local maxHp=math.max(1,tonumber(mon.maxHp) or 1)
      text('HP',r.x+14*s,r.y+40*s,28*s,12*s,{.72,.85,.93,1})
      bar(r.x+47*s,r.y+43*s,r.w-62*s,8*s,math.max(0,math.min(1,hp/maxHp)),hp/maxHp>.5 and {.21,.9,.48} or (hp/maxHp>.2 and {1,.78,.15} or {1,.27,.29}))
      local status=Statuses and Statuses.resolve(mon.status,mon.statusToxic)
      text(tostring(hp)..' / '..tostring(mon.maxHp or '?'),r.x+47*s,r.y+58*s,status and 137*s or r.w-61*s,14*s)
      if status then
        local bx,by,bw,bh=r.x+r.w-138*s,r.y+57*s,124*s,23*s
        local c=status.color
        g.setColor(c[1]*.25,c[2]*.25,c[3]*.25,.92);g.rectangle('fill',bx,by,bw,bh,7*s,7*s)
        g.setColor(c[1],c[2],c[3],.85);g.setLineWidth(s);g.rectangle('line',bx,by,bw,bh,7*s,7*s)
        text(status.id,bx+5*s,by+7*s,25*s,8*s,{c[1],c[2],c[3],1})
        text(status.label,bx+32*s,by+5*s,bw-36*s,10*s)
      end
      if player then
        text('EXP',r.x+14*s,r.y+84*s,30*s,10*s,{.45,.79,1,1})
        bar(r.x+47*s,r.y+86*s,r.w-62*s,6*s,mon.expFraction,{.21,.67,1})
        if mon.expAtMax then text('MÁX',r.x+r.w-52*s,r.y+96*s,40*s,9*s,{.55,.8,1,1})
        elseif mon.expFraction==nil then text('—',r.x+r.w-28*s,r.y+96*s,20*s,9*s,{.55,.8,1,1}) end
      end
    end
    if not options.nativeHud then hud(snapshot.enemy,l.enemyHud,false);hud(snapshot.player,l.playerHud,true) end
    if not Model.active(snapshot) then
      local message=type(snapshot.message)=='table' and table.concat(snapshot.message,'\n') or snapshot.message or ''
      if tostring(message):match('^%s*$') and not snapshot.dialogueActive then l.rects={};l.settings=nil;V.motion={};return l end
      panel(l.message,s,{.28,.61,.78},false,.91)
      local f=font(18*s);local _,lines=f:getWrap(tostring(message),l.message.w-32*s)
      for i,line in ipairs(lines) do if i>3 then break end;text(line,l.message.x+16*s,l.message.y+(15+(i-1)*23)*s,l.message.w-32*s,18*s) end
      l.rects={};l.settings=nil;V.motion={};return l
    end
    local cards=Model.cards(snapshot)
    local names={[2]='Trocar Pokémon',[3]='Mochila',[4]='Fugir'}
    local colors={[2]={.22,.85,.73},[3]={.28,.34,1},[4]={1,.30,.42}}
    if options.nativePalette then colors={[2]={.63,.72,.38},[3]={.85,.78,.38},[4]={.64,.66,.38}} end
    
    local focus=selection.focus or (selection.menu==1 and selection.move or ({[3]=5,[2]=6,[4]=7})[selection.menu])
    for _,r in ipairs(l.rects) do
      local move=r.kind=='move';local card=move and cards[r.index]
      local selected=move and focus==r.index or (not move and focus==({[3]=5,[2]=6,[4]=7})[r.index])
      if not move then
        if options.pastel then pastel(r,s,colors[r.index],selected,r.index,now)
        else metallic(r,s,colors[r.index],selected,r.index,now,options.nativePalette) end
        text(names[r.index],r.x+72*s,r.y+18*s,r.w-80*s,15*s,options.pastel and neutral.ink or nil)
      else
        local k=r.scale or s
        local alpha=r.alpha or Model.alpha(r.index,selection.move)
        local t=Types.resolve(card.type)
        local compact=options.style=='list' or options.style=='stack'
        local ink=card.disabled and {.72,.77,.82,.85} or {.94,.97,1,.98}
        g.push('all')
        if r.angle then
          g.translate(r.x+r.w/2,r.y+r.h/2);g.rotate(r.angle);g.translate(-r.x-r.w/2,-r.y-r.h/2)
        end
        if options.pastel then solid(r,k,neutral.moves,selected)
        else panel(r,k,{.32,.9,1},selected,(options.opacity or .70)*alpha) end
        -- Back cards retain a subtle type tint; cyan focus stays distinct.
        if not options.pastel then
        g.setColor(t.color[1],t.color[2],t.color[3],.09*alpha)
        g.rectangle('fill',r.x+2*k,r.y+2*k,r.w-4*k,r.h-4*k,12*k,12*k)
        g.setColor(t.color[1],t.color[2],t.color[3],alpha)
        g.rectangle('fill',r.x+3*k,r.y+10*k,4*k,r.h-20*k,2*k,2*k)
        end
        if card.empty then
          text('—',r.x+20*k,r.y+12*k,r.w-40*k,16*k,ink)
        else
          local size=(compact and 30 or 36)*k
          local ix=r.x+29*k;local iy=r.y+(compact and 25 or 29)*k
          local badge=not options.nativePalette and tostring(card.type):upper()=='PSYCHIC' and not t.image and Art and Art.psychic(ix-size/2,iy-size/2,size,alpha)
          if not badge then
            if options.pastel then
              g.setColor(neutral.ivory);g.circle('fill',ix,iy,size/2)
              g.setColor(neutral.outline);g.setLineWidth(1.5*k);g.circle('line',ix,iy,size/2)
            else
            for ring=0,12 do
              local q=ring/12;local bright=.60+.40*q
              local c=options.nativePalette and {1,1,27/31} or t.color
              g.setColor(c[1]*bright,c[2]*bright,c[3]*bright,math.max(.35,alpha))
              g.circle('fill',ix,iy,size/2*(1-q*.16))
            end
            end
            if options.pastel then g.setColor(neutral.ink)
            elseif options.nativePalette then g.setColor(8/31,8/31,8/31,math.max(.5,alpha)) else g.setColor(1,1,1,math.max(.5,alpha)) end
            if t.image then
              local iw,ih=t.image:getDimensions();local scale=math.min(size*.72/iw,size*.72/ih)
              g.draw(t.image,ix-iw*scale/2,iy-ih*scale/2,0,scale,scale)
            else Icons.type(card.type,ix,iy,size*.42) end
          end
          local tx=r.x+54*k
          -- Two lines in the compact mode keep long names and PP apart.
          text(card.name,tx,r.y+(compact and 5 or 15)*k,r.w-68*k,17*k,ink)
          local tagX=tx;local tagY=r.y+(compact and 29 or 58)*k
          local tagW=math.min(100*k,r.w*.36)
          g.setColor(t.color[1]*.6,t.color[2]*.6,t.color[3]*.6,math.max(.3,alpha))
          g.rectangle('fill',tagX,tagY,tagW,17*k,8*k,8*k)
          text(t.label,tagX+6*k,tagY+1*k,tagW-12*k,10*k,ink)
          text(tostring(card.pp or '?')..' / '..tostring(card.maxPp or '?')..' PP',tagX+tagW+12*k,tagY,r.w-180*k,12*k,ink)
        end
        g.pop()
      end
    end
    local settings=l.settings
    if options.pastel then solid(settings,s,neutral.settings,false) else panel(settings,s,{.32,.9,1},false,.65) end
    if options.pastel then
      local cx,cy,rad=settings.x+21*s,settings.y+settings.h/2,14*s
      g.setColor(neutral.ivory);g.circle('fill',cx,cy,rad)
      g.setColor(neutral.outline);g.setLineWidth(1.5*s);g.circle('line',cx,cy,rad)
      g.circle('line',cx,cy,5*s)
      for i=0,7 do local a=i*math.pi/4;g.line(cx+math.cos(a)*6*s,cy+math.sin(a)*6*s,cx+math.cos(a)*9*s,cy+math.sin(a)*9*s) end
      text('Ajustes · SELECT',settings.x+42*s,settings.y+12*s,settings.w-48*s,12*s,neutral.ivory)
    else text('Ajustes · SELECT',settings.x+14*s,settings.y+12*s,settings.w-28*s,14*s) end
    if errorText then
      local r={x=l.x,y=l.y-28*s,w=l.w,h=24*s}
      panel(r,s,{1,.62,.49},false,.9)
      text(errorText,r.x+8*s,r.y+4*s,r.w-16*s,12*s,{1,.72,.62,1})
    else
      text('← → golpes   ↑ Mochila   ↓ Trocar',l.x,l.y-22*s,l.w,11*s,{.80,.91,1,.92})
    end
    return l
  end
  function V.settings(layout,rows,index)
    local height=120+#rows*45
    local s=math.min(layout.scale,(layout.height-24)/height);local w=math.min(layout.width-24*s,480*s)
    local r={x=(layout.width-w)/2,y=(layout.height-height*s)/2,w=w,h=height*s}
    local g=love.graphics
    g.setColor(.008,.02,.045,.65);g.rectangle('fill',0,0,layout.width,layout.height)
    if layout.neutral then solid(r,s,neutral.settings,false) else panel(r,s,{.32,.9,1},true,.96) end
    text('AJUSTES DA BATALHA',r.x+20*s,r.y+18*s,r.w-40*s,19*s)
    local targets={}
    for i,row in ipairs(rows) do
      local q={x=r.x+16*s,y=r.y+(57+(i-1)*45)*s,w=r.w-32*s,h=38*s,index=i}
      if layout.neutral then solid(q,s,neutral.settings,index==i) else panel(q,s,{.32,.9,1},index==i,.55) end
      text(row.label,q.x+12*s,q.y+11*s,q.w*.46,13*s)
      text('‹ '..row.value..' ›',q.x+q.w*.49,q.y+11*s,q.w*.48,13*s)
      targets[#targets+1]=q
    end
    local close={x=r.x+16*s,y=r.y+r.h-48*s,w=r.w-32*s,h=34*s}
    if layout.neutral then solid(close,s,neutral.settings,false) else panel(close,s,{.32,.9,1},false,.6) end
    text('A / B / SELECT · voltar',close.x+12*s,close.y+9*s,close.w-24*s,13*s)
    return {rows=targets,close=close}
  end
  return V
end
