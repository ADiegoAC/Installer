# ==========================================
# GUI DE BUILD PS2EXE (COMPLETO - PS 5.1)
# ==========================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing

# ── CARREGAR LICENÇAS DO JSON ────────────────────────────────────────────────
 $jsonPath = ".\licenses-complete.json"
if (Test-Path $jsonPath) {
    $licensesData = (Get-Content $jsonPath -Raw | ConvertFrom-Json).licenses
} else {
    Write-Warning "Arquivo $jsonPath não encontrado. Nenhuma licença carregada."
    $licensesData = @()
}

# ── XAML DA INTERFACE (Usando @' para PS 5.1 evitar erro de chaves) ────────
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="1nst4ll3r Builder" Height="710" Width="720"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#2D2D30" Foreground="#FFFFFF" FontFamily="Segoe UI"
        UseLayoutRounding="True" SnapsToDevicePixels="True">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="12"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#005A9E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#3E3E42"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#555"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="MinHeight" Value="24"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0">
            <TextBlock Text="Configuração do Build" FontSize="16" FontWeight="Bold" Margin="0,0,0,15" Foreground="#4EC9B0"/>
            
            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="Pasta Fonte:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtSource" Grid.Column="1" Text=".\bin" VerticalAlignment="Center"/>
                <Button Name="btnBrowseSource" Content="..." Grid.Column="2" Margin="5,0,0,0" Width="40"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="EXE Principal:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtMainExe" Grid.Column="1" Text="" VerticalAlignment="Center"/>
                <Button Name="btnBrowseMainExe" Content="..." Grid.Column="2" Margin="5,0,0,0" Width="40"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="Script PS1:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtScript" Grid.Column="1" Text=".\1nst4ll3r.ps1" VerticalAlignment="Center"/>
                <Button Name="btnBrowseScript" Content="..." Grid.Column="2" Margin="5,0,0,0" Width="40"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="Ícone (.ico):" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtIcon" Grid.Column="1" Text="" VerticalAlignment="Center"/>
                <Button Name="btnBrowseIcon" Content="..." Grid.Column="2" Margin="5,0,0,0" Width="40"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Content="Nome do EXE:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtOutput" Grid.Column="1" Text="Setup.exe" VerticalAlignment="Center"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Content="Nome do App:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtAppName" Grid.Column="1" Text="MeuApp" VerticalAlignment="Center"/>
            </Grid>

            <!-- Checkbox de Admin -->
            <CheckBox Name="chkRequireAdmin" Content="Modo Administrador (Pede UAC e instala em Program Files)" 
                      Margin="0,15,0,0" Foreground="#FFFFFF" Background="#2D2D30" 
                      BorderBrush="#4EC9B0" VerticalContentAlignment="Center"/>

            <Separator Margin="0,15,0,15" Background="#555"/>

            <TextBlock Text="Configuração de Licença (EULA)" FontSize="14" FontWeight="Bold" Foreground="#CE9178"/>
            
            <!-- Overlay do ComboBox -->
            <Grid Margin="0,10,0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="Modelo de Licença:" Grid.Column="0" VerticalAlignment="Center"/>
                <Canvas Grid.Column="1" Height="24" VerticalAlignment="Center">
                    <ComboBox Name="cboLicense" Width="300" Height="24" Foreground="#3E3E42" BorderBrush="#555"/>
                    <TextBox Name="txtLicenseDisplay" Width="275" Height="24" Text="Nenhuma (Sem EULA)" IsReadOnly="True" 
                             Background="#3E3E42" Foreground="#FFFFFF" BorderThickness="0"
                             VerticalContentAlignment="Center" Padding="5,0"/>
                </Canvas>
                <Button Name="btnLoadFile" Content="Carregar Arquivo" Grid.Column="2" Margin="5,0,0,0"/>
            </Grid>

            <Label Content="Conteúdo da Licença (Pré-visualização):" FontSize="10" Foreground="#AAA"/>
            <TextBox Name="txtLicenseContent" Height="60" TextWrapping="Wrap" AcceptsReturn="True" 
                     VerticalScrollBarVisibility="Auto" Margin="0,0,0,10" FontSize="10" Background="#252526"/>

            <Button Name="btnBuild" Content="GERAR INSTALADOR (BUILD)" Height="40" FontSize="14" FontWeight="Bold"/>
        </StackPanel>

        <GroupBox Header="Log de Saída" Grid.Row="1" Margin="0,1,0,0" Foreground="#AAA" BorderBrush="#555">
            <TextBox Name="txtLog" IsReadOnly="True" Background="#1E1E1E" Foreground="#CCC" 
                     Height="100" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
        </GroupBox>
    </Grid>
</Window>
'@

# ── INICIALIZAÇÃO ─────────────────────────────────────────────────────────────
 $reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Erro ao carregar XAML: $_"
    return
}

# Mapeamento de elementos
 $txtSource       = $window.FindName("txtSource")
 $txtMainExe      = $window.FindName("txtMainExe")
 $txtScript       = $window.FindName("txtScript")
 $txtIcon         = $window.FindName("txtIcon")
 $txtOutput       = $window.FindName("txtOutput")
 $txtLicense      = $window.FindName("txtLicenseContent")
 $txtLog          = $window.FindName("txtLog")
 $cboLicense      = $window.FindName("cboLicense")
 $txtLicenseDisplay = $window.FindName("txtLicenseDisplay")
 $txtAppName        = $window.FindName("txtAppName")
 $tempLicensePath   = $null

# ── FUNÇÕES ───────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$msg, [string]$color = "#CCC")
    $txtLog.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $msg`r`n")
    $txtLog.ScrollToEnd()
}

function Select-Folder {
    param([string]$InitialPath)

    $resolvedPath = Resolve-Path $InitialPath -ErrorAction SilentlyContinue
    if ($resolvedPath) {
        $InitialPath = $resolvedPath.Path
    } else {
        $InitialPath = (Get-Location).Path
    }

    $shell = New-Object -ComObject Shell.Application
    $browseFlags = 0x1 + 0x10 + 0x40
    $folder = $shell.BrowseForFolder(0, "Escolha a pasta fonte", $browseFlags, 0)

    if ($folder) {
        return $folder.Self.Path
    }

    return $null
}

function Get-RelativePath {
    param([string]$BasePath, [string]$Path)

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
    $targetFullPath = [System.IO.Path]::GetFullPath($Path)
    $baseUri = New-Object System.Uri($baseFullPath)
    $targetUri = New-Object System.Uri($targetFullPath)

    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Get-MainExeCandidate {
    param([string]$SourcePath)

    $resolvedSource = Resolve-Path $SourcePath -ErrorAction SilentlyContinue
    if (-not $resolvedSource) { return $null }

    $exeFiles = @(Get-ChildItem -Path $resolvedSource.Path -Recurse -File -Filter *.exe)
    if ($exeFiles.Count -eq 1) {
        return (Get-RelativePath $resolvedSource.Path $exeFiles[0].FullName)
    }

    return $null
}

function Resolve-MainExePath {
    param([string]$SourcePath, [string]$MainExe)

    if ([string]::IsNullOrWhiteSpace($MainExe)) { return $null }
    if ([System.IO.Path]::IsPathRooted($MainExe)) { return $MainExe }

    return (Join-Path $SourcePath $MainExe)
}

function Export-AssociatedIcon {
    param([string]$ExePath, [string]$IconPath)

    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
    if (-not $icon) { return $false }

    $stream = [System.IO.File]::Create($IconPath)
    try {
        $icon.Save($stream)
    } finally {
        $stream.Close()
        $icon.Dispose()
    }

    return $true
}

# ── PREENCHER COMBO ───────────────────────────────────────────────────────────
[void]$cboLicense.Items.Add("Nenhuma (Sem EULA)")
foreach ($lic in $licensesData) {
    [void]$cboLicense.Items.Add($lic.name)
}
 $cboLicense.SelectedIndex = 0 

# ── EVENTOS ───────────────────────────────────────────────────────────────────
 $window.FindName("btnBrowseSource").Add_Click({
    $selectedPath = Select-Folder $txtSource.Text
    if ($selectedPath) {
        $txtSource.Text = $selectedPath
        $mainExeCandidate = Get-MainExeCandidate $txtSource.Text
        if ($mainExeCandidate) {
            $txtMainExe.Text = $mainExeCandidate
        }
    }
})

 $window.FindName("btnBrowseMainExe").Add_Click({
    $ofd = New-Object Microsoft.Win32.OpenFileDialog
    $ofd.Filter = "Executáveis (*.exe)|*.exe"
    $sourcePath = Resolve-Path $txtSource.Text -ErrorAction SilentlyContinue
    if ($sourcePath) {
        $ofd.InitialDirectory = $sourcePath.Path
    } else {
        $ofd.InitialDirectory = (Get-Location).Path
    }
    if ($ofd.ShowDialog() -eq $true) {
        if ($sourcePath -and $ofd.FileName.StartsWith($sourcePath.Path, [System.StringComparison]::OrdinalIgnoreCase)) {
            $txtMainExe.Text = Get-RelativePath $sourcePath.Path $ofd.FileName
        } else {
            $txtMainExe.Text = $ofd.FileName
        }
    }
})

 $window.FindName("btnBrowseScript").Add_Click({
    $ofd = New-Object Microsoft.Win32.OpenFileDialog
    $ofd.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
    $ofd.InitialDirectory = (Get-Location).Path
    if ($ofd.ShowDialog() -eq $true) { $txtScript.Text = $ofd.FileName }
})

 $window.FindName("btnBrowseIcon").Add_Click({
    $ofd = New-Object Microsoft.Win32.OpenFileDialog
    $ofd.Filter = "Icon Files (*.ico)|*.ico"
    $ofd.InitialDirectory = (Get-Location).Path
    if ($ofd.ShowDialog() -eq $true) { $txtIcon.Text = $ofd.FileName }
})

# Sincronizar Overlay do ComboBox
 $cboLicense.Add_SelectionChanged({
    if ($cboLicense.SelectedItem -ne $null) {
        $selected = $cboLicense.SelectedItem
        $txtLicenseDisplay.Text = $selected
        
        if ($selected -eq "Nenhuma (Sem EULA)") {
            $txtLicense.Text = ""
        } else {
            # Busca o texto da licença no JSON carregado baseado no nome selecionado
            $selectedLic = $licensesData | Where-Object { $_.name -eq $selected }
            if ($selectedLic) {
                $txtLicense.Text = $selectedLic.licenseText
            }
        }
        
        if ($script:tempLicensePath) { $script:tempLicensePath = $null }
    }
})

 $window.FindName("btnLoadFile").Add_Click({
    $ofd = New-Object Microsoft.Win32.OpenFileDialog
    $ofd.Filter = "Text Files (*.txt;*.rtf)|*.txt;*.rtf|All Files (*.*)|*.*"
    $ofd.InitialDirectory = (Get-Location).Path
    if ($ofd.ShowDialog() -eq $true) {
        $txtLicense.Text = [IO.File]::ReadAllText($ofd.FileName)
        $txtLicenseDisplay.Text = (Split-Path $ofd.FileName -Leaf)
        $tempLicensePath = $ofd.FileName 
        $cboLicense.SelectedIndex = -1 
        Write-Log "Licença carregada do arquivo: $($ofd.FileName)"
    }
})

# ── BOTÃO BUILD ───────────────────────────────────────────────────────────────
 $window.FindName("btnBuild").Add_Click({
    if (-not (Test-Path $txtSource.Text)) { Write-Log "Erro: Pasta fonte não encontrada." "#FF5555"; return }
    if (-not (Test-Path $txtScript.Text)) { Write-Log "Erro: Script de instalação não encontrado." "#FF5555"; return }
    if ([string]::IsNullOrWhiteSpace($txtMainExe.Text)) {
        $mainExeCandidate = Get-MainExeCandidate $txtSource.Text
        if ($mainExeCandidate) {
            $txtMainExe.Text = $mainExeCandidate
            Write-Log "EXE principal detectado automaticamente: $mainExeCandidate" "#4EC9B0"
        } else {
            Write-Log "Erro: escolha o EXE principal. Há zero ou múltiplos executáveis na pasta fonte." "#FF5555"
            return
        }
    }

    $mainExePath = Resolve-MainExePath $txtSource.Text $txtMainExe.Text
    if (-not (Test-Path $mainExePath)) {
        Write-Log "Erro: EXE principal não encontrado: $($txtMainExe.Text)" "#FF5555"
        return
    }

    $resolvedSource = Resolve-Path $txtSource.Text
    $sourceFullPath = [System.IO.Path]::GetFullPath($resolvedSource.Path).TrimEnd('\') + '\'
    $mainExeFullPath = [System.IO.Path]::GetFullPath($mainExePath)
    if (-not $mainExeFullPath.StartsWith($sourceFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Log "Erro: o EXE principal precisa estar dentro da pasta fonte." "#FF5555"
        return
    }

    $txtMainExe.Text = Get-RelativePath $resolvedSource.Path $mainExeFullPath
    
    $destFolder = $txtAppName.Text
    $tempIconPath = $null
    $btn = $window.FindName("btnBuild")
    $btn.IsEnabled = $false
    $btn.Content = "PROCESSANDO..."

    try {
        Write-Log "Iniciando Build..." "#4EC9B0"

        # 1. Zip
        $zipName = "payload.zip"
        $zipPath = Join-Path (Get-Location) $zipName
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        
        $src = $txtSource.Text.TrimEnd('\')
        Write-Log "Compactando arquivos de $src..."
        Compress-Archive -Path "$src\*" -DestinationPath $zipPath -Force
        
        if (-not (Test-Path $zipPath)) {
             Write-Log "Erro ao criar ZIP." "#FF5555"
             $btn.IsEnabled = $true; $btn.Content = "GERAR INSTALADOR (BUILD)"
             return
        }
        Write-Log "ZIP criado." "#4EC9B0"

        # 2. Licença
        $licenseFile = $null
        if ($cboLicense.SelectedIndex -ne -1 -and $cboLicense.SelectedItem -ne "Nenhuma (Sem EULA)") {
            # Salva na pasta atual junto com o zip, apenas para o build
            $licenseFile = Join-Path (Get-Location) "temp_eula.rtf"
            $txtLicense.Text | Out-File -FilePath $licenseFile -Encoding UTF8
            Write-Log "Licença preset salva temporariamente."
        } elseif ($tempLicensePath) {
            $licenseFile = $tempLicensePath
            Write-Log "Licença de arquivo externo definida."
        }

        # 3. Hash Table (O Segredo)
        $embedHash = @{
            "%TEMP%\payload.zip" = $zipPath
        }
        if ($licenseFile) {
            $embedHash["%TEMP%\eula.rtf"] = $licenseFile
            Write-Log "EULA adicionada ao pacote de embarque."
        }

        # Injeta o Nome do App no script antes de compilar
        Write-Log "Injetando Nome do App no script..."
        $tempScriptPath = Join-Path (Get-Location) "temp_build_script.ps1"
        $scriptContent = Get-Content $txtScript.Text -Raw
        $scriptContent = $scriptContent.Replace('{{DEST_FOLDER}}', $txtAppName.Text)
        $scriptContent = $scriptContent.Replace('{{MAIN_EXE}}', $txtMainExe.Text)
        $scriptContent = $scriptContent.Replace('{{SHORTCUT_NAME}}', $txtAppName.Text)
        $scriptContent | Set-Content $tempScriptPath -Encoding UTF8

        # 4. Params (PS 5.1 Safe)
        $buildParams = @{}
        $buildParams['inputFile'] = $tempScriptPath
        $buildParams['outputFile'] = (Join-Path (Get-Location) $txtOutput.Text)
        $buildParams['embedFiles'] = $embedHash
        $buildParams['noConsole'] = $true

        if (-not [string]::IsNullOrWhiteSpace($txtIcon.Text) -and (Test-Path $txtIcon.Text)) {
            $buildParams['iconFile'] = $txtIcon.Text
            Write-Log "Ícone do setup definido pelo arquivo .ico."
        } else {
            $tempIconPath = Join-Path (Get-Location) "temp_main_icon.ico"
            if (Export-AssociatedIcon $mainExePath $tempIconPath) {
                $buildParams['iconFile'] = $tempIconPath
                Write-Log "Ícone do setup extraído do EXE principal."
            } else {
                Write-Log "Aviso: não foi possível extrair ícone do EXE principal." "#CE9178"
            }
        }

        # Checkbox Admin
        $chkRequireAdmin = $window.FindName("chkRequireAdmin")
        if ($chkRequireAdmin.IsChecked -eq $true) {
            $buildParams['requireAdmin'] = $true
            Write-Log "Modo ADMIN habilitado. O instalador pedirá UAC." "#CE9178"
        } else {
            Write-Log "Modo USUÁRIO habilitado. Instalará silenciosamente em AppData." "#4EC9B0"
        }

        # 5. Executar
        Write-Log "Rodando PS2EXE..."
        & ps2exe @buildParams 2>&1 | ForEach-Object { Write-Log "$_" }

        $finalExe = $buildParams['outputFile']
        if (Test-Path $finalExe) {
            $size = [math]::Round((Get-Item $finalExe).Length / 1KB, 2)
            Write-Log "BUILD CONCLUÍDO COM SUCESSO!" "#4EC9B0"
            Write-Log "Arquivo gerado: $finalExe ($size KB)"
        } else {
            Write-Log "Falha: EXE não gerado. Verifique o log acima." "#FF5555"
        }

        # 6. Limpeza
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        # Apaga o rtf temporário, mas NÃO apaga o arquivo original do usuário
        if ($licenseFile -and $licenseFile -ne $tempLicensePath -and (Test-Path $licenseFile)) { 
            Remove-Item $licenseFile -Force 
        }
        if (Test-Path $tempScriptPath) { Remove-Item $tempScriptPath -Force }
        if ($tempIconPath -and (Test-Path $tempIconPath)) { Remove-Item $tempIconPath -Force }

    } catch {
        Write-Log "ERRO CRÍTICO: $_" "#FF5555"
    } finally {
        $btn.IsEnabled = $true
        $btn.Content = "GERAR INSTALADOR (BUILD)"
    }
})

# ── MOSTRAR JANELA ───────────────────────────────────────────────────────────
 $window.ShowDialog() | Out-Null
