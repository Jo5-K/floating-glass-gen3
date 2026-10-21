-- Deliberately inert outside Gen3, even when the loader's target override
-- forces this mod onto a different game. No KRS files are read or changed.
return function(mod)
  local game=require('src.core.GameVersion').get()
  if not ({firered=true,leafgreen=true,ruby=true,sapphire=true,emerald=true})[game] then return end
  local source,err=mod:read('gen3/bootstrap.lua')
  assert(type(source)=='string',err or 'Missing independent FRLG bootstrap')
  return assert(load(source,'@floating_glass_frlg/gen3/bootstrap.lua'))()(mod)
end
