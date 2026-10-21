local Semver=dofile('tests/fixtures/Semver-0.3.93.lua')
local function compile(source,name,env)
 if setfenv then local f=assert(loadstring(source,name));setfenv(f,env);return f end
 return load(source,name,'t',env)
end
local f=assert(io.open('floating_glass_frlg/gen3/bootstrap.lua'));local source=f:read('*a');f:close()
local count=0
for version,expected in pairs({['0.3.91']=false,['0.3.92']=false,['0.3.93-beta.1']=false,['0.0.0-dev']=false,['0.3.93']=true,['0.3.93+build.1']=true,['0.3.94']=true,['0.4.0']=true,['1.0.0']=true,['invalid']=false}) do
 local reached=false
 local env=setmetatable({require=function(name)
  if name=='src.core.GameVersion' then return {get=function() return 'firered' end} end
  if name=='src.core.Version' then return {engine=version} end
  if name=='src.mods.Semver' then return Semver end
  error(name)
 end},{__index=_G})
 local entry=assert(compile(source,'@bootstrap-version',env))()
 pcall(entry,{read=function() reached=true;error('stop after version gate') end})
 assert(reached==expected,'bootstrap requirement: '..version)
 assert(Semver.satisfies(version,'>=0.3.93')==expected,'manifest range: '..version)
 count=count+2
end
print(count..' engine requirement checks passed; no runtime compatibility claim.')
