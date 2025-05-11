# SFDL_Decrypter

About
Mit diesem Tool können *.sfdl Dateien entschlüsselt werden. Grundlage hierfür ist Powershell.
Basis für das Tool bildet die Verschlüsselungsdokumentation unter https://docs.rs/sfdl.

Screenshot
![SFDL_Decrypter](https://github.com/user-attachments/assets/d9862ced-b8d8-4c16-8ee4-b14dbf745cdb)


Wer selbst kompilieren möchte
gui.xaml und SFDL_Decrypter.ps1 in ein Verzeichnis legen.
Entsprechende Powershell Erweiterung installieren: "Install-Module -Name PS2EXE -Scope CurrentUser".
In diesem Verzeichnis folgenden Befehl ausführen: "Invoke-PS2EXE -InputFile "SFDLDecrypter.ps1" -OutputFile "SFDLDecrypter.exe" -NoConsole"

