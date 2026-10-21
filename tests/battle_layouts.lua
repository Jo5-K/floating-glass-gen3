-- Production layout/navigation checks. No ROM, save, GPU, or Windows execution.
local root='floating_glass_frlg/modules/ui/floating_battle/'
local Layout=dofile(root..'ui/layout.lua')
local Navigation=dofile(root..'systems/navigation.lua')
local Model=dofile(root..'systems/model.lua')
local passed=0
local function check(ok,msg) assert(ok,msg);passed=passed+1 end
local function eq(a,b,msg) check(a==b,msg..': expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b) return math.abs(a-b)<.001 end
local function inside(r,w,h)
  return r.w>0 and r.h>0 and r.x>=-.001 and r.y>=-.001 and r.x+r.w<=w+.001 and r.y+r.h<=h+.001
end
local allMoves={
  {id=33,name='TACKLE',type='NORMAL',pp=35,maxPp=35},
  {id=45,name='GROWL',type='NORMAL',pp=0,maxPp=40},
  {id=22,name='VINE WHIP',type='GRASS',pp=10,maxPp=10},
  {id=73,name='LEECH SEED',type='GRASS',pp=7,maxPp=10},
}
local sparse={[1]=allMoves[1],[3]=allMoves[2]}
for _,style in ipairs({'list','layers'}) do
  for _,size in ipairs({{1280,720},{960,720},{640,960},{480,270}}) do
    for _,scale in ipairs({.58,.68,.78}) do
      for _,position in ipairs({'left','right'}) do
        for selected=1,4 do
          local l=Layout.compute(size[1],size[2],style,scale,selected,{moves=allMoves,position=position,nativeHud=true})
          local counts,movesSeen,lastDepth,lastMove={},0,math.huge,nil
          local anyCommand=false
          for _,r in ipairs(l.rects) do
            assert(inside(r,size[1],size[2]),string.format('%s %dx%d scale %.2f %s: rect %s/%s outside viewport',style,size[1],size[2],scale,position,r.kind,r.index))
            if r.kind=='move' then
              assert(not anyCommand,'Move rendered over command')
              counts[r.index]=(counts[r.index] or 0)+1;movesSeen=movesSeen+1;lastMove=r
              assert(r.alpha and r.alpha>0 and r.alpha<=1,'Invalid card opacity')
              assert(r.scale and r.scale>0,'Invalid local card scale')
              if style=='layers' then assert(r.depth<=lastDepth,'Layers not drawn back to front');lastDepth=r.depth end
            else
              anyCommand=true
              if r.index==3 then assert(r.y-6*l.scale>=size[2]*46/160,'Bag badge overlaps original-style enemy HUD') end
            end
          end
          assert(movesSeen==4,'Occupied move count differs from snapshot')
          for i=1,4 do assert(counts[i]==1,'Move index duplicated or lost') end
          if style=='layers' then assert(lastMove.index==selected and lastMove.depth==0,'Selected card is not foremost') end
          assert(inside(l.playerHud,size[1],size[2]) and inside(l.enemyHud,size[1],size[2]),'HUD outside viewport')
          check(true,string.format('%s: responsive geometry %dx%d scale %.2f %s selection %d',style,size[1],size[2],scale,position,selected))
        end
      end
    end
  end
  local l=Layout.compute(1280,720,style,.68,3,{moves=sparse,position='left'})
  local found={};for _,r in ipairs(l.rects) do if r.kind=='move' then found[#found+1]=r.index end end
  eq(#found,2,style..': sparse moves do not allocate empty cards')
  check((found[1]==1 and found[2]==3) or (found[1]==3 and found[2]==1),style..': original slots retained')
  eq(Navigation.step(1,'right',style,1,sparse),3,style..': right skips empty slot and reaches zero PP')
  eq(Navigation.step(3,'right',style,3,sparse),1,style..': right wraps')
  eq(Navigation.step(1,'left',style,1,sparse),3,style..': left wraps across empty slots')
  eq(Navigation.step(3,'up',style,3,sparse),5,style..': moves up to bag')
  eq(Navigation.step(3,'down',style,3,sparse),6,style..': moves down to party')
  eq(Navigation.step(5,'down',style,3,sparse),3,style..': bag returns to remembered move')
  eq(Navigation.step(6,'up',style,3,sparse),3,style..': party returns to remembered move')
  eq(Navigation.step(6,'right',style,3,sparse),7,style..': party reaches separated run')
  eq(Navigation.step(7,'left',style,3,sparse),6,style..': run returns to party')
  local single={[4]=allMoves[4]}
  eq(Navigation.step(4,'right',style,4,single),4,style..': one occupied slot loops to itself')
  eq(Navigation.step(4,'left',style,4,single),4,style..': single slot loops left')
  local blank=Layout.compute(1280,720,style,.68,1,{moves={},position='left'})
  local count=0;for _,r in ipairs(blank.rects) do if r.kind=='move' then count=count+1 end end
  eq(count,0,style..': no empty card can be clicked')
end
local cards=Model.cards({moves=sparse})
check(cards[3].disabled and not cards[3].empty,'Zero PP remains a real disabled move for native rejection')
check(cards[2].empty,'Missing slot is distinct from zero PP')
local l=Layout.compute(1280,720,'layers',.68,2,{moves=allMoves,position='left'})
local selected,behind
for _,r in ipairs(l.rects) do if r.kind=='move' then if r.index==2 then selected=r else behind=r end end end
local x1,y1=math.max(selected.x,behind.x),math.max(selected.y,behind.y)
local x2,y2=math.min(selected.x+selected.w,behind.x+behind.w),math.min(selected.y+selected.h,behind.y+behind.h)
check(x2>x1 and y2>y1,'Layered production cards actually overlap')
eq(Layout.hit(l,(x1+x2)/2,(y1+y2)/2).index,2,'Hit test chooses foremost selected card at overlap')
local top={x=10,y=10,w=100,h=50,kind='move',index=4}
local bottom={x=0,y=0,w=150,h=90,kind='move',index=1}
eq(Layout.hit({scale=1,rects={bottom,top}},30,30),top,'Hit traversal follows actual paint order')
eq(Layout.hit({scale=1,rects={bottom,top}},140,80),bottom,'Exposed back card stays clickable')
eq(Layout.hit({scale=1,rects={bottom,top}},200,200),nil,'Blank canvas submits no command')
local g=Layout.compute(1280,720,'grid',.68)
eq(#g.rects,7,'Legacy grid remains available')
eq(Navigation.step(1,'right'),2,'Legacy navigation remains available')
print(string.format('Battle layouts: %d checks passed (simulated layout/input host only).',passed))
