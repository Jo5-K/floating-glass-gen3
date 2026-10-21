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
  -- Background replacement is exclusively owned by scenery.lua.
  function A.installLoaded() end
  return A
end
