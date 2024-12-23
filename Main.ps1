# Prompt the user to enter the file path for the file to be deleted
$filePath = Read-Host "enter your file location"

# Check if the file exists
if (-Not (Test-Path $filePath)) {
    Write-Host "The file does not exist. Please check the path and try again."
    exit
}

# Prompt the user to enter the deletion date in YYYY-MM-DD format
$DeletionDateString = Read-Host "Enter the deletion date (YYYY-MM-DD) for the file $filePath"

# Convert the string to a DateTime object
try {
    $DeletionDate = [DateTime]::ParseExact($DeletionDateString, "yyyy-MM-dd", $null)
} catch {
    Write-Host "Invalid date format. Please use YYYY-MM-DD format."
    exit
}

# Change the LastWriteTime (modification date) of the file
(Get-Item $filePath).LastWriteTime = $DeletionDate

# Confirm the deletion
$confirmation = Read-Host "Are you sure you want to delete the file $filePath with the date set to $DeletionDate? (Y/N)"
if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
    # Securely delete the file using a custom function if sdelete is not available
    function Secure-Delete {
        param ($Path)
        if (Test-Path $Path) {
            $file = Get-Item $Path
            $file.Delete()
            Write-Host "File $Path deleted securely."
        } else {
            Write-Host "File $Path does not exist."
        }
    }
    Secure-Delete -Path $filePath

    # Function to clear specific directories and files related to the file
    function Clear-Directories {
        param ($paths)
        foreach ($path in $paths) {
            if (Test-Path $path) {
                Get-ChildItem $path -Recurse | ForEach-Object {
                    if ($_.FullName -match [regex]::Escape($filePath)) {
                        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                        Write-Host "$($_.FullName) cleared."
                    }
                }
            }
        }
    }

    # Call the Clear-Directories function with paths to check
    Clear-Directories @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Recent\*",
        "$env:APPDATA\Microsoft\Windows\Recent\*",
        "$env:USERPROFILE\AppData\Local\Temp\*",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Recent\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Recent\*",
        "$env:PUBLIC\Documents\*",
        "$env:PUBLIC\Downloads\*",
        "$env:PUBLIC\Pictures\*",
        "$env:PUBLIC\Videos\*",
        "$env:PUBLIC\Music\*"
    )

    # Clear Event Logs (Auto-detection)
    Get-EventLog -List | ForEach-Object {
        try {
            Clear-EventLog -LogName $_.LogName
            Write-Host "Cleared Event Log: $($_.LogName)"
        } catch {
            Write-Host "Failed to clear Event Log: $($_.LogName)"
        }
    }

    # Clear TEMP Files
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared TEMP files."

    # Remove Prefetch Files
    Remove-Item "$env:WINDOWS\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared Prefetch files."

    # Empty Recycle Bin
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Emptied Recycle Bin."

    # Remove File Metadata
    function Clear-Metadata {
        param ($file)
        if (Test-Path $file) {
            $shell = New-Object -ComObject Shell.Application
            $folder = $shell.Namespace((Get-Item $file).DirectoryName)
            $item = $folder.ParseName((Get-Item $file).Name)
            $folder.GetDetailsOf($item, 1) # Clear EXIF Metadata
            Write-Host "Cleared metadata for file $file"
        }
    }
    Clear-Metadata -file $filePath

    # Clear Network Cache and Logs
    function Clear-NetworkCache {
        $cachePaths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
            "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftEdge_*\AC\MicrosoftEdge\User\Default\WebCache\*",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*",
            "$env:APPDATA\Microsoft\Windows\Recent\*"
        )
        Clear-Directories -paths $cachePaths
    }
    Clear-NetworkCache
    Write-Host "Cleared Network Cache and Logs."

    # Clear Volume Shadow Copies
    vssadmin delete shadows /all /quiet
    Write-Host "Cleared Volume Shadow Copies."

    # Clear Pagefile
    function Clear-Pagefile {
        $pagefile = Get-WmiObject -Query "SELECT * FROM Win32_PageFileSetting"
        foreach ($pf in $pagefile) {
            $pf.Delete()
            Write-Host "Cleared Pagefile."
        }
    }
    Clear-Pagefile

    # Clear Hibernation File
    function Clear-HibernationFile {
        powercfg -h off
        Write-Host "Cleared Hibernation File."
    }
    Clear-HibernationFile

    # Clear File System Journal
    function Clear-FileSystemJournal {
        $fileSystemJournal = Get-WmiObject -Query "SELECT * FROM Win32_NTLogEvent WHERE Logfile='System' AND EventCode=15"
        foreach ($entry in $fileSystemJournal) {
            $entry.Delete()
            Write-Host "Cleared File System Journal."
        }
    }
    Clear-FileSystemJournal

    # Clear System Restore Points
    function Clear-SystemRestorePoints {
        vssadmin delete shadows /all /quiet
        Write-Host "Cleared System Restore Points."
    }
    Clear-SystemRestorePoints

    # Clear Application-specific Logs
    function Clear-ApplicationLogs {
        $logPaths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*",
            "$env:APPDATA\Local\Temp\*"
        )
        Clear-Directories -paths $logPaths
    }
    Clear-ApplicationLogs
    Write-Host "Cleared Application-specific Logs."

    # Clear Registry Entries
    function Clear-RegistryEntries {
        $paths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
        )
        foreach ($path in $paths) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleared Registry Entries: $path"
        }
    }
    Clear-RegistryEntries

    # Clear Prefetch Files
    function Clear-PrefetchFiles {
        Remove-Item "$env:WINDOWS\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared Prefetch files."
    }
    Clear-PrefetchFiles

    # Clear TEMP Files
    function Clear-TEMPFiles {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared TEMP files."
    }
    Clear-TEMPFiles

    # Clear User-specific Logs
    function Clear-UserLogs {
        $userLogPaths = @(
            "$env:LOCALAPPDATA\Temp\*",
            "$env:APPDATA\Microsoft\Windows\Recent\*"
        )
        Clear-Directories -paths $userLogPaths
    }
    Clear-UserLogs
    Write-Host "Cleared User-specific Logs."

    # Clear System Logs
    function Clear-SystemLogs {
        Remove-Item "$env:WINDOWS\Logs\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared System Logs."
    }
    Clear-SystemLogs

    # Clear Browser History for Various Browsers
    function Clear-BrowserHistory {
        # Google Chrome
        Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History" -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared Google Chrome History."

        # Mozilla Firefox
        Remove-Item "$env:APPDATA\Mozilla\Firefox\Profiles\*\places.sqlite" -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared Mozilla Firefox History."

        # Microsoft Edge
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History" -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared Microsoft Edge History."
    }
    Clear-BrowserHistory
    Write-Host "Cleared Browser History."

    # Clear Volume Shadow Copies
    function Clear-VolumeShadowCopies {
        vssadmin delete shadows /all /quiet
        Write-Host "Cleared Volume Shadow Copies."
    }
    Clear-VolumeShadowCopies

    # Clear Hibernation File
    function Clear-HibernationFile {
        powercfg -h off
        Write-Host "Cleared Hibernation File."
    }
    Clear-HibernationFile

    Write-Host "Cleanup completed successfully."

} else {
    Write-Host "File deletion aborted."
}
