-- Optional, public Gen3 HD exports only. No imports of another mod's sources,
-- no edits to its tags/assets/options, and no dependency when it is absent.
return function(R)
 local X={}
 function X.hd()
  if not(R.mod and type(R.mod.find)=='function') then return end
  local ok,mod=pcall(R.mod.find,R.mod,'gen3-hd-sprites')
  local api=ok and mod and mod.exports
  if type(api)~='table' or type(api.tagOf)~='function' then return end
  if api.enabled then local yes,on=pcall(api.enabled,'battle');if not yes or not on then return end end
  return api
 end
 function X.tag(image)
  if not(R.battle and R.battle.owns and R.battle.owns())then return end
  local api=X.hd();if not api then return end
  local ok,spec=pcall(api.tagOf,image)
  if ok and type(spec)=='table' and spec.texture and spec.pivot and spec.lowPivot then return spec end
 end
 -- A public HD tag maps a full-resolution pivot onto the stand-in's lowPivot.
 -- Returned bounds are in the stand-in's local draw units, before its origin.
 function X.geometry(image,quad)
  local spec=X.tag(image);if not spec then return end
  local qp=quad and spec.quadPivots and spec.quadPivots[quad]
  if quad and not qp then return end
  local lp,hp=qp or spec.lowPivot,qp or spec.pivot
  local k=qp and qp[3] or spec.scale or 1
  local iw,ih=spec.texture:getDimensions()
  if spec.quad then local _,_,w,h=spec.quad:getViewport();iw,ih=w,h end
  local b=spec.body or {0,spec.top or 0,iw,ih}
  return {lp[1]+(b[1]-hp[1])*k,lp[2]+(b[2]-hp[2])*k,
          lp[1]+(b[3]-hp[1])*k,lp[2]+(b[4]-hp[2])*k}, {lp[1],lp[2]},spec
 end
 function X.shadowImage(image,args)
  local quad=type(args[1])~='number' and args[1] or nil
  -- Native strip/distortion effects already provide the precise cropped draw.
  -- Do not expand each strip into an entire HD frame.
  if quad then return image,args end
  local _,_,spec=X.geometry(image,quad);if not spec then return image,args end
  local i=quad and 2 or 1
  local x,y,r,sx,sy,ox,oy=args[i],args[i+1],args[i+2] or 0,args[i+3] or 1,args[i+4],args[i+5] or 0,args[i+6] or 0
  sy=sy or sx
  local qp=quad and spec.quadPivots and spec.quadPivots[quad]
  local lp,hp=qp or spec.lowPivot,qp or spec.pivot
  local k=qp and qp[3] or spec.scale or 1
  local px,py=(lp[1]-ox)*sx,(lp[2]-oy)*sy;local c,s=math.cos(r),math.sin(r)
  x,y=x+c*px-s*py,y+s*px+c*py
  local out={x,y,r,sx*k,sy*k,hp[1],hp[2]}
  if spec.quad then table.insert(out,1,spec.quad) end
  return spec.texture,out
 end
 -- Every owned HUD camera uses our final projection, including Native/Original.
 -- Suspend the provider's automatic refit for this draw only, otherwise its
 -- compositor can independently enlarge the sprite after our arena was placed.
 -- Provider tags and species scaling remain unchanged.
 -- Scope camera ownership around Game3.draw, including HD's final compositor.
 -- The public switch is transient; no persistent option or tag is overwritten.
 function X.begin()
  if not(R.battle and R.battle.owns and R.battle.owns()) then return end
  local api=X.hd();if not(api and api.fitEnabled and api.setFit) then return end
  local ok,on=pcall(api.fitEnabled);if not ok or not on then return end
  local yes,err=pcall(api.setFit,false)
  if not yes then R.warn('HD camera ownership unavailable',err);return end
  return api
 end
 function X.finish(api)
  if api then local ok,err=pcall(api.setFit,true);if not ok then R.warn('HD camera ownership restore',err) end end
 end
 return X
end
