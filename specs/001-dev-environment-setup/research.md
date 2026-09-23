# Research: Development Environment Setup

## Java Runtime

**Decision**: Adotar Java 25 como toolchain e runtime JVM padrão.

**Rationale**: Java 25 é a versão LTS mais recente na data do plano e é
suportada para execução pelo Gradle 9.1 ou posterior. Isso cumpre a constituição
sem adotar uma release intermediária.

**Alternatives considered**:

- Java 21 LTS: madura, mas não é a LTS mais recente exigida pelo projeto.
- Java 26/27: releases não LTS e, no caso do Java 27, ainda não suportada pelo
  Gradle atual.

**Sources**:

- <https://www.oracle.com/java/technologies/java-se-support-roadmap.html>
- <https://docs.gradle.org/current/userguide/compatibility.html>

## Kotlin and Gradle

**Decision**: Usar Kotlin 2.4.20, Gradle Wrapper 9.7.1 e Kotlin DSL.

**Rationale**: Kotlin 2.4.20 é a release estável atual e Gradle 9.7.1 declara
compatibilidade com Kotlin 2.4.x e Java 25. O Wrapper fixa e provisiona o Gradle
sem instalação global. Kotlin DSL mantém build logic tipada e consistente com
os futuros serviços Kotlin.

**Alternatives considered**:

- Gradle instalado globalmente: rejeitado por não garantir builds
  reproduzíveis.
- Groovy DSL: válido, mas adicionaria uma terceira linguagem principal ao
  repositório sem benefício para o objetivo.
- Builds Gradle independentes por serviço: adiados; aumentariam manutenção no
  estágio inicial e dificultariam verificações comuns no monorepo.

**Sources**:

- <https://kotlinlang.org/docs/releases.html>
- <https://docs.gradle.org/current/userguide/compatibility.html>
- <https://docs.gradle.org/current/userguide/gradle_wrapper.html>
- <https://docs.gradle.org/current/userguide/multi_project_builds.html>

## Build Organization

**Decision**: Usar um build multi-project com version catalog e convention
plugins em included build `build-logic`.

**Rationale**: A raiz oferece `build`, `check`, `test`, `spotlessCheck` e
`spotlessApply` consistentes, enquanto cada serviço mantém plugins e
dependências explícitos. Convention plugins compartilham somente regras
técnicas neutras; código de domínio não será compartilhado.

**Alternatives considered**:

- Um único módulo: rejeitado porque apagaria os limites dos futuros serviços.
- Biblioteca `shared` genérica: rejeitada pelo risco de acoplamento de domínio.
- Repetir configuração em cada serviço: rejeitado por divergência e
  manutenção desnecessária.

**Sources**:

- <https://docs.gradle.org/current/userguide/multi_project_builds.html>
- <https://docs.gradle.org/current/userguide/platforms.html>

## Formatting and Build Tests

**Decision**: Aplicar Spotless 8.10.2 nas fontes Java, Kotlin, Kotlin Gradle,
Markdown, JSON e YAML. Validar build logic com JUnit 6.1.3 e Gradle TestKit.

**Rationale**: Um único plugin oferece verificação e aplicação explícitas de
formatação. O hook usa apenas `spotlessCheck`; a aplicação fica em comando
separado para não alterar arquivos silenciosamente. TestKit executa builds
reais isolados e verifica convention plugins pelo comportamento.

**Alternatives considered**:

- Formatar automaticamente no pre-commit: rejeitado porque pode alterar o
  working tree e tornar o conteúdo efetivamente commitado menos previsível.
- Configurar formatadores desconectados por módulo: rejeitado por duplicação.
- Testar apenas scripts estaticamente: rejeitado porque não prova que o build
  funciona.

**Sources**:

- <https://plugins.gradle.org/plugin/com.diffplug.spotless>
- <https://docs.gradle.org/current/userguide/test_kit.html>
- <https://docs.junit.org/current/user-guide/>

## WSL and Container Runtime

**Decision**: Suportar Ubuntu 22.04 ou posterior no WSL 2, com Docker Desktop
WSL integration e Linux containers. Manter o checkout no filesystem Linux.

**Rationale**: O backend WSL 2 evita manter scripts Windows e Linux separados,
fornece Docker CLI dentro da distribuição e melhora o desempenho de filesystem
em comparação com trabalhar sob `/mnt/c`.

**Alternatives considered**:

- Docker Engine instalado também dentro da distribuição: rejeitado porque pode
  conflitar com Docker Desktop.
- Executar primariamente pelo PowerShell/NTFS: rejeitado por divergência do
  ambiente Linux e desempenho inferior para builds com muitos arquivos.
- Máquina virtual dedicada: rejeitada por custo e fricção desnecessários.

**Source**:

- <https://docs.docker.com/desktop/features/wsl/>

## Compose Lifecycle and Configuration

**Decision**: Usar `compose.yaml` na raiz, projeto nomeado explicitamente,
`.env.example`, variáveis obrigatórias com erro, volumes nomeados e health
checks. Dependências usam `condition: service_healthy` quando readiness for
necessário.

**Rationale**: Um nome fixo evita colisões acidentais; interpolação permite
configuração local sem versionar segredos; volumes preservam dados; health
checks distinguem processo iniciado de serviço pronto.

**Alternatives considered**:

- Apenas `depends_on` simples: rejeitado porque não espera readiness.
- Bind mounts para dados persistentes: rejeitados como padrão por diferenças de
  permissões e filesystem entre hosts.
- Valores secretos em `.env` versionado: rejeitados por segurança.

**Sources**:

- <https://docs.docker.com/compose/how-tos/startup-order/>
- <https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/>
- <https://docs.docker.com/compose/how-tos/project-name/>

## Git Hooks and Commit Validation

**Decision**: Usar Node.js 24 LTS para tooling; Husky 9.1.7 para `pre-commit` e
`commit-msg`; lint-staged 17.5.1 para selecionar arquivos; commitlint 21.2.3
com política local de tipos; Prettier 3.9.8 para arquivos textuais.

**Rationale**: Husky mantém hooks versionados. lint-staged limita validações ao
conteúdo preparado, cria backup temporário e preserva mudanças parciais. O
pre-commit executa verificações, não correções: Prettier `--check` para
documentação/configuração e Gradle `spotlessCheck`/testes quando arquivos JVM ou
de build são staged. O `commit-msg` fornece feedback imediato e consistente.

**Alternatives considered**:

- Hook shell sem Husky: rejeitado por contrariar a constituição.
- Executar `spotlessApply` no hook: rejeitado por modificar arquivos durante o
  commit.
- Validar apenas em CI: rejeitado por feedback tardio e requisito explícito de
  pre-commit.
- Node 26 Current: rejeitado em favor de uma linha LTS.

**Sources**:

- <https://nodejs.org/en/about/previous-releases>
- <https://typicode.github.io/husky/get-started.html>
- <https://github.com/lint-staged/lint-staged>
- <https://commitlint.js.org/guides/local-setup.html>

## Failure Semantics

**Decision**: Todos os scripts retornam `0` apenas quando o objetivo foi
atingido; erros de pré-requisito usam saída acionável e código diferente de
zero. `up` aguarda saúde com timeout, `status` mostra estados e `reset` exige
confirmação explícita ou flag não interativa.

**Rationale**: Sucesso não pode mascarar ambiente parcial ou indisponível. A
distinção por código de saída permite uso humano e automação futura.

**Alternatives considered**:

- Retornar sucesso após apenas criar containers: rejeitado porque running não
  significa ready.
- Remover volumes no comando normal de parada: rejeitado por risco de perda de
  dados.
- Recuperar automaticamente de toda falha: rejeitado porque esconderia a causa
  e dificultaria o aprendizado.
