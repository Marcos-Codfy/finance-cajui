# Compila o APK, instala no celular ligado e deixa uma cópia na área de
# trabalho, para instalar em outro aparelho quando quiser.
#
# A cópia leva a data e a hora no nome: duas versões do mesmo dia não se
# sobrescrevem, e dá para voltar para a de ontem sem recompilar.
#
# Uso, da raiz do projeto (o PowerShell do Windows basta; não há `pwsh` aqui):
#   .\scripts\apk.ps1             depuração, para desenvolver: 200 MB e lento
#   .\scripts\apk.ps1 -Release    de uso: pequeno e rápido, é o do dia a dia
#
# **O número da versão sobe a cada APK.** O Android recusa instalar por cima
# um APK de número menor, e a saída seria desinstalar — que apaga o livro
# do aparelho e a chave dele. Por isso o número é o tempo, e por isso o de
# uso **não** usa `--split-per-abi`: aquilo multiplica o número por mil e
# prende o celular numa linha de que ele não volta.
#
# **Os APKs daqui só se atualizam entre si.** Todos são assinados pela
# chave de depuração deste computador; o que sair de outra máquina, ou da
# conferência do GitHub, não instala por cima.

param([switch]$Release)

$ErrorActionPreference = 'Stop'

$raiz = Resolve-Path (Join-Path $PSScriptRoot '..')
# Subpasta própria: na raiz, quatro APKs de 200 MB escondem os documentos.
$copia = Join-Path $HOME 'Desktop\Relatorio Cajui\apk'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'

$modo = if ($Release) { 'release' } else { 'debug' }
Push-Location (Join-Path $raiz 'app')
try {
    Write-Host "compilando o APK de $modo…"
    $numero = [int]((Get-Date) - (Get-Date '2026-01-01')).TotalMinutes
    $opcoes = @("--$modo", "--build-number=$numero")
    # Só 64 bits no de uso: é o que os celulares de hoje têm, e o arquivo
    # fica com um terço do tamanho.
    if ($Release) { $opcoes += '--target-platform=android-arm64' }
    flutter build apk @opcoes
    if ($LASTEXITCODE -ne 0) { throw "a compilação falhou" }
} finally {
    Pop-Location
}

$apk = Join-Path $raiz "app\build\app\outputs\flutter-apk\app-$modo.apk"
$tamanho = [math]::Round((Get-Item $apk).Length / 1MB, 1)

New-Item -ItemType Directory -Force -Path $copia | Out-Null
$carimbo = Get-Date -Format 'yyyy-MM-dd-HHmm'
$destino = Join-Path $copia "cajui-$modo-$carimbo.apk"
Copy-Item $apk $destino -Force
Write-Host "cópia em $destino  ($tamanho MB)"

# Celular ligado por cabo: instala por cima, mantendo os dados.
if (Test-Path $adb) {
    $aparelhos = & $adb devices | Select-String -Pattern '\sdevice$'
    if ($aparelhos) {
        Write-Host 'instalando no celular ligado…'
        & $adb install -r $apk
    } else {
        Write-Host 'nenhum celular ligado: só a cópia foi gerada.'
    }
}
