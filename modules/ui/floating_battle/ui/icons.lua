-- Vector redraws following the white-on-color pictograms in the reference.
local I={}
function I.gender(mark,x,y,r)
  local g=love.graphics
  local old=g.getLineWidth and g.getLineWidth() or 1
  g.setLineWidth(math.max(1,r*.18))
  if mark=='♀' then
    g.setColor(1,.51,.70,1);g.circle('line',x,y-r*.30,r*.50)
    g.line(x,y+r*.20,x,y+r*.95);g.line(x-r*.32,y+r*.60,x+r*.32,y+r*.60)
  else
    g.setColor(.45,.77,1,1);g.circle('line',x-r*.14,y+r*.10,r*.50)
    g.line(x+r*.20,y-r*.24,x+r*.77,y-r*.81)
    g.line(x+r*.77,y-r*.81,x+r*.28,y-r*.81)
    g.line(x+r*.77,y-r*.81,x+r*.77,y-r*.32)
  end
  g.setLineWidth(old)
end
function I.caught(x,y,r)
  local g=love.graphics
  g.setColor(.95,.96,.98,1);g.circle('fill',x,y,r)
  local points={x-r,y}
  for i=0,16 do
    local a=math.pi+math.pi*i/16
    points[#points+1]=x+math.cos(a)*r;points[#points+1]=y+math.sin(a)*r
  end
  g.setColor(.94,.20,.25,1);g.polygon('fill',points)
  g.setColor(.07,.12,.18,1);g.setLineWidth(math.max(1,r*.18))
  g.circle('line',x,y,r);g.line(x-r,y,x+r,y)
  g.circle('fill',x,y,r*.38)
  g.setColor(.98,.99,1,1);g.circle('fill',x,y,r*.21)
end
function I.type(id,x,y,r)
  local g=love.graphics;id=tostring(id or ''):upper();g.setLineWidth(math.max(1,r*.16))
  local function polygon(points,mode)
    local out={};for i=1,#points,2 do out[#out+1]=x+points[i]*r;out[#out+1]=y+points[i+1]*r end
    g.polygon(mode or 'fill',out)
  end
  if id=='NORMAL' then
    g.setLineWidth(r*.25);g.circle('line',x,y,r*.52)
  elseif id=='GRASS' then
    polygon({0,.72,-.17,.26,-.60,.09,-.67,-.50,-.15,-.17,0,-.74,.26,-.29,.65,-.49,.60,.10,.16,.30})
    g.line(x,y+r*.66,x,y-r*.38)
  elseif id=='DRAGON' then
    polygon({-.57,.66,-.48,.31,-.09,.12,-.31,-.10,-.54,-.10,-.35,-.42,-.09,-.39,.07,-.75,.24,-.43,.63,-.27,.34,.04,.58,.22,.45,.57,.12,.71,-.04,.41,-.26,.47,-.22,.72})
  elseif id=='BUG' then
    g.ellipse('fill',x-r*.30,y-r*.25,r*.28,r*.42);g.ellipse('fill',x+r*.30,y-r*.25,r*.28,r*.42)
    g.ellipse('fill',x-r*.28,y+r*.36,r*.24,r*.30);g.ellipse('fill',x+r*.28,y+r*.36,r*.24,r*.30)
    g.line(x,y-r*.35,x,y+r*.57);g.line(x-r*.1,y-r*.36,x-r*.30,y-r*.72);g.line(x+r*.1,y-r*.36,x+r*.30,y-r*.72)
  elseif id=='PSYCHIC' then
    local lastX,lastY
    for i=0,64 do local a=-.8+i/64*math.pi*4.7;local radius=r*(.68-.61*i/64);local px,py=x+math.cos(a)*radius,y+math.sin(a)*radius
      if lastX then g.line(lastX,lastY,px,py) end;lastX,lastY=px,py
    end
  elseif id=='FAIRY' then
    polygon({0,-.75,.19,-.25,.70,-.17,.33,.20,.42,.73,0,.45,-.42,.73,-.33,.20,-.70,-.17,-.19,-.25})
    g.circle('line',x,y,r*.22)
  elseif id=='WATER' then
    g.circle('fill',x,y+r*.23,r*.44);polygon({0,-.75,-.40,.04,.40,.04})
  elseif id=='FIRE' then
    polygon({-.56,.35,-.34,-.21,-.27,-.60,-.06,-.24,.25,-.79,.24,-.24,.57,.24,.43,.59,0,.76,-.40,.61})
  elseif id=='ELECTRIC' then
    polygon({.13,-.80,-.53,.06,-.04,.06,-.17,.80,.53,-.18,.05,-.18})
  elseif id=='ICE' then
    for i=0,5 do
      local a=i*math.pi/3;local ux,uy=math.cos(a),math.sin(a)
      g.line(x,y,x+ux*r*.73,y+uy*r*.73)
      local bx,by=x+ux*r*.49,y+uy*r*.49
      g.line(bx,by,bx+math.cos(a+2.3)*r*.22,by+math.sin(a+2.3)*r*.22)
    end
  elseif id=='FLYING' then
    polygon({-.68,.56,-.37,-.20,.10,-.60,.76,-.57,.39,-.17,-.04,-.03,.30,.03,.04,.32,-.35,.35})
  elseif id=='FIGHTING' then
    polygon({-.54,.26,-.56,-.24,-.31,-.45,-.13,-.36,.05,-.55,.30,-.42,.53,-.26,.51,.26,.26,.56,-.28,.56})
  elseif id=='POISON' then
    g.circle('fill',x,y+r*.05,r*.49);g.circle('fill',x-r*.37,y-r*.46,r*.20);g.circle('fill',x+r*.31,y-r*.52,r*.18)
    polygon({-.30,.29,-.27,.73,.26,.73,.32,.29})
  elseif id=='GROUND' then
    polygon({-.72,.57,-.22,-.47,.23,-.47,.75,.57});g.line(x-r*.65,y+r*.73,x+r*.65,y+r*.73)
  elseif id=='ROCK' then
    polygon({-.72,.37,-.48,-.41,.03,-.65,.69,-.31,.73,.33,.30,.66,-.35,.60})
  elseif id=='STEEL' then
    polygon({-.66,-.34,0,-.73,.66,-.34,.66,.34,0,.73,-.66,.34},'line');g.circle('line',x,y,r*.3)
  elseif id=='GHOST' then
    g.circle('fill',x,y-r*.15,r*.52);polygon({-.52,-.12,-.60,.66,-.21,.47,.04,.70,.30,.45,.63,.57,.51,-.12})
  elseif id=='DARK' then
    g.setLineWidth(r*.28);g.arc('line','open',x,y,r*.55,.52,math.pi*1.86)
  else
    g.circle('line',x,y,r*.54);g.line(x-r*.2,y-r*.2,x+r*.2,y+r*.2);g.line(x+r*.2,y-r*.2,x-r*.2,y+r*.2)
  end
end
function I.action(kind,x,y,r)
  local g=love.graphics;g.setLineWidth(math.max(1,r*.14))
  if kind==3 then
    g.rectangle('line',x-r*.52,y-r*.2,r*1.04,r*.82,r*.12,r*.12)
    g.arc('line','open',x,y-r*.2,r*.29,math.pi,math.pi*2)
  elseif kind==2 then
    g.arc('line','open',x,y,r*.55,-.4,2.4);g.arc('line','open',x,y,r*.55,2.75,5.55)
    g.line(x-r*.50,y+r*.30,x-r*.72,y+r*.12);g.line(x+r*.52,y-r*.25,x+r*.73,y-r*.06)
  elseif kind==4 then
    g.circle('fill',x+r*.14,y-r*.59,r*.17)
    g.line(x+r*.05,y-r*.24,x-r*.16,y+r*.19,x-r*.58,y+r*.57)
    g.line(x-r*.16,y+r*.19,x+r*.3,y+r*.31,x+r*.48,y+r*.65)
    g.line(x-r*.04,y-r*.14,x+r*.50,y-r*.10);g.line(x-r*.02,y-r*.12,x-r*.44,y-r*.35)
  else
    g.line(x-r*.50,y-r*.52,x+r*.50,y+r*.52);g.line(x+r*.50,y-r*.52,x-r*.50,y+r*.52)
  end
end
return I
