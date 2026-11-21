# Registro de aprendizados

Aprendizados não óbvios, evidenciados e duráveis, capturados pela [skill lessons-learned](../../.agents/skills/lessons-learned/SKILL.md). O registro garante rastreabilidade. A regra em si vive no destino canônico indicado em cada entrada; este arquivo não substitui o `AGENTS.md`, as skills nem os how-tos.

## Formato

```markdown
### LL-NNNN — Título curto

- **Data:** AAAA-MM-DD
- **Contexto:** tarefa ou situação em que surgiu
- **Evidência:** comando e saída, mensagem do usuário, arquivo:linha ou documentação oficial com data
- **Aprendizado:** o que um agente precisa saber para não errar
- **Destino:** link para o documento canônico, ou "somente registro"
- **Status:** Proposta | Incorporada | Descartada (motivo)
```

Entradas não são reescritas. Se um aprendizado se mostrar errado, mude o status para Descartada com o motivo, ou crie uma entrada nova que o substitua.

## Entradas

<!-- kit:omit-start -->
### LL-0001 — Claude Code não descobre `.agents/skills/`

- **Data:** 2026-11-20
- **Contexto:** configuração multi-provider (Codex, Claude Code, Devin).
- **Evidência:** documentação e issues públicas consultadas em 2026-11-20. Na sessão, as skills só apareceram na lista do Claude Code depois que os stubs foram gerados em `.claude/skills/`.
- **Aprendizado:** Codex e Devin leem `AGENTS.md` e `.agents/skills/`. O Claude Code lê `CLAUDE.md` e `.claude/skills/`, e um `CLAUDE.md` existente faz o `AGENTS.md` ser ignorado, salvo se importado com `@AGENTS.md`.
- **Destino:** [ADR-0002](../architecture/adr/0002-multi-provider-agent-context.md) e [context-engineering.md](context-engineering.md)
- **Status:** Incorporada

### LL-0002 — Docker Desktop parado aparece como FAIL da integração

- **Data:** 2026-11-20
- **Contexto:** `bash scripts/verify.sh` após mudanças de configuração.
- **Evidência:** saída `[FAIL] Docker indisponível; integração NOT RUN.`. O `docker info` mostrou o cliente, mas falhou ao conectar em `npipe:////./pipe/dockerDesktopLinuxEngine` ("The system cannot find the file specified").
- **Aprendizado:** no Windows, `docker` no PATH não significa daemon ativo. O diagnóstico é o erro de conexão no pipe `dockerDesktopLinuxEngine`, e a solução é iniciar o Docker Desktop. Nunca contornar com `SKIP_INTEGRATION=1` sem autorização.
- **Destino:** [run-tests.md, Diagnóstico](../how-to/run-tests.md#diagnóstico)
- **Status:** Incorporada

### LL-0003 — `env "$@"` em helpers de teste consome argumentos do script

- **Data:** 2026-11-20
- **Contexto:** criação de `scripts/tests/test-agent-config.sh`.
- **Evidência:** a chamada `check ... sync-agent-skills.sh --check` falhou com `env: unknown option -- check`, exit 125.
- **Aprendizado:** misturar variáveis de ambiente e argumentos posicionais em `env "$@" bash script` faz o `env` interpretar opções do script. Separe as duas coisas: variáveis por uma variável dedicada (`CHECK_ENV`) e argumentos repassados com `"$@"` ao script.
- **Destino:** somente registro (padrão aplicado em `scripts/tests/test-agent-config.sh`)
- **Status:** Incorporada

### LL-0004 — Configuração e regras do Codex só valem em projeto confiável

- **Data:** 2026-11-20
- **Contexto:** criação de `.codex/config.toml` e `.codex/rules/delivery.rules`.
- **Evidência:** documentação oficial do Codex (configuração e regras) consultada em 2026-11-20. `codex execpolicy check --rules .codex/rules/delivery.rules -- git push --force` retornou `"decision":"forbidden"` (codex-cli 0.167.0).
- **Aprendizado:** a camada `.codex/` do projeto é ignorada até o projeto ser marcado como confiável. As regras podem ser validadas offline com `codex execpolicy check`, e os exemplos `match`/`not_match` são verificados ao carregar.
- **Destino:** [context-engineering.md](context-engineering.md)
- **Status:** Incorporada

### LL-0005 — No Git Bash, cada processo criado custa caro

- **Data:** 2026-11-20
- **Contexto:** otimização de `check-agent-config.sh` e `sync-agent-skills.sh`.
- **Evidência:** com `awk`, `sed`, `cat` e `basename` por arquivo, o check levou 9,4 s e o `sync --check` 2,9 s. Com uma passada `awk` sobre todos os arquivos e expansões do Bash no laço, os tempos caíram para 2,3 s e 0,15 s (medidos com `time`), com saída idêntica.
- **Aprendizado:** em scripts do harness que percorrem muitos arquivos, agregue o trabalho em um único `awk`/`find`, use `$(<arquivo)` e expansões de parâmetro em vez de `cat`, `basename` e `dirname`, e evite `$(...)` dentro de laços.
- **Destino:** somente registro (aplicado nos dois scripts)
- **Status:** Incorporada

### LL-0006 — No Windows, encerrar o `mvnw` não encerra a JVM da aplicação

- **Data:** 2026-11-20
- **Contexto:** smoke k6 real contra a aplicação iniciada com `bash ./mvnw spring-boot:test-run` em segundo plano.
- **Evidência:** depois de interromper a tarefa em segundo plano (bash/mvnw), `curl http://localhost:8080/actuator/health` ainda retornou `{"status":"UP"}` e `netstat` mostrou a porta 8080 em LISTEN pelo PID 19652, o mesmo PID do log `Started JavaAiEngineeringLabApplication`. A porta só foi liberada com `Stop-Process -Id 19652`.
- **Aprendizado:** no Git Bash/Windows, encerrar o processo pai não propaga o sinal à JVM filha do plugin Spring Boot. Encerre com `Ctrl+C` no próprio terminal ou finalize o PID registrado no log da aplicação, e confirme que a porta foi liberada antes de declarar o ambiente limpo.
- **Destino:** [run-tests.md, Performance](../how-to/run-tests.md#performance)
- **Status:** Incorporada

### LL-0007 — `scripts/test/` e `scripts/tests/` lado a lado são ambíguos

- **Data:** 2026-11-20
- **Contexto:** reorganização de `scripts/` em subpastas por domínio.
- **Evidência:** a primeira proposta mantinha `scripts/test/` (suítes do projeto) ao lado de `scripts/tests/` (testes do próprio harness). Os nomes diferem por uma letra e não dizem o que testam.
- **Aprendizado:** nomeie pastas pelo domínio do que contêm. Os testes do harness ficaram em `scripts/harness-tests/`, e a verificação de caminhos em `scripts/agents/check-config.sh` impede referências a nomes antigos.
- **Destino:** somente registro (aplicado na estrutura de `scripts/`)
- **Status:** Incorporada

### LL-0008 — Padrões genéricos do `.gitignore` podem esconder scripts do harness

- **Data:** 2026-11-20
- **Contexto:** reorganização de `scripts/`, com a criação de `scripts/build/compile.sh`.
- **Evidência:** `git check-ignore -v scripts/build/compile.sh` retornou `.gitignore:28:build/`. Numa prévia com índice temporário, `scripts/build.sh` aparecia como removido e o novo arquivo não aparecia. Todas as verificações que usam `find` passavam, porque não consideram o `.gitignore`.
- **Aprendizado:** padrões herdados de templates (`build/`, `out/`, `bin/`) também atingem pastas de código e scripts. Ao criar pastas com esses nomes, confira com `git check-ignore`. O `scripts/agents/check-config.sh` agora falha se qualquer arquivo do harness ou da configuração de agentes estiver ignorado.
- **Destino:** `.gitignore` (exceção `!/scripts/build/`) e verificação 8 de `scripts/agents/check-config.sh`
- **Status:** Incorporada

### LL-0009 — A feature Java do devcontainer resolve a versão principal para o patch mais recente

- **Data:** 2026-11-20
- **Contexto:** criação de `.devcontainer/devcontainer.json` com `ghcr.io/devcontainers/features/java:1.8.3` e `"version": "27"`.
- **Evidência:** `devcontainer build` (CLI 0.87.0) concluiu com `"outcome":"success"`. Dentro da imagem, `java -version` mostrou `Temurin-27.0.1.1+4`, enquanto o baseline local é `openjdk version "27"` (27 GA).
- **Aprendizado:** fixar imagem e versão da feature não fixa o patch do JDK. A feature instala o patch mais recente da linha 27 via SDKMAN no momento do build, então o devcontainer pode estar à frente do baseline local. Para reprodutibilidade estrita, informe a versão completa (por exemplo `27.0.1.1-tem`) e atualize-a deliberadamente.
- **Destino:** `.devcontainer/devcontainer.json`, que fixa `"version": "27.0.1.1+4"` (identificador SDKMAN `27.0.1.1+4-tem`, conferido com `devcontainer build` em 2026-11-20). Atualizações passam a ser deliberadas; se o SDKMAN deixar de publicar o patch, o build falha e sinaliza a necessidade de atualizar.
- **Status:** Incorporada (decisão do responsável em 2026-11-20)

### LL-0010 — Repositórios Git temporários em `target/` quebram o `mvn clean` no Windows

- **Data:** 2026-11-20
- **Contexto:** primeira execução do `verify.sh` depois de criar `scripts/harness-tests/git-hooks.sh`.
- **Evidência:** `maven-clean-plugin:3.5.0:clean` falhou com `Failed to delete ...\target\git-hooks-check.Az5hjP\repo with spaces\.git\objects\4b\825dc642...`. O Git grava os objetos como somente leitura, e no Windows o `clean` não consegue apagá-los.
- **Aprendizado:** testes do harness que criam repositórios Git (ou qualquer arquivo somente leitura) dentro de `target/` precisam removê-los ao sair, com `trap` e `chmod -R u+w` antes do `rm -rf`, inclusive em falha. Senão, o próximo `verify.sh` falha no build, sem relação com o código.
- **Destino:** aplicado em `scripts/harness-tests/git-hooks.sh`; somente registro
- **Status:** Incorporada

### LL-0011 — Testes do harness não podem depender de o projeto estar vazio

- **Data:** 2026-11-20
- **Contexto:** primeira execução de `scripts/harness-tests/quality-gates.sh` depois da FEAT-0001.
- **Evidência:** a cópia de `src/` passou a incluir `api` e `persistence` da feature real, cobertos só por `*IT`. Com apenas unitários na cópia, o caso "código conforme" falhou: `[FAIL] Cobertura: jacoco:check rejeitou os limites ou Maven falhou.`
- **Aprendizado:** um teste do harness que mede gates sobre código de exemplo precisa isolar esse exemplo do código real (remover `feature/`, `shared/` e as migrações da cópia). Senão ele passa no scaffold e quebra na primeira feature. Ao criar uma feature, execute também `harness-tests/quality-gates.sh` e `harness-tests/maven-isolation.sh`.
- **Destino:** aplicado em `scripts/harness-tests/quality-gates.sh`; somente registro
- **Status:** Incorporada

### LL-0012 — Jackson converte números e booleanos em `String` sem avisar

- **Data:** 2026-11-20
- **Contexto:** review do Devin no PR #1 (FEAT-0001).
- **Evidência:** antes da correção, `ProductCreationIT.rejectsNonStringTextFields` falhou: `{"sku":123,...}`, `{"name":true,...}` e `{"description":42,...}` retornaram `201` (Jackson 3.1.7, Spring Boot 4.1.2).
- **Aprendizado:** `fail-on-unknown-properties` não impede coerção de escalares. Campos cujo contrato exige string JSON precisam de validação de token (`JsonStringOnlyDeserializer`), assim como números exigem `JsonNumberOnlyDeserializer`. Teste o tipo errado de cada campo, não só os valores inválidos.
- **Destino:** `CreateProductRequest` e a skill `rest-api-contract` (regra 7)
- **Status:** Incorporada

### LL-0013 — Sem `produces`, o Spring executa o handler e só depois responde 406

- **Data:** 2026-11-20
- **Contexto:** review do Devin no PR #1.
- **Evidência:** `rejectsUnsupportedResponseMediaTypeWithoutPersisting` falhou antes da correção: com `Accept: text/html`, a resposta foi `406`, mas o produto já estava gravado (count esperado 0).
- **Aprendizado:** a negociação de conteúdo da resposta acontece depois do método do controller. Endpoints com efeito colateral (`POST`, `PUT`, `DELETE`) devem declarar `produces` para que um `Accept` incompatível seja rejeitado no mapeamento, antes da transação.
- **Destino:** `ProductController` e a skill `rest-api-contract` (regra 8)
- **Status:** Incorporada

### LL-0014 — Hooks recebem um índice temporário em `GIT_INDEX_FILE`

- **Data:** 2026-11-20
- **Contexto:** review do Devin no PR #1, sobre `scripts/security/scan-secrets.sh`.
- **Evidência:** com um token falso preparado só em `GIT_INDEX_FILE=.git/probe-index`, `scan-secrets.sh --staged` via Docker retornou `[PASS]`, porque o contêiner lia o índice padrão. Depois da correção, retornou `[FAIL]` com `File: leak-probe.txt`.
- **Aprendizado:** em `git commit -a` e `git commit <caminhos>`, o Git define `GIT_INDEX_FILE` para os hooks. Ferramentas executadas em contêiner não herdam esse ambiente; repasse a variável com o caminho mapeado no volume.
- **Destino:** `scripts/security/scan-secrets.sh` e caso em `scripts/harness-tests/harness.sh`
- **Status:** Incorporada

### LL-0015 — Arquivos pessoais declarados no `.gitignore` não são artefatos perdidos

- **Data:** 2026-11-20
- **Contexto:** review do Devin no PR #1, sobre a verificação 8 de `scripts/agents/check-config.sh`.
- **Evidência:** com `.claude/settings.local.json` presente, o check retornou `[FAIL] Arquivo ignorado pelo .gitignore e não versionável: .claude/settings.local.json`, bloqueando `verify.sh` e o `pre-commit`.
- **Aprendizado:** uma verificação de "arquivo ignorado por engano" precisa de uma lista explícita de exceções para os arquivos locais que o próprio projeto declara (`local_files` no check). Teste os dois lados: o arquivo pessoal passa e um script novo ignorado continua sendo detectado.
- **Destino:** `scripts/agents/check-config.sh` e caso em `scripts/harness-tests/agent-config.sh`
- **Status:** Incorporada

### LL-0016 — Saída de `ls` não serve de lista de exclusão para apagar

- **Data:** 2026-11-21
- **Contexto:** limpeza de um projeto de teste para reaplicar o kit, com `ls -A | grep -vx -e app -e infra` alimentando `rm -rf`.
- **Evidência:** no Git Bash deste ambiente, `ls -A` mostra diretórios com barra final (`app/`); o filtro não protegeu nada, e `app/` e `infra/` foram apagados. A recuperação regenerou o projeto pelo Spring Initializr com os mesmos parâmetros, e os 10 arquivos conferiram com os SHA-1 registrados antes da limpeza.
- **Aprendizado:** para apagar, enumere os alvos por caminho explícito (ou `find -mindepth 1 -maxdepth 1 ! -name ...`), mostre a lista antes de executar e registre hashes do que precisa sobreviver. A formatação do `ls` depende do perfil do shell.
- **Destino:** este registro (a regra geral de conferir o alvo antes de apagar já vale para os agentes)
- **Status:** Registrada
<!-- kit:omit-end -->
