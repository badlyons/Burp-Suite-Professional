# Importar módulo
Import-Module "$PSScriptRoot\BurpUtils.psm1"


# Ruta fija en base al usuario actual
$workDir = Join-Path $env:LOCALAPPDATA "Programs\BurpSuiteProfessional"

# Crear carpeta si no existe
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
    Write-Host "Carpeta creada en: $workDir"
}
else {
    Write-Host "Usando carpeta existente: $workDir"
}

# Cambiar a la carpeta de trabajo
Set-Location $workDir
Write-Host "Directorio de trabajo: $(Get-Location)"


# Obtener versión más reciente estable
$version = Get-LatestStableBurpVersion


if (-not $version) {
    Write-Host "Could not get the latest stable version." -ForegroundColor Red
    exit
}


# Guardar el valor en el archivo .version (crea el archivo si no existe)
$version | Out-File -FilePath ".version" -Encoding UTF8



# Set Wget Progress to Silent, Becuase it slows down Downloading by 50x
Write-Output "Setting Wget Progress to Silent, Becuase it slows down Downloading by 50x`n"
$ProgressPreference = 'SilentlyContinue'


# Check JDK-21 Availability or Download JDK-21
$jdk21 = Get-WmiObject -Class Win32_Product -filter "Vendor='Oracle Corporation'" | Where-Object Caption -clike "Java(TM) SE Development Kit 21*"
if (!($jdk21)) {
    Write-Output "`t`tDownnloading Java JDK-21 ...."
    Invoke-WebRequest "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe" -O jdk-21.exe  
    Write-Output "`n`t`tJDK-21 Downloaded, lets start the Installation process"
    Start-Process -wait jdk-21.exe
    Remove-Item jdk-21.exe
}
else {
    Write-Output "Required JDK-21 is Installed"
    $jdk21
}


# Download Burpsuite Professional
Write-Host "Downloading Burp Suite Professional Latest..."
$version_year = "2025"

Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/download?product=pro&type=Jar&version=$version" `
    -OutFile "burpsuite_pro_v$version_year.jar"


# Creating Burp.bat file with command for execution
if (Test-Path burp.bat) { Remove-Item burp.bat }
$path = "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:`"$pwd\loader.jar`" -noverify -jar `"$pwd\burpsuite_pro_v$version_year.jar`""
$path | add-content -path Burp.bat
Write-Output "`nBurp.bat file is created"



# Creating Burp-Suite-Pro.vbs File for background execution
if (Test-Path Burp-Suite-Pro.vbs) {
    Remove-Item Burp-Suite-Pro.vbs
}
Write-Output "Set WshShell = CreateObject(`"WScript.Shell`")" > Burp-Suite-Pro.vbs
add-content Burp-Suite-Pro.vbs "WshShell.Run chr(34) & `"$pwd\Burp.bat`" & Chr(34), 0"
add-content Burp-Suite-Pro.vbs "Set WshShell = Nothing"
Write-Output "`nBurp-Suite-Pro.vbs file is created."


# Download loader if it not exists
if (!(Test-Path loader.jar)) {
    Write-Output "`nDownloading Loader ...."
    Invoke-WebRequest -Uri "https://github.com/badlyons/Burpsuite-Professional/raw/refs/heads/main/loader.jar" -OutFile loader.jar
    Write-Output "`nLoader is Downloaded"
}
else {
    Write-Output "`nLoader is already Downloaded"
}


# Lets Activate Burp Suite Professional with keygenerator and Keyloader
Write-Output "Reloading Environment Variables ...."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 
Write-Output "`n`nStarting Keygenerator ...."
start-process java.exe -argumentlist "-jar loader.jar"
Write-Output "`n`nStarting Burp Suite Professional"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"loader.jar" -noverify -jar "burpsuite_pro_v$version_year.jar"



#---------------------------------------------------------
# --- Descargar icono ---
Invoke-WebRequest -Uri "https://github.com/badlyons/BurpSuite-Pro-Icon/raw/refs/heads/main/IconGroup1001.ico" -OutFile "icon.ico"
Write-Host "Icono descargado en: $workDir\icon.ico"

# --- Carpeta del Menú Inicio ---
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Burp Suite Professional"
if (!(Test-Path $startMenuDir)) {
    New-Item -ItemType Directory -Path $startMenuDir | Out-Null
    Write-Host "Carpeta de menú inicio creada: $startMenuDir"
}

# --- Crear acceso directo al .vbs ---
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut((Join-Path $startMenuDir "Burp Suite Professional.lnk"))
$shortcut.TargetPath = Join-Path $workDir "Burp-Suite-Pro.vbs"
$shortcut.WorkingDirectory = $workDir
$shortcut.IconLocation = Join-Path $workDir "icon.ico"
$shortcut.Save()
Write-Host "Acceso directo creado en el menú inicio"