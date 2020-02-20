param (
    $TempLocation = "C:\Windows\Temp\LGPOBackup",
    $LGPOLocation = "C:\Windows\Temp\LGPO.exe",
    $TempBackupName = 'LGPOTempBackup'
)
$TempBackupPath = (Join-Path $TempLocation $TempBackupName)
function removeExistingBackupFolder {
    Remove-Item $TempLocation -Recurse -Force -ErrorAction SilentlyContinue
}
function makeBackupFolder {
    New-Item -ItemType Directory -Path "C:\Windows\Temp\LGPOBackup" -ErrorAction SilentlyContinue
}
function backupLGPO {
    $BackupArgs = '/b', $TempLocation, '/n', 'LGPOTemp'
    Start-Process $LGPOLocation -ArgumentList $BackupArgs -Wait -WindowStyle Hidden
}
function renameBackup {
    $LGPOBackup = Get-ChildItem -Path $TempLocation -Filter '{*}'
    if (($LGPOBackup | Measure-Object | Select-Object -ExpandProperty Count) -gt 1) {
        exit 1
    }
    else {
        Rename-Item $LGPOBackup.FullName -NewName 
    }
}
function extractBackup {
    $ExtractionArgs = '/parse', '/m', (Join-Path $TempBackupPath "\DomainSysvol\GPO\Machine\registry.pol")
    Start-Process $LGPOLocation -ArgumentList $ExtractionArgs -Wait -WindowStyle Hidden
}
removeExistingBackupFolder
makeBackupFolder
backupLGPO
renameBackup