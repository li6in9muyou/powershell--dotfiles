chcp 65001 | Out-Null
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

function Convert-BytesToHumanReadable
{
    param(
        [Parameter(Mandatory=$true)]
        [int64]$Bytes
    )

    $sizes = 'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'
    $factor = [math]::Floor([math]::Log($Bytes, 1024))
    $humanReadable = [string]::Format("{0,8:F2}{1}", $Bytes / [math]::Pow(1024, $factor), $sizes[$factor])

    return $humanReadable
}

function ll
{
    param (
        [string]$target
    )

    Get-ChildItem $target | ForEach-Object {
        $name = $_.Name
        if ($_.PSIsContainer)
        {
            $name += "\"
        }
        [PSCustomObject]@{
            LastWriteTime = $_.LastWriteTime
            Size = Convert-BytesToHumanReadable($_.Length)
            Name = "  " + $name
        }
    } | Sort-Object -Property LastWriteTime
}

function prompt
{
    "$([char]27)[41m$([char]27)[93mPS $($executionContext.SessionState.Path.CurrentLocation)>$([char]27)[0m "
}

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function ctitle
{
    param (
        [string]$Title
    )

    $host.ui.RawUI.WindowTitle = $Title
}

function here
{
    explorer.exe .
}

function remove
{
    param (
        [string[]]$targets
    )

    Remove-Item -Force -Recurse $targets
}

function pyserve
{
    ipconfig | findstr /C:"IPv4 Address" | ForEach-Object { $_.trim() }
    python -m http.server 13333
}

function gitdb
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$branchToDelete
    )

    git branch -M $branchToDelete $("deprecated/{0}" -f $branchToDelete)
}

Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory
Set-PSReadLineKeyHandler -Chord Ctrl+y -Function AcceptLine

