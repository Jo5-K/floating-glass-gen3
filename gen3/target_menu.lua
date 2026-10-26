-- Presentation only. Target validation and submission remain in native BattleAPI.
return function(R,Skin,tr)
 local T={fonts={}}
 function T.cards(snap)
  local available={};for _,id in ipairs(snap.targets or {})do available[id]=true end
  local out={}
  for _,id in ipairs({3,1,0,2})do
   local mon=snap.hudBattlers and snap.hudBattlers[id]
   if mon and available[id] and (mon.hp or 0)>0 and (id~=snap.active or snap.allowSelf)then out[#out+1]={id=id,mon=mon,slot=(id==3 and 0 or id==1 and 1 or id==0 and 2 or 3)}end
  end
  return out
 end
 function T.layout(snap,w,h,field)
  local u=math.min(w,h)/480;local width=math.min(w*(h>w and .88 or .46),480*u)
  local right=R.option('battle_layout','layers')=='commands'or R.option('battle_position','left')=='right'
  local row=58*u;local x=h>w and (w-width)/2 or right and w-width-20*u or 20*u
  local y=h>w and ((field and field.y+field.h or h*.52)+h*.028)or h-204*u
  local layout={rects={},scale=u,message={x=x,y=y,w=width,h=188*u},width=w,height=h}
  for _,v in ipairs(T.cards(snap))do
   layout.rects[#layout.rects+1]={x=x+v.slot%2*(width+8*u)/2,y=y+30*u+math.floor(v.slot/2)*(row+8*u),w=(width-8*u)/2,h=row,kind='target',id=v.id,mon=v.mon}
  end
  layout.rects[#layout.rects+1]={x=x,y=y+166*u,w=width,h=32*u,kind='back'}
  if R.option('battle_settings_button',true)then layout.settings={x=w-156*u,y=12*u,w=144*u,h=34*u,kind='settings'}end
  return layout
 end
 local function label(text,r,size)
  local g=love.graphics;size=math.max(10,math.floor(size))
  if not T.fonts[size]then T.fonts[size]=g.newFont(size)end
  local f=T.fonts[size];g.setFont(f);if Skin.crystal then g.setColor(Skin.colors.ink)else g.setColor(.97,.97,.94,1)end
  local name=tostring(text or '');local width=r.w-16
  if f.getWidth then while #name>1 and f:getWidth(name)>width do
   -- Trim complete UTF-8 codepoints, preserving translated/native names.
   local last=#name;while last>1 and name:byte(last)>=128 and name:byte(last)<192 do last=last-1 end
   name=name:sub(1,last-1)
  end end
  g.printf(name,r.x+8,r.y+math.max(2,(r.h-size)/2),width,'center')
 end
 function T.draw(snap,w,h,field,errorText)
  local l=T.layout(snap,w,h,field);local g=love.graphics;local u=l.scale
  g.push('all')
  if Skin.configure then Skin.configure(R.option('battle_skin','current')=='emerald_gba',R.option('battle_skin','current')=='crystal_glass')end
  label(tr('Escolha o alvo'),{x=l.message.x,y=l.message.y,w=l.message.w,h=26*u},18*u)
  for _,r in ipairs(l.rects)do
   Skin.panel(r,u,r.kind=='back'and 'run'or'move',r.kind=='target'and r.id==snap.target)
   label(r.kind=='back'and tr('Voltar')or r.mon.name,r,r.kind=='back'and 15*u or 17*u)
  end
  if l.settings then Skin.panel(l.settings,u,'move',false);label(tr('Ajustes'),l.settings,15*u)end
  if errorText then label(errorText,{x=l.message.x,y=l.message.y+202*u,w=l.message.w,h=24*u},13*u)end
  g.pop();return l
 end
 function T.shutdown()for _,f in pairs(T.fonts)do if f.release then f:release()end end;T.fonts={}end
 return T
end
