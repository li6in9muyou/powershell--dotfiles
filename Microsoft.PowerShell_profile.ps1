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

    $readable = @{label="Size";expression={Convert-BytesToHumanReadable($_.Length)}}
    $padded = @{label="Name";expression={"  {0}" -f $_.Name}}

    Get-ChildItem $target 
    | Sort-Object -Property LastWriteTime
    | Select-Object -Property LastWriteTime, $readable, $padded
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
        [string]$target
    )

    Remove-Item -Force -Recurse $target
}

function pyserve
{
    python -m http.server 13333
}

function gitc
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    git commit -m $Message
}

function gitlog
{
    git log --graph --oneline -n 15 --exclude=refs/heads/deprecated/* --all
}

function gits
{
    git status -v
}

Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory
Set-PSReadLineKeyHandler -Chord Ctrl+y -Function AcceptLine

