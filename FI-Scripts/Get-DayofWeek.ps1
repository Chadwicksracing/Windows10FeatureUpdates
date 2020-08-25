$month = 8..12
$year = 2020
$startDay = "Monday"

foreach ($currentmonth in $month) {
    Write-Host $currentmonth
    1..[DateTime]::DaysInMonth($year,$currentmonth) | ForEach-Object { (Get-Date -Year $year -Month $currentmonth -Day $_ -Format "D") | Where-Object { $_ -match $StartDay } } 
}
