-- Native primary statuses. Only presentation; engine owns application/cure timing.
local S={}
local defs={
 SLP={label='Dormindo',color={.57,.64,.95}},
 PAR={label='Paralisado',color={1,.76,.22}},
 PSN={label='Envenenado',color={.78,.42,.89}},
 TOX={label='Veneno grave',color={.90,.31,.76}},
 BRN={label='Queimado',color={1,.45,.25}},
 FRZ={label='Congelado',color={.38,.83,1}},
}
local aliases={SLEEP='SLP',PARALYSIS='PAR',PARALYZED='PAR',POISON='PSN',POISONED='PSN',TOXIC='TOX',BURN='BRN',BURNED='BRN',FREEZE='FRZ',FROZEN='FRZ'}
function S.resolve(value,toxic)
 if value==nil or value==false then return nil end
 local id=tostring(value):upper()
 if id=='' or id=='NONE' or id=='OK' or id=='HEALTHY' or id=='0' then return nil end
 id=aliases[id] or id;if id=='PSN' and toxic then id='TOX' end
 local d=defs[id]
 return {id=id,label=d and d.label or tostring(value),color=d and d.color or {.76,.63,.90}}
end
return S
