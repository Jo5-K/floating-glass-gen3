-- Project the exact current sprite alpha onto the ground; no animation clock.
return function(R)
 local S={modified=false,images=setmetatable({},{__mode='k'}),failed=false}
 local source=[[vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  return vec4(0.0, 0.0, 0.0, Texel(tex, uv).a * color.a);
 }]]
 function S.beginFrame() S.drawn={} end
 function S.reset(state)
  if S.state~=state then S.state=state;S.modified=R.option('sprite_source','native')=='krs' end
 end
 function S.register(entry,origin)
  local img=entry and entry.image;if not img then return end
  if S.images[img]==nil then
   local ok,w,h=pcall(img.getDimensions,img)
   local canvas=img.typeOf and img:typeOf('Canvas')
   local modified=canvas or entry.sheetH or entry.frames or entry.quad or ok and (w~=64 or h~=64)
   if not modified then
    local native=entry.lru==true or origin=='frame' or origin=='substitute'
    if not native then
      local P=R.module('src.core.game3.pokemon')
      for _,name in ipairs({'_front','_back','_spindaPics'}) do
        for _,pic in pairs(P and P[name] or {}) do if type(pic)=='table' and pic.image==img then native=true end end
      end
    end
    modified=not native
   end
   S.images[img]=not not modified
  end
  if S.images[img] then S.modified=true end
 end
 function S.enabled(key)
  if R.camera and R.camera.native() then return false end
  local mode=R.option('shadows','auto')
  if R.camera and mode=='off' then mode='auto' end -- old saved setting follows new camera policy
  if mode=='off' then return false end
  local player=key=='player' or type(key)=='number' and key%2==0
  return mode=='both' or not player or mode=='auto' and (R.camera~=nil or S.modified)
 end
 function S.draw(downstream,img,key,anchors,...)
  if S.failed or not S.enabled(key) then return end
  local args={...};local quad=type(args[1])~='number' and args[1]
  S.drawn=S.drawn or {}
  if S.drawn[key] and not quad then return end
  local g=love.graphics
  if not(g.newShader and g.getColor and g.inverseTransformPoint and g.shear) then return end
  if not S.shader then
   local ok,v=pcall(g.newShader,source)
   if not ok then S.failed=true;R.warn('shadow shader unavailable',v);return end
   S.shader=v
  end
  local b=anchors.displayBounds and anchors.displayBounds(key) or anchors.fixed[key] or anchors.bounds[key];if not b then return end
  local knee=R.option('shadow_anchor','feet')=='knees' and .22 or 0
  local gx,gy=g.inverseTransformPoint((b.l+b.r)/2,b.b-(b.b-b.t)*knee)
  if knee==0 and anchors.displayGround then
    local x,y=anchors.displayGround(key);if x then gx,gy=g.inverseTransformPoint(x,y) end
  end
  local _,_,_,alpha=g.getColor();
  local Anim=R.module('src.core.game3.battle.anim');local pr=Anim and Anim.present and Anim.present(key) or {}
  if pr.visible==false or pr.blinkHidden or pr.invisible or pr.battlerInvisible then return end
  S.drawn[key]=true
  local elevation=R.battle and R.battle.elevation and R.battle.elevation(key) or 0
  g.push('all')
  local ok,err=pcall(function()
   g.setShader(S.shader);g.setColor(0,0,0,(alpha or 1)*.30)
   g.translate(gx,gy+elevation);g.shear(.65,0);g.scale(1,-.24);g.translate(-gx-(pr.ox or 0),-gy-(pr.oy or 0))
   local texture,drawArgs=img,args
   if R.compat then texture,drawArgs=R.compat.shadowImage(img,args) end
   downstream(texture,(table.unpack or unpack)(drawArgs))
  end)
  g.pop()
  if not ok then S.failed=true;R.warn('shadow draw disabled',err) end
 end
 function S.shutdown() if S.shader and S.shader.release then S.shader:release() end;S.shader=nil end
 return S
end
