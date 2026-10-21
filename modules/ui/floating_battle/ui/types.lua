-- Visual metadata only. Actual move types come from BattleAPI after mods.
local T = {}
local definitions={
 NORMAL={'Normal','N',.63,.66,.72}, FIRE={'Fogo','F',1,.38,.20},
 WATER={'Água','A',.20,.58,.98}, ELECTRIC={'Elétrico','E',.97,.78,.16},
 GRASS={'Planta','G',.30,.76,.39}, ICE={'Gelo','I',.35,.83,.87},
 FIGHTING={'Lutador','L',.85,.33,.29}, POISON={'Veneno','V',.70,.36,.82},
 GROUND={'Terrestre','T',.80,.62,.35}, FLYING={'Voador','W',.50,.65,.96},
 PSYCHIC={'Psíquico','P',.96,.33,.60}, BUG={'Inseto','B',.63,.74,.23},
 ROCK={'Pedra','R',.71,.66,.39}, GHOST={'Fantasma','H',.49,.44,.77},
 DRAGON={'Dragão','D',.45,.36,.95}, DARK={'Sombrio','S',.48,.44,.49},
 STEEL={'Aço','M',.62,.70,.78}, FAIRY={'Fada','★',.95,.52,.80}
}
local function key(id) return tostring(id or ''):upper() end
function T.register(id, spec)
  assert(type(id)=='string' and #id>0,'type id required')
  assert(type(spec)=='table' and type(spec.label)=='string','label required')
  local c=spec.color
  assert(type(c)=='table','color required')
  for i=1,3 do assert(type(c[i])=='number' and c[i]>=0 and c[i]<=1,'RGB must be 0..1') end
  T[key(id)]={label=spec.label,glyph=spec.glyph or '?',color={c[1],c[2],c[3]},image=spec.image}
end
for id,s in pairs(definitions) do T.register(id,{label=s[1],glyph=s[2],color={s[3],s[4],s[5]}}) end
function T.resolve(id)
  return T[key(id)] or {label=id and tostring(id) or 'Tipo desconhecido',glyph='?',color={.51,.59,.67}}
end
return T
