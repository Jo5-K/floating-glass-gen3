-- Isolate the two supplied arena islands at draw time; never rewrite the PNG.
-- Source alpha was inspected: the main islands do not cross x = 3.1*y + 120.
return function(R)
  local F={cache=setmetatable({},{__mode='k'})}
  local shapes={
    player={l=31,t=304,r=1435,b=734,cx=730,cy=520,sign=-1},
    enemy={l=1029,t=96,r=1967,b=372,cx=1500,cy=233,sign=1},
  }
  F.shapes=shapes
  local function distance(p,s) return s.sign*(p[1]-3.1*p[2]-120) end
  local function polygon(s)
    local input={{s.l,s.t},{s.r,s.t},{s.r,s.b},{s.l,s.b}};local output={}
    local previous=input[#input];local pd=distance(previous,s)
    for _,point in ipairs(input) do
      local d=distance(point,s)
      if (d>=0)~=(pd>=0) then
        local k=pd/(pd-d)
        output[#output+1]={previous[1]+k*(point[1]-previous[1]),previous[2]+k*(point[2]-previous[2])}
      end
      if d>=0 then output[#output+1]=point end
      previous,pd=point,d
    end
    return output
  end
  local function resources(img,side)
    local bySide=F.cache[img]
    if not bySide then bySide={};F.cache[img]=bySide end
    if bySide[side] then return bySide[side] end
    local s=shapes[side];local g=love.graphics;local iw,ih=img:getDimensions()
    local result={};bySide[side]=result
    if g.newMesh then
      local vertices={}
      for _,p in ipairs(polygon(s)) do
        vertices[#vertices+1]={p[1]-s.l,p[2]-s.t,p[1]/iw,p[2]/ih,1,1,1,1}
      end
      local ok,mesh=pcall(g.newMesh,vertices,'fan','static')
      if ok and mesh and mesh.setTexture then
        local attached=pcall(mesh.setTexture,mesh,img)
        if attached then result.mesh=mesh end
      end
    end
    -- Older/headless render hosts can use tightly clipped one-pixel strips.
    -- Their shared diagonal keeps the other circle out of overlapping bounds.
    if not result.mesh and g.newQuad then
      result.strips={}
      for y=s.t,s.b-1 do
        local cut=math.floor(3.1*(y+.5)+120+.5)
        local l=side=='enemy' and math.max(s.l,cut) or s.l
        local r=side=='player' and math.min(s.r,cut) or s.r
        if r>l then
          result.strips[#result.strips+1]={q=g.newQuad(l,y,r-l,1,iw,ih),x=l,y=y}
        end
      end
    end
    return result
  end
  function F.draw(img,side,cx,cy,width)
    local s=shapes[side]
    if not s or not img or not width or width<=0 then return end
    local k=width/(s.r-s.l);local cached=resources(img,side);local g=love.graphics
    if cached.mesh then
      g.draw(cached.mesh,cx,cy,0,k,k,s.cx-s.l,s.cy-s.t)
    elseif cached.strips then
      for _,strip in ipairs(cached.strips) do
        g.draw(img,strip.q,cx+(strip.x-s.cx)*k,cy+(strip.y-s.cy)*k,0,k,k)
      end
    else return end
    return {l=cx+(s.l-s.cx)*k,t=cy+(s.t-s.cy)*k,
      r=cx+(s.r-s.cx)*k,b=cy+(s.b-s.cy)*k,
      width=width,height=(s.b-s.t)*k,cx=cx,cy=cy,scale=k}
  end
  return F
end
