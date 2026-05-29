# PS2EXE Builder GUI  
A powerful, dark-themed WPF graphical interface for the PS2EXE module. This tool automates the process of converting PowerShell installation scripts into standalone Windows executables (.exe), complete with embedded payloads, dynamic EULAs, and custom installation behaviors.  

PS2EXE Builder GUI  

✨ Features  
Intuitive WPF Interface: Clean, modern dark-theme UI built with XAML and PowerShell.  
Dynamic Payload Embedding: Automatically compresses your source folder (bin) into payload.zip and embeds it directly into the final executable.  
SPDX License Integration: Dynamically loads licenses from a JSON file (licenses-complete.json), allowing users to select standard EULAs (like MIT, GPL, Apache) from a dropdown.  
Variable Injection (Token Replacement): Passes the "App Name" directly from the GUI into your installer script using {{DEST_FOLDER}} token replacement, no external config files needed at runtime.  
UAC & Installation Modes: Toggle between User mode (silent install to AppData) and Admin mode (prompts UAC to install to Program Files).  
Custom Branding: Easily set custom icons (.ico) for your generated executables.  
📋 Prerequisites  
OS: Windows 10 / 11  
PowerShell: Version 5.1 (Built specifically for PS 5.1 compatibility)  
Module: PS2EXE (Install via: Install-Module -Name ps2exe -Force)  
🚀 How to Use  
Clone the repository and ensure ps2exe is installed.  
Run the builder:
.\builder.ps1  
Fill in the configuration fields in the GUI:
Source Folder: The directory containing files to compress and embed.  
PS1 Script: Your main installation script.  
Icon: Optional .ico file for the executable.  
EXE Name: The output file name (e.g., Setup.exe).  
App Name: The name of your application (used to create the installation folder).  
Select a license from the dropdown or load a custom text/RTF file.  
Choose the installation mode (Admin or User).  
Click GERAR INSTALADOR (BUILD).  
⚙️ The Installer Script (instalador.ps1)  
The builder compiles your instalador.ps1 into an EXE. Because the EXE runs independently, it expects the embedded files and uses specific variables.  

Injecting the App Name  
In your instalador.ps1, define your destination folder variable using the {{DEST_FOLDER}} token. The builder will automatically replace this token with the "App Name" from the GUI before compiling:  

powershell  

The builder replaces {{DEST_FOLDER}} with the text from the "Nome do App" field  
 $destFolder = "{{DEST_FOLDER}}"  

if ($isAdmin) {  
    $installPath = "$env:ProgramFiles\$destFolder"  
} else {  
    $installPath = "$env:LOCALAPPDATA\$destFolder"  
}  
Accessing Embedded Files  
The builder embeds the payload and EULA into the EXE. Your installer script must read them from the temp directory at runtime:  

powershell  

1. Extract the embedded payload  
 $zipPath = "$env:TEMP\payload.zip"  
Expand-Archive -Path $zipPath -DestinationPath $installPath -Force  

2. Show EULA (if it exists)  
 $eulaPath = "$env:TEMP\eula.txt" # or .rtf depending on your setup  
if (Test-Path $eulaPath) {  
    # Show your EULA form logic here  
    # Ensure the form's CancelButton is set so clicking "X" cancels the installation!  
}  
📄 Licenses JSON  
The builder dynamically populates the license dropdown using a licenses-complete.json file. This file should follow the standard SPDX format:  

json  

{  
    "licenses": [  
        {  
            "licenseId": "MIT",  
            "name": "MIT License",  
            "licenseText": "MIT License\n\nCopyright (c)..."  
        },  
        {  
            "licenseId": "Apache-2.0",  
            "name": "Apache License 2.0",  
            "licenseText": "Apache License..."  
        }  
    ]  
}  
🛠️ Technologies  
PowerShell 5.1  
WPF (Windows Presentation Foundation) via XAML  
System.Windows.Forms (for File/Folder dialogs)  
ps2exe (PowerShell to EXE compiler)  
📜 License  
This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
```
