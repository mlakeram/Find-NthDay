# Logic 
#   [x] Determine what day of the week the 1st day of the current month landed on
#   [x] Compute all occurrences of that day for a month with 31 days
#   [x] Allow the user to specify any day of the week as an input argument
#   [x] Determind the 1st occurrence of the user specified day
#   [x] Computer all occurrences of user specified day in a month with 31 days
#   [x] Store results in an array and output the dates using Write-Output (will allow the results to be piped into other commands)
#   [x] Only output one result if the user specifies which occurrence to return as an optional second argument  
#   
#
# Input
#   [ ] Enforce rules for input
#   [ ] Check for input errors 
#   [ ] consider enforcing mandatory input vs using default values
#   
#
# Output
#   [ ] 
#
# Bugs
#   [ ] Prevent adding the 5th occurrance date if it falls on the 31st of a month with only 30 days
#   [ ] Prevent adding of 0th date
# 


Param (
  [string]$targetDay = (Get-Date).DayOfWeek,
  [int]$occurrance
)

$daysOfTheWeek = @("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday") 
# $daysOfTheWeek = @("Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Monday") # scrambled version for logic testing

# Create array to store all occurrence dates
$allDatesOfTargetDay = @()

# Determind first occurrence of target day & add it to the array
$firstDayOfTheMonth = (Get-Date -Day 1).DayOfWeek
$firstDayOfTheMonthIndex = $daysOfTheWeek["$firstDayOfTheMonth"]
$targetDayIndex = $daysOfTheWeek.IndexOf("$targetDay")

if ($firstDayOfTheMonth -eq $targetDay) {
  $allDatesOfTargetDay += 1
} elseif ($firstDayOfTheMonthIndex -lt $targetDayIndex) {
  $allDatesOfTargetDay += $targetDayIndex - $firstDayOfTheMonthIndex
} else {
  $allDatesOfTargetDay += 7 - $firstDayOfTheMonthIndex + $targetDayIndex 
}


# Add following occurrences of target day to the array
while (31 -ge ($allDatesOfTargetDay[-1] + 7)) {
  $lastOccurrence = $allDatesOfTargetDay[-1]
  $allDatesOfTargetDay += $lastOccurrence + 7 # adds the occurrance date as an integer 
}


# Format and output result(s)
Write-Output $(
  if (-Not $occurrance) {
    $allDatesOfTargetDay | ForEach-Object {
      Write-Output ((Get-Date -Format "yyyy/MM") + "/$_")
    }
  } else {
    Write-Output ((Get-Date -Format "yyyy/MM") + '/' + $allDatesOfTargetDay[$occurrance - 1])
  }
)
