-- Only public BattleAPI snapshots leave this adapter. No ROM offsets.
local M = {}
function M.active(s)
  return type(s) == 'table' and s.kind ~= 'oldman'
    and (s.prompt == 'menu' or s.prompt == 'moves')
end
function M.alpha(index, selected)
  local distance = (index - selected) % 4
  return distance == 0 and 1 or (distance == 1 and .5 or .25)
end
function M.cards(s)
  local cards = {}
  for i=1,4 do
    local m = s.moves and s.moves[i]
    cards[i] = m and {slot=i, name=tostring(m.name or m.id or 'Golpe'),
      type=m.type, pp=m.pp, maxPp=m.maxPp,
      disabled=m.disabled == true or (tonumber(m.pp) or 0) <= 0,
      empty=false} or {slot=i,name='Sem golpe',disabled=true,empty=true}
  end
  return cards
end
function M.send(api, snapshot, kind, fields, serial)
  if not M.active(snapshot) then return nil,'A batalha não aceita comandos agora.' end
  local intent={id=serial,revision=snapshot.revision,kind=kind}
  for k,v in pairs(fields or {}) do intent[k]=v end
  return api:submit(intent)
end
return M
