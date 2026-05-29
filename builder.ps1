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
        Title="PS2EXE Builder" Height="670" Width="720"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#2D2D30" Foreground="#FFFFFF" FontFamily="Segoe UI">

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
                <Label Content="Script PS1:" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtScript" Grid.Column="1" Text=".\instalador.ps1" VerticalAlignment="Center"/>
                <Button Name="btnBrowseScript" Content="..." Grid.Column="2" Margin="5,0,0,0" Width="40"/>
            </Grid>

            <Grid Margin="0,5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Label Content="Ícone (.ico):" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtIcon" Grid.Column="1" Text=".\app.ico" VerticalAlignment="Center"/>
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

# ── PREENCHER COMBO ───────────────────────────────────────────────────────────
[void]$cboLicense.Items.Add("Nenhuma (Sem EULA)")
foreach ($lic in $licensesData) {
    [void]$cboLicense.Items.Add($lic.name)
}
 $cboLicense.SelectedIndex = 0 

# ── EVENTOS ───────────────────────────────────────────────────────────────────
 $window.FindName("btnBrowseSource").Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtSource.Text
    if ($fbd.ShowDialog() -eq "OK") { $txtSource.Text = $fbd.SelectedPath }
})

 $window.FindName("btnBrowseScript").Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
    $ofd.InitialDirectory = (Get-Location).Path
    if ($ofd.ShowDialog() -eq "OK") { $txtScript.Text = $ofd.FileName }
})

 $window.FindName("btnBrowseIcon").Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Icon Files (*.ico)|*.ico"
    if ($ofd.ShowDialog() -eq "OK") { $txtIcon.Text = $ofd.FileName }
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
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Text Files (*.txt;*.rtf)|*.txt;*.rtf|All Files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq "OK") {
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
    
    $destFolder = $txtAppName.Text
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
        $scriptContent = $scriptContent -replace '\{\{DEST_FOLDER\}\}', $txtAppName.Text
        $scriptContent | Set-Content $tempScriptPath -Encoding UTF8

        # 4. Params (PS 5.1 Safe)
        $buildParams = @{}
        $buildParams['inputFile'] = $tempScriptPath
        $buildParams['outputFile'] = (Join-Path (Get-Location) $txtOutput.Text)
        $buildParams['embedFiles'] = $embedHash
        $buildParams['noConsole'] = $true

        if (Test-Path $txtIcon.Text) { $buildParams['iconFile'] = $txtIcon.Text }

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

    } catch {
        Write-Log "ERRO CRÍTICO: $_" "#FF5555"
    } finally {
        $btn.IsEnabled = $true
        $btn.Content = "GERAR INSTALADOR (BUILD)"
    }
})

# ── MOSTRAR JANELA ───────────────────────────────────────────────────────────
 $window.ShowDialog() | Out-Null