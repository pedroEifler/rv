# Data Model: Development Environment Setup

Esta feature não persiste entidades de negócio. O modelo abaixo descreve os
artefatos de configuração e estados observáveis que formam o contrato do
ambiente.

## Development Environment Profile

Representa as versões e capacidades necessárias para executar o projeto.

| Field | Description | Validation |
|-------|-------------|------------|
| `wslVersion` | Versão principal do WSL | Deve ser `2` |
| `distribution` | Distribuição Linux ativa | Ubuntu 22.04 ou posterior |
| `dockerAvailable` | Docker CLI acessível dentro do WSL | Deve ser verdadeiro |
| `composeAvailable` | Docker Compose acessível | Deve ser verdadeiro |
| `javaVersion` | Runtime/toolchain JVM | Deve corresponder ao Java 25 |
| `nodeVersion` | Runtime do tooling de hooks | Deve pertencer à linha Node 24 LTS |
| `repositoryFilesystem` | Local do checkout | Deve ser filesystem Linux, não `/mnt/*` |

**Relationships**: É validado pelo comando `doctor` e referencia o Build
Toolchain e o Container Environment.

## Build Toolchain

Representa as versões versionadas e tarefas comuns do monorepo.

| Field | Description | Validation |
|-------|-------------|------------|
| `gradleVersion` | Versão distribuída pelo Wrapper | Exatamente 9.7.1 |
| `javaToolchain` | Versão usada para compilar/testar | Exatamente 25 |
| `kotlinVersion` | Versão do plugin Kotlin | Exatamente 2.4.20 |
| `formatPolicy` | Regras comuns de formato | Deve ter modos check e apply separados |
| `verificationTasks` | Tarefas obrigatórias | Deve incluir build, test e quality checks |

**Relationships**: Um Build Toolchain configura zero ou mais Service Modules e
é consumido pelo Quality Gate.

## Service Definition

Representa um componente local coordenado pelo ambiente.

| Field | Description | Validation |
|-------|-------------|------------|
| `name` | Nome estável do componente | Minúsculo, palavras separadas por hífen |
| `imageOrBuild` | Origem executável | Exatamente uma origem válida |
| `dependencies` | Componentes dos quais depende | Sem ciclos |
| `healthCheck` | Critério de readiness | Obrigatório para serviço de longa duração |
| `configuration` | Variáveis aceitas | Valores secretos nunca versionados |
| `persistentVolumes` | Dados preservados entre reinícios | Volumes nomeados |

**Relationships**: Pertence ao Container Environment e pode depender de outras
Service Definitions saudáveis.

## Container Environment

Representa uma instância local do conjunto de componentes.

| Field | Description | Validation |
|-------|-------------|------------|
| `projectName` | Namespace do ambiente | Valor fixo e válido para Compose |
| `services` | Componentes participantes | Ao menos um smoke component nesta feature |
| `configurationSource` | Valores locais | `.env` ignorado e exemplo versionado |
| `volumes` | Dados persistentes | Não removidos por parada normal |
| `state` | Estado agregado | Um dos estados definidos abaixo |

### State Transitions

```text
NOT_CONFIGURED -> STOPPED -> STARTING -> HEALTHY
                         \-> DEGRADED
                         \-> FAILED
HEALTHY -> STOPPING -> STOPPED
DEGRADED|FAILED -> STOPPING -> STOPPED
STOPPED -> RESETTING -> STOPPED
```

- `HEALTHY` exige que todos os componentes obrigatórios estejam saudáveis.
- `DEGRADED` indica que ao menos um componente iniciou, mas não está saudável.
- `FAILED` indica erro que impede a operação mínima.
- `reset` é a única transição que remove volumes persistentes.

## Quality Gate

Representa uma validação aplicada antes do commit ou sob comando explícito.

| Field | Description | Validation |
|-------|-------------|------------|
| `name` | Identificador da verificação | Único e legível |
| `trigger` | Momento de execução | `pre-commit`, `commit-msg` ou manual |
| `fileScope` | Arquivos relevantes | Derivado do stage quando aplicável |
| `command` | Verificação não interativa | Deve retornar código significativo |
| `mutatesFiles` | Se altera conteúdo | Deve ser falso nos hooks |
| `failureMessage` | Orientação de correção | Obrigatória |

**Relationships**: Um hook executa um ou mais Quality Gates. O gate de mensagem
usa a Commit Policy.

## Commit Policy

Representa a gramática aceita para mensagens.

| Field | Description | Validation |
|-------|-------------|------------|
| `type` | Categoria da mudança | `feat`, `fix`, `docs`, `refactor`, `test`, `build` ou `chore` |
| `scope` | Área opcional afetada | Minúsculo e sem espaços |
| `breaking` | Indicador opcional `!` | Booleano |
| `description` | Resumo imperativo | Obrigatório e não vazio |
| `body` | Contexto opcional | Texto livre |
| `footer` | Metadados opcionais | Compatível com trailers Git |

**Canonical shape**:

```text
type(scope)!: description
```
