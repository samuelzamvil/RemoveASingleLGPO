param (
    $TempLocation = "C:\Windows\Temp\LGPOBackup",
    $LGPOLocation = "C:\Windows\Temp\LGPO.exe",
    $TempBackupName = 'LGPOTempBackup'
)
$TempBackupPath = (Join-Path $TempLocation $TempBackupName)
$RegPolFilePath = (Join-Path $TempBackupPath "\DomainSysvol\GPO\Machine\registry.pol")
$DefaultAssociationsPattern = 'DefaultAssociationsConfiguration'
$UpdatedPolicyFile = (Join-Path $TempLocation 'UpdatedPolicy.txt')
$UpdatedRegPolFile = (Join-Path $TempLocation 'UpdatedRegistry.pol')
function removeExistingBackupFolder {
    Remove-Item $TempLocation -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep 5
} # end function
function makeBackupFolder {
    New-Item -ItemType Directory -Path "C:\Windows\Temp\LGPOBackup" -ErrorAction SilentlyContinue
} # end function
function backupLGPO {
    $BackupArgs = '/b', $TempLocation, '/n', 'LGPOTemp'
    Start-Process $LGPOLocation -ArgumentList $BackupArgs -Wait -WindowStyle Hidden
} # end function
function renameBackup {
    $LGPOBackup = Get-ChildItem -Path $TempLocation -Filter '{*}'
    if (($LGPOBackup | Measure-Object | Select-Object -ExpandProperty Count) -gt 1) {
        exit 1
    }
    else {
        Rename-Item $LGPOBackup.FullName -NewName $TempBackupPath
    }
} # end function
function extractParsedPolicy {
    $ExtractedBackup = & $LGPOLocation /parse /m $RegPolFilePath
    return $ExtractedBackup
} # end function
function updatePolicy {
    param (
        [System.Object]$Policy,
        [string]$Pattern
    )
    # Check to see if policy pattern exists
    if ($Policy -ccontains $Pattern) {
        # Get the index of the Policies name
        $PolicyLine = $Policy.IndexOf($Pattern)
        for ($i = 0; $i -lt $Policy.Length; $i++) {
            # Make new file by ignoring the lines the policy exists on
            if ($i -le ($PolicyLine - 4) -or $i -ge ($PolicyLine + 2)) {
                $Policy[$i] | out-file $UpdatedPolicyFile -Append -Force
            } # end if
        } # end for
    } #end if
    else {
        exit 1
    }
} # end function

function encapsulateParsedPolicy {
    & $LGPOLocation /r $UpdatedPolicyFile /w $UpdatedRegPolFile
    # if updating the pol file fails exit
    if ($LASTEXITCODE -ne 0) {
        exit 2
    }
} # end function

function replacePolFile {
    Copy-Item $UpdatedRegPolFile $RegPolFilePath
}
function removeOldPolicyFiles {
    Remove-Item 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol' -Force
}
function importUpdatedPolicy {
    & $LGPOLocation /m $UpdatedRegPolFile
}
removeExistingBackupFolder
makeBackupFolder
backupLGPO
renameBackup
$ParsedComputerPolicy = extractParsedPolicy
updatePolicy -Policy $ParsedComputerPolicy -Pattern $DefaultAssociationsPattern
encapsulateParsedPolicy
removeOldPolicyFile
importUpdatedPolicy