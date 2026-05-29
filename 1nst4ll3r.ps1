# ── Verifica se está rodando como Administrador ─────────────────────────────
 $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ── Obtém os caminhos de forma segura via .NET (Não usa $env:) ─────────────
 $localAppData  = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
 $programFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
 $programFiles    = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)

# Se não encontrar o ProgramFiles normal (raro), usa o X86
if ([string]::IsNullOrWhiteSpace($programFiles)) { $programFiles = $programFilesX86 }

# ── Configuração de Caminhos ───────────────────────────────────────────────
 $tempPath = [System.IO.Path]::GetTempPath().TrimEnd('\')
 $zipPath = Join-Path $tempPath "payload.zip"
 $extractId  = [Guid]::NewGuid().ToString()
 $sourceFolder = Join-Path $tempPath $extractId
 $destFolder = "{{DEST_FOLDER}}"

# ── Validação e Extração ────────────────────────────────────────────────────
if (-not (Test-Path $zipPath)) {
    [System.Windows.Forms.MessageBox]::Show("Erro crítico: O arquivo 'payload.zip' não foi extraído pelo instalador.", "Erro", "OK", "Error")
    return
}

try {
    # Cria a pasta de extração
    New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
    
    # Expande o zip que o ps2exe já deixou pronto na temp
    Expand-Archive -Path $zipPath -DestinationPath $sourceFolder -Force
    
    # Opcional: Apagar o zip da temp já que já extraímos
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao extrair arquivos: $_", "Erro de Extração", "OK", "Error")
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── TELA DE EULA (Licença) ──────────────────────────────────────────────────
 $eulaPath = Join-Path $tempPath "eula.rtf"

if (Test-Path $eulaPath) {
    $eulaText = [System.IO.File]::ReadAllText($eulaPath)

    $formEula             = New-Object System.Windows.Forms.Form
    $formEula.Text        = "Contrato de Licença"
    $formEula.Size        = New-Object System.Drawing.Size(500, 450)
    $formEula.StartPosition = "CenterScreen"
    $formEula.FormBorderStyle = "FixedDialog"
    $formEula.MaximizeBox = $false
    $formEula.MinimizeBox = $false
    $formEula.BackColor   = [System.Drawing.Color]::FromArgb(245, 245, 243)
    $formEula.Font        = New-Object System.Drawing.Font("Segoe UI", 9)

    $lblEulaTitle         = New-Object System.Windows.Forms.Label
    $lblEulaTitle.Text    = "Por favor, leia o contrato de licença abaixo:"
    $lblEulaTitle.Location = New-Object System.Drawing.Point(15, 15)
    $lblEulaTitle.Size    = New-Object System.Drawing.Size(470, 20)

    $txtEula              = New-Object System.Windows.Forms.TextBox
    $txtEula.Text         = $eulaText
    $txtEula.Multiline    = $true
    $txtEula.ScrollBars   = "Vertical"
    $txtEula.ReadOnly     = $true
    $txtEula.Location     = New-Object System.Drawing.Point(15, 40)
    $txtEula.Size         = New-Object System.Drawing.Size(455, 320)
    $txtEula.BackColor    = [System.Drawing.Color]::White
    $txtEula.BorderStyle  = "FixedSingle"

    $btnAccept            = New-Object System.Windows.Forms.Button
    $btnAccept.Text       = "Eu Aceito"
    $btnAccept.Location   = New-Object System.Drawing.Point(280, 375)
    $btnAccept.Size       = New-Object System.Drawing.Size(95, 30)
    $btnAccept.FlatStyle  = "Flat"
    $btnAccept.BackColor  = [System.Drawing.Color]::FromArgb(15, 110, 86)
    $btnAccept.ForeColor  = [System.Drawing.Color]::White
    $btnAccept.Font       = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnAccept.DialogResult = [System.Windows.Forms.DialogResult]::OK


    $btnDecline           = New-Object System.Windows.Forms.Button
    $btnDecline.Text      = "Não Aceito"
    $btnDecline.Location  = New-Object System.Drawing.Point(385, 375)
    $btnDecline.Size      = New-Object System.Drawing.Size(85, 30)
    $btnDecline.FlatStyle = "Flat"
    $btnDecline.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 243)
    $btnDecline.ForeColor = [System.Drawing.Color]::Black
    $btnDecline.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $formEula.CancelButton = $btnDisagree

    # Se aceitar, apenas fecha a janela da EULA e o script continua自然mente
    $btnAccept.Add_Click({ $formEula.Close() })

    $formEula.Controls.AddRange(@($lblEulaTitle, $txtEula, $btnAccept, $btnDecline))
    $result = $formEula.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        # O usuário clicou no X, apertou ESC, ou clicou em "I Disagree"
        Write-Host "Instalação cancelada pelo usuário."
        if (Test-Path $sourceFolder) { Remove-Item $sourceFolder -Recurse -Force -ErrorAction SilentlyContinue }
        [Environment]::Exit(0)
    }

# Se chegou aqui, o usuário clicou em "I Agree". Continua a instalação...

}

# ── Configuração dos arquivos a instalar ──────────────────────────────────────
#$destFolder   = "meuApp"

# ── Define o destino com base nos Privilégios Reais ─────────────────────────
if ($isAdmin) {
    $defaultDest  = Join-Path $programFiles $destFolder
} else {
    $defaultDest  = Join-Path $localAppData $destFolder
}


# ── Helpers ───────────────────────────────────────────────────────────────────
function Resolve-EnvPath($path) {
    [System.Environment]::ExpandEnvironmentVariables($path)
}
function Format-Size($bytes) {
    if ($bytes -ge 1MB) { "{0:F1} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { "{0:F0} KB" -f ($bytes / 1KB) }
    else { "$bytes B" }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Formulário ────────────────────────────────────────────────────────────────
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "Instalador"
$form.Size             = New-Object System.Drawing.Size(500, 330)
$form.StartPosition    = "CenterScreen"
$form.FormBorderStyle  = "FixedDialog"
$form.MaximizeBox      = $false
$form.MinimizeBox      = $false
$form.BackColor        = [System.Drawing.Color]::FromArgb(245, 245, 243)
$form.Font             = New-Object System.Drawing.Font("Segoe UI", 9)

# ── Painel esquerdo ───────────────────────────────────────────────────────────
$panelLeft             = New-Object System.Windows.Forms.Panel
$panelLeft.Location    = New-Object System.Drawing.Point(14, 14)
$panelLeft.Size        = New-Object System.Drawing.Size(364, 270)

# Label destino
$lblDest               = New-Object System.Windows.Forms.Label
$lblDest.Text          = "DESTINO"
$lblDest.Location      = New-Object System.Drawing.Point(0, 0)
$lblDest.Size          = New-Object System.Drawing.Size(364, 18)
$lblDest.ForeColor     = [System.Drawing.Color]::FromArgb(120, 120, 115)
$lblDest.Font          = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

# TextBox + botão procurar
$txtDest               = New-Object System.Windows.Forms.TextBox
$txtDest.Text          = $defaultDest
$txtDest.Location      = New-Object System.Drawing.Point(0, 20)
$txtDest.Size          = New-Object System.Drawing.Size(332, 24)
$txtDest.BackColor     = [System.Drawing.Color]::FromArgb(235, 235, 232)
$txtDest.BorderStyle   = "FixedSingle"

$btnBrowse             = New-Object System.Windows.Forms.Button
$btnBrowse.Text        = "..."
$btnBrowse.Location    = New-Object System.Drawing.Point(336, 19)
$btnBrowse.Size        = New-Object System.Drawing.Size(28, 24)
$btnBrowse.FlatStyle   = "Flat"
$btnBrowse.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(245, 245, 243)
$btnBrowse.BackColor   = [System.Drawing.Color]::FromArgb(235, 235, 232)

$btnBrowse.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Escolha o destino de instalação"
    $fbd.SelectedPath = Resolve-EnvPath $txtDest.Text
    if ($fbd.ShowDialog() -eq "OK") { $txtDest.Text = Join-Path $fbd.SelectedPath $destFolder }
})

# Label arquivos
$lblFiles              = New-Object System.Windows.Forms.Label
$lblFiles.Text         = "ARQUIVOS"
$lblFiles.Location     = New-Object System.Drawing.Point(0, 54)
$lblFiles.Size         = New-Object System.Drawing.Size(364, 18)
$lblFiles.ForeColor    = [System.Drawing.Color]::FromArgb(120, 120, 115)
$lblFiles.Font         = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

# ListView de arquivos
$listView              = New-Object System.Windows.Forms.ListView
$listView.Location     = New-Object System.Drawing.Point(0, 74)
$listView.Size         = New-Object System.Drawing.Size(364, 140)
$listView.View         = "Details"
$listView.FullRowSelect = $true
$listView.GridLines    = $false
$listView.BorderStyle  = "FixedSingle"
$listView.BackColor    = [System.Drawing.Color]::FromArgb(235, 235, 232)
$listView.HeaderStyle  = "Nonclickable"
[void]$listView.Columns.Add("", 28)
[void]$listView.Columns.Add("Arquivo", 240)
[void]$listView.Columns.Add("Tamanho", 88)

# Label progresso
$lblProgress           = New-Object System.Windows.Forms.Label
$lblProgress.Text      = "PROGRESSO"
$lblProgress.Location  = New-Object System.Drawing.Point(0, 224)
$lblProgress.Size      = New-Object System.Drawing.Size(364, 18)
$lblProgress.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 115)
$lblProgress.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

# ProgressBar
$progressBar           = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location  = New-Object System.Drawing.Point(0, 244)
$progressBar.Size      = New-Object System.Drawing.Size(364, 10)
$progressBar.Minimum   = 0
$progressBar.Maximum   = $installMap.Count
$progressBar.Value     = 0
$progressBar.Style     = "Continuous"

# Label status
$lblStatus             = New-Object System.Windows.Forms.Label
$lblStatus.Text        = "Pronto para instalar."
$lblStatus.Location    = New-Object System.Drawing.Point(0, 256)
$lblStatus.Size        = New-Object System.Drawing.Size(364, 18)
$lblStatus.ForeColor   = [System.Drawing.Color]::FromArgb(120, 120, 115)
$lblStatus.Font        = New-Object System.Drawing.Font("Segoe UI", 9)

$panelLeft.Controls.AddRange(@($lblDest, $txtDest, $btnBrowse, $lblFiles, $listView, $lblProgress, $progressBar, $lblStatus))

# ── Painel direito (botões) ───────────────────────────────────────────────────
$panelRight            = New-Object System.Windows.Forms.Panel
$panelRight.Location   = New-Object System.Drawing.Point(390, 14)
$panelRight.Size       = New-Object System.Drawing.Size(96, 270)

$btnInstall            = New-Object System.Windows.Forms.Button
$btnInstall.Text       = "Instalar"
$btnInstall.Location   = New-Object System.Drawing.Point(0, 0)
$btnInstall.Size       = New-Object System.Drawing.Size(96, 30)
$btnInstall.FlatStyle  = "Flat"
$btnInstall.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(122, 122, 122)
$btnInstall.BackColor  = [System.Drawing.Color]::FromArgb(245, 245, 243)
$btnInstall.ForeColor  = [System.Drawing.Color]::Black
$btnInstall.Font       = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

$btnCancel             = New-Object System.Windows.Forms.Button
$btnCancel.Text        = "Cancelar"
$btnCancel.Location    = New-Object System.Drawing.Point(0, 38)
$btnCancel.Size        = New-Object System.Drawing.Size(96, 30)
$btnCancel.FlatStyle   = "Flat"
$btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(122, 122, 122)
$btnCancel.BackColor   = [System.Drawing.Color]::FromArgb(245, 245, 243)
$btnCancel.ForeColor   = [System.Drawing.Color]::Black

$btnCancel.Add_Click({ $form.Close() })

$panelRight.Controls.AddRange(@($btnInstall, $btnCancel))

# ── Lógica de instalação ──────────────────────────────────────────────────────
$btnInstall.Add_Click({

    $allFiles = Get-ChildItem -Path $sourceFolder -Recurse -File

    if ($allFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Instalador corrompido: nenhum arquivo encontrado em '$sourceFolder'.",
            "Erro",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }
    $btnInstall.Enabled = $false
    $btnBrowse.Enabled  = $false
    $txtDest.Enabled    = $false

    $baseDest = Resolve-EnvPath $txtDest.Text
    $errors   = 0

    $progressBar.Maximum = $allFiles.Count

    foreach ($file in $allFiles) {
        $relativePath = $file.FullName.Substring($sourceFolder.Length).TrimStart('\')
        if ($relativePath -match '^bin\\') {
            $relativePath = $relativePath -replace '^bin\\', ''
        }
        $destDir      = Join-Path (Resolve-EnvPath $txtDest.Text) (Split-Path $relativePath)

        $item = New-Object System.Windows.Forms.ListViewItem("")
        [void]$item.SubItems.Add($relativePath)
        [void]$item.SubItems.Add((Format-Size $file.Length))
        $item.ForeColor = [System.Drawing.Color]::FromArgb(0, 100, 160)
        $item.SubItems[0].Text = "→"
        [void]$listView.Items.Add($item)
        $listView.EnsureVisible($listView.Items.Count - 1)

        $lblStatus.Text = "Copiando $relativePath..."
        $form.Refresh()

        try {
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $destDir -Force -ErrorAction Stop
            $item.ForeColor        = [System.Drawing.Color]::FromArgb(15, 110, 86)
            $item.SubItems[0].Text = "✓"
        }
        catch {
            $item.ForeColor        = [System.Drawing.Color]::FromArgb(163, 45, 45)
            $item.SubItems[0].Text = "✗"
            $errors++
        }

        $progressBar.Value++
        $form.Refresh()
    }
    if ($errors -eq 0) {

        # ── Atalhos opcionais ─────────────────────────────────────────────────────────
        $exePath  = Join-Path (Resolve-EnvPath $txtDest.Text) "cpuz_x64.exe"
        $iconPath = Join-Path (Resolve-EnvPath $txtDest.Text) "cpuz.ico"   # ou caminho para um .ico separado
        $shell      = New-Object -ComObject WScript.Shell

        function New-Shortcut($destination) {
            $lnk             = $shell.CreateShortcut($destination)
            $lnk.TargetPath  = $exePath
            $lnk.IconLocation = "$iconPath,0"
            $lnk.WorkingDirectory = Split-Path $exePath
            $lnk.Save()
        }

        # Área de trabalho
        New-Shortcut (Join-Path (Resolve-EnvPath "%USERPROFILE%\Desktop") "RCAmgr.lnk")

        # Menu Iniciar — pasta do usuário, sem admin
        $startMenu = Resolve-EnvPath "%APPDATA%\Microsoft\Windows\Start Menu\Programs"
        New-Shortcut (Join-Path $startMenu "RCAmgr.lnk")

        $btnInstall.Enabled = $false
        $lblStatus.Text = "Instalação concluída com sucesso."
        $btnCancel.Text = "Fechar"

    } else {
        $lblStatus.Text = "$errors arquivo(s) com erro. Verifique as permissões."
        $btnInstall.Enabled = $true
        $btnBrowse.Enabled  = $true
        $txtDest.Enabled    = $true
        $btnCancel.Text     = "Fechar"
    }
})

# ── Monta e exibe ─────────────────────────────────────────────────────────────
$form.Controls.AddRange(@($panelLeft, $panelRight))
$form.ShowDialog() | Out-Null