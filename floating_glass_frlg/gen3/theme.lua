-- Presentation-only palette shared by owned HD screens and native-frame bridge.
return function()
  local function rgb(h) return {tonumber(h:sub(1,2),16)/255,tonumber(h:sub(3,4),16)/255,tonumber(h:sub(5,6),16)/255,1} end
  local T={outline=rgb('10141D'),ivory=rgb('FFF8E5'),gold=rgb('FFD36B'),ink=rgb('171F2E'),muted=rgb('C2C9D5')}
  T.roles={base={rgb('303B50'),rgb('171F2E')},settings={rgb('3B4254'),rgb('1C2231')},
    bag={rgb('E8C77D'),rgb('846A3B'),light=true},party={rgb('AFC9E8'),rgb('577AA3'),light=true},
    exit={rgb('E7A6A0'),rgb('9D5555'),light=true}}
  function T.role(label,art)
    local s=tostring(art or label or ''):upper()
    if s:find('BAG') or s:find('POCKET') or s:find('MOCHILA') then return 'bag' end
    if s:find('POKEMON') or s:find('POKÉMON') or s:find('PARTY') then return 'party' end
    if s:find('CLOSE') or s:find('CANCEL') or s=='NO' or s:find('BACK') or s:find('EXIT') then return 'exit' end
    if s:find('OPTION') or s:find('MODS') or s:find('SETTING') then return 'settings' end
    return 'base'
  end
  function T.panel(x,y,w,h,selected,role,unit,radius)
    local g=love.graphics;unit=unit or 1;radius=radius or 14*unit
    local p=T.roles[role or 'base'] or T.roles.base
    g.setColor(p[1]);g.rectangle('fill',x,y,w,h,radius,radius)
    g.setColor(T.outline);g.setLineWidth(4*unit);g.rectangle('line',x,y,w,h,radius,radius)
    g.setColor(p[2]);g.setLineWidth(1.5*unit);g.rectangle('line',x+unit,y+unit,w-2*unit,h-2*unit,radius,radius)
    if selected then
      g.setColor(T.gold);g.setLineWidth(2*unit)
      g.rectangle('line',x-2*unit,y-2*unit,w+4*unit,h+4*unit,radius,radius)
    end
  end
  return T
end
