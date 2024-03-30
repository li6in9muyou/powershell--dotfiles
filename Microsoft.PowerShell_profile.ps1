chcp 65001 | Out-Null
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

function prompt {
    "$([char]27)[41m$([char]27)[93mPS $($executionContext.SessionState.Path.CurrentLocation)>$([char]27)[0m "
}

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function ctitle {
    param (
        [string]$Title
    )

    $host.ui.RawUI.WindowTitle = $Title
}

Set-Alias -Name st -Value Set-ShellTitle

function here {
    explorer.exe .
}

function remove {
    param (
        [string]$target
    )

    Remove-Item -Force -Recurse $target
}

function pyserve {
    python -m http.server 13333
}

function gitc {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    git commit -m $Message
}

function gitlog {
    git log --graph --oneline -n 15
}

function gits {
    git status -v
}

Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory

