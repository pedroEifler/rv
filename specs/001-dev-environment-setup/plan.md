# Implementation Plan: Development Environment Setup

**Branch**: `001-dev-environment-setup` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from
`/specs/001-dev-environment-setup/spec.md`

## Summary

Estabelecer a fundação reproduzível do monorepo para desenvolvimento em WSL 2:
um build Gradle multi-project versionado, execução local coordenada por Docker
Compose, verificações de saúde e scripts únicos para o ciclo do ambiente.
Adicionar controles Husky para validar arquivos staged e mensagens Conventional
Commits sem alterar conteúdo não preparado. As decisões e versões estão
consolidadas em [research.md](./research.md).

## Technical Context

**Language/Version**: Java 25 LTS; Kotlin 2.4.20; JavaScript ESM executado em
Node.js 24 LTS apenas para tooling de contribuição

**Primary Dependencies**: Gradle Wrapper 9.7.1, Spotless 8.10.2, Docker Compose,
Husky 9.1.7, lint-staged 17.5.1, commitlint 21.2.3 e Prettier 3.9.8

**Storage**: Volumes nomeados do Docker para dados locais persistentes; nenhum
banco de domínio será criado nesta feature

**Testing**: JUnit 6.1.3, Gradle TestKit, testes shell de smoke/end-to-end e
cenários isolados de hooks Git

**Target Platform**: Ubuntu 22.04 ou posterior em WSL 2, com Docker Desktop
integrado à distribuição Linux

**Project Type**: Fundação de monorepo Gradle multi-project para futuros
microserviços JVM

**Performance Goals**: Ambiente saudável em até 5 minutos após imagens e
dependências estarem em cache; validação pre-commit em até 60 segundos para uma
mudança típica; diagnóstico inicial em até 10 segundos

**Constraints**: Operação primária dentro do filesystem Linux do WSL; nenhuma
dependência global de Gradle; hooks não podem adicionar ou modificar
silenciosamente arquivos fora do stage; configurações locais não podem conter
segredos versionados; comandos devem funcionar sem interação para futura CI

**Scale/Scope**: Um monorepo, base para cerca de 10 microserviços independentes;
nesta feature apenas build logic, tooling, scripts, configuração de ambiente e
um componente mínimo de smoke test

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Constitutional rule | Status | Evidence |
|---------------------|--------|----------|
| Serviços mantêm limites e dados próprios | PASS | A estrutura reserva `services/` sem introduzir banco ou código compartilhado de domínio. |
| Java/Kotlin LTS compatível e Gradle | PASS | Java 25 LTS, Kotlin 2.4.20 e Gradle Wrapper 9.7.1 são versões compatíveis e fixadas. |
| Testes e validações são obrigatórios | PASS | `check`, TestKit, smoke tests e hooks são parte da entrega. |
| Integrações têm saúde e observabilidade | PASS | Compose usa health checks e status explícito; não há integração de negócio nesta feature. |
| Simulação segura e determinística | PASS | Nenhuma simulação ou conteúdo temático é implementado nesta feature. |
| WSL, Docker e Compose | PASS | São o alvo e os mecanismos centrais do ambiente local. |
| Husky e Conventional Commits | PASS | Hooks pre-commit e commit-msg são contratos obrigatórios do design. |
| Simplicidade e evolução incremental | PASS | Apenas fundação e smoke component; serviços de domínio ficam fora do escopo. |

### Post-Design Gate

| Constitutional rule | Status | Design verification |
|---------------------|--------|---------------------|
| Isolamento de serviços | PASS | Cada futuro serviço terá diretório, build e container próprios; convenções não incluem domínio compartilhado. |
| Escolhas justificadas | PASS | `research.md` registra decisão, motivo e alternativas para cada tecnologia. |
| Qualidade verificável | PASS | `contracts/developer-commands.md` define resultados e códigos de saída; `quickstart.md` cobre cenários positivos e negativos. |
| Saúde e falhas explícitas | PASS | O contrato diferencia running, healthy, unhealthy e dependency failure. |
| Segurança da simulação | PASS | Sem superfície de simulação nesta entrega. |
| Fluxo de contribuição | PASS | O contrato de commit restringe tipos, formato e comportamento dos hooks. |

Todos os gates passam. Não há violações que exijam Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-dev-environment-setup/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── commit-policy.md
│   └── developer-commands.md
└── tasks.md
```

### Source Code (repository root)

```text
.
├── .husky/
│   ├── commit-msg
│   └── pre-commit
├── build-logic/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── src/
│       ├── main/kotlin/
│       └── test/kotlin/
├── gradle/
│   ├── libs.versions.toml
│   └── wrapper/
├── infra/
│   └── smoke/
├── scripts/
│   ├── dev/
│   │   ├── doctor.sh
│   │   ├── down.sh
│   │   ├── reset.sh
│   │   ├── status.sh
│   │   └── up.sh
│   └── quality/
│       ├── check-staged.sh
│       └── verify.sh
├── services/
│   └── .gitkeep
├── tests/
│   ├── environment/
│   └── hooks/
├── .editorconfig
├── .env.example
├── .gitattributes
├── .gitignore
├── .nvmrc
├── build.gradle.kts
├── commitlint.config.mjs
├── compose.yaml
├── gradlew
├── gradlew.bat
├── lint-staged.config.mjs
├── package-lock.json
├── package.json
├── README.md
└── settings.gradle.kts
```

**Structure Decision**: Usar um monorepo Gradle multi-project com convention
plugins isolados em `build-logic/`. `services/` é reservado para os futuros
microserviços, mas nenhum projeto inexistente será incluído no
`settings.gradle.kts`, pois Gradle 9 rejeita diretórios ausentes. Scripts em
`scripts/dev/` constituem a interface humana estável; Compose permanece na raiz
para descoberta padrão. Node é restrito ao tooling de hooks e documentação.

## Complexity Tracking

Não aplicável: o design não viola nenhum gate constitucional.
