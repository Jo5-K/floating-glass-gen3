-- Original user artwork, kept byte-for-byte as external atlases.
-- Quads select the buttons and empty frame regions without baked move text.
return function(runtime)
  local A={images={},quads={}}
  local function image(name)
    if A.images[name]~=nil then return A.images[name] or nil end
    local ok,img=pcall(function()
      if runtime.assets and runtime.assetPath then
        return runtime.assets:image(runtime.assetPath('floating_battle/assets/'..name..'.png'),'linear')
      end
    end)
    A.images[name]=ok and img or false;return A.images[name] or nil
  end
  local function piece(name,sx,sy,sw,sh,x,y,w,h,alpha)
    local img=image(name);local g=love.graphics
    if not img or not g.newQuad then return false end
    local key=table.concat({name,sx,sy,sw,sh},':')
    if not A.quads[key] then local iw,ih=img:getDimensions();A.quads[key]=g.newQuad(sx,sy,sw,sh,iw,ih) end
    g.setColor(1,1,1,alpha or 1)
    g.draw(img,A.quads[key],x,y,0,w/sw,h/sh)
    return true
  end
  local buttons={
    [3]={508,258,463,164},
    [2]={508,430,508,147},
    [4]={508,584,463,170},
  }
  function A.action(index,r,alpha)
    local b=buttons[index];if not b then return false end
    return piece('actions',b[1],b[2],b[3],b[4],r.x,r.y,r.w,r.h,alpha)
  end
  function A.frame(r,s,alpha)
    if not image('move-card') then return false end
    local edge=math.min(16*s,r.h/3,r.w/4)
    local xs={16,151,1901};local ys={64,174,552}
    local ws={135,1750,135};local hs={110,378,110}
    local dx={r.x,r.x+edge,r.x+r.w-edge};local dy={r.y,r.y+edge,r.y+r.h-edge}
    local dw={edge,r.w-2*edge,edge};local dh={edge,r.h-2*edge,edge}
    for row=1,3 do for col=1,3 do
      local x,y,w,h=xs[col],ys[row],ws[col],hs[row]
      -- Only this clean blue strip is used for the centre. Names, PP,
      -- the psychic badge and type tag in the source are never copied.
      if row==2 and col==2 then x,y,w,h=1000,174,65,378 end
      if not piece('move-card',x,y,w,h,dx[col],dy[row],dw[col],dh[row],alpha) then return false end
    end end
    piece('move-card',1760,180,120,390,r.x+r.w-31*s,r.y+15*s,14*s,r.h-30*s,(alpha or 1)*.65)
    return true
  end
  local mask
  local function roundBadge(name,b,x,y,size,alpha)
    local g=love.graphics
    if mask==nil then
      local ok,shader=pcall(function()return g.newShader([[
        extern vec4 sourceRect;
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
          vec2 p=(uv-sourceRect.xy)/sourceRect.zw-vec2(0.5);
          float coverage=1.0-smoothstep(0.485,0.5,length(p));
          return Texel(texture,uv)*color*coverage;
        }
      ]])end)
      mask=ok and shader or false
    end
    local img=image(name)
    if not mask or not img then return false end
    local iw,ih=img:getDimensions();local previous=g.getShader and g.getShader()
    mask:send('sourceRect',{b[1]/iw,b[2]/ih,b[3]/iw,b[4]/ih})
    g.setShader(mask)
    local ok,result=pcall(piece,name,b[1],b[2],b[3],b[4],x,y,size,size,alpha)
    g.setShader(previous)
    return ok and result or false
  end
  local badges={[3]={537,265,152,152},[2]={534,433,142,142},[4]={540,590,150,150}}
  function A.badge(index,x,y,size,alpha)
    local b=badges[index];return b and roundBadge('actions',b,x,y,size,alpha) or false
  end
  function A.psychic(x,y,size,alpha)
    return roundBadge('move-card',{188,180,225,225},x,y,size,alpha)
  end
  return A
end
