-- Presentation only: fixed scene scale plus an independent foreground anchor.
return function(R)
 local C={}
 function C.mode()
  local value=R.option('battle_camera','native')
  return ({current='original',native_depth='foreground',g9_compat='g9',native='native'})[value] or 'native'
 end
 function C.depth() return C.mode()=='foreground' end
 function C.compat() return C.mode()=='g9' end
 function C.native() return C.mode()=='native' end
 function C.hudAdjustment()
  local mode=C.mode();if mode=='original' or mode=='g9' then return .8,-5 end
  return 1,0
 end
 function C.ground(key)
  -- Ground profile of the Original composition, matching the supplied native
  -- Torchic/Poochyena reference. This is presentation, never ROM coordinates.
  if key=='player' then return 72,108 end
  if key=='enemy' then return 176,64 end
 end
 -- The foreground ally is translated independently; never infer a zoom
 -- from its size or from the distance to the enemy.
 function C.spriteOffset(anchors,key,st)
  if not st or st.double or not (C.depth() or C.compat()) then return 0,0 end
  if key~='player' and key~='enemy' then return 0,0 end
  local battler=st[key]
  if anchors.state~=st or anchors.owners[key]~=(battler and battler.mon) then return 0,0 end
  local b=anchors.fixed[key] or anchors.ready[key] and anchors.bounds[key]
  local plan=anchors.cameraPlan
  if not b or not plan then return 0,0 end
  if C.compat() then
   if not anchors.sources or anchors.sources[key]=='native' or not anchors.sources[key] then return 0,0 end
   local foot=anchors.fixedRest and anchors.fixedRest[key] or anchors.rest and anchors.rest[key]
   local bx,by=foot and foot.x or (b.l+b.r)/2,foot and foot.y or b.b
   local x,y=C.ground(key)
   local elevation=R.battle and R.battle.elevation and R.battle.elevation(key) or 0
   return (plan.x+plan.k*x-bx)/plan.k,(plan.y+plan.k*(y+plan.drop-elevation)-by)/plan.k
  end
  if key~='player' then return 0,0 end
  local D=R.module and R.module('src.core.game3.display')
  local h
  if love.graphics.getDimensions then local _,height=love.graphics.getDimensions();h=height end
  if D and D.fit then local _,_,_,_,ph=D.fit();if ph and ph>0 then h=ph end end
  if not h or h<=0 then return 0,0 end
  return (240*.35-(b.l+b.r)/2)/plan.k,(160+160/h-b.b)/plan.k
 end
 function C.activeOffset(anchors,key)
  local B=R.battle
  if not B or not B.owns or not B.owns() then return 0,0 end
  return C.spriteOffset(anchors,key,B.context())
 end
 -- Native animation endpoints use the same translated ally coordinates.
 -- Copy return values; never overwrite the native coordinate tables, animation
 -- presentation objects, VM overrides, battle state or any gameplay action.
 C.seen=setmetatable({},{__mode='k'})
 function C.installLoaded()
  local A=R.module('src.core.game3.battle.anim_coords')
  if not A or C.seen[A] then return end
  C.seen[A]=true
  R.wrap(A,'coords',function(next,st,key)
   local value=next(st,key)
   if not value or not A.idOf then return value end
   local id=A.idOf(key);if id~=0 and id~=1 then return value end
   local dx,dy=C.activeOffset(R.battle.anchors,id==0 and 'player' or 'enemy')
   if dx==0 and dy==0 then return value end
   local result={};for k,v in pairs(value) do result[k]=v end
   result.x,result.y=value.x+dx,value.y+dy
   result[1],result[2]=result.x,result.y
   return result
  end)
 end
 function C.plan(st,selected,drop)
  if C.native() then return {x=0,y=0,k=1,drop=0,signature='native-'..(st and st.double and 'double' or 'single')} end
  if C.depth() then
   if st and st.double then return {x=8,y=28,k=1,drop=drop,signature='depth-double'} end
   return {x=-8,y=16,k=1.05,drop=drop,signature='depth-single'}
  end
  if st and st.double then return {x=0,y=0,k=1,drop=0,signature='native-double'} end
  if selected=='forest' then return {x=24,y=32,k=.8,drop=drop,signature=C.compat() and 'g9-forest' or 'current-forest'} end
  return {x=0,y=0,k=1,drop=drop,signature=C.compat() and 'g9' or 'current'}
 end
 function C.apply(plan)
  local g=love.graphics;g.translate(plan.x,plan.y);g.scale(plan.k,plan.k);g.translate(0,plan.drop)
 end
 function C.hud(side,w,h,bw,bh,double)
  local player=side=='player' or type(side)=='number' and side%2==0
  local slot=type(side)=='number' and math.floor(side/2) or 0
  local gap=math.max(4,h*.012);local x,y
  if player then x=w*(double and .43 or .52);local row=double and 1-slot or slot;y=h-bh-gap-row*(bh+gap)
  else x=gap+slot*w*.075;y=gap+slot*(bh+gap) end
  return math.max(0,math.min(w-bw,x)),math.max(0,math.min(h-bh,y))
 end
 return C
end
