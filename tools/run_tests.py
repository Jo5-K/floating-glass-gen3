"""Run Lua 5.4 checks through a system runtime, including systems without lua CLI."""
import ctypes, ctypes.util, pathlib, os, sys
root=pathlib.Path(__file__).resolve().parents[1]
os.chdir(root)
libpath=ctypes.util.find_library('lua5.4')
if not libpath:
    raise SystemExit('Instale Lua 5.4 e execute: lua tests/test.lua (na raiz do pacote).')
lua=ctypes.CDLL(libpath)
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_close.argtypes=[ctypes.c_void_p]
for path in sorted(root.rglob('*.lua')):
    state=lua.luaL_newstate()
    error=lua.luaL_loadfilex(state,str(path).encode(),None)
    if error: raise SystemExit(lua.lua_tolstring(state,-1,None).decode())
    lua.lua_close(state)
state=lua.luaL_newstate();lua.luaL_openlibs(state)
script=sys.argv[1] if len(sys.argv)>1 else 'tests/test.lua'
if script=='tests/preview_battle.lua':
    (root/'preview_frames').mkdir(exist_ok=True)
error=lua.luaL_loadfilex(state,script.encode(),None)
if not error: error=lua.lua_pcallk(state,0,-1,0,0,None)
if error: raise SystemExit(lua.lua_tolstring(state,-1,None).decode())
lua.lua_close(state)
print('Syntax: all Lua files passed (Lua 5.4).')
