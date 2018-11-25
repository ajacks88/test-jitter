## Test-Jitter.ps1
* PowerShell based script that uses Test-Connection to determine your network jitter (network latency variation) and packet loss to a destination address. 

## Task Scheduler Details (Recurring Mode)
* Action: Start a program
* Program/script: powershell.exe
* Add arguments (optional): -command "& 'C:\Path\To\Test-Jitter.ps1' -GenerateReport -ReportPath 'C:\Path\To\Export\Directory' -ReportName 'jitter_report.csv' -RecurringMode"

## Parameters
* ComputerName
    * What computer name would you like to target? Default is Google DNS (8.8.8.8).
* Count
    * How many time would you like to test the connection to the target? Default is 10.
* Passes
    * How many time would you like to run the whole test and average the results? Default is 3.
* GenerateReport
    * Set to $True if you want to generate a .csv report of the results. Default is false.
* ReportPath 
    * UNC destination for report. Default is current directory.
* ReportName
    * File name for the report. Default is jitter_report.csv
* RecurringMode
    * Recurring Mode will create a new directory within $ExportPath and seperate data into individual daily reports. Default is $False.