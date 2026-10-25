-- Optional presentation skin. No game actions, state writes or sprite transforms.
return function()
 local S={fonts={},canvases={}}
 local function rgb(hex) return {tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255,1} end
 S.colors={green=rgb('366B5A'),lit=rgb('3B7663'),ivory=rgb('FFFFDE'),hp=rgb('FFF6DC'),gold=rgb('E5AF2C'),wine=rgb('642333'),red=rgb('D62630'),dark=rgb('111C1D'),shade=rgb('173C33'),shine=rgb('4A8675'),metal=rgb('D8CFA5'),white=rgb('F7F7F2'),ink=rgb('102027'),normal=rgb('B6B0A4'),healthy=rgb('48EC58'),mid=rgb('F5C344'),critical=rgb('EA4545'),exp=rgb('F0B72D'),cyan=rgb('15BFD1')}
 local original=S.colors
 local native={green=rgb('526B63'),lit=rgb('7B9484'),ivory=rgb('FFFFDE'),hp=rgb('FFFFDE'),gold=rgb('FFE68C'),wine=rgb('A542A5'),red=rgb('EF3100'),dark=rgb('293A42'),shade=rgb('3A5242'),shine=rgb('9CDEDE'),metal=rgb('DED6B5'),white=rgb('FFFFFF'),ink=rgb('293A42'),normal=rgb('ADAD7B'),healthy=rgb('7BCE52'),mid=rgb('FFB510'),critical=rgb('EF3100'),exp=rgb('6B94F7'),cyan=rgb('3A6B8C')}
 local c=S.colors
 function S.configure(enabled)S.native=enabled==true;c=S.native and native or original;S.colors=c end
 -- Closest original Emerald menu swatches; Fairy remains available with expansion mods.
 local swatches={NORMAL='ADAD7B',FIRE='F78431',WATER='4A84FF',GRASS='7BCE52',ELECTRIC='FFB510',ICE='9CDEDE',FIGHTING='EF3100',POISON='A542A5',GROUND='BDA53A',FLYING='6B94F7',PSYCHIC='FF5A8C',BUG='DEE631',ROCK='BD9C5A',GHOST='636373',DRAGON='D66BFF',DARK='424242',STEEL='A5A5A5',FAIRY='FF5A8C'}
 function S.commandColor(i)return i==1 and native.red or i==3 and native.gold or i==4 and native.wine or native.green end
 function S.typeColor(id,fallback)if S.native then return rgb(swatches[tostring(id):upper()]or 'ADAD7B')end;return fallback end
 local function color(v,a) love.graphics.setColor(v[1],v[2],v[3],a or 1) end
 local function shape(r,inset,dy)
  inset=inset or 0;dy=dy or 0
  local x,y,w,h=r.x+inset,r.y+inset+dy,r.w-2*inset,r.h-2*inset
  local k=math.min(h*.24,12*(r.unit or 1))
  return {x+k,y,x+w-k,y,x+w,y+k,x+w,y+h-k,x+w-k,y+h,x+k,y+h,x,y+h-k,x,y+k}
 end
 function S.panel(r,s,role,selected,typeColor)
  local g=love.graphics;r.unit=s
  local hp=role=='hp';local top=hp and c.hp or role=='run' and c.wine or c.lit
  local bottom=hp and c.hp or role=='run' and rgb('421622') or c.shade
  if S.native and not hp then top=role=='run'and c.wine or c.green;bottom=top end
  if role=='move' and typeColor then
   top={typeColor[1],typeColor[2],typeColor[3]}
   bottom=S.native and top or {typeColor[1]*.42,typeColor[2]*.42,typeColor[3]*.42}
  end
  -- Approved darker variant: dim only green panel bodies, preserve accents.
  if not S.native and not hp and role~='run' then
   top={top[1]*.5,top[2]*.5,top[3]*.5}
   bottom={bottom[1]*.5,bottom[2]*.5,bottom[3]*.5}
  end
  color(rgb('050A09'),.4);g.polygon('fill',shape(r,0,5*s))
  color(bottom);g.polygon('fill',shape(r))
  -- Insets follow the chamfer, keeping every gradient strip within the panel.
  local chamfer=math.min(r.h*.24,12*s)
  for j=0,31 do
   local t=j/31;local y=r.h*j/32;local h=r.h/32+.1*s
   local edge=math.max(0,chamfer-math.min(y,r.h-y-h))
   g.setColor(top[1]*(1-t)+bottom[1]*t,top[2]*(1-t)+bottom[2]*t,top[3]*(1-t)+bottom[3]*t,1)
   g.rectangle('fill',r.x+edge,r.y+y,r.w-2*edge,h)
  end
  color(c.dark);g.setLineWidth(3*s);g.polygon('line',shape(r))
  color(selected and {1,1,1} or c.metal);g.setLineWidth(1.2*s);g.polygon('line',shape(r,2*s))
  color(c.ivory,.3);g.setLineWidth(s);g.line(r.x+chamfer,r.y+4*s,r.x+r.w-chamfer,r.y+4*s)
  for i=0,2 do color(c.ivory,.4+i*.3);g.rectangle('fill',r.x+r.w-(13+i*7)*s,r.y+r.h-10*s,4*s,4*s) end
  if selected then
   color({1,1,1});local x,y=r.x-9*s,r.y+r.h/2
   g.polygon('fill',x-5*s,y-5*s,x+1*s,y,x-5*s,y+5*s)
  end
 end
 function S.ball(x,y,r,ultra)
  local g=love.graphics
  color(c.dark);g.circle('fill',x,y,r)
  color(c.white);g.circle('fill',x,y,r*.83)
  local points={x-r*.83,y}
  for i=0,20 do local a=math.pi+i/20*math.pi;points[#points+1]=x+math.cos(a)*r*.83;points[#points+1]=y+math.sin(a)*r*.83 end
  color(ultra and c.dark or c.red);g.polygon('fill',points)
  if ultra then
   color(c.gold);g.rectangle('fill',x-r*.51,y-r*.58,r*.23,r*.51);g.rectangle('fill',x+r*.28,y-r*.58,r*.23,r*.51)
  end
  color(c.dark);g.setLineWidth(r*.15);g.line(x-r*.83,y,x+r*.83,y);g.circle('fill',x,y,r*.3)
  color(c.white);g.circle('fill',x,y,r*.17)
 end
 function S.badge(index,x,y,d,Icons)
  local g=love.graphics;local r=d/2;local cx,cy=x+r,y+r
  color(c.dark,.45);g.circle('fill',cx,cy+3,r+2)
  color(c.dark);g.circle('fill',cx,cy,r)
  color(c.metal);g.setLineWidth(math.max(1,d*.025));g.circle('line',cx,cy,r-1)
  local fill=index==3 and c.gold or index==4 and c.red or c.dark
  color(fill);g.circle('fill',cx,cy,r*.85)
  color(c.ivory,.25);g.arc('line','open',cx,cy,r*.76,-2.8,-.5)
  if index==2 then S.ball(cx,cy,r*.62,false)
  else
   color(c.dark,.6);Icons.action(index,cx+1,cy+2,d*.25)
   color(c.white);Icons.action(index,cx,cy,d*.25)
  end
 end
 function S.text(str,x,y,size,ink)
  local g=love.graphics;size=math.max(1,math.floor(size+.5))
  if not S.fonts[size] then S.fonts[size]=g.newFont(size) end
  g.setFont(S.fonts[size]);color(ink or c.ink);g.print(tostring(str or ''),x,y)
 end
 function S.hud(mon,player,x,y,w,h,Icons)
  local g=love.graphics;g.push('all');g.translate(x,y);g.scale(w/416,h/(player and 148 or 116))
  S.panel({x=0,y=0,w=416,h=player and 148 or 116},1,'hp',false)
  S.ball(27,30,19,true)
  local name=tostring(mon.name or mon.species or '')
  local gender=name:find('♀',1,true) and '♀' or name:find('♂',1,true) and '♂'
  name=name:gsub('♀',''):gsub('♂',''):gsub('%s+$','')
  -- Fit names instead of baking or truncating dynamic text into artwork.
  local size=23
  repeat
   if not S.fonts[size] then S.fonts[size]=g.newFont(size) end
   local f=S.fonts[size];if not f.getWidth or f:getWidth(name)<=230 or size<=12 then break end
   size=size-1
  until false
  S.text(name,52,15,size)
  if gender then Icons.gender(gender,300,29,10,gender=='♀' and rgb('EF414B') or rgb('11C4E0')) end
  S.text('Lv'..tostring(mon.level or '?'),326,17,20)
  S.text('HP',52,59,19,c.shade)
  color(c.dark);g.rectangle('fill',90,61,296,18,5,5)
  local max=math.max(1,tonumber(mon.maxHp) or 1);local ratio=math.max(0,math.min(1,(tonumber(mon.hp) or 0)/max))
  color(ratio>.5 and c.healthy or ratio>.2 and c.mid or c.critical)
  g.rectangle('fill',93,64,290*ratio,12,3,3)
  if player then
   S.text(tostring(mon.hp or '?')..' / '..tostring(mon.maxHp or '?'),237,84,23)
   S.text('EXP',24,119,15,c.cyan)
   color(c.dark);g.rectangle('fill',72,123,313,8,2,2)
   color(c.exp);g.rectangle('fill',73,124,311*math.max(0,math.min(1,tonumber(mon.expFraction) or 0)),6,2,2)
  end
  -- Ailment information stays visible; no translated Portuguese status strings.
  if mon.status and mon.status~='NONE' and mon.status~='0' then S.text(mon.status,52,player and 87 or 88,14,c.wine) end
  g.pop()
 end
 -- Composite a complete card before applying opacity, including borders/text.
 function S.group(key,r,alpha,draw)
  local g=love.graphics
  if alpha>=1 or not (g.newCanvas and g.setCanvas and g.getCanvas and g.origin and g.clear and g.setBlendMode) then return draw() end
  local pad=24*(r.scale or 1);local w,h=math.ceil(r.w+pad*2),math.ceil(r.h+pad*2)
  local cached=S.canvases[key]
  if not cached or cached.w~=w or cached.h~=h then
   if cached and cached.canvas.release then cached.canvas:release() end
   cached={canvas=g.newCanvas(w,h),w=w,h=h};S.canvases[key]=cached
  end
  local target={g.getCanvas()};g.push('all')
  local ok,err=pcall(function()
   g.setCanvas(cached.canvas);if g.setShader then g.setShader() end;g.origin();g.setScissor();g.clear(0,0,0,0);g.setBlendMode('alpha');g.translate(pad-r.x,pad-r.y);draw()
  end)
  g.setCanvas((table.unpack or unpack)(target));g.pop()
  if not ok then error(err,0) end
  g.push('all');g.setBlendMode('alpha','premultiplied');g.setColor(alpha,alpha,alpha,alpha)
  g.draw(cached.canvas,r.x-pad,r.y-pad);g.pop()
 end
 function S.shutdown()
  for _,v in pairs(S.canvases) do if v.canvas.release then v.canvas:release() end end
  S.canvases={}
 end
 return S
end
