-- Geometry in window coordinates; move indices always remain native slots.
local L={}
local function slots(moves)
  local ids={}
  for i=1,4 do if moves==nil or (moves[i] and moves[i]~=0) then ids[#ids+1]=i end end
  return ids
end
function L.compute(w,h,style,factor,selected,options)
  options=options or {};style=style or 'layers'
  local s=math.min(w/1280,h/720)*(factor or .68)/.68
  s=math.min(s,w/820,h/680)
  local pad=24*s
  if style=='commands' then
    local base=math.min(w/1280,h/720)
    local factor=tonumber(options.commandScale) or 1
    if factor~=.75 and factor~=1 and factor~=1.25 and factor~=1.5 then factor=1 end
    s=math.min(base*factor,(w-24*base)/320,(h-24*base)/92)
    local gx,gy=w-24*base-320*s,h-24*base-92*s
    local rects={}
    for i=1,4 do
      local commands=options.commandStage~='moves'
      if commands or options.moves and options.moves[i] then
        rects[#rects+1]={x=gx+((i-1)%2)*170*s,y=gy+math.floor((i-1)/2)*52*s,
          w=150*s,h=40*s,scale=s,alpha=1,depth=0,index=i,
          kind=commands and 'menu' or 'move',classic=true,commandDeck=true}
      end
    end
    return {style=style,scale=s,x=gx,y=gy,w=320*s,h=92*s,rects=rects,width=w,height=h,
      commandCenter={x=gx+160*s,y=gy+46*s},
      settings={x=w-24*base-190*base,y=24*base,w=190*base,h=42*base,kind='settings'},
      message={x=(w-math.min(w-48*base,700*base))/2,y=h-124*base,w=math.min(w-48*base,700*base),h=100*base}}
  end
  local playerHud={x=w-pad-330*s,y=h-pad-220*s,w=330*s,h=112*s}
  local enemyHud={x=pad,y=pad,w=330*s,h=88*s}
  local rects={};local ids=slots(options.moves);local ordinal=1
  for n,i in ipairs(ids) do if i==selected then ordinal=n end end
  local x=pad+12*s;local y=214*s
  -- Native enemy box occupies y=14..46 of the 160-line game plane.
  -- Keep the animated bag badge and cards below it at every aspect ratio.
  if options.nativeHud then y=math.max(y,h*46/160+96*s) end
  local groupW=360*s
  if options.position=='right' then
    x=w-pad-12*s-groupW
    enemyHud.x=w-pad-enemyHud.w;playerHud.x=pad
  end
  local function add(r) rects[#rects+1]=r end
  local bottom=y
  if style=='grid' or style=='stack' then
    -- Retained for historical previews and backwards-compatible consumers.
    for i=1,4 do
      local list=style=='stack'
      add({x=x+(list and 0 or ((i-1)%2)*184*s),y=y+(list and (i-1)*50*s or math.floor((i-1)/2)*100*s),
        w=(list and 360 or 176)*s,h=(list and 44 or 88)*s,scale=s,alpha=1,depth=0,kind='move',index=i})
    end
    bottom=y+200*s
  elseif style=='list' then
    for n,i in ipairs(ids) do
      local depth=(n-ordinal)%#ids
      add({x=x,y=y+(n-1)*56*s,w=360*s,h=50*s,scale=s,alpha=depth==0 and 1 or (depth==1 and .5 or .25),depth=depth,kind='move',index=i})
    end
    bottom=y+#ids*56*s
  else
    -- Back to front. Selected card is always last, including when wrapping.
    local frontY=y+math.max(0,#ids-1)*30*s
    for depth=#ids-1,0,-1 do
      local i=ids[(ordinal+depth-1)%#ids+1];local k=1-depth*.055
      add({x=x+depth*22*s,y=frontY-depth*30*s,w=330*s*k,h=94*s*k,scale=s*k,
        alpha=depth==0 and 1 or (depth==1 and .5 or .25),depth=depth,angle=-.025+depth*.022,kind='move',index=i})
    end
    bottom=frontY+94*s
  end
  local bag={x=x,y=y-78*s,w=220*s,h=54*s,kind='menu',index=3}
  local party={x=x,y=bottom+26*s,w=240*s,h=54*s,kind='menu',index=2}
  local run={x=options.position=='right' and pad or w-pad-220*s,y=h-pad-60*s,w=220*s,h=54*s,kind='menu',index=4}
  local commandCenter
  if options.classicButtons then
    local gx=options.position=='right' and pad or w-pad-320*s
    local gy=h-pad-92*s
    local function command(index,col,row)
      add({x=gx+col*170*s,y=gy+row*52*s,w=150*s,h=40*s,kind='menu',index=index,classic=true})
    end
    command(1,0,0);command(2,1,0);command(3,0,1);command(4,1,1)
    commandCenter={x=gx+160*s,y=gy+46*s}
  else add(bag);add(party);add(run) end
  if options.classicColors then for _,r in ipairs(rects) do if r.kind=='menu' then r.classic=true end end end
  local mw=math.min(w-pad*2,700*s)
  return {commandCenter=commandCenter,style=style,scale=s,x=x,y=y,w=groupW,h=bottom-y,rects=rects,
    enemyHud=enemyHud,playerHud=playerHud,
    settings={x=options.position=='right' and pad or w-pad-190*s,y=pad,w=190*s,h=42*s,kind='settings'},
    message={x=(w-mw)/2,y=h-pad-100*s,w=mw,h=100*s},width=w,height=h}
end
function L.actionBadge(r,s)
  local d=r.h+12*s
  return {x=r.x-6*s,y=r.y-6*s,d=d}
end
function L.contains(r,x,y)
  if not r then return false end
  if r.angle then
    local dx,dy=x-r.x-r.w/2,y-r.y-r.h/2
    local c,t=math.cos(r.angle),math.sin(r.angle)
    x,y=r.x+r.w/2+dx*c+dy*t,r.y+r.h/2-dx*t+dy*c
  end
  if r.classic then
    local cx=r.index==1 or r.index==3
    local cy=r.index==1 or r.index==2
    local dx=cx and r.x+r.w-x or x-r.x
    local dy=cy and r.y+r.h-y or y-r.y
    if dx+dy<r.h*.45 then return false end
  end
  return x>=r.x and y>=r.y and x<=r.x+r.w and y<=r.y+r.h
end
function L.hit(layout,x,y)
  if not layout then return end
  if L.contains(layout.settings,x,y) then return layout.settings end
  for i=#layout.rects,1,-1 do
    local r=layout.rects[i]
    if r.kind=='menu' and not r.classic then
      local b=L.actionBadge(r,layout.scale)
      if (x-b.x-b.d/2)^2+(y-b.y-b.d/2)^2<=(b.d/2)^2 then return r end
    end
    if L.contains(r,x,y) then return r end
  end
end
return L
