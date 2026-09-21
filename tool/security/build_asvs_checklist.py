"""Gera docs/security/asvs-checklist.md a partir do CSV oficial do ASVS 5.0.0.

O checklist nasce do CSV, e não de digitação, para que nenhum número de
requisito seja inventado nem esquecido. O texto de cada requisito não é
copiado para o repositório: a tabela leva o identificador, e o texto se lê na
fonte.

Uso, da raiz do repositório:

    curl -L -o asvs.csv https://raw.githubusercontent.com/OWASP/ASVS/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv
    python tool/security/build_asvs_checklist.py asvs.csv

A situação de cada linha vem das tabelas abaixo. Quando um passo da Fase 6
entrega o controle, troca-se "planejado" por "atende" aqui, com a evidência, e
roda-se o script de novo.
"""

import csv
import sys
from collections import OrderedDict
from pathlib import Path

OUTPUT = Path("docs/security/asvs-checklist.md")

# Seção → (controle, onde está decidido, passo em que nasce).
SECTIONS = {
    "V1.1": ("Entrada decodificada uma vez, na borda da API", "ADR-015", "F6-03"),
    "V1.2": ("Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado", "ADR-010 · T-20", "F6-04"),
    "V1.3": ("Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado", "ADR-007 · ADR-010", "F6-04"),
    "V1.5": ("Só JSON, lido para tipos fechados e validado contra esquema", "ADR-015 · RNF-SEC-09", "F6-03"),
    "V2.1": ("As 345 regras RN-xxx são a documentação de validação", "docs/spec/rules", "feito"),
    "V2.2": ("O servidor revalida tudo com o mesmo domínio do app", "ADR-001 · T-05", "F6-03"),
    "V2.3": ("Limites de negócio no domínio; escrita tudo-ou-nada; chave de idempotência", "ADR-004 · ADR-012", "F6-02"),
    "V2.4": ("Limite de taxa por origem e global", "RNF-SEC-08 · T-11", "F6-03"),
    "V3.2": ("Interface em canvas; nenhum HTML montado a partir de dado", "ADR-013", "F6-12"),
    "V3.3": ("Cookie de sessão `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict`", "ADR-008", "F6-12"),
    "V3.4": ("HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy", "RNF-SEC-10 · BL-021", "Fase 7"),
    "V3.5": ("Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web", "ADR-011 · T-12", "F6-12"),
    "V3.7": ("Sem redirecionamento para destino vindo de dado", "ADR-013", "F6-12"),
    "V4.1": ("`Content-Type` com charset; a API não redireciona HTTP; cabeçalhos do proxy só valem vindos do Caddy", "ADR-003 · ADR-011", "F6-03 · Fase 7"),
    "V4.2": ("Limites de tamanho de mensagem no Caddy e na API", "ADR-003 · E-REQ-04", "F6-03"),
    "V5.1": ("Tipos e tamanhos aceitos documentados no fluxo de compartilhamento", "docs/spec/sharing-flow.md", "feito"),
    "V5.4": ("Exportação com nome gerado pelo servidor e tipo fixo", "ADR-005", "F6-02"),
    "V6.1": ("Os dois caminhos de autenticação documentados, com a defesa contra força bruta", "ADR-008", "feito"),
    "V6.3": ("Chave em hardware liberada por biometria assina desafio; sem conta padrão; web com força equivalente", "ADR-008 · T-02", "F6-11"),
    "V6.4": ("Trocar ou recuperar aparelho exige SSH na VM: é a prova de identidade", "ADR-008 · T-03", "F6-03"),
    "V6.5": ("Códigos de uso único, de gerador criptográfico, com validade curta", "ADR-008", "F6-03"),
    "V6.6": ("O código de pareamento nasce no aparelho autenticado e vale 2 minutos, uma vez", "ADR-008", "F6-11"),
    "V7.1": ("Tempos de sessão documentados: 15 min no app, 30 min de inatividade e 12 h na web", "ADR-008", "feito"),
    "V7.2": ("Token opaco de 128+ bits, validado no servidor, novo a cada autenticação", "ADR-008", "F6-03"),
    "V7.3": ("Tempo de inatividade e tempo absoluto aplicados no servidor", "ADR-008", "F6-03"),
    "V7.4": ("Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web", "ADR-008 · T-10", "F6-11"),
    "V7.5": ("Biometria de novo antes de parear; lista de sessões abertas no app", "ADR-008", "F6-11"),
    "V8.1": ("Uma regra: autenticado é o dono; sessão da web é só leitura", "ADR-008", "feito"),
    "V8.2": ("Aplicado no servidor, por rota", "ADR-008 · T-12", "F6-03"),
    "V8.3": ("Autorização decidida no servidor, nunca no cliente", "ADR-008", "F6-03"),
    "V11.1": ("Inventário de chaves e algoritmos na ADR-005", "ADR-005", "F6-02"),
    "V11.2": ("Algoritmos padrão atrás de uma porta, com versão no envelope para poder trocar", "ADR-005", "F6-02"),
    "V11.3": ("AES-256-GCM: cifra autenticada, nonce único por registro", "ADR-005 · T-31", "F6-02"),
    "V11.4": ("SHA-256 na cadeia do registro; nenhuma chave derivada de senha", "ADR-005", "F6-02"),
    "V11.5": ("Gerador criptográfico do sistema para nonce, token e código", "ADR-005 · ADR-008", "F6-02"),
    "V11.6": ("ECDSA P-256 para a chave do aparelho", "ADR-008", "F6-11"),
    "V12.1": ("Só TLS 1.2 e 1.3, configurados no Caddy", "RNF-SEC-02", "Fase 7"),
    "V12.2": ("Certificado público do Let's Encrypt, sem alternativa em claro", "ADR-011", "Fase 7"),
    "V12.3": ("Saída para a DeepSeek por HTTPS com validação; SSH só por chave", "ADR-010 · T-26", "F6-04 · Fase 7"),
    "V13.1": ("Toda comunicação externa está no diagrama de contêineres", "docs/architecture/c4.md", "feito"),
    "V13.2": ("Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup", "ADR-003 · T-36", "Fase 7"),
    "V13.3": ("Segredos só como credencial cifrada do systemd, entregue ao serviço em memória", "ADR-005 · T-27", "Fase 7"),
    "V13.4": ("Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem", "ADR-003", "Fase 7"),
    "V14.1": ("Classes de dado e o que pode sair do aparelho e do servidor, documentados", "ADR-010 · RN-989", "F6-04"),
    "V14.2": ("Nada sensível em URL; sem cache de resposta da API; mascaramento antes da IA", "ADR-010 · T-23", "F6-03 · F6-04"),
    "V14.3": ("A web não grava nada no navegador além do cookie de sessão; `Clear-Site-Data` ao sair", "ADR-008 · T-10", "F6-12"),
    "V15.1": ("Prazo de correção de dependência e funções caras documentados", "ADR-014", "F6-03"),
    "V15.2": ("Versões travadas num `pubspec.lock` único; nada de teste no build de produção", "ADR-014 · T-37", "contínuo"),
    "V15.3": ("DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento", "ADR-015", "F6-03"),
    "V16.1": ("Inventário do que se registra, e do que nunca se registra", "RNF-SEC-12", "F6-03"),
    "V16.2": ("Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal", "ADR-015 · T-09", "F6-03"),
    "V16.3": ("Toda autenticação, toda recusa de autorização e todo erro inesperado são registrados", "RNF-SEC-13", "F6-03"),
    "V16.4": ("Registro codificado contra injeção, legível só pelo serviço e por root", "ADR-003", "Fase 7"),
    "V16.5": ("Erro tipado e sem detalhe interno; falha da IA cai nas regras locais; nada falha aberto", "ADR-015 · ADR-010", "F6-03 · F6-04"),
}

# Seção ou requisito que não se aplica → motivo.
NOT_APPLICABLE = {
    "V1.4": "Dart tem gerência automática de memória",
    "V4.3": "Não há GraphQL",
    "V4.4": "Não há WebSocket: o assistente usa HTTP comum",
    "V5.2": "O servidor não recebe arquivo, só texto extraído (ADR-007)",
    "V5.3": "O servidor não guarda arquivo enviado",
    "V6.2": "Não existe senha em nenhum caminho de autenticação (ADR-008)",
    "V6.8": "Não há provedor de identidade externo",
    "V7.6": "Não há sessão federada",
    "V9.1": "A sessão usa token opaco, não token autocontido (ADR-008)",
    "V9.2": "A sessão usa token opaco, não token autocontido (ADR-008)",
    "V10.1": "Não há OAuth nem OIDC", "V10.2": "Não há OAuth nem OIDC",
    "V10.3": "Não há OAuth nem OIDC", "V10.4": "Não há OAuth nem OIDC",
    "V10.5": "Não há OAuth nem OIDC", "V10.6": "Não há OAuth nem OIDC",
    "V10.7": "Não há OAuth nem OIDC",
    "V17.1": "Não há WebRTC", "V17.2": "Não há WebRTC", "V17.3": "Não há WebRTC",
    "V1.2.4": "Não há SQL", "V1.2.6": "Não há LDAP", "V1.2.7": "Não há XPath",
    "V1.2.8": "Não há LaTeX", "V1.3.8": "Não há JNDI", "V1.3.9": "Não há memcache",
    "V1.3.11": "O servidor não envia e-mail", "V1.5.1": "Não há XML",
    "V5.4.3": "O servidor não serve arquivo enviado por terceiros",
    "V8.4.1": "Usuário único: não há multilocação",
    "V15.3.6": "Não há JavaScript próprio",
}

# Exceção aceita ao nível 2 → (por que não cabe, controle compensatório).
EXCEPTIONS = {
    "V13.3.1": ("Cofre de segredos gerenciado não existe a custo zero", "Credencial cifrada do systemd, entregue só ao serviço; nada em variável de ambiente, arquivo legível ou repositório (ADR-005)"),
    "V16.4.3": ("Sistema de registro separado exigiria uma segunda máquina", "Registro local sem dado sensível, legível só por root; eventos de segurança viram aviso dentro do app (RNF-SEC-13)"),
    "V12.3.3": ("Caddy e API estão na mesma máquina", "A API escuta só em `127.0.0.1`; nenhum tráfego interno sai da VM (ADR-003)"),
    "V11.2.1": ("Não há biblioteca criptográfica validada formalmente em Dart puro", "Só algoritmos padrão (AES-256-GCM, SHA-256, ECDSA P-256), conferidos contra vetores de teste publicados; envelope versionado para trocar de implementação (ADR-005)"),
}


def situation(section_id, req_id):
    """Devolve (situação, controle, referência, passo) de um requisito."""
    if req_id in EXCEPTIONS:
        why, compensation = EXCEPTIONS[req_id]
        return ("**exceção**", f"{why}. Compensação: {compensation}", "BL-013", "—")
    reason = NOT_APPLICABLE.get(req_id) or NOT_APPLICABLE.get(section_id)
    if reason:
        return ("não se aplica", reason, "—", "—")
    control, reference, step = SECTIONS[section_id]
    return ("atende" if step == "feito" else "planejado", control, reference, step)


def main(csv_path):
    rows = [r for r in csv.DictReader(open(csv_path, encoding="utf-8-sig")) if int(r["L"]) <= 2]
    chapters = OrderedDict()
    counts = OrderedDict((k, 0) for k in ("atende", "planejado", "não se aplica", "**exceção**"))
    for row in rows:
        state, control, reference, step = situation(row["section_id"], row["req_id"])
        counts[state] += 1
        key = (row["chapter_id"], row["chapter_name"])
        chapters.setdefault(key, []).append(
            f"| {row['req_id'][1:]} | L{row['L']} | {row['section_name']} | {state} | {control} | {reference} | {step} |"
        )

    out = [
        HEADER.format(
            total=len(rows),
            atende=counts["atende"],
            planejado=counts["planejado"],
            nao_se_aplica=counts["não se aplica"],
            excecao=counts["**exceção**"],
        )
    ]
    for (chapter_id, name), lines in chapters.items():
        out += [f"## {chapter_id} {name}", "", TABLE_HEAD, *lines, ""]
    OUTPUT.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{len(rows)} requisitos · " + " · ".join(f"{k.strip('*')}: {v}" for k, v in counts.items()))


TABLE_HEAD = "| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |\n|---|---|---|---|---|---|---|"

HEADER = """# Checklist do OWASP ASVS 5.0.0 — nível 2

O Cajui é **autoavaliado contra o OWASP ASVS 5.0.0, nível 2, com exceções listadas** (RNF-SEC-01). A OWASP não certifica nada: este documento é a avaliação do próprio projeto, feita para ser conferida por quem quiser.

Gerado por `tool/security/build_asvs_checklist.py` a partir do CSV oficial, para que nenhum requisito seja esquecido nem inventado. O texto de cada requisito não é copiado aqui: o identificador leva à [fonte](https://github.com/OWASP/ASVS/tree/v5.0.0/5.0) (licença CC BY-SA 4.0).

## Situação

| Situação | Requisitos | Significa |
|---|---|---|
| atende | {atende} | O controle já existe, com a evidência indicada |
| planejado | {planejado} | O controle está decidido numa ADR e nasce no passo indicado. Vira "atende" no PR daquele passo |
| não se aplica | {nao_se_aplica} | A tecnologia ou o cenário não existe no Cajui |
| **exceção** | {excecao} | O nível 2 pede algo que não cabe numa VM a custo zero. Há controle compensatório, por escrito |
| **Total, níveis 1 e 2** | **{total}** | |

As quatro exceções respondem ao item BL-013. Dizer "ASVS nível 2" sem listá-las seria falso.

O ASVS não cobre backup, DNS, CI nem hospedagem, e não tem capítulo de IA generativa. Esses riscos estão no [modelo de ameaças](threat-model.md): fronteira 3, e a fronteira 2 inteira para injeção de prompt.
"""

if __name__ == "__main__":
    main(sys.argv[1])
