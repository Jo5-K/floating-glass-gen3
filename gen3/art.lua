return function(R)
  local A={images={},seen=setmetatable({},{__mode='k'})}
  local index=R.load('gen3/art_index.lua')
  local function slug(s)
    return tostring(s or ''):lower():gsub('♀','-f'):gsub('♂','-m'):gsub('_','-'):gsub('[%.\']',''):gsub('%s+','-')
  end
  R.mod.hooks:wrap('pokemon.sprite',function(next,path,ctx)
    ctx=ctx or {}
    if not R.active() or R.option('sprite_source','native')~='krs' then return next(path,ctx) end
    if ctx.letter or ctx.species=='SPINDA' or ctx.species=='CASTFORM' or ctx.species=='DEOXYS'
      or (tonumber(ctx.form) or 0)~=0 then return next(path,ctx) end
    local side=ctx.side=='back' and 'back' or 'front'
    local generation=tostring(R.option(side..'_generation','5'))
    local family=ctx.shiny==true and 'shiny' or 'normal'
    local bucket=index[side] and index[side][generation]
    local entry=bucket and bucket[family] and bucket[family][slug(ctx.species)]
    if not entry then return next(path,ctx) end
    ctx.trueColor=true
    return R.mod.assets:path(entry)
  end,250)
  function A.backgroundName(key)
    return ({grass='grass_day',long_grass='grass_day',sand='road_day',plain='road_day',
      underwater='sea_day',water='sea_day',pond='sea_day',mountain='cave_dark',cave='cave_dark',
      building='silph_co',lorelei='league_lorelei',bruno='league_bruno',agatha='league_agatha',
      lance='league_lance',champion='league_champion'})[key]
  end
  function A.installLoaded()
    local Bg=R.module('src.core.game3.battle.bg')
    if not Bg or A.seen[Bg] then return end
    A.seen[Bg]=true
    R.wrap(Bg,'draw',function(next,id,enemyOx,playerOx,bgOx)
      if R.option('background','native')~='krs' then return next(id,enemyOx,playerOx,bgOx) end
      local name=A.backgroundName(Bg.env and Bg.env().TERRAIN_SHEET[id or Bg.terrainId()] or (Bg.sheetKey and Bg.sheetKey(id or Bg.terrainId())))
      if not name then return next(id,enemyOx,playerOx,bgOx) end
      local img=A.images[name]
      if img==nil then
        local ok,value=pcall(R.mod.assets.image,R.mod.assets,
          'modules/ui/assets/battle/backgrounds/canonical/'..name..'.png')
        img=ok and value or false;A.images[name]=img
        if not img then R.warn('background '..name,value) end
      end
      if not img then return next(id,enemyOx,playerOx,bgOx) end
      local iw,ih=img:getDimensions();local k=math.max(240/iw,160/ih)
      love.graphics.draw(img,(240-iw*k)/2,(160-ih*k)/2,0,k,k)
      return true
    end)
  end
  return A
end
