# ADR-005 — Criptografia em repouso e o `dbtool`

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4
- **Data:** 2026-09-20
- **Responde:** BL-014 e BL-015

## Contexto

Dois pedidos do projeto se contradizem: o registro deve ficar **cifrado em repouso**, e deve dar para **ler por SSH**. Arquivo cifrado não se lê com `cat`. E há um problema técnico por baixo (BL-015): não se acrescenta uma linha a um arquivo cifrado inteiro — seria preciso decifrar e recifrar tudo a cada evento.

O que se quer proteger, e de quê: cópia do disco, backup extraviado e arquivo lido por quem entrou na VM sem ser root. **Não** se promete proteção contra quem toma o processo em execução: ele precisa da chave para funcionar.

## Decisão

1. **Cifra por registro.** Cada linha do registro de eventos é um envelope independente: `AES-256-GCM`, com `nonce` único por registro, em base64. Acrescentar um evento é acrescentar uma linha; nada é recifrado.
2. **A cadeia de hash é calculada sobre a linha cifrada**, e os dados autenticados do envelope incluem `seq` e `prev`. Consequências: alterar, reordenar ou remover registros do meio é detectável (cortar o fim pede uma âncora fora do disco — ver abaixo); e conferir a integridade **não exige a chave** — o backup pode ser verificado em qualquer máquina.
3. **A chave de dados** (32 bytes) nasce no servidor e é guardada como **credencial cifrada do systemd** (`systemd-creds`), entregue só ao serviço da API, em memória. Não está em variável de ambiente, em arquivo legível nem no repositório.
4. **`dbtool`** é a resposta ao "ler por SSH": uma ferramenta de linha de comando, só de leitura, iniciada por `systemd-run` para receber a credencial do mesmo jeito que o serviço — o que exige `sudo`, e deixa rastro no diário do sistema.
   - `dbtool cat [--month 2026-09]` — decifra e imprime JSON legível
   - `dbtool verify` — percorre a cadeia e aponta o registro exato em que ela quebra
   - `dbtool export` — gera um pacote decifrado para migração
   - `dbtool enroll` — emite o código de cadastro de aparelho ([ADR-008](ADR-008-autenticacao.md))
5. **O backup é cifrado de novo antes de sair da VM**, com `age`, para uma chave pública cuja metade privada **não está no servidor** — fica com o dono, fora da nuvem. Comprometer a VM depois não abre os backups antigos. Destinos: armazenamento de objetos gratuito da própria Oracle (outro domínio de falha que o disco da VM) e uma cópia puxada para o computador do dono.
6. No **aparelho**, o mesmo envelope cifra o armazenamento local, com chave guardada no Android Keystore ([ADR-012](ADR-012-modo-offline.md)).

### O que a cadeia não pega sozinha

Descoberto ao escrever os testes: alterar, remover do meio ou reordenar registros quebra a cadeia, mas **cortar as últimas linhas inteiras** deixa uma cadeia válida, só que mais curta. Nenhuma estrutura guardada no mesmo disco resolve isso — quem corta o registro corta também a âncora. A âncora precisa estar fora do alcance de quem tem o disco:

- o **app guarda o maior `seq` que já viu**; o servidor informa o seu a cada sincronização, e um número menor vira aviso de segurança dentro do app (`E-DATA-02`). Entra com o backend, no passo F6-03;
- o **backup diário**, que é um prefixo do registro: `dbtool verify` numa cópia de ontem diz quantos registros havia.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Cifrar o arquivo inteiro | Cada evento exigiria regravar tudo; a queda no meio corromperia o registro |
| Disco cifrado (LUKS) e arquivos em claro | Protege contra roubo do disco, mas não contra backup em claro nem contra leitura por outro usuário da VM. E pede senha a cada reinício, ou chave no próprio disco |
| Chave em variável de ambiente ou em `.env` | Aparece em `ps`, em despejo de processo e em erro de configuração. A credencial do systemd existe para isso |
| Cofre de segredos gerenciado | Não existe a custo zero. É uma das exceções ao ASVS nível 2 registradas no BL-013 |
| Backup cifrado com a mesma chave de dados | Quem levasse a chave do servidor levaria todos os backups |

## Consequências

- **Bom:** os dois pedidos ficam atendidos, e a contradição vira uma ferramenta pequena e testada.
- **Bom:** integridade verificável sem segredo: `dbtool verify` roda até numa cópia de backup.
- **Custo:** quem é root na VM lê a chave. É o limite honesto de uma VM só; o modelo de ameaças da Fase 5 parte daqui.
- **Custo:** perder a chave privada do `age` é perder os backups. Ela ganha um ritual de guarda no runbook, e a **restauração é ensaiada** na Fase 7, antes de haver dado real.
- **Biblioteca:** implementação em Dart puro (`cryptography`), para não levar dependência nativa à compilação cruzada. O volume é de poucos registros por minuto.

## Como se confere

- Testes: registro alterado, removido, reordenado e truncado — todos detectados, com o `seq` apontado.
- Teste: a mesma mensagem cifrada duas vezes gera linhas diferentes (nonce único).
- Fase 7: restaurar um backup numa máquina limpa, do zero, com o roteiro cronometrado.
