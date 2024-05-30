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
    function truncate_path
    {
        param (
            [string]$Path,
            [int]$MaxTotalLength = 70
        )

        if ($Path.Length -lt $MaxTotalLength)
        {
            return $Path
        }

        $pathComponents = $Path.split("\")
        [array]::Reverse($pathComponents)

        $truncatedComponents = @()
        $totalLength = 0
        foreach ($component in $pathComponents)
        {
            if ($totalLength + $component.Length -gt $MaxTotalLength)
            {
                break
            }

            $truncatedComponents += $component
            $totalLength += $component.Length
        }
        [array]::Reverse($truncatedComponents)
        $truncatedPath = $truncatedComponents -join '\'

        return "..." + $truncatedPath
    }
    # https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#extended-colors
    "$([char]27)[48;2;255;0;0m$([char]27)[38;2;255;255;0mPS $(truncate_path $executionContext.SessionState.Path.CurrentLocation)>$([char]27)[0m "
}

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function ctitle
{
    param (
        [string]$Title
    )

    $host.ui.RawUI.WindowTitle = $Title
}


function mytabs
{
    wt new-tab --tabColor '#FF0000' --title 'MAIN'
    wt new-tab --tabColor '#00FF00' --title 'GIT_GIT_GIT'
    wt new-tab --tabColor '#aaaaaa' --title 'DAEMON_DAEMON'
    wt new-tab --tabColor '#0000aa' --title 'WHATEVER'
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

function touch
{
    param (
        [string]$target
    )

    (Get-ChildItem $target).LastWriteTime = Get-Date
}

Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory
Set-PSReadLineKeyHandler -Chord Ctrl+y -Function AcceptLine
Set-Alias -Name gti -Value git -Force

function sb
{
    $b = $(git branch --all | fzf)
    if ($null -eq $b)
    {
        Write-Host "no branch is selected"
        return
    }

    $branch = $b.Substring(2)
    git checkout $branch
}
