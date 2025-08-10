Add-Type -AssemblyName System.Windows.Forms

function Get-LatestStableBurpVersion {
    $url = "https://portswigger.net/burp/releases#professional"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing

    # Buscar todas las coincidencias "Professional / Community X.Y.Z"
    $versionMatches = [regex]::Matches($html.Content, 'Professional / Community ([0-9]+\.[0-9]+(\.[0-9]+)?)')

    if ($versionMatches.Count -ge 2) {
        # El segundo match es la última versión estable
        return $versionMatches[1].Groups[1].Value
    }
    else {
        return $null
    }
}

function Update-BurpSuite {
    Add-Type -AssemblyName System.Windows.Forms

    $workDir = Join-Path $env:LOCALAPPDATA "Programs\BurpSuiteProfessional"
    if (!(Test-Path $workDir)) {
        Write-Host "No se encontró instalación existente en $workDir" -ForegroundColor Red
        exit
    }

    $tempJarPath = Join-Path $env:TEMP "burpsuite_pro_v$version_year.jar"
    $workDirJarPath = Join-Path $workDir "burpsuite_pro_v$version_year.jar"

    function DownloadBurp {
        $wc = New-Object System.Net.WebClient
        try {
            $wc.DownloadFile("https://ddd.uab.cat/pub/clivetpeqani/11307064v16n3/11307064v16n3p142.pdf", $tempJarPath)
            return $true
        }
        catch {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Error durante la descarga de Burp Suite.`n¿Quieres reintentar?",
                "Error de Descarga",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $result -eq [System.Windows.Forms.DialogResult]::Yes
        }
    }

    do {
        $finished = DownloadBurp
    } while (-not $finished)

    $updateNow = [System.Windows.Forms.MessageBox]::Show(
        "La descarga de Burp Suite $latestStableVersion ha finalizado.`n¿Deseas actualizar ahora?",
        "Actualizar Burp Suite",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($updateNow -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "Actualización cancelada por el usuario."
        return
    }

    Write-Host "Procediendo a actualizar Burp Suite..."

    # Finalizar Burp Suite
    $javaProcs = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -ieq "java.exe" -and
        $_.ExecutablePath -ieq "C:\Program Files\Java\jdk-21\bin\java.exe"
    }

    if ($javaProcs) {
        foreach ($proc in $javaProcs) {
            Write-Host "Finalizando proceso java.exe PID $($proc.ProcessId) ubicado en $($proc.ExecutablePath)"
            Stop-Process -Id $proc.ProcessId -Force

            do {
                Start-Sleep -Milliseconds 500
                $procCheck = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue
            } while ($procCheck)
        }
    }


    # Mover nuevo jar desde TEMP a workDir, sobrescribiendo
    Write-Host "Moviendo archivo descargado a carpeta de trabajo..."
    Move-Item -Path $tempJarPath -Destination $workDirJarPath -Force
    
    # Actualizar archivo .version con la nueva versión
    Set-Content -Path (Join-Path $workDir ".version") -Value $latestStableVersion -Encoding UTF8


    Write-Host "Actualización completada. Para iniciar Burp Suite, ejecútalo manualmente."
}


# Variables
$version_year = "2025"
$currentVersion = Get-Content ".version" -Raw | ForEach-Object { $_.Trim() }
$latestStableVersion = Get-LatestStableBurpVersion


if ($null -eq $latestStableVersion) {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not get the latest stable version.",
        "Burp Suite - Version Check",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}
elseif ($currentVersion -ne $latestStableVersion) {
    $respuesta = [System.Windows.Forms.MessageBox]::Show(
        "New stable version available: $latestStableVersion (current: $currentVersion)`nDo you want to update now?",
        "Burp Suite - Update Available",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($respuesta -eq [System.Windows.Forms.DialogResult]::Yes) {
        Update-BurpSuite
    }
}