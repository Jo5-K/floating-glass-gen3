-- Temporary visual diagnostics; no writes to saves, options or battle state.
return function(R)
 local D={}
 function D.draw(game,viewport)
  local g=love.graphics;local B=R.battle
  local state,native,U=B.context()
  if not state then return end
  local lines={'FG '..R.version..' / G1R '..tostring(R.engine)}
  lines[#lines+1]='UI: '..(B.failed and 'DRAW FAILED' or B.owns() and 'ACTIVE' or 'NATIVE FALLBACK')..' | mode='..tostring(U and U._mode)..' phase='..tostring(native and native._phase)
  lines[#lines+1]='theme='..tostring(R.option('theme','floating_glass'))..' battle='..tostring(R.option('battle',true))..' double='..tostring(state.double)
  local Stack=R.module('src.ui.game3.stack');local Choice=R.module('src.ui.game3.choice');local Fade=R.module('src.ui.game3.fade')
  lines[#lines+1]='stack='..tostring(Stack and Stack.busy and Stack.busy())..' choice='..tostring(Choice and Choice.active)..' fade='..tostring(Fade and Fade.lockInput)..' auto='..tostring(native and native._auto)
  local keys={};for k in pairs(R.warnings)do keys[#keys+1]=k end;table.sort(keys)
  for _,k in ipairs(keys)do lines[#lines+1]=k..': '..tostring(R.warnings[k]):sub(1,420)end
  g.push('all');g.origin();g.setShader();g.setScissor();g.setBlendMode('alpha')
  local w=viewport.width;local size=math.max(12,math.min(19,w/44));if not D.font then D.font=g.newFont(math.floor(size))end;g.setFont(D.font)
  local text=table.concat(lines,'\n');local _,wrapped=D.font:getWrap(text,w-20);local h=math.min(viewport.height*.4,#wrapped*D.font:getHeight()+16)
  g.setColor(0,0,0,.88);g.rectangle('fill',0,0,w,h);g.setColor(1,.9,.45,1);g.printf(text,10,8,w-20);g.pop()
 end
 return D
end
