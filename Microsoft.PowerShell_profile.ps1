$Env:COREPACK_ENABLE_AUTO_PIN = 0
chcp 65001 | Out-Null
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

$MaximumHistoryCount = 32767
Set-PSReadLineOption -MaximumHistoryCount 100000 -HistoryNoDuplicates

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

function format-for-ll
{
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
}

function list-existing-dir
{
    param (
        [string]$target
    )

    Get-ChildItem $target
    | ForEach-Object { format-for-ll }
    | Sort-Object -Property LastWriteTime
}

function ll
{
    param (
        [string]$target="."
    )

    if(Test-Path $target)
    {
        list-existing-dir $target
    } else
    {
        Write-Host "filter: Where-Object -Property Name -CMatch $target" -ForegroundColor Red
        Get-ChildItem -Depth 0
        | Where-Object -Property Name -CMatch $target
        | ForEach-Object { format-for-ll }
        | Sort-Object -Property LastWriteTime
    }
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

        $truncated = $false
        [System.Collections.ArrayList]$truncatedComponents = @()
        $totalLength = 0
        foreach ($component in $pathComponents)
        {
            if ($totalLength + $component.Length -gt $MaxTotalLength)
            {
                $truncated = $true
                break
            }

            $truncatedComponents += $component
            $totalLength += $component.Length
        }
        if (!$truncated)
        {
            $truncatedComponents.Remove($truncatedComponents[-1])
        }

        $truncatedComponents.Reverse()
        $truncatedPath = $truncatedComponents -join '\'

        return "..." + $truncatedPath
    }

    $time = $(Get-Date -Format "HH:mm:ss")

    # https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#extended-colors
    $color_prefix=""
    switch ($($Host.UI.RawUI.WindowTitle -Split '_' | Select-Object -first 1)) {
        "WHATEVER" { $color_prefix = "$([char]27)[48;2;0;0;255m$([char]27)[38;2;255;255;255m" }
        "DAEMON" { $color_prefix = "$([char]27)[48;2;100;100;100m$([char]27)[38;2;255;255;0m" }
        "GIT" { $color_prefix = "$([char]27)[48;2;0;255;0m$([char]27)[38;2;0;0;0m" }
        "MAIN" { $color_prefix = "$([char]27)[48;2;255;0;0m$([char]27)[38;2;255;255;0m" }
        default { $color_prefix = "$([char]27)[48;2;210;180;140m$([char]27)[38;2;0;0;0m" }
    }
    "$color_prefix$time $($Host.UI.RawUI.WindowTitle -Split '_' | Select-Object -first 1) $(truncate_path $executionContext.SessionState.Path.CurrentLocation)>$([char]27)[0m "
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
    wt --window 0 new-tab --tabColor '#FF0000' --title 'MAIN' -d ./
    wt --window 0 new-tab --tabColor '#00FF00' --title 'GIT_GIT_GIT' -d ./
    wt --window 0 new-tab --tabColor '#aaaaaa' --title 'DAEMON_DAEMON' -d ./
    wt --window 0 new-tab --tabColor '#0000aa' --title 'WHATEVER' -d ./
    start-sleep 1.5
    exit
}

Set-Alias -Name my -Value mytabs -Force
Set-Alias -Name myt -Value mytabs -Force
Set-Alias -Name myta -Value mytabs -Force
Set-Alias -Name mytab -Value mytabs -Force
Set-Alias -Name myutabs -Value mytabs -Force
Set-Alias -Name muytabs -Value mytabs -Force

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
    param (
        [int]$Port = 13333
    )

    ipconfig | findstr /C:"IPv4 Address" | ForEach-Object { $_.trim() }
    Start-Process -FilePath "python" -ArgumentList "-m http.server $Port" -NoNewWindow -Wait
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
Set-Alias -Name g -Value git -Force
Set-Alias -Name nivm -Value nvim -Force
Set-Alias -Name nvmi -Value nvim -Force
Set-Alias -Name mvn -Value nvm -Force

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

function repeat
{
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Param1,
        [Parameter(Mandatory=$false, Position=1)]
        $Param2
    )
    if ($null -ne $Param2) {
        $Count = $Param1
        $Command = $Param2
    } else {
        $Count = 7
        $Command = $Param1
    }

    for ($i = 1; $i -lt $Count + 1; $i++)
    {
        Write-Host "running: $i / $Count, $Command" -BackgroundColor Blue -ForegroundColor Yellow
        Invoke-Expression $Command
    }
}


function take_a_break {
    param (
        [string[]]$Times = @("09:48", "10:48", "11:48", "14:30", "15:30", "16:30")
    )

    $lockTimes = $Times | ForEach-Object { [TimeSpan]::Parse($_) }
    Write-Output "breaks: $Times"
    Write-Output ""

    while ($true) {
        $currentTime = (Get-Date).TimeOfDay
        Write-Output "running... $(Get-Date -Format HH:mm:ss)"

        $isBreakTime = $false
        foreach ($lockTime in $lockTimes) {
            if ($currentTime.Hours -eq $lockTime.Hours -and $currentTime.Minutes -eq $lockTime.Minutes) {
                $isBreakTime = $true
                break
            }
        }

        if ($isBreakTime) {
            rundll32.exe user32.dll,LockWorkStation
            Start-Sleep -Seconds 1
        } else {
            Start-Sleep -Seconds 50
        }
    }
}

function fzf_git_checkout {
    $selectedBranch = git newbranch |
                      ForEach-Object { ($_ -split '\s+')[-1] } |
                      ForEach-Object { $_.Trim() } |
                      Select-Object -Unique |
                      fzf --tac --cycle --preview "pwsh -NoProfile -Command echo {} && git lgl {}"`
                        --preview-window "right,70%,wrap"

    if ($selectedBranch) {
        git checkout $selectedBranch
    }
}

Set-Alias -Name gc -Value fzf_git_checkout -Force

function fz {
    $targetDirectory = Get-ChildItem -Recurse -Directory -Force |
                       Select-Object -ExpandProperty FullName |
                       fzf --cycle
    if ($targetDirectory) {
        z $targetDirectory
    }
}

Set-Alias -Name g -Value git -Force
Set-Alias -Name n -Value nvim -Force
Set-Alias -Name v -Value nvim -Force
