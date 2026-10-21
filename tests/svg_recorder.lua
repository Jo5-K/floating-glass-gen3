-- A small LÖVE graphics recorder for production-view previews, not a GPU test.
-- PNG header parsing works in Lua 5.1/LuaJIT and Lua 5.4 without string.unpack.
local S={}
local unpack=table.unpack or unpack
local function esc(v) return tostring(v):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;') end
local function numberAt(body,n)
  local a,b,c,d=body:byte(n,n+3);return ((a*256+b)*256+c)*256+d
end
function S.image(path)
  local f=assert(io.open(path,'rb'));local body=f:read('*a');f:close()
  assert(body:sub(1,8)=='\137PNG\13\10\26\10','Expected PNG: '..path)
  local w,h=numberAt(body,17),numberAt(body,21)
  return {path=path,w=w,h=h,getDimensions=function(self) return self.w,self.h end}
end
function S.new(w,h)
  local R={w=w,h=h,nodes={},stack={},texts={},images=0,clips=0}
  local state={color={1,1,1,1},font={size=18},line=1,m={1,0,0,1,0,0}}
  local function emit(node) R.nodes[#R.nodes+1]=node end
  local function color()
    local c=state.color
    return string.format('rgb(%d,%d,%d)',math.floor(c[1]*255+.5),math.floor(c[2]*255+.5),math.floor(c[3]*255+.5))
  end
  local function attrs(mode)
    if mode=='line' then return string.format('fill="none" stroke="%s" stroke-width="%.3f" stroke-linejoin="round" stroke-linecap="round" opacity="%.4f"',color(),state.line,state.color[4]) end
    return string.format('fill="%s" opacity="%.4f"',color(),state.color[4])
  end
  local function node(markup)
    local m=state.m
    local start,finish='',''
    if state.scissor then
      R.clips=R.clips+1;local c=state.scissor
      emit(string.format('<defs><clipPath id="clip%d"><rect x="%.3f" y="%.3f" width="%.3f" height="%.3f"/></clipPath></defs>',R.clips,c[1],c[2],c[3],c[4]))
      start=string.format('<g clip-path="url(#clip%d)">',R.clips);finish='</g>'
    end
    emit(start..string.format('<g transform="matrix(%s)">',table.concat(m,' '))..markup..'</g>'..finish)
  end
  local function multiply(n)
    local m=state.m
    state.m={m[1]*n[1]+m[3]*n[2],m[2]*n[1]+m[4]*n[2],m[1]*n[3]+m[3]*n[4],m[2]*n[3]+m[4]*n[4],m[1]*n[5]+m[3]*n[6]+m[5],m[2]*n[5]+m[4]*n[6]+m[6]}
  end
  local g={}
  g.setColor=function(r,b,c,a) state.color=type(r)=='table' and {r[1],r[2],r[3],r[4] or 1} or {r,b,c,a or 1} end
  g.getColor=function() return unpack(state.color) end
  g.newFont=function(size)
    local f={size=size}
    function f:getWidth(t) return #t*self.size*.55 end
    function f:getHeight() return self.size end
    function f:getWrap(t,width)
      local lines,line={},''
      for word in tostring(t):gmatch('%S+') do
        if #line>0 and self:getWidth(line..' '..word)>width then lines[#lines+1]=line;line='' end
        line=line=='' and word or line..' '..word
      end
      lines[#lines+1]=line;return width,lines
    end
    return f
  end
  state.font=g.newFont(18)
  g.setFont=function(f) state.font=f end
  g.getFont=function() return state.font end
  g.setLineWidth=function(n) state.line=n end
  g.getLineWidth=function() return state.line end
  g.push=function()
    local copy={};for k,v in pairs(state) do copy[k]=v end
    R.stack[#R.stack+1]=copy
  end
  g.pop=function() state=assert(table.remove(R.stack),'graphics state underflow') end
  g.origin=function() state.m={1,0,0,1,0,0} end
  g.translate=function(x,y) multiply({1,0,0,1,x,y}) end
  g.scale=function(x,y) multiply({x,0,0,y or x,0,0}) end
  g.shear=function(kx,ky) multiply({1,ky or 0,kx or 0,1,0,0}) end
  g.inverseTransformPoint=function(x,y) local m=state.m;local d=m[1]*m[4]-m[2]*m[3];local a,b=x-m[5],y-m[6];return (m[4]*a-m[3]*b)/d,(-m[2]*a+m[1]*b)/d end
  g.rotate=function(a) multiply({math.cos(a),math.sin(a),-math.sin(a),math.cos(a),0,0}) end
  g.transformPoint=function(x,y) local m=state.m;return m[1]*x+m[3]*y+m[5],m[2]*x+m[4]*y+m[6] end
  g.getScissor=function() if state.scissor then return unpack(state.scissor) end end
  g.setScissor=function(x,y,w,h) state.scissor=x and {x,y,w,h} or nil end
  g.intersectScissor=function(x,y,w,h)
    local c=state.scissor
    if c then local right,bottom=math.min(x+w,c[1]+c[3]),math.min(y+h,c[2]+c[4]);x,y=math.max(x,c[1]),math.max(y,c[2]);w,h=math.max(0,right-x),math.max(0,bottom-y) end
    g.setScissor(x,y,w,h)
  end
  g.rectangle=function(mode,x,y,w,h,rx,ry) node(string.format('<rect x="%.3f" y="%.3f" width="%.3f" height="%.3f" rx="%.3f" ry="%.3f" %s/>',x,y,math.max(0,w),math.max(0,h),rx or 0,ry or rx or 0,attrs(mode))) end
  g.circle=function(mode,x,y,r) node(string.format('<circle cx="%.3f" cy="%.3f" r="%.3f" %s/>',x,y,r,attrs(mode))) end
  g.ellipse=function(mode,x,y,rx,ry) node(string.format('<ellipse cx="%.3f" cy="%.3f" rx="%.3f" ry="%.3f" %s/>',x,y,rx,ry,attrs(mode))) end
  g.line=function(...)
    local p={...};if type(p[1])=='table' then p=p[1] end
    node(string.format('<polyline points="%s" %s/>',table.concat(p,' '),attrs('line')))
  end
  g.polygon=function(mode,...)
    local p={...};if type(p[1])=='table' then p=p[1] end
    node(string.format('<polygon points="%s" %s/>',table.concat(p,' '),attrs(mode)))
  end
  g.arc=function(mode,arctype,x,y,r,a1,a2)
    local p={};local span=a2-a1
    if arctype=='pie' then p[#p+1]=x;p[#p+1]=y end
    for i=0,48 do p[#p+1]=x+math.cos(a1+span*i/48)*r;p[#p+1]=y+math.sin(a1+span*i/48)*r end
    if mode=='fill' then g.polygon(mode,p) else g.line(p) end
  end
  g.print=function(t,x,y)
    R.texts[#R.texts+1]=tostring(t)
    node(string.format('<text x="%.3f" y="%.3f" font-family="DejaVu Sans" font-size="%.3f" %s>%s</text>',x,y+state.font.size*.94,state.font.size,attrs('fill'),esc(t)))
  end
  g.printf=function(t,x,y,width,align)
    local _,lines=state.font:getWrap(t,width)
    for i,line in ipairs(lines) do local xx=x;if align=='center' then xx=x+(width-state.font:getWidth(line))/2 elseif align=='right' then xx=x+width-state.font:getWidth(line) end;g.print(line,xx,y+(i-1)*state.font.size*1.2) end
  end
  g.newQuad=function(x,y,w,h,iw,ih) return {x=x,y=y,w=w,h=h,iw=iw,ih=ih,getViewport=function() return x,y,w,h end} end
  -- Textured convex meshes: the arena separator uses a single affine UV map.
  -- Preserve that polygon clip in previews, instead of drawing the whole atlas.
  g.newMesh=function(vertices,mode,usage)
    assert(mode=='fan','recorder only supports convex triangle fans')
    local mesh={vertices=vertices,mesh=true}
    function mesh:setTexture(texture) self.texture=texture end
    return mesh
  end
  -- The production badge shader only masks a circular atlas region. SVG clips
  -- reproduce that geometry, but do not claim native shader validation.
  g.newShader=function(source) return {source=source,send=function(self,key,value) self[key]=value end} end
  g.getShader=function() return state.shader end
  g.setShader=function(shader) state.shader=shader end
  g.draw=function(img,q,x,y,rot,sx,sy,ox,oy)
    if type(q)=='number' or q==nil then oy,ox,sy,sx,rot,y,x,q=ox,sy,sx,rot,y,x,q,nil end
    x,y,rot,sx=x or 0,y or 0,rot or 0,sx or 1;sy=sy or sx;ox,oy=ox or 0,oy or 0
    local image
    if img.mesh then
      assert(not q,'recorder mesh does not take a quad')
      local texture=assert(img.texture,'mesh texture missing');local iw,ih=texture:getDimensions()
      local points={};local first=img.vertices[1]
      local sourceX,sourceY=first[3]*iw-first[1],first[4]*ih-first[2]
      for _,v in ipairs(img.vertices) do
        assert(math.abs(v[3]*iw-v[1]-sourceX)<.001 and math.abs(v[4]*ih-v[2]-sourceY)<.001,'recorder needs affine untranslated UV mapping')
        points[#points+1]=string.format('%.5f,%.5f',v[1]-ox,v[2]-oy)
      end
      R.clips=R.clips+1;local id=R.clips
      image=string.format('<defs><clipPath id="clip%d"><polygon points="%s"/></clipPath></defs><g clip-path="url(#clip%d)"><image href="%s" x="%.5f" y="%.5f" width="%s" height="%s" image-rendering="pixelated"/></g>',id,table.concat(points,' '),id,esc(texture.path),-sourceX-ox,-sourceY-oy,iw,ih)
    else
      local iw,ih=img:getDimensions();q=q or {x=0,y=0,w=iw,h=ih}
      image=string.format('<svg x="%.3f" y="%.3f" width="%.3f" height="%.3f" viewBox="%s %s %s %s" overflow="hidden"><image href="%s" width="%s" height="%s" preserveAspectRatio="none" image-rendering="pixelated"/></svg>',-ox,-oy,q.w,q.h,q.x,q.y,q.w,q.h,esc(img.path),iw,ih)
    end
    if not img.mesh and state.shader and state.shader.sourceRect then
      R.clips=R.clips+1;local id=R.clips
      image=string.format('<defs><clipPath id="clip%d"><circle cx="%.3f" cy="%.3f" r="%.3f"/></clipPath></defs><g clip-path="url(#clip%d)">%s</g>',id,q.w/2-ox,q.h/2-oy,math.min(q.w,q.h)*.495,id,image)
    end
    if state.shader and state.shader.source and state.shader.source:find('Texel(tex, uv).a * color.a',1,true) then
      R.clips=R.clips+1;local id=R.clips
      image=string.format('<defs><filter id="black%d" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"/></filter></defs><g filter="url(#black%d)">%s</g>',id,id,image)
    end
    R.images=R.images+1
    node(string.format('<g transform="translate(%.3f %.3f) rotate(%.3f) scale(%.5f %.5f)" opacity="%.4f">%s</g>',x,y,rot*180/math.pi,sx,sy,state.color[4],image))
  end
  R.graphics=g
  function R:save(path)
    assert(#self.stack==0,'Unbalanced graphics state')
    local f=assert(io.open(path,'w'));f:write(string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">',self.w,self.h),table.concat(self.nodes),'\n</svg>');f:close()
  end
  return R
end
return S
