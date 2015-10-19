# PowerShell Disk Space Report
# Twitter: @GavinEke
#
# Requires Microsoft Chart Controls for Microsoft .NET Framework 3.5 (http://www.microsoft.com/en-us/download/details.aspx?id=14422)
# Tested on Windows 7 using PowerShell 3.0
# Example usage: .\Get-DiskSpaceReport.ps1 .\list.txt

#region Varibles
# You should change the variables in this region to suit your environment
$users = "test@example.com" # List of users to email your report to (separate by comma)
$fromemail = "test@example.com" # Enter the email you would like the report sent from
$server = "mail.example.com" # Enter your own SMTP server DNS name / IP address here
$driveletter = "C" # Enter the drive letter you would like to record
$DBSize = 10 # Enter the number of records you would like to keep
#endregion

##############################################
#   DO NOT CHANGE ANYTHING PAST THIS LINE!   #
##############################################

# Test to make sure there is only 1 argument
if(!($($args.Count) -eq 1)){
	Write-Host " "
	Write-Host "The Script requires 1 argument only, please check example usage and try again"
	Write-Host " "
	Write-Host "Press any key to exit ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

# Test if list exists and print error and exit if it does not
if(!(Test-Path -Path $args[0])){
	Write-Host " "
	Write-Host "Error - The following path was not found: $args"
	Write-Host " "
	Write-Host "Press any key to exit ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit
}

# Variables
$list = $args[0] # This accepts the argument you add to your scheduled task for the list of servers. i.e. list.txt
$computers = get-content $list #grab the names of the servers/computers to check from the list.txt file.
$ListOfAttachments = @()

# Create-PieChart Function by Sean Duffy (@shogan85)
# Requires Microsoft Chart Controls for Microsoft .NET Framework 3.5
# http://www.microsoft.com/en-us/download/details.aspx?id=14422
Function Create-PieChart(){
	param([string]$FileName)
	
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
	
	#Create our chart object 
	$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
	$Chart.Width = 550
	$Chart.Height = 400 
	$Chart.Left = 10
	$Chart.Top = 10
	
	#Create a chartarea to draw on and add this to the chart 
	$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$Chart.ChartAreas.Add($ChartArea) 
	[void]$Chart.Series.Add("Data") 
	
	#Add a datapoint for each value specified in the arguments (args) 
	foreach ($value in $args[0]){
		Write-Host "Now processing chart value: " + $value
		$datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $value)
		$datapoint.AxisLabel = "Value" + "(" + $value + " GB)"
		$Chart.Series["Data"].Points.Add($datapoint)
	}
	
	$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
	$Chart.Series["Data"]["PieLabelStyle"] = "Outside" 
	$Chart.Series["Data"]["PieLineColor"] = "Black" 
	$Chart.Series["Data"]["PieDrawingStyle"] = "Concave" 
	($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
	
	#Set the title of the Chart to the current date and time 
	$Title = new-object System.Windows.Forms.DataVisualization.Charting.Title 
	$Chart.Titles.Add($Title) 
	$Chart.Titles[0].Text = "HDD Space Remaining"
	
	#Save the chart to a file
	$Chart.SaveImage($FileName + ".png","png")
}

# Assemble the HTML Header and CSS for our Report
$HTMLHeader = @"
<!DOCTYPE html>
<html>
<head>
<title>PowerShell HDD Usage Line Chart</title>
<style>
	body{
		font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
	}
	
	#report{
		width: 600px;
	}
	
	h3{
		clear: both;
		font-size: 115%;
		margin-left: 20px;
		margin-top: 30px;
	}
</style>
</head>
<body>

"@

# Run this for each computer in the list
foreach ($computer in $computers){
	if(!(Test-Path -Path .\$computer-$driveletter.txt)){
		New-Item -ItemType file -Path .\$computer-$driveletter.txt
	}
	
	# Get the number of lines in the file
	$txtLineCount = Get-Content .\$computer-$driveletter.txt | Measure-Object -Line
	$txtLineCount = $txtLineCount.Lines
	
	# Delete first line of text file
	if($txtLineCount -gt $DBSize){
		Get-Content ".\$computer-$driveletter.txt" | Select-Object -Skip 1 | Set-Content ".\temp.txt"
		Move ".\temp.txt" ".\$computer-$driveletter.txt" -Force
	}
	
	# Get HDD free space and save it to a flat file database
	$DiskInfo = Get-WMIObject -ComputerName $computer Win32_LogicalDisk -filter "DeviceID='C:'" | Where-Object{$_.DriveType -eq 3} | Select-Object $_.freespace
	$DiskInfo = $DiskInfo.FreeSpace/1GB
	$DiskInfo = [Math]::Round($DiskInfo, 2)
	Write-Host $DiskInfo
	Add-Content .\$computer-$driveletter.txt "$DiskInfo"
	$GetHDDSpace = Get-Content .\$computer-$driveletter.txt
	
	# Create the chart using our Chart Function
	Create-PieChart -FileName ((Get-Location).Path + "\$computer-$driveletter") $GetHDDSpace
	$ListOfAttachments += "$computer-$driveletter.png"
	
	# Create HTML Report for the current System being looped through
	$CurrentSystemHTML = @"
	<div id="report">
	<p><h3>$computer $driveletter HDD Space</p></h3>
	<img src="$computer-$driveletter.png" alt="$computer Chart">
	<hr noshade size=3 width="100%">
	</div>
	
"@

	# Add the current System HTML Report into the final HTML Report body
	$HTMLMiddle += $CurrentSystemHTML
	
}
  
# Assemble the closing HTML for our report.
$HTMLEnd = @"
</body>
</html>
"@

# Assemble the final report from all our HTML sections
$HTMLMessage = $HTMLHeader + $HTMLMiddle + $HTMLEnd

# Save the report out to a file in the current path
$HTMLMessage | Out-File ((Get-Location).Path + "\HDDSpaceReport.html")

# Email our report out
Send-MailMessage -from $fromemail -to $users -subject "$driveletter Drive Line Chart" -Attachments $ListOfAttachments -BodyAsHTML -body $HTMLMessage -priority Normal -smtpServer $server