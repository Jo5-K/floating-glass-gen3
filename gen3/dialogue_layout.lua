-- Presentation only: native pages, reveal order and callbacks stay untouched.
local D={}
function D.compute(w,h,size,measuredWidth,lineCount)
  local unit=math.min(w/1280,h/720)
  local large=math.max(3*unit,math.min(2.5,w/240))
  local scales={small=1.2*unit,medium=1.8*unit,medium_large=2.4*unit,large=large}
  local k=math.min(scales[size] or scales.medium,(w-80*unit)/224)
  local width=math.min(w-48*unit,math.max(80,measuredWidth or 224)*k+32*unit)
  -- Right edge starts at the window centre. Fill left first, then extend right.
  -- Measure the complete native page, keeping the box stable while it is revealed.
  local x=math.max(24*unit,w/2-width)
  local height=math.min(h-48*unit,(math.max(2,lineCount or 2)*16+10)*k+24*unit)
  return {x=x,y=h-24*unit-height,w=width,h=height},k,unit
end
return D
