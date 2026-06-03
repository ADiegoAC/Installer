# Uninstaller template compiled by builder.ps1 and installed as Uninstall.exe.
param(
    [switch]$FromTemp,
    [string]$InstallDir,
    [string]$ManifestPath,
    [string]$OriginalPath
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$appName = "{{APP_NAME}}"

function Show-Error {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        "Desinstalador",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Remove-PathSafe {
    param(
        [string]$Path,
        [switch]$Recurse
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return $true }
    if (-not (Test-Path -LiteralPath $Path)) { return $true }

    try {
        if ($Recurse) {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        } else {
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        }
        return $true
    } catch {
        return $false
    }
}

function Start-SelfDelete {
    param([string]$TempExe)

    if ([string]::IsNullOrWhiteSpace($TempExe)) { return }

    $cmd = "/c for /l %i in (1,1,20) do @if exist ""$TempExe"" (del /f /q ""$TempExe"" > nul 2>&1 & if not exist ""$TempExe"" exit /b 0 & timeout /t 1 /nobreak > nul)"
    Start-Process -FilePath "cmd.exe" -ArgumentList $cmd -WindowStyle Hidden | Out-Null
}

function Get-Manifest {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Invoke-Removal {
    param(
        [object]$Manifest,
        [string]$RootDir,
        [string]$ManifestFile,
        [string]$InstalledUninstaller
    )

    $failed = New-Object System.Collections.Generic.List[string]

    foreach ($shortcut in @($Manifest.shortcuts)) {
        if (-not (Remove-PathSafe -Path $shortcut)) { [void]$failed.Add($shortcut) }
    }

    foreach ($file in @($Manifest.installedFiles | Sort-Object -Descending)) {
        if (-not (Remove-PathSafe -Path $file)) { [void]$failed.Add($file) }
    }

    if (-not (Remove-PathSafe -Path $ManifestFile)) { [void]$failed.Add($ManifestFile) }
    if (-not (Remove-PathSafe -Path $InstalledUninstaller)) { [void]$failed.Add($InstalledUninstaller) }

    if (Test-Path -LiteralPath $RootDir) {
        $remaining = @(Get-ChildItem -LiteralPath $RootDir -Force -ErrorAction SilentlyContinue)
        if ($remaining.Count -eq 0) {
            if (-not (Remove-PathSafe -Path $RootDir -Recurse)) { [void]$failed.Add($RootDir) }
        }
    }

    return $failed
}

if ($FromTemp) {
    $runningExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    Start-Sleep -Milliseconds 800
    $manifest = Get-Manifest -Path $ManifestPath
    if (-not $manifest) {
        Remove-PathSafe -Path $OriginalPath | Out-Null
        Start-SelfDelete -TempExe $runningExe
        [Environment]::Exit(0)
    }

    $failed = Invoke-Removal -Manifest $manifest -RootDir $InstallDir -ManifestFile $ManifestPath -InstalledUninstaller $OriginalPath
    $message = if ($failed.Count -eq 0) {
        "$appName foi removido com sucesso."
    } else {
        "A remocao terminou, mas alguns itens nao puderam ser apagados:`r`n`r`n$($failed -join "`r`n")"
    }

    [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Desinstalador",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

    Start-SelfDelete -TempExe $runningExe
    [Environment]::Exit(0)
}

$currentExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$installDir = Split-Path $currentExe -Parent
$manifestPath = Join-Path $installDir "install-manifest.json"
$manifest = Get-Manifest -Path $manifestPath

if (-not $manifest) {
    Show-Error "Nao foi possivel encontrar ou ler o manifesto de instalacao.`r`n$manifestPath"
    return
}

$filesCount = @($manifest.installedFiles).Count
$shortcutsCount = @($manifest.shortcuts).Count

$form = New-Object System.Windows.Forms.Form
$form.Text = "Desinstalar $appName"
$form.Size = New-Object System.Drawing.Size(460, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 243)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Remover $appName"
$lblTitle.Location = New-Object System.Drawing.Point(16, 16)
$lblTitle.Size = New-Object System.Drawing.Size(410, 24)
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "O desinstalador vai remover os arquivos instalados, atalhos e o manifesto."
$lblInfo.Location = New-Object System.Drawing.Point(16, 48)
$lblInfo.Size = New-Object System.Drawing.Size(410, 38)

$list = New-Object System.Windows.Forms.ListView
$list.Location = New-Object System.Drawing.Point(16, 92)
$list.Size = New-Object System.Drawing.Size(410, 104)
$list.View = "Details"
$list.FullRowSelect = $true
$list.HeaderStyle = "Nonclickable"
[void]$list.Columns.Add("Item", 150)
[void]$list.Columns.Add("Valor", 250)

$rowInstall = New-Object System.Windows.Forms.ListViewItem("Pasta")
[void]$rowInstall.SubItems.Add($installDir)
[void]$list.Items.Add($rowInstall)

$rowFiles = New-Object System.Windows.Forms.ListViewItem("Arquivos")
[void]$rowFiles.SubItems.Add($filesCount)
[void]$list.Items.Add($rowFiles)

$rowShortcuts = New-Object System.Windows.Forms.ListViewItem("Atalhos")
[void]$rowShortcuts.SubItems.Add($shortcutsCount)
[void]$list.Items.Add($rowShortcuts)

$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "Desinstalar"
$btnUninstall.Location = New-Object System.Drawing.Point(228, 216)
$btnUninstall.Size = New-Object System.Drawing.Size(96, 30)
$btnUninstall.FlatStyle = "Flat"

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancelar"
$btnCancel.Location = New-Object System.Drawing.Point(330, 216)
$btnCancel.Size = New-Object System.Drawing.Size(96, 30)
$btnCancel.FlatStyle = "Flat"
$btnCancel.Add_Click({ $form.Close() })

$btnUninstall.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Deseja remover $appName deste computador?",
        "Confirmar desinstalacao",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $tempExe = Join-Path ([System.IO.Path]::GetTempPath()) ("uninstall-" + [Guid]::NewGuid().ToString() + ".exe")
    try {
        Copy-Item -LiteralPath $currentExe -Destination $tempExe -Force -ErrorAction Stop
        $args = @(
            "-FromTemp",
            "-InstallDir", "`"$installDir`"",
            "-ManifestPath", "`"$manifestPath`"",
            "-OriginalPath", "`"$currentExe`""
        ) -join " "
        Start-Process -FilePath $tempExe -ArgumentList $args -WindowStyle Normal | Out-Null
        $form.Close()
    } catch {
        Show-Error "Nao foi possivel preparar a copia temporaria do desinstalador.`r`n$_"
    }
})

$form.Controls.AddRange(@($lblTitle, $lblInfo, $list, $btnUninstall, $btnCancel))
$form.ShowDialog() | Out-Null
