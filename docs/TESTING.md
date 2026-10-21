# Testes

Os testes são simulados: não executam uma ROM nem validam uma GPU real. Fixtures de contratos nativos conservam a licença e as atribuições da engine. A fixture AnimCoords é da v0.3.93; parte dos demais contratos é da v0.3.91, como informado nos próprios testes.

Na raiz do repositório, com LuaJIT instalado:

```sh
luajit tests/test.lua
luajit tests/sprite_compat.lua
luajit tests/foreground.lua
luajit tests/visual_system.lua
```

Com Python 3 e a biblioteca Lua 5.4 do sistema:

```sh
python3 tools/run_tests.py tests/test.lua
```

Para o teste principal dos cinco jogos, use `FRLG_TEST_GAME` com `firered`, `leafgreen`, `ruby`, `sapphire` ou `emerald`. As outras suítes ativas são `anchors`, `scenery`, `framing`, `wide`, `responsive`, `battle_layouts` e `engine_version`.

```sh
python3 tools/verify_package.py
python3 tools/build_release.py
```

O primeiro confere hashes do payload. O segundo gera o instalável e verifica o CRC. A rotina privada de continuidade também simula upgrades dos baselines alpha.2 até alpha.17, recusa de alterações desconhecidas e rollback. O histórico privado completo não faz parte deste repositório.

Antes de afirmar compatibilidade visual, teste no jogo as câmeras, troca de fonte, entrada de Pokémon, ataques, HP/EXP, estados e configurações persistidas. Testes de biblioteca Lua não substituem execução de LÖVE/LuaJIT no aplicativo.
