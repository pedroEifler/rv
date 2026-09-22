<!--
Sync Impact Report
- Version change: unratified scaffold -> 1.0.0
- Modified principles: all five scaffold principles replaced with project-specific
  architecture, testing, integration, observability, and educational-design rules.
- Added sections: Additional Constraints; Development Workflow.
- Removed sections: none.
- Follow-up TODOs: confirm the original ratification date.
-->

# Breaking Bad Production Simulator Constitution

## Core Principles

### I. Microservice Boundaries and Data Ownership
Cada etapa do fluxo simulado — estoque, ordem de compra, preparação de
ingredientes, mixing, heating, cooling, quality, packaging, distribution e
delivery — MUST ser implementada como um microserviço independente quando fizer
parte do produto. Cada serviço MUST possuir seu próprio banco e não pode acessar
diretamente o banco de outro serviço. A comunicação MUST ocorrer por APIs ou
mensageria com contratos explícitos. A separação existe para tornar observáveis
os limites de contexto, falhas, consistência e padrões de integração estudados.

### II. Escolha Justificada de Tecnologia
Cada serviço MUST escolher entre PostgreSQL e MongoDB com base no modelo de
dados, consistência, consultas, volume e padrão de acesso daquele serviço; a
escolha e suas consequências MUST ser registradas na documentação técnica.
Java ou Kotlin MUST ser escolhido por serviço conforme o melhor encaixe
didático e técnico, usando a versão Java LTS suportada pelo projeto, Kotlin
compatível e Gradle. Abstrações, interfaces, herança, SOLID, coleções, filas,
cache, threads e locks MUST ser usados somente quando demonstrarem um conceito
relevante ou resolverem uma necessidade real do serviço.

### III. TDD, Contratos e Qualidade Verificável
Novas regras de negócio MUST começar por testes automatizados que expressem o
comportamento esperado, seguindo o ciclo Red-Green-Refactor sempre que
praticável. Cada serviço MUST ter testes unitários e testes de integração para
persistência e comunicação; contratos de API e eventos MUST ter testes de
compatibilidade. Uma alteração só pode ser considerada pronta quando os testes,
formatação, análise estática e validações obrigatórias passarem.

### IV. Integração Resiliente e Eventos Observáveis
Cada interação entre serviços MUST escolher conscientemente entre chamada
síncrona, fila, evento ou WebSocket, documentando a razão, os limites de
consistência, timeout, retry, idempotência e tratamento de duplicidade. Falhas
de rede, indisponibilidade, mensagens fora de ordem e reprocessamento MUST ser
testáveis. Logs estruturados, correlação de requisições, métricas essenciais e
documentação OpenAPI/Swagger MUST permitir acompanhar uma ordem desde o estoque
até a entrega.

### V. Simulação Segura, Reprodutível e Sem Spoilers
O sistema MUST tratar a obra apenas como ambientação ficcional, sem reproduzir
procedimentos químicos reais, instruções operacionais perigosas ou spoilers.
Eventos randômicos de falha, quantidade incorreta de ingredientes, variação de
qualidade e percalços de entrega MUST ser modelados como regras abstratas,
testáveis e configuráveis. A aleatoriedade MUST aceitar uma seed para permitir
reprodução. Atores simulados podem ser representados por threads ou tarefas
concorrentes com atributos únicos, mas esses atributos MUST influenciar outros
serviços somente por eventos ou contratos explícitos, nunca por estado
compartilhado. Concorrência MUST incluir testes de race conditions, locks,
ordenação e recuperação.

## Additional Constraints

O ambiente de desenvolvimento e execução local MUST funcionar em WSL com Docker
e Docker Compose, permitindo subir, parar, observar e reiniciar os serviços sem
dependências manuais ocultas. Cada serviço MUST fornecer configuração externa,
health check, migrações ou inicialização de banco reproduzível e documentação
de execução.

O repositório MUST usar commits no padrão Conventional Commits, incluindo tipos
como `feat`, `fix`, `docs`, `refactor`, `test`, `build` e `chore`. Um hook de
pre-commit via Husky MUST executar formatação e as validações de padrão
definidas pelo projeto. O pipeline local e o de integração MUST rejeitar
commits que violem esses contratos.

O design MUST favorecer simplicidade e evolução incremental. Código duplicado,
acoplamento entre bancos, estado global mutável e abstrações sem caso de uso
MUST ser evitados. Toda complexidade adicional MUST ter justificativa
documentada. Javadoc ou KDoc MUST explicar APIs públicas e decisões não óbvias.
Uma futura interface visual pode consumir os mesmos contratos públicos, sem
alterar a autonomia dos serviços.

## Development Workflow

Cada mudança MUST ser descrita por comportamento observável, serviço afetado,
contrato alterado, estratégia de persistência e estratégia de teste. A
implementação MUST preservar compatibilidade ou documentar explicitamente a
migração e a quebra de contrato. Pull requests MUST incluir evidências das
validações executadas e uma revisão de conformidade com esta constituição.

O desenvolvimento deve evoluir em fatias verticais: primeiro um fluxo mínimo
executável, depois persistência, integração, falhas, concorrência,
observabilidade e otimizações. Novos padrões de design MUST vir acompanhados
de um exemplo pequeno e de um teste que torne seu propósito visível. Serviços
que simulam eventos aleatórios MUST permitir execução determinística em testes
e execução configurável no ambiente local.

## Governance

Esta constituição é a autoridade para decisões de arquitetura, qualidade,
segurança da simulação e fluxo de contribuição. Em caso de conflito, uma regra
mais específica pode detalhar, mas não contradizer, estes princípios.

Alterações exigem uma proposta no pull request, contendo motivação, impacto nos
serviços, migração necessária, impacto educacional e atualização dos testes ou
documentação afetados. A alteração MUST ser revisada antes de ser incorporada.
Toda revisão deve verificar limites de dados, contratos, testes, observabilidade,
reprodutibilidade da simulação e conformidade com o fluxo de commits.

O versionamento da constituição segue SemVer:

- MAJOR para remover ou redefinir uma regra de modo incompatível.
- MINOR para adicionar um princípio, seção ou requisito material.
- PATCH para esclarecimentos, correções editoriais e refinamentos sem mudança
  de obrigação.

Uma revisão de conformidade MUST ocorrer em cada mudança arquitetural relevante
e antes de uma release. Violações devem ser corrigidas ou acompanhadas de uma
exceção explícita, temporária, aprovada no pull request e com responsável e
prazo de remoção. A constituição deve ser atualizada na mesma mudança quando a
regra deixar de refletir o projeto.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirmar a data de adoção inicial | **Last Amended**: 2026-09-22
