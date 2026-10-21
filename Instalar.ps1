param([string]$ModsPath)
$ErrorActionPreference='Stop'
try {
  $candidate=if ([string]::IsNullOrWhiteSpace($ModsPath)) {
    'H:\gen1recomp-0.3.51-windows\gen1recomp-win64\mods'
  } else { $ModsPath.Trim().Trim('"') }
  Write-Host 'Floating Glass FRLG - mod independente'
  Write-Host $candidate
  do { $answer=(Read-Host 'Esta e a pasta mods? (S/N)').Trim().ToUpperInvariant() } until ($answer -eq 'S' -or $answer -eq 'N')
  if ($answer -eq 'N') { $candidate=(Read-Host 'Informe a pasta mods').Trim().Trim('"') }
  if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { throw 'Pasta mods nao encontrada.' }
  $cleanPath=$candidate.TrimEnd([char]92,[char]47)
  if ((Split-Path -Path $cleanPath -Leaf) -ne 'mods') { throw 'Informe a pasta mods do recomp, nao a pasta de um mod existente.' }
  $source=Join-Path $PSScriptRoot 'floating_glass_frlg'
  $target=Join-Path $candidate 'floating_glass_frlg'
  $list=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ARQUIVOS.json') -Raw | ConvertFrom-Json
  $identity=Get-Content -LiteralPath (Join-Path $source 'manifest.json') -Raw | ConvertFrom-Json
  if ($identity.id -ne 'floating_glass_frlg') { throw 'Identificacao de pacote invalida.' }
  foreach ($item in $list) {
    $relative=[string]$item.path
    if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains('..') -or $relative.Contains(':')) { throw 'Caminho de pacote invalido.' }
    $inputFile=Join-Path $source $relative
    if ((Get-FileHash -LiteralPath $inputFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw ('Pacote corrompido: '+$relative) }
  }
  $created=-not (Test-Path -LiteralPath $target)
  $changed=@()
  $obsolete=@()
  $backup=$null
  if (-not $created) {
    $currentIdentity=Get-Content -LiteralPath (Join-Path $target 'manifest.json') -Raw | ConvertFrom-Json
    if ($currentIdentity.id -ne 'floating_glass_frlg') { throw 'Esta pasta nao pertence ao mod independente.' }
    $previous=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA2.json') -Raw | ConvertFrom-Json)) { $previous[$item.path]=$item.sha256 }
    $previous3=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA3.json') -Raw | ConvertFrom-Json)) { $previous3[$item.path]=$item.sha256 }
    $previous4=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA4.json') -Raw | ConvertFrom-Json)) { $previous4[$item.path]=$item.sha256 }
    $previous5=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA5.json') -Raw | ConvertFrom-Json)) { $previous5[$item.path]=$item.sha256 }
    $previous6=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA6.json') -Raw | ConvertFrom-Json)) { $previous6[$item.path]=$item.sha256 }
    $previous7=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA7.json') -Raw | ConvertFrom-Json)) { $previous7[$item.path]=$item.sha256 }
    $previous8=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA8.json') -Raw | ConvertFrom-Json)) { $previous8[$item.path]=$item.sha256 }
    $previous9=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA9.json') -Raw | ConvertFrom-Json)) { $previous9[$item.path]=$item.sha256 }
    $previous10=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA10.json') -Raw | ConvertFrom-Json)) { $previous10[$item.path]=$item.sha256 }
    $previous11=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA11.json') -Raw | ConvertFrom-Json)) { $previous11[$item.path]=$item.sha256 }
    $previous12=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA12.json') -Raw | ConvertFrom-Json)) { $previous12[$item.path]=$item.sha256 }
    $previous13=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA13.json') -Raw | ConvertFrom-Json)) { $previous13[$item.path]=$item.sha256 }
    $previous131=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA13.1.json') -Raw | ConvertFrom-Json)) { $previous131[$item.path]=$item.sha256 }
    $previous132=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA13.2.json') -Raw | ConvertFrom-Json)) { $previous132[$item.path]=$item.sha256 }
    $previous133=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA13.3.json') -Raw | ConvertFrom-Json)) { $previous133[$item.path]=$item.sha256 }
    $previous134=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA13.4.json') -Raw | ConvertFrom-Json)) { $previous134[$item.path]=$item.sha256 }
    $previous14=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA14.json') -Raw | ConvertFrom-Json)) { $previous14[$item.path]=$item.sha256 }
    $previous15=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA15.json') -Raw | ConvertFrom-Json)) { $previous15[$item.path]=$item.sha256 }
    $previous16=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA16.json') -Raw | ConvertFrom-Json)) { $previous16[$item.path]=$item.sha256 }
    $previous17=@{}
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ATUALIZAR-DE-ALPHA17.json') -Raw | ConvertFrom-Json)) { $previous17[$item.path]=$item.sha256 }
    foreach ($item in $list) {
      $existing=Join-Path $target $item.path
      if (Test-Path -LiteralPath $existing -PathType Leaf) {
        $hash=(Get-FileHash -LiteralPath $existing -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -eq $item.sha256) { continue }
        if ($hash -ne $previous[$item.path] -and $hash -ne $previous3[$item.path] -and $hash -ne $previous4[$item.path] -and $hash -ne $previous5[$item.path] -and $hash -ne $previous6[$item.path] -and $hash -ne $previous7[$item.path] -and $hash -ne $previous8[$item.path] -and $hash -ne $previous9[$item.path] -and $hash -ne $previous10[$item.path] -and $hash -ne $previous11[$item.path] -and $hash -ne $previous12[$item.path] -and $hash -ne $previous13[$item.path] -and $hash -ne $previous131[$item.path] -and $hash -ne $previous132[$item.path] -and $hash -ne $previous133[$item.path] -and $hash -ne $previous134[$item.path] -and $hash -ne $previous14[$item.path] -and $hash -ne $previous15[$item.path] -and $hash -ne $previous16[$item.path] -and $hash -ne $previous17[$item.path]) { throw ('Arquivo do mod editado ou desconhecido: '+$item.path+'. Preserve sua alteracao antes de atualizar.') }
      }
      $changed+=@($item)
    }
    foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'REMOVIDOS.json') -Raw | ConvertFrom-Json)) {
      $relative=[string]$item.path
      if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains('..') -or $relative.Contains(':')) { throw 'Caminho antigo invalido.' }
      $existing=Join-Path $target $relative
      if (Test-Path -LiteralPath $existing -PathType Leaf) {
        $hash=(Get-FileHash -LiteralPath $existing -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($item.hashes -notcontains $hash) { throw ('Menu antigo alterado: '+$relative+'. Preserve sua alteracao antes de atualizar.') }
        $obsolete+=@($item)
      }
    }
    if ($changed.Count -eq 0 -and $obsolete.Count -eq 0) { Write-Host 'Esta versao independente ja esta instalada.';exit 0 }
    $backup=Join-Path (Split-Path -Parent $candidate) ('mod-backups\floating_glass_frlg\'+(Get-Date -Format 'yyyyMMddHHmmssfff'))
    foreach ($item in $changed) {
      $old=Join-Path $target $item.path
      if (Test-Path -LiteralPath $old) {
        $copy=Join-Path $backup $item.path
        New-Item -ItemType Directory -Path (Split-Path $copy) -Force | Out-Null
        Copy-Item -LiteralPath $old -Destination $copy
      }
    }
  } else {
    $changed=@($list)
    New-Item -ItemType Directory -Path $target | Out-Null
  }
  try {
    foreach ($item in $changed | Sort-Object { if ($_.path -eq 'manifest.json') {2} elseif ($_.path -eq 'main.lua') {1} else {0} }) {
      $outputFile=Join-Path $target $item.path
      New-Item -ItemType Directory -Path (Split-Path $outputFile) -Force | Out-Null
      Copy-Item -LiteralPath (Join-Path $source $item.path) -Destination $outputFile -Force
      if ((Get-FileHash -LiteralPath $outputFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw ('Falha de copia: '+$item.path) }
    }
    foreach ($item in $obsolete) {
      $old=Join-Path $target $item.path
      $archived=Join-Path $backup $item.path
      New-Item -ItemType Directory -Path (Split-Path $archived) -Force | Out-Null
      Move-Item -LiteralPath $old -Destination $archived -Force
    }
  } catch {
    if ($created) { Remove-Item -LiteralPath $target -Recurse -Force }
    else {
      foreach ($item in (@($changed)+@($obsolete))) {
        $old=Join-Path $backup $item.path;$outputFile=Join-Path $target $item.path
        if (Test-Path -LiteralPath $old) { Copy-Item -LiteralPath $old -Destination $outputFile -Force }
        elseif (Test-Path -LiteralPath $outputFile) { Remove-Item -LiteralPath $outputFile }
      }
    }
    throw
  }
  Write-Host 'Instalado apenas em mods\floating_glass_frlg.'
  Write-Host 'Nenhum arquivo de outros mods foi alterado.'
  if ($backup) { Write-Host ('Backup apenas dos arquivos antigos deste mod: '+$backup) }
  Write-Host 'Beta 01: somente apresentacao de batalha. Menus fora dela sao nativos. SELECT abre os ajustes.'
  Write-Host 'Menus KRS antigos reconhecidos foram movidos para o backup; documentacao historica preservada.'
} catch { Write-Host ('ERRO: '+$_.Exception.Message);exit 1 }
