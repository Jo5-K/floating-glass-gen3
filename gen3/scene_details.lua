-- Atmospheric built-in layer plus optional isolated providers: drawn after the backdrop, before arenas/battlers/HUD.
-- Providers are presentation callbacks; no native battle actions are exposed.
return function(R)
 local D={providers={}}
 local builtin=R.load and R.load('gen3/environment_details.lua')(R)
 function D.register(id,scene,draw)
  assert(type(id)=='string' and type(scene)=='string' and type(draw)=='function','scene layer requires id, scene and draw callback')
  D.providers[id]={scene=scene,draw=draw};return id
 end
 function D.remove(id) D.providers[id]=nil end
 function D.draw(frame)
  if R.postLight then R.postLight.draw(frame.width,frame.height,true) end
  if next(D.providers)==nil and not builtin then return end
  local g=love.graphics;local ids={}
  for id,p in pairs(D.providers) do if p.scene==frame.scene then ids[#ids+1]=id end end
  if builtin and not builtin.failed then ids[#ids+1]='__builtin' end
  table.sort(ids)
  for _,id in ipairs(ids) do
   local provider=id=='__builtin' and {draw=builtin.draw} or D.providers[id]
   local ctx={scene=frame.scene,time=frame.time,artWidth=frame.artWidth,artHeight=frame.artHeight}
   -- Position and scale are in original backdrop pixels. No per-window anchors.
   function ctx.draw(img,x,y,sx,sy)
    x,y=x or 0,y or 0;sx=sx or 1;sy=sy or sx
    local iw,ih=img:getDimensions()
    local transform={iw*sx/frame.artWidth,ih*sy/frame.artHeight,x/frame.artWidth,y/frame.artHeight}
    if R.lighting then
     return R.lighting.arenaBackground(transform,g.draw,img,x,y,0,sx,sy)
    end
    return g.draw(img,x,y,0,sx,sy)
   end
   function ctx.drawQuad(img,quad,x,y,sx,sy,qx,qy)
    local iw,ih=img:getDimensions()
    local transform={iw*sx/frame.artWidth,ih*sy/frame.artHeight,(x-qx*sx)/frame.artWidth,(y-qy*sy)/frame.artHeight}
    if R.lighting then return R.lighting.arenaBackground(transform,g.draw,img,quad,x,y,0,sx,sy) end
    return g.draw(img,quad,x,y,0,sx,sy)
   end
   g.push('all');g.translate(frame.x,frame.y);g.scale(frame.scale,frame.scale)
   local ok,err=pcall(provider.draw,ctx)
   g.pop()
   if not ok then if id=='__builtin' then builtin.failed=true else D.providers[id]=nil end;R.warn('scene detail layer disabled: '..id,err) end
  end
 end
 function D.shutdown() D.providers={};if builtin then builtin.shutdown()end end
 return D
end
