# Arquitetura e contexto

Mod independente, ID `floating_glass_frlg`, engine >=0.3.93, API 2, sem dependências obrigatórias. Base desta beta: alpha.17. A execução é restrita a FireRed, LeafGreen, Ruby, Sapphire e Emerald.

## Caminho ativo

- `gen3/bootstrap.lua`: requisitos, opções, carregamento e restauração dos wrappers.
- `gen3/battle.lua`: apresentação e ligação à BattleAPI nativa. Ela é o único caminho de envio de comandos.
- `gen3/camera.lua`: Nativa, Original, Compatibilidade G9/HD e Primeiro plano.
- `gen3/anchors.lua`: limites visíveis, ponto de repouso, troca de fonte e âncoras estabilizadas.
- `gen3/sprite_compat.lua`: consulta opcional da API pública do Gen3 HD Sprites; pivôs e suspensão temporária de Battle Fit durante o desenho, com restauração inclusive em erro.
- `gen3/scenery.lua`, catálogos e renderizador de arenas: resolução do cenário e projeção proporcional.
- `gen3/shadows.lua`: silhueta preta e transparente do quadro corrente, sem relógio paralelo.
- `gen3/framing.lua`: integração de janela, canvas e área de jogo.
- `modules/ui/floating_battle/`: layout, navegação, ícones e desenho dos comandos.

A apresentação não pode consumir itens, mover Pokémon, excluir saves nem substituir transações, callbacks ou mensagens por uma simulação própria. Wrappers devolvem o controle nativo e são restaurados ao descarregar.

## Módulos nativos

Use `R.module` e o `require` permitido. Não procure módulos nativos em `package.loaded`: LegacyCompat fornece um cache vazio/isolado ao mod. Os testes podem usar caches simulados; isso não é um exemplo para chunks de produção.

## Câmera G9/HD

A âncora usa `lowPivot`, `pivot`, `scale`, `body` e `quad` quando o provedor HD os expõe. A passagem de um quadro de entrada nativo para a fonte substituída invalida a medição anterior. Um novo quadro animado não deve deslocar a arena nem reiniciar a animação.

Durante uma batalha simples comum neste modo, o mod solicita temporariamente que o Battle Fit do HD não reenquadre a mesma cena. A opção anterior é restaurada; não há alteração persistente nem edição do outro mod. Sem essa API, usa-se medição de alfa/origem, com os limites descritos em KNOWN_ISSUES.md.

## Escopo histórico

Os módulos e recursos exclusivos das telas KRS fora da batalha foram arquivados fora do mod; sua documentação histórica local foi preservada. Não alterar KRS original, outros mods, Gen1 ou Gen2. O repositório não inclui as referências integrais da engine/KRS nem o histórico privado de transferência.
