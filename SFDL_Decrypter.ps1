Add-Type -AssemblyName PresentationFramework

[xml]$XAML = Get-Content -Path "gui.xaml" -Raw -Encoding UTF8

# GUI laden
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$window = [Windows.Markup.XamlReader]::Load($reader)

# UI-Elemente
$InputBox = $window.FindName("InputBox")
$BrowseButton = $window.FindName("BrowseButton")
$DecryptButton = $window.FindName("DecryptButton")
$PasswordBox = $window.FindName("PasswordBox")
$PreviewBox = $window.FindName("PreviewBox")
$StatusBlock = $window.FindName("StatusBlock")
$PasswordBox.Password = ""

# AES-Decryption
function Decrypt-AES128-CBC {
    param ([string]$EncryptedBase64, [string]$Password)
    try {
        $data = [Convert]::FromBase64String($EncryptedBase64)
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $key = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))
        $iv = $data[0..15]
        $cipherText = $data[16..($data.Length - 1)]
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Mode = 'CBC'
        $aes.Padding = 'PKCS7'
        $aes.Key = $key
        $aes.IV = $iv
        $decryptor = $aes.CreateDecryptor()
        $plain = $decryptor.TransformFinalBlock($cipherText, 0, $cipherText.Length)
        return [System.Text.Encoding]::UTF8.GetString($plain)
    } catch {
        return $EncryptedBase64
    }
}

# Datei verarbeiten
function Decrypt-SFDLFile {
    param ([string]$filePath, [string]$password)

    try {
        [xml]$xmlDoc = Get-Content -Path $filePath -Raw -Encoding UTF8
        $fields = @("Description", "Uploader", "Host", "Username", "Password", "DefaultPath", "BulkFolderPath", "PackageName")
        foreach ($field in $fields) {
            $nodes = $xmlDoc.SelectNodes("//$field")
            foreach ($node in $nodes) {
                if (-not [string]::IsNullOrWhiteSpace($node.InnerText)) {
                    $node.InnerText = Decrypt-AES128-CBC $node.InnerText $password
                }
            }
        }
        $outputPath = [System.IO.Path]::ChangeExtension($filePath, $null) + "_decrypted.sfdl"
        $xmlDoc.Save($outputPath)
        return [PSCustomObject]@{ Path = $outputPath; Content = $xmlDoc.OuterXml }
    } catch {
        return $null
    }
}

# Datei auswählen
$BrowseButton.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "SFDL Dateien (*.sfdl)|*.sfdl"
    $dlg.Title = "SFDL Datei auswählen"
    if ($dlg.ShowDialog()) {
        $InputBox.Text = $dlg.FileName
    }
})

# Entschlüsseln
$DecryptButton.Add_Click({
    $file = $InputBox.Text
    $pwd = $PasswordBox.Password

    if (-not (Test-Path $file)) {
        $StatusBlock.Text = "❌ Datei nicht gefunden."
        $StatusBlock.Foreground = "Red"
        return
    }

    $StatusBlock.Text = "🔄 Entschlüsselung läuft..."
    $StatusBlock.Foreground = "Gray"
    $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render)

    $result = Decrypt-SFDLFile $file $pwd

    if ($result) {
        $StatusBlock.Text = "✅ Gespeichert: $([System.IO.Path]::GetFileName($result.Path))"
        $StatusBlock.Foreground = "Green"
        $PreviewBox.Text = $result.Content
    } else {
        $StatusBlock.Text = "❌ Fehler bei Entschlüsselung"
        $StatusBlock.Foreground = "Red"
        $PreviewBox.Text = ""
    }
})

# Drag & Drop
$window.Add_Drop({
    $e = $_
    $e.Handled = $true
    if ($e.Data.GetDataPresent("FileDrop")) {
        $file = $e.Data.GetData("FileDrop")[0]
        if ($file -like "*.sfdl") {
            $InputBox.Text = $file
        }
    }
})

$window.ShowDialog() | Out-Null
