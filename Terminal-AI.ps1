# Load the .env file
$envPath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^\s*([^=]+)=(.*)") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
} else {
    Write-Host "Error: Archivo .env no encontrado." -ForegroundColor Red
    exit 1
}

$LogPath = Join-Path $PSScriptRoot "TerminalLog.txt"

# Gemini API Key
$API_KEY = $env:GEMINI_API_KEY

# Function to load configuration from Config.json
function Load-Config {
    $configPath = Join-Path $PSScriptRoot "Config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath | ConvertFrom-Json
            return $config
        } catch {
            Write-Host "Error loading configuration file." -ForegroundColor ($config.ErrorColor)
            exit 1
        }
    } else {
        Write-Host "Configuration file 'Config.json' not found." -ForegroundColor ($config.ErrorColor)
        exit 1
    }
}


# Function to get the Battery Status
function Get-BatteryStatus {
    $battery = Get-WmiObject -Class Win32_Battery
    if ($battery) {
        $status = $battery.EstimatedChargeRemaining
        $status = [math]::Round($status, 0)
        return $status
    } else {
        return $null
    }
}

# Function to truncate the path according to the configuration
function Get-TruncatedPath {
    param (
        [string]$path,
        [int]$truncateFolders
    )
    $folders = $path.Split([System.IO.Path]::DirectorySeparatorChar)
    if ($folders.Count -gt $truncateFolders) {
        $truncatedPath = ".\" + ($folders[-$truncateFolders..-1] -join "\")
        return $truncatedPath
    } else {
        return $path
    }
}

# Function to show help
function Show-Help {
    Write-Host "`n`n`t`t`t📚 Help 📚" -ForegroundColor ($config.HelpTitleColor)
    Write-Host "  - Basic Commands:" -ForegroundColor ($config.HelpSubTitleColor)
    Write-Host "      ls/dir       - List files in the current directory." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "      pwd          - Show the current directory." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "      cd <path>    - Change to the specified directory." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "      mkdir <dir>  - Create a new directory." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "      exit         - Exit the terminal." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "  - AI Queries:" -ForegroundColor ($config.HelpSubTitleColor)
    Write-Host "      !<query>     - Make a query to the Gemini API." -ForegroundColor ($config.HelpCommandColor)
    Write-Host "  - Configuration:" -ForegroundColor ($config.HelpSubTitleColor)
    Write-Host "      Config.json  - Customize the terminal behavior." -ForegroundColor ($config.HelpCommandColor)
}

# get the last lines of the log file
function Get-Log {
    if ($config.Log -eq $false) {
        return $null
    }

    $log = Get-Content -Path $LogPath -Tail $config.AILogHistory
    return $log
}

# Function to call the Gemini API
function Call-GeminiAPI {
    param (
        [string]$prompt
    )

    # Full URL with endpoint and API key
    $FULL_URI = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$API_KEY"

    # Build the JSON body
    $JSON_BODY = @{
        system_instruction = @{
            parts = @{
                text = $config.InstructionAI + "This are the commands executed in the terminal: " + (Get-Log -join " ")
            }
        }
        contents = @(
            @{
                parts = @(
                    @{
                        text = $prompt
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    # Send the POST request
    try {
        $response = Invoke-RestMethod -Uri $FULL_URI `
            -Method Post `
            -ContentType "application/json" `
            -Body $JSON_BODY

        # Return the model's response
        return $response.candidates.content.parts.text
    } catch {
        Write-Host "Error calling the API:" -ForegroundColor ($config.ErrorColor)
        Write-Host $_.Exception.Message
        return $null
    }
}

function add-log {
    param (
        [string]$log
    )
    if ($config.Log -eq $true) {
        # Save the log
        Add-Content -Path $LogPath -Value $log
    }
}


# Load the configuration
$config = Load-Config

# Main function: Interactive terminal
function Run-Terminal {
    while ($true) {
        Write-Host "`n|  " -NoNewline -foregroundColor ($config.DecorationColor)

        # Get the truncated path according to the configuration
        if ($config.TruncatePathFolders -eq 0) {
            $currentPath = " 📂 "
        } else {
            $currentPath = Get-TruncatedPath -path (Get-Location).Path -truncateFolders $config.TruncatePathFolders
        }

        # Get the Battery Status
        $batteryStatus = Get-BatteryStatus

        # Show the battery status if available and if  showbattery is true
        if ($batteryStatus -and $config.ShowBattery -eq $true) {
            if ($batteryStatus -lt 20) {
                Write-Host "󰁻 $batteryStatus% " -ForegroundColor ($config.BatteryLowColor) -NoNewline
            } elseif ($batteryStatus -lt 50) {
                Write-Host "󰁾 $batteryStatus% " -ForegroundColor ($config.BatteryMidColor) -NoNewline
            } else {
                Write-Host "󰁹 $batteryStatus% " -ForegroundColor ($config.BatteryFullColor) -NoNewline
            }
        }

        # Show the UserName
        if ($config.ShowUserName -eq $true) {

            if ($config.Username -ne "") {
                Write-Host $config.Username  -NoNewline -ForegroundColor ($config.UserNameColor)
                Write-Host -NoNewline " "
            } else {
                Write-Host "$env:USERNAME " -NoNewline -ForegroundColor ($config.UserNameColor)
            }
        }

        # Show the current path
        if ($config.ShowPath -eq $true) {
            Write-Host "$currentPath" -NoNewline -ForegroundColor ($config.PathColor)
        }

        if ($config.NewLine -eq $true) {
            Write-Host "`n|" -foregroundColor ($config.DecorationColor)
            Write-Host "|" -NoNewline -foregroundColor ($config.DecorationColor)
        }

        Write-Host $config.separator -NoNewline -ForegroundColor ($config.SeparatorColor)
        $inputCommand =  Read-Host

        # Exit if the user types 'exit' or presses Ctrl+C
        if ($inputCommand -eq "exit") {
            Write-Host "👋 Exiting..."
            break
        }

        # Show help if the user types 'help'
        if ($inputCommand -eq "help") {
            Show-Help
            continue
        }

        # If the command starts with '!', activate the Gemini function
        if ($inputCommand.StartsWith("!")) {
            # Extract the text after '!'
            $prompt = $inputCommand.Substring(1).Trim()

            # Call the Gemini API
            $response = Call-GeminiAPI -prompt $prompt

            # Show the response
            if ($response) {
                Write-Host "`n`n🤖: " -ForegroundColor ($config.AITittle) -NoNewline    
                Write-Host $response -ForegroundColor ($config.AIContent)
                
                # Log the query and response
                $log = $prompt + " | " + $response
                # Save the log
                add-log -log $LogPath  
            }
        } else {
            # Execute other commands directly in the terminal
            try {
                # Execute the command
                Invoke-Expression $inputCommand

                # Log the command
                $log = (Get-Date).ToString() + " | " + $inputCommand

                # Save the log
                add-log -log $log
            } catch {
                Write-Host "❌ Error executing the command: " -ForegroundColor ($config.ErrorColor) -NoNewline
                Write-Host $inputCommand -ForegroundColor ($config.ErrorColor)

                # Log the error
                $errorLog = "ERROR: " + $inputCommand + " | " + $_.Exception.Message

                # Save the log
                add-log -log $errorLog

                Write-Host "`n" $_.Exception.Message
            }
        }
    }
}

# Start the terminal
if ($config.hint_enabled) {
    Write-Host "🚀 AI Terminal: Use '! <Question>' for queries" -ForegroundColor ($config.PathColor)
}
Run-Terminal