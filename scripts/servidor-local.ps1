# Sobe o servidor do Cajui nesta máquina, com a chave da IA, sem a chave
# encostar no repositório.
#
# O servidor lê a chave como **credencial**, e não como variável de ambiente
# (ADR-005): ele espera um diretório em CREDENTIALS_DIRECTORY com um arquivo
# chamado `cajui-deepseek-key` contendo só a chave. Na VM quem monta esse
# diretório é o systemd, com a chave cifrada na unidade. Aqui este script faz
# o mesmo papel, lendo de C:\Users\<voce>\.cajui\cajui.env — que fica fora da
# pasta do projeto de propósito.
#
# Uso, da raiz do projeto:  .\scripts\servidor-local.ps1

$ErrorActionPreference = 'Stop'

$envFile = Join-Path $HOME '.cajui\cajui.env'
if (-not (Test-Path $envFile)) {
    throw "Não achei $envFile. Crie o arquivo e ponha DEEPSEEK_API_KEY=<a chave>."
}

$chave = (Get-Content $envFile |
    Where-Object { $_ -match '^\s*DEEPSEEK_API_KEY\s*=' } |
    ForEach-Object { ($_ -split '=', 2)[1].Trim() } |
    Select-Object -First 1)

# O diretório de credenciais vive no perfil do usuário, nunca no repositório.
$credenciais = Join-Path $HOME '.cajui\credentials'
New-Item -ItemType Directory -Force -Path $credenciais | Out-Null

if ([string]::IsNullOrWhiteSpace($chave)) {
    Write-Host 'Sem chave no arquivo: o servidor sobe só com as regras locais.'
    Remove-Item (Join-Path $credenciais 'cajui-deepseek-key') -ErrorAction SilentlyContinue
} else {
    # Sem quebra de linha no fim: o servidor faz trim, mas o systemd não põe.
    [System.IO.File]::WriteAllText(
        (Join-Path $credenciais 'cajui-deepseek-key'), $chave)
    Write-Host 'Chave carregada da sua pasta pessoal. Ela não passa pelo repositório.'
}

# A chave que cifra os dados também precisa existir: o servidor a exige, e
# na VM ela vem da credencial do systemd. Aqui nasce uma de brincadeira, na
# pasta de dados local — nunca a mesma da VM, e nunca no repositório.
$dados = Join-Path $HOME '.cajui\dados-locais'
New-Item -ItemType Directory -Force -Path $dados | Out-Null
$chaveDados = Join-Path $credenciais 'cajui-data-key'
if (-not (Test-Path $chaveDados)) {
    $bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    [IO.File]::WriteAllText($chaveDados, [Convert]::ToBase64String($bytes))
}

$env:CREDENTIALS_DIRECTORY = $credenciais
$env:HOST = '127.0.0.1'
$env:PORT = '8080'

Push-Location (Join-Path $PSScriptRoot '..\server')
try {
    # `serve`, e a pasta de dados: sem os dois argumentos o servidor só
    # imprime o modo de usar e sai. Ele nunca subiu por aqui até hoje.
    dart run bin/server.dart serve $dados
} finally {
    Pop-Location
    # A cópia em claro da chave da IA não fica para trás. A chave de dados
    # fica: sem ela, o registro local vira ruído na próxima execução.
    Remove-Item (Join-Path $credenciais 'cajui-deepseek-key') -ErrorAction SilentlyContinue
}
