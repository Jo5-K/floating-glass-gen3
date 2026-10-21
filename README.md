# Floating Glass Gen3

**Beta 01 · 1.2.0-beta.1 · Gen1Recomp >=0.3.93 · Mod API 2**

Apresentação de batalha para Pokémon FireRed, LeafGreen, Ruby, Sapphire e Emerald: cenários ultrawide, controles flutuantes, HUD nativo e sombras animadas por silhueta.

Esta é a primeira publicação beta, baseada na alpha.17. Os cinco jogos são alvos experimentais. A promoção para beta organiza a distribuição; não significa que todas as câmeras, espécies, animações e combinações de mods estejam visualmente validadas.

## Download e instalação

Baixe o ZIP **Floating-Glass-Gen3-1.2.0-beta.1.zip** na [Beta 01](https://github.com/Jo5-K/floating-glass-gen3/releases/tag/v1.2.0-beta.1). Não use o ZIP automático de código-fonte como instalador.

1. Feche o jogo.
2. Extraia o pacote em uma pasta temporária.
3. Copie a pasta `floating_glass_frlg` para a pasta `mods` da sua instalação, ou execute `INSTALAR.cmd` no Windows e informe o destino.
4. Ative **Floating Glass Gen3** no gerenciador e reinicie a engine.

Para atualizar versões alpha conhecidas, prefira o instalador: ele confere hashes, cria backup e recusa arquivos alterados desconhecidos. Os módulos/recursos antigos dos menus KRS reconhecidos são movidos para o backup, fora do mod; a documentação histórica é preservada. Não exclua os outros mods. O identificador permanece `floating_glass_frlg`.

## Câmeras e controles

Durante uma decisão de batalha, **SELECT** abre os ajustes. Cima/baixo escolhe a opção; esquerda/direita altera; A/B/SELECT fecha. As ações da batalha continuam sendo executadas pela interface nativa.

| Câmera | Uso |
| --- | --- |
| **Nativa** | Padrão para novos perfis; sem sombras adicionadas por este mod. |
| **Original** | Composição anterior do Floating Glass, com sombras automáticas nos dois lados. |
| **Compatibilidade G9/HD** | Corrige o apoio de sprites substituídos; integração opcional com os pivôs públicos do Gen3 HD Sprites. |
| **Primeiro plano** | Composição com o aliado próximo à borda inferior; opção experimental separada. |

Com G9 Battle Sprites/Gen3 HD Sprites, experimente **Compatibilidade G9/HD**. Essa correção foi implementada e testada com gráficos simulados; a aparência final ainda precisa de confirmação no jogo. Nenhum desses provedores é uma dependência obrigatória.

Na Original e na G9/HD, em batalhas simples, o HUD de HP está 20% menor que na alpha.16 e sua borda superior sobe cinco pixels de janela. Os valores salvos `current` e `native_depth` continuam correspondendo a Original e Primeiro plano.

## O que está ativo

- Interface de comandos de batalha com seleção de golpes, mochila, troca e fuga pela lógica nativa.
- 24 cenários e nove arenas nomeadas; preenchimento pela altura, preservando a proporção da arte.
- Formato de janela, nativo, 4:3 e 16:9; primeiros planos e ajustes de apresentação.
- HP/EXP/status desenhados pela Healthbox nativa.
- Sombras que reutilizam o quadro animado do Pokémon.

Os menus fora da batalha — título, seleção de saves, Start, equipe, mochila e demais telas — usam a interface nativa. Os módulos e recursos exclusivos dessas telas foram movidos para um arquivo local fora do mod e não são distribuídos nesta beta.

## Validação e limites

As verificações usam LuaJIT e Lua 5.4 com host, gráficos e dados de jogo simulados, incluindo contratos extraídos das versões exatas da engine. Há capturas de uso fornecidas durante o desenvolvimento; a última correção de posicionamento G9/HD ainda aguarda confirmação visual.

Não houve uma campanha completa de QA com Windows/LÖVE/GPU, ROMs e saves reais. Duplas, situações especiais, formas e integrações específicas ainda exigem validação ou usam fallbacks. Veja [limitações](docs/KNOWN_ISSUES.md) e [testes](docs/TESTING.md).

## Desenvolvimento

O código ativo está em `floating_glass_frlg/gen3/` e a UI compartilhada de batalha em `floating_glass_frlg/modules/ui/floating_battle/`. Leia a [arquitetura](docs/ARCHITECTURE.md) e as [orientações de contribuição](CONTRIBUTING.md).

## Créditos e licença

Projeto Floating Glass/MFA, mantido neste repositório por **Jo5-K**. Recursos e referências do Kanto Rework Suite: **Faendra** e respectivos autores. Os provedores G9 Battle Sprites e Gen3 HD Sprites são projetos separados e não estão incluídos.

Based on the Pokemon Gen 1 Recompilation Project by BOIS CLUB GAMES, LLC
(https://github.com/bryanthaboi/gen1recomp)

Pokémon e os materiais relacionados pertencem aos seus respectivos titulares. Este pacote não inclui ROM, executável, launcher, saves ou credenciais. As atribuições não concedem uma licença geral sobre recursos de terceiros: consulte [avisos](THIRD_PARTY_NOTICES.md) e [situação da licença](LICENSE.md).
