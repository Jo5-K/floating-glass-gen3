-- Scene-wide artistic lighting only. No masks, altered PNGs or inferred depth.
local families={
 open={day=1,night=.92,dayTint={1,1,.98},nightTint={.85,.92,1.04},direction=1,pool={.35,.18,.8,.14}},
 canopy={day=.92,night=.78,dayTint={1.02,.99,.88},nightTint={.77,.88,1.03},direction=.85,pool={.38,.22,.58,.23}},
 cave={day=.60,night=.43,dayTint={.90,.86,.77},nightTint={.66,.77,.97},direction=.35,pool={.52,.32,.65,.17}},
 torch={day=.72,night=.53,dayTint={1.04,.88,.72},nightTint={.84,.78,.88},direction=.4,pool={.5,.24,.8,.15}},
 dark={day=.67,night=.45,dayTint={.94,.84,1.02},nightTint={.73,.76,1.03},direction=.35,pool={.5,.26,.8,.13}},
 room={day=.86,night=.61,dayTint={1.02,.96,.86},nightTint={.83,.85,1.02},direction=.55,pool={.32,.25,.7,.17}},
 hall={day=.9,night=.69,dayTint={1,.98,.94},nightTint={.83,.89,1.02},direction=.4,pool={.5,.23,.85,.17}},
 ice={day=.9,night=.68,dayTint={.91,.99,1.05},nightTint={.74,.86,1.08},direction=.4,pool={.5,.25,.85,.17}},
 virtual={day=.86,night=.68,dayTint={.84,.99,1.06},nightTint={.69,.86,1.08},direction=.25,pool={.5,.36,.9,.16}},
}
local scenes={beach='open',desert='open',mountain='open',rocky='open',plain='open',pond='open',water='open',
 forest='canopy',tall_grass='canopy',cave='cave',bruno='torch',dragon='torch',sidney='torch',
 ghost='dark',lavender='dark',interior='room',gym='hall',building='hall',rocket='hall',blue='hall',grand_hall='hall',ice='ice',wallace='ice',virtual='virtual'}
local dusk={predawn=1,dawn=.6,morning=.12,noon=0,dusk=.6,night=1}
local E={families=families,scenes=scenes}
function E.resolve(id,profile)
 local family=scenes[id] or 'open';local p=families[family];local n=dusk[profile] or 0
 local tint={};for i=1,3 do tint[i]=p.dayTint[i]*(1-n)+p.nightTint[i]*n end
 return {id=id or 'unknown',family=family,exposure=p.day*(1-n)+p.night*n,tint=tint,direction=p.direction,
  pool={p.pool[1],p.pool[2],p.pool[3],p.pool[4]*(1-.40*n)}}
end
return E
