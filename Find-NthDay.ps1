Param (
  [Parameter(Position = 0)]
  [ValidateRange(1, 5)]
  [int]$n,
  
  [Parameter(Position = 1)]
  $Day,
  
  [Parameter(Position = 2)]
  [ValidateRange(1, 12)]
  [int]$Month,
  
  [Parameter(Position = 3)]
  [ValidateRange(1, 9999)]
  [int]$Year,
  
  [datetime]$Validate
)

# UTILITY FUNCTIONS ------------------------------------------------------------ 

function Write-ErrorWithoutReference($errorMessage) {
  $errorRecord = [System.Management.Automation.ErrorRecord]::new(
    [Exception]::new($errorMessage),
    "CustomError",
    [System.Management.Automation.ErrorCategory]::NotSpecified,
    $null
  )

  return $errorRecord
}

function Get-ValidDayOfWeek {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    $Day
  )

  $validDaysOfWeek = @{
    Sunday    = (Get-Date -Day 7 -Month 1 -Year 2024).DayOfWeek
    Monday    = (Get-Date -Day 1 -Month 1 -Year 2024).DayOfWeek
    Tuesday   = (Get-Date -Day 2 -Month 1 -Year 2024).DayOfWeek
    Wednesday = (Get-Date -Day 3 -Month 1 -Year 2024).DayOfWeek
    Thursday  = (Get-Date -Day 4 -Month 1 -Year 2024).DayOfWeek
    Friday    = (Get-Date -Day 5 -Month 1 -Year 2024).DayOfWeek
    Saturday  = (Get-Date -Day 6 -Month 1 -Year 2024).DayOfWeek
  }

  $validatedDay = $validDaysOfWeek.GetEnumerator() | ForEach-Object {
    if ($_.Value -eq $Day) { return $_.Value }
  }

  if ($validDaysOfWeek.Keys -notcontains $validatedDay) {
    throw [System.ArgumentException]::new("Invalid -Day argument. `"$Day`" does not match any days of the week.")
  }
  
  Write-Verbose "Returning valid name for $Day"
  return $validatedDay
}


function Get-NumberSuffix {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [int]$number
  )

  $secondToLastDigit = ([Math]::Floor($number / 10)) % 10
  if (1 -eq $secondToLastDigit) { return "$($number)th" }

  $lastDigit = $number % 10

  switch ($lastDigit) {
    1 { if ($secondToLastDigit -ne 1) { return "$($number)st" } }
    2 { if ($secondToLastDigit -ne 1) { return "$($number)nd" } }
    3 { if ($secondToLastDigit -ne 1) { return "$($number)rd" } }
    default { return "$($number)th" }
  }
}

# Core Functions
function Find-FirstDayOfMonth {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [ValidateRange(1, 12)]
    [int]$Month,
    
    [Parameter(Position = 1, ValueFromPipeline)]
    [ValidateRange(1, 9999)]
    [int]$Year,

    [Parameter(ValueFromPipeline)]
    [datetime]$Date
  )

  if ($Date) {
    $Month = (Get-Date $Date).Month
    $Year = (Get-Date $Date).Year
  }
  if (-Not $Month) {
    $Month = (Get-Date).Month
    Write-Warning "No -Month provided. Using current month ($Month) as default."
  }
  If (-Not $Year) {
    $Year = (Get-Date).Year
    Write-Warning "No -Year provided. Using current year ($Year) as default."
  }

  $firstDay = (Get-Date -Year $Year -Month $Month -Day 1).Date
  Write-Verbose "Returning first day of $($firstDay.Date.ToString("MMMM")) $Year"
  return $firstDay
}

function Find-LastDayOfMonth {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [ValidateRange(1, 12)]
    [int]$Month,
    
    [Parameter(Position = 1, ValueFromPipeline)]
    [ValidateRange(1, 9999)]
    [int]$Year,

    [Parameter(ValueFromPipeline)]
    [datetime]$Date 
  )

  if ($Date) {
    $Month = (Get-Date $Date).Month
    $Year = (Get-Date $Date).Year
  }
  if (-Not $Month) {
    $Month = (Get-Date).Month
    Write-Warning "No -Month provided. Using current month ($Month) as default."
  }
  If (-Not $Year) {
    $Year = (Get-Date).Year
    Write-Warning "No -Year provided. Using current year ($Year) as default."
  }

  $firstDay = Find-FirstDayOfMonth -Month $Month -Year $Year
  $lastDay = $firstDay.Date.AddMonths(1).AddDays(-1)

  Write-Verbose "Returning last day of $($lastDay.Date.ToString("MMMM")) $Year"
  return $lastDay
}

# Core Functions
function Find-FirstOccurrenceDate {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    $Day,

    [Parameter(Position = 1, ValueFromPipeline)]
    [ValidateRange(1, 12)]
    [int]$Month,

    [Parameter(Position = 2, ValueFromPipeline)]
    [ValidateRange(1, 9999)]
    [int]$Year
  )

  if ($Day -or 0 -eq $Day) {
    try {
      $Day = (Get-ValidDayOfWeek -Day $Day)
    }
    catch [System.ArgumentException] {
      Write-ErrorWithoutReference "$($_.Exception.Message) `nTerminating process..."
      exit 1
    }
  }
  else {
    $Day = (Get-Date).DayOfWeek
    Write-Warning "No -Day provided. Using current day ($Day) as default."
  }

  if (-Not $Month) {
    $Month = (Get-Date).Month
    Write-Warning "No -Month provided. Using current month ($Month) as default."
  }
  If (-Not $Year) {
    $Year = (Get-Date).Year
    Write-Warning "No -Year provided. Using current year ($Year) as default."
  }

  $firstOccurrenceDate = (Find-FirstDayOfMonth -Year $Year -Month $Month).Date

  while (($firstOccurrenceDate).DayOfWeek -ne $Day) {
    $firstOccurrenceDate = ($firstOccurrenceDate).Date.AddDays(1)
  }

  Write-Verbose "Returning first occurrence of $Day in $($firstOccurrenceDate.Date.ToString("MMMM")) $Year"
  return ($firstOccurrenceDate).Date
}

function Find-FollowingOccurrenceDates {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [datetime]$Date 
  )

  if (-Not $Date) {
    Write-Warning "No -Date provided. Using current date as default."
    $Date = (Get-Date).Date
  }
  else {
    $Date = (Get-Date $Date).Date 
  }

  $occurrences = @($Date)
  $lastOccurrence = $occurrences[-1]
  $lastDayOfMonth = (Find-LastDayOfMonth -Date $Date).day

  while ($lastDayOfMonth -ge ($lastOccurrence.Day + 7)) {
    $occurrences += $lastOccurrence.Date.AddDays(7)
    $lastOccurrence = $occurrences[-1]
  }

  $Day = ($Date).DayOfWeek
  $Month = ($Date).ToString("MMMM")
  $Year = ($Date).Year

  Write-Verbose "Returning occurrences of $Day`s in $Month $Year beginning $Month $(Get-NumberSuffix $Date.Day)"
  return $occurrences
}


function Find-AllOccurrenceDates {
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    $Day,
    
    [Parameter(Position = 1, ValueFromPipeline)]
    [ValidateRange(1, 12)]
    [int]$Month,
    
    [Parameter(Position = 2, ValueFromPipeline)]
    [ValidateRange(1, 9999)]
    [int]$Year
  )

  if ($Day -or 0 -eq $Day) {
    try {
      $Day = (Get-ValidDayOfWeek -Day $Day)
    }
    catch [System.ArgumentException] {
      Write-ErrorWithoutReference "$($_.Exception.Message) `nTerminating process..."
      exit 1
    }
  }
  else {
    $Day = (Get-Date).DayOfWeek
    Write-Warning "No -Day provided. Using current day ($Day) as default."
  }

  if (-Not $Month) {
    $Month = (Get-Date).Month
    Write-Warning "No -Month provided. Using current month ($Month) as default."
  }
  If (-Not $Year) {
    $Year = (Get-Date).Year
    Write-Warning "No -Year provided. Using current year ($Year) as default."
  }

  $firstOccurrance = Find-FirstOccurrenceDate -Day $Day -Month $Month -Year $Year
  $allOccurrences = $firstOccurrance.Date | Find-FollowingOccurrenceDates

  Write-Verbose "Returning all occurrence of $Day in $((Get-Date -Month $Month).Date.ToString("MMMM")) $Year"
  return $allOccurrences
}

function Find-NthOccurrenceDate {
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline)]
    [ValidateRange(1, 5)]
    [int]$n,
    
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline)]
    $Day,
    
    [Parameter(Mandatory = $True, Position = 2, ValueFromPipeline)]
    [ValidateRange(1, 12)]
    [int]$Month,
    
    [Parameter(Mandatory = $True, Position = 3, ValueFromPipeline)]
    [ValidateRange(1, 9999)]
    [int]$Year
  )

  try {
    $Day = (Get-ValidDayOfWeek -Day $Day)
  }
  catch [System.ArgumentException] {
    Write-ErrorWithoutReference "$($_.Exception.Message) `nTerminating process..."
    exit 1
  }
  
  try {
    $allOccurrences = (Find-AllOccurrenceDates -Day $Day -Month $Month -Year $Year)

    if ($n -gt $allOccurrences.Length) {
      $dayOfWeek = $allOccurrences[0].Date.DayOfWeek
      $total = $allOccurrences.Length
      $monthName = $allOccurrences[0].ToString("MMMM")
      $yearNum = $allOccurrences[0].Year
      $occurrencesString = (($allOccurrences -join '').Trim() -replace "12:00:00", " " -replace "AM", " ")
      
      throw [System.ArgumentException]::new("Invalid argument. There are only $($total) occurrences of $($dayOfWeek) in $monthName $yearNum : 
      $($occurrencesString)")
    }
  }
  catch [System.ArgumentException] {    
    Write-ErrorWithoutReference "$($_.Exception.Message) `n`nTerminating process..."
    exit 1
  }
  catch {
    Write-Error "$($_.Exception.Message) `n`nTerminating process..."
    exit 1
  }

  return $allOccurrences[$n - 1]
}

function Confirm-DateOccurrence {
  param(
    [Parameter(Position = 0)]
    [ValidateRange(1, 5)]
    [int]$n,
    
    [Parameter(Position = 1)]
    $Day,
    
    [Parameter(Position = 2)]
    [ValidateRange(1, 12)]
    [int]$Month,
    
    [Parameter(Position = 3)]
    [ValidateRange(1, 9999)]
    [int]$Year,
    
    [datetime]$Validate
  )

  if ($Day -or 0 -eq $Day) {
    try {
      $Day = Get-ValidDayOfWeek -Day $Day
    }
    catch [System.ArgumentException] {
      Write-ErrorWithoutReference "$($_.Exception.Message) `nTerminating process..."
      exit 1
    }
  }
  else {
    $Day = (Get-Date).DayOfWeek
    Write-Warning "No -Day provided. Using current day ($($Day)) as default."
  }

  if ($n) {
    $nthOccurrence = Find-NthOccurrenceDate -n $n -Day $Day -Month $Month -Year $Year
    return ($nthOccurrence.Date -eq $Validate.Date)
  }
  else {
    $allOccurrences = Find-AllOccurrenceDates -Day $Day -Month $Month -Year $Year
    return ($allOccurrences -contains $Validate)
  }
}



# Script logic

if ($Day -or 0 -eq $Day) {
  try {
    $Day = Get-ValidDayOfWeek -Day $Day
  }
  catch [System.ArgumentException] {
    Write-ErrorWithoutReference "$($_.Exception.Message) `nTerminating process..."
    exit 1
  }
}
else {
  $Day = (Get-Date).DayOfWeek
  Write-Warning "No -Day provided. Using current day ($($Day)) as default."
}

if (-Not $Month) {
  $Month = (Get-Date).Month
  Write-Warning "No -Month provided. Using current month ($Month) as default."
}
If (-Not $Year) {
  $Year = (Get-Date).Year
  Write-Warning "No -Year provided. Using current year ($Year) as default."
}

if (-Not $n -and -Not $Validate) {
  Write-Warning "No -n value provided. Finding all occurrences..."
  Write-Output "All $($Day)s in $((Get-Date -Month $Month).ToString("MMMM")) $Year`:"
  return Find-AllOccurrenceDates -Day $Day -Month $Month -Year $Year
}
elseif ($n -and -Not $Validate) {
  Write-Output "$(Get-NumberSuffix $n) $Day in $((Get-Date -Month $Month).ToString("MMMM")) $Year`:"
  return  Find-NthOccurrenceDate -n $n -Day $Day -Month $Month -Year $Year
}
elseif ($Validate) {
  $confirmationDate = $(Get-Date $Validate).ToString().Split(' ')[0]

  if ($n) {
    Write-Output "Checking if $confirmationDate fall on the $(Get-NumberSuffix $n) $Day in $((Get-Date -Month $Month).ToString("MMMM")) $Year"
  }
  else {
    Write-Warning "No -n value provided. `nChecking if $confirmationDate fall on ANY $Day in $((Get-Date -Month $Month).ToString("MMMM")) $Year"
  }
  return Confirm-DateOccurrence -n $n -Day $Day -Month $Month -Year $Year -Validate $Validate
}
