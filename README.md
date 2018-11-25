## Test-Jitter.ps1
* PowerShell based script that uses Test-Connection to determine your network jitter and packet loss to a destination address. 

## Task Scheduler Details (Recurring Mode)
* Action: Start a program
* Program/script: powershell.exe
* Add arguments (optional): -command "& 'C:\Path\To\Test-Jitter.ps1' -GenerateReport -ReportPath 'C:\Path\To\Export\Directory' -ReportName 'jitter_report.csv' -RecurringMode"

## Parameters
* ComputerName
** What computer name would you like to target? Default is Google DNS (8.8.8.8).
* 