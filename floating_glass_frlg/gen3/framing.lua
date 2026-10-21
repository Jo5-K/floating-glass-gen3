-- Display.fit is the shared contract used by native presentation, HUD and input.
-- Do not mutate Display.W/H, ROM coordinates or global saved display settings.
return function(R)
  local F={seen=setmetatable({},{__mode='k'})}
  function F.ratio()
    if R.option('battle_aspect','window')=='window' then
      local g=love and love.graphics
      if g and g.getDimensions then local w,h=g.getDimensions();if h>0 then return w/h end end
    end
    return ({['4:3']=4/3,['16:9']=16/9})[R.option('battle_aspect','window')] or 1.5
  end
  function F.drop()
    local n=tonumber(R.option('battle_drop',8)) or 8
    return math.max(0,math.min(12,n))
  end
  function F.installLoaded()
    local D=R.module('src.core.game3.display')
    if not D then return end
    if not F.seen[D] then
    F.seen[D]=true
    R.wrap(D,'present',function(next,game,w,h)
      local result=next(game,w,h)
      -- Native fallback bypasses Renderer.blitCanvas. Redraw its ready canvas
      -- over the full-window backdrop; never run the battle update/draw twice.
      if D.planesBroken and D._canvas and (R.battle.sceneryOwns or R.battle.owns)() and R.scenery.wideActive then
        local g=love.graphics
        if not w or not h then w,h=g.getDimensions() end
        local sx,x,y,_,_,sy=D.fit(w,h)
        g.push('all');g.origin();g.setShader()
        local ok,err=pcall(function()
          R.scenery.drawWide(w,h,{x=x,y=y,w=240*sx,h=160*sy});g.setColor(1,1,1,1)
          g.draw(D._canvas,x,y,0,sx,sy)
        end)
        g.pop();if not ok then error(err,0) end
      end
      return result
    end)
    R.wrap(D,'fit',function(next,w,h)
      local sx,x,y,pw,ph,sy=next(w,h)
      if R.option('battle_aspect','window')=='native' or not R.battle.owns() then return sx,x,y,pw,ph,sy end
      local g=love and love.graphics
      local gw,gh=0,0
      if g and g.getDimensions then gw,gh=g.getDimensions() end
      w,h=w or gw,h or gh
      if not w or not h or w<=0 or h<=0 then return sx,x,y,pw,ph,sy end
      local ax,ay,aw,ah=0,0,w,h
      local Safe=R.module('src.core.SafeArea')
      if w==gw and h==gh and Safe and Safe.windowRect then
        local a,b,c,d=Safe.windowRect()
        if c and d and c>0 and d>0 then ax,ay,aw,ah=a,b,c,d end
      end
      local Play=R.module('src.render.Playfield')
      local cutout=false
      if Play and Play.cutout then
        local a,b,c,d=Play.cutout(w,h)
        if a and c and d and c>0 and d>0 then ax,ay,aw,ah=a,b,c,d;cutout=true end
      end
      if not cutout and ah>aw then ah=ah*.48 end -- retain mobile control deck
      local ratio=R.option('battle_aspect','window')=='window' and aw/ah or F.ratio()
      pw=math.min(aw,ah*ratio);ph=pw/ratio
      x,y=ax+(aw-pw)/2,ay+(ah-ph)/2
      return pw/240,x,y,pw,ph,ph/160
    end)
    end
    -- Normal Game3 uses Renderer planes, not Display.presentFlat. Adapt its
    -- final native canvas blit too, keeping palette zones and clip in sync.
    local Renderer=R.module('src.render.Renderer')
    if Renderer and not F.seen[Renderer] then
      F.seen[Renderer]=true
      F.wideReady=type(Renderer.blitCanvas)=='function'
      R.wrap(Renderer,'blitCanvas',function(next,self,canvas,sx,sy,zones,zsx,zsy,bx,by,x,y,w,h,dx,dy)
        if canvas==self.canvas and (R.battle.sceneryOwns or R.battle.owns)() then
          if R.battle.owns() and R.option('battle_aspect','window')~='native' and canvas.getDimensions then
            local cw,ch=canvas:getDimensions()
            if cw==240 and ch==160 then
              local nsx,nx,ny,nw,nh,nsy=D.fit()
              if nsx and nsy and nw and nh then
                zsx,zsy=(zsx or sx)*nsx/sx,(zsy or sy)*nsy/sy
                sx,sy,bx,by,x,y,w,h=nsx,nsy,nx,ny,nx,ny,nw,nh
              end
            end
          end
          if R.scenery.wideActive then
            local ww,wh=love.graphics.getDimensions()
            R.scenery.drawWide(ww,wh,{x=bx,y=by,w=240*sx,h=160*sy})
          end
        end
        return next(self,canvas,sx,sy,zones,zsx,zsy,bx,by,x,y,w,h,dx,dy)
      end)
    end
  end
  return F
end
