-- Optional four-command deck; presentation only, no battle actions.
return function()
 local C={}
 local colors={[1]={.78,.12,.15},[2]={.12,.55,.20},[3]={.86,.49,.08},[4]={.12,.34,.78}}
 function C.button(r,s,selected,Icons)
  local g=love.graphics;local x,y,w,h=r.x,r.y,r.w,r.h;local n=18*s
  local vertices={}
  -- The inward corner leaves room for the shared central diamond.
  local corners={{x,y},{x+w,y},{x+w,y+h},{x,y+h}}
  local inward=({[1]=3,[2]=4,[3]=2,[4]=1})[r.index]
  for i,p in ipairs(corners) do
   local prev=corners[(i+2)%4+1];local after=corners[i%4+1]
   local k=i==inward and n or 3*s
   local function toward(other)
    local dx,dy=other[1]-p[1],other[2]-p[2];local length=math.sqrt(dx*dx+dy*dy)
    vertices[#vertices+1]=p[1]+dx/length*k;vertices[#vertices+1]=p[2]+dy/length*k
   end
   toward(prev);toward(after)
  end
  local color=colors[r.index]
  g.setColor(color[1],color[2],color[3],1);g.polygon('fill',vertices)
  g.setColor(.025,.09,.075,1);g.setLineWidth(4*s);g.polygon('line',vertices)
  g.setColor(selected and 1 or .8,selected and .9 or .88,selected and .4 or .8,selected and 1 or .5)
  g.setLineWidth((selected and 2 or .8)*s);g.polygon('line',vertices)
  -- Muted function silhouettes sit at the outside edge, away from the notch.
  local cx=x+w-24*s;local cy=y+h/2
  if r.index==1 or r.index==3 then cx=x+24*s end
  g.setColor(1,1,1,.38)
  if r.index==1 then
   g.setLineWidth(4*s);g.line(cx-8*s,cy+8*s,cx+7*s,cy-7*s);g.line(cx-7*s,cy-8*s,cx+8*s,cy+7*s)
   g.setLineWidth(2*s);g.line(cx-11*s,cy+2*s,cx-2*s,cy+11*s);g.line(cx+2*s,cy-11*s,cx+11*s,cy-2*s)
  elseif r.index==2 then
   g.setLineWidth(2.5*s);g.circle('line',cx,cy,10*s);g.line(cx-10*s,cy,cx+10*s,cy);g.circle('fill',cx,cy,3*s)
  else Icons.action(r.index,cx,cy,12*s) end
 end
 function C.center(r,s)
  local g=love.graphics;local x,y=r.x,r.y;local radius=16*s
  g.setColor(.035,.13,.105,1);g.polygon('fill',x,y-radius,x+radius,y,x,y+radius,x-radius,y)
  g.setColor(.12,.32,.22,1);g.setLineWidth(3*s);g.polygon('line',x,y-radius,x+radius,y,x,y+radius,x-radius,y)
 end
 return C
end
