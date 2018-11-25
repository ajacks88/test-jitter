<#
.SYNOPSIS
    Tests for jitter (network latency variation) against remote computer.

.DESCRIPTION
    The Test-Jitter cmdlet tests for jitter against one or more specified computers. 

.EXAMPLE
    Test-Jitter -GenerateReport $True -ReportName 'test_jitter.csv'
    This example will run Test-Jitter and generate a report in the current directory of the results named 'test_jitter.csv'.

.EXAMPLE
    Test-Jitter -Count '25' -Passes '10'
    This example will run Test-Jitter running each test 25 times, then running the entire test 10 times and average the results.

.PARAMETER ComputerName
    The computer name, or ip address, for the computer you want to test for jitter against.

.PARAMETER Count
    The number of times you want to test the connection to the target.

.PARAMETER Passes
    The number of times you want to run the whole test and average the results.

.PARAMETER GenerateReport
    Whether or not you want to generate a .csv jitter report of the results.

.PARAMETER ExportPath
    The UNC path to the report export destination. 

.PARAMETER ReportName
    The file name to use for the jitter report. default is jitter_report.csv

.PARAMETER RecurringMode
    Recurring Mode will create a new directory within $ExportPath and seperate data into individual daily reports.
#>
Param
(
    [Parameter(
        Mandatory=$False,
        HelpMessage='What computer name would you like to target? Default is Google DNS (8.8.8.8).'
    )]
    [string]$ComputerName = '8.8.8.8',

    [Parameter(
        Mandatory=$False,
        HelpMessage='How many time would you like to test the connection to the target? Default is 10.'
    )]
    [int]$Count = '10',

    [Parameter(
        Mandatory=$False,
        HelpMessage='How many time would you like to run the whole test and average the results? Default is 3.'
    )]
    [int]$Passes = '3',

    [Parameter(
        ParameterSetName='GenerateReport',
        Mandatory=$False,
        HelpMessage='Set to $True if you want to generate a .csv report of the results. Default is false.'
    )]
    [switch]$GenerateReport,

    [Parameter(
        ParameterSetName='GenerateReport',
        Mandatory=$False,
        HelpMessage='UNC destination for report. Default is current directory.'
    )]
    [string]$ReportPath = (Get-Location),

    [Parameter(
        ParameterSetName='GenerateReport',
        Mandatory=$False,
        HelpMessage='File name for the report. Default is jitter_report.csv'
    )]
    [string]$ReportName = 'jitter_report.csv',

    [Parameter(
        ParameterSetName='GenerateReport',
        Mandatory=$False,
        HelpMessage='Recurring Mode will create a new directory within $ExportPath and seperate data into individual daily reports. Default is $False.'
    )]
    [switch]$RecurringMode
)

Begin
{
    Function Find-Difference
    {
        Param
        (
            [int]$ReferenceInt,
            [int]$DifferenceInt
        )

        If (($ReferenceInt -eq $Null) -or ($DifferenceInt -eq $Null))
        {
            Write-Error -Message 'Either $ReferenceInt or $DifferenceInt -eq $Null' -Category 'Find-Difference'
            Break
        }

        If ($ReferenceInt -gt $DifferenceInt)
        {
            $Difference = $ReferenceInt - $DifferenceInt
            Write-Verbose -Message ('$Difference = ' + $Difference)
            $Difference
        }

        Else
        {
            $Difference = $DifferenceInt - $ReferenceInt
            Write-Verbose -Message ('$Difference = ' + $Difference)
            $Difference
        }
    }

    Function Test-Jitter
    {
        Param
        (
            [string]$ComputerName,
            [int]$Count
        )

        $Results = New-Object -TypeName System.Object
        [int]$DiffTotal = '0'

        Write-Verbose -Message ("Running 'Test-Connection -ComputerName $Computername -Count $Count'")
        $Test = Test-Connection -ComputerName $ComputerName -Count $Count

        Write-Verbose -Message ('$PacketLoss = 100 - ((' + $Test.ResponseTime.Count + ' / ' + $Count + ') * 100)')
        $PacketLoss = 100 - (($Test.ResponseTime.Count / $Count) * 100)

        Write-Verbose -Message ("Looping through ResponseTimes")
        $i = 0
        While ($i -lt ($Test.ResponseTime.Count))
        {
            Write-Verbose -Message ('Finding difference between ' + $Test[$i].ResponseTime + ' and ' + $Test[($i+1)].ResponseTime)
            $Difference = Find-Difference -ReferenceInt $Test[$i].ResponseTime -DifferenceInt $Test[($i+1)].ResponseTime
            Write-Verbose -Message ("Adding $Difference to " + '$DiffTotal ' + "($DiffTotal)")
            $DiffTotal += $Difference
            Write-Verbose -Message ('$DiffTotal = ' + $DiffTotal)
            $i++
        }

        Write-Verbose ('Calculating Jitter (' + $DiffTotal + ' / ' + $Test.ResponseTime.Count + ')')
        [int]$Jitter = $DiffTotal / $Test.ResponseTime.Count
        Write-Verbose ('$Jitter = ' + $Jitter + ', rounding $Jitter')
        [int]$Jitter = [math]::Round($Jitter, [System.MidpointRounding]::AwayFromZero)
        Write-Verbose -Message ('$Jitter = ' + $Jitter)

        Write-Verbose -Message ('Adding jitter(ms) to $Results ' + "($Jitter)")
        $Results | Add-Member -MemberType NoteProperty -Name 'jitter(ms)' -Value $Jitter
        Write-Verbose -Message ('Adding packetloss(%) to $Results ' + "($PacketLoss)")
        $Results | Add-Member -MemberType NoteProperty -Name 'packetloss(%)' -Value $PacketLoss

        Write-Verbose -Message 'Returning Results'
        Return $Results
    }

    Function Export-JitterReport
    {
        Param
        (
            [string]$ReportPath,
            [string]$ReportName,
            [string]$ComputerName,
            $ExportObject
        )

        If ($RecurringMode)
        {
            Write-Verbose -Message ('$RecurringMode = $True')
            $FolderName = 'Recurring_Jitter_Report'
            Write-Verbose -Message ('$FolderName = ' + $FolderName)
            $ReportName = ($Date + '.csv')
            Write-Verbose -Message ('$ReportName = ' + $ReportName)
            $ExportPath = ($ReportPath + '\' + $FolderName + '\' + $ReportName)
            Write-Verbose -Message ('$ExportPath = ' + $ExportPath)
            If (!(Test-Path -Path ($ReportPath + '\' + $FolderName) -ErrorAction SilentlyContinue))
            {
                Write-Verbose -Message ('Creating folder named ' + $FolderName + 'here: ' + $ReportPath)
                $CreateFolder = New-Item -Path $ReportPath -Name $FolderName -ItemType 'Directory' -ErrorAction SilentlyContinue
            }
            Write-Verbose -Message ('Exporting report')
            $ExportCSV = Export-Csv -InputObject $ExportObject -Path $ExportPath -Append -NoTypeInformation
        }
        Else
        {
            Write-Verbose -Message ('$RecurringMode = $True')
            $ExportPath = ($ReportPath + '\' + $ReportName)
            Write-Verbose -Message ('$ExportPath = ' + $ExportPath)
            Write-Verbose -Message ('Building $ExportObject')
            $ExportCSV = Export-Csv -InputObject $ExportObject -Path $ExportPath -Append -NoTypeInformation
            Write-Verbose -Message ('Exporting report')
        }
    }
}

Process
{
    [int]$TotalJitter = '0'
    [int]$TotalPacketLoss = '0'
    [int]$i = '0'
    Write-Verbose -Message ('$Passes = ' + $Passes)

    While ($i -lt $Passes)
    {
        Write-Verbose -Message ('Starting pass # ' + $i)
        Write-Verbose -Message ('Testing for jitter against ' + $ComputerName + ' $Count = ' + $Count)
        $JitterTest = Test-Jitter -ComputerName $ComputerName -Count $Count

        Write-Verbose -Message ('Adding ' + $JitterTest.'jitter(ms)' + ' to $TotalJitter ' + "($TotalJitter)")
        $TotalJitter += $JitterTest.'jitter(ms)'
        Write-Verbose -Message ('Adding ' + $JitterTest.'packetloss(%)' + ' to $TotalPacketLoss ' + "($TotalPacketLoss)")
        $TotalPacketLoss += $JitterTest.'packetloss(%)'

        $i++
    }

    Write-Verbose -Message ('Calculating final jitter (' + $TotalJitter + ' / ' + $Passes + ')')
    $Jitter = ($TotalJitter / $Passes)
    Write-Verbose -Message ('Raw final jitter = ' + $Jitter + ', rounding jitter')
    $Jitter = [math]::Round($Jitter, [System.MidpointRounding]::AwayFromZero)
    Write-Verbose -Message ('Final jitter = ' + $Jitter)

    Write-Verbose -Message ('Calculating final packet loss (' + $TotalPacketLoss + ' / ' + $Passes + ')')
    $PacketLoss = ($TotalPacketLoss / $Passes)
    Write-Verbose -Message ('Final packet loss = ' + $PacketLoss)

    Write-Verbose -Message ('Building $Results')
    $Results = New-Object System.Object
    $Date = Get-Date -Format yyyy-MM-dd
    Write-Verbose -Message ('$Date = ' + $Date)
    $Time = Get-Date -Format 'hh:mm:ss tt'
    Write-Verbose -Message ('$Time = ' + $Time)

    If (!($RecurringMode))
    {
        $Results | Add-Member -MemberType NoteProperty -Name 'Date' -Value $Date
    }

    $Results | Add-Member -MemberType NoteProperty -Name 'Time' -Value $Time
    $Results | Add-Member -MemberType NoteProperty -Name 'Target' -Value $ComputerName
    $Results | Add-Member -MemberType NoteProperty -Name 'Jitter(ms)' -Value $Jitter
    $Results | Add-Member -MemberType NoteProperty -Name 'PacketLoss(%)' -Value $PacketLoss

    If ($GenerateReport)
    {
        Write-Verbose -Message ('Generating report')
        $ExportReport = Export-JitterReport -ReportPath $ReportPath -ReportName $ReportName -ComputerName $ComputerName -ExportObject $Results
    }
    Else
    {
        Write-Verbose -Message ('Printing results')
        $Results
    }
}