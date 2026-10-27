-- Battle-only presentation; native Choice handles cursor, input and callbacks.
return function(R,Skin)
 local Q={}
 function Q.active()
  if Q.failed or R.unloaded or not R.glass()or not R.option('battle',true)then return false end
  local b=R.module('src.core.game3.battle.init')or R.module('src.core.game3.battle')
  local c=R.module('src.ui.game3.choice');local stack=R.module('src.ui.game3.stack')
  return b and b.isActive and b.isActive()and c and c.active and c.kind=='yesno'and c.style=='battle'and not(stack and stack.busy and stack.busy())
 end
 function Q.observe()
  local b=R.module('src.core.game3.battle.init')or R.module('src.core.game3.battle')
  local st=b and b.getState and b.getState()
  if st~=Q.state then Q.state=st;Q.page=nil;Q.limit=nil end
  local m=R.module('src.ui.game3.message')
  if m and m._frame=='battle'and m.currentPage then
   local page=m.currentPage();if type(page)=='string'and page:match('%S')then Q.page=page;Q.limit=m._revealed end
  end
  -- Shift mode closes Message before opening Yes/No. Use the exact native
  -- dialogue log (already ROM/mod translated), never a hard-coded question.
  if b and b._phase=='shift_prompt' then
   local ui=R.module('src.core.game3.battle.ui')
   local log=ui and ui.log and ui.log()
   local text=type(log)=='table'and log[#log]
   if type(text)=='string'and text:match('%S')then Q.page=text;Q.limit=nil end
  end
 end
 function Q.layout(w,h)
  local portrait=h>w;local u=math.min(w/1280,h/720)
  local width=math.min(w*.94,1000*u);local height=math.max(100*u,h*(portrait and .16 or .16))
  local x=(w-width)/2;local y=h*(portrait and .61 or .78)
  if y+height>h*.94 then y=h*.94-height end
  local cw=width*.20;local gap=12*u
  return {message={x=x,y=y,w=width-cw-gap,h=height},rows={{x=x+width-cw,y=y,w=cw,h=(height-gap)/2,index=1},{x=x+width-cw,y=y+(height+gap)/2,w=cw,h=(height-gap)/2,index=2}},unit=u,w=w,h=h}
 end
 function Q.draw(w,h)
  if not Q.active()then Q.targets=nil;return end
  Q.observe();local c=R.module('src.ui.game3.choice');local m=R.module('src.ui.game3.message')
  local f=R.module('src.ui.game3.frlg_font');if not f or not f.draw then return end
  local l=Q.layout(w,h);local g=love.graphics;local glass=R.option('battle_menu_skin','crystal_glass')=='crystal_glass'
  Skin.configure(R.option('battle_menu_skin','crystal_glass')=='emerald_gba',glass)
  g.push('all');g.origin();g.setShader();g.setScissor(0,0,w,h)
  local ok,err=pcall(function()
   local r=l.message
   g.setColor(0,.015,.035,.24);g.rectangle('fill',r.x+l.unit*3,r.y+l.unit*5,r.w,r.h,12*l.unit,12*l.unit)
   Skin.panel(r,l.unit,'auxiliary',false)
   local page=Q.page or ''
   if m and m.currentPage then local p=m.currentPage();if type(p)=='string'and p:match('%S')then page=p end end
   local k=math.min(2*l.unit,(r.w-28*l.unit)/224,(r.h-20*l.unit)/42)
   g.push('all');g.translate(r.x+14*l.unit,r.y+10*l.unit);g.scale(k,k)
   local rendered,why=pcall(f.draw,page,0,0,{maxWidth=(r.w-28*l.unit)/k,colors=glass and f.COLOR.NORMAL or f.COLOR.WHITE,linePitch=16});g.pop();if not rendered then error(why,0)end
   for _,row in ipairs(l.rows)do
    Skin.panel(row,l.unit,'auxiliary',c.cursor==row.index)
    Skin.text((c.options or {})[row.index]or '',row.x+12*l.unit,row.y+row.h*.28,math.max(12,18*l.unit),glass and Skin.colors.ink or {1,1,.96,1})
   end
  end)
  g.pop()
  if not ok then Q.failed=true;Q.targets=nil;R.warn('battle choice; native presentation restored',err);return end
  Q.targets=l
 end
 function Q.pointer(game,x,y,button)
  if button~=1 or not Q.active()or not Q.targets then return false end
  local c=R.module('src.ui.game3.choice')
  for _,r in ipairs(Q.targets.rows)do
   if x>=r.x and y>=r.y and x<=r.x+r.w and y<=r.y+r.h then
    return R.battleTouch and R.battleTouch.moveTo(game,c,'cursor',r.index,false)or false
   end
  end
  return false
 end
 return Q
end
