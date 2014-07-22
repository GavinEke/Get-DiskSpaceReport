PowerShell Disk Space Report
Twitter: @GavinEke
-----------------------------



About
-----------------------------
Script gets current HDD Space and stores that data in a flat file database. 
From this data it creates a graph and sends it to the email specified in the varible section.

The Script will need to be run about 10 times before you have data required to visualize the changes.
It is suggested to have the script setup as a weekly task automatically being run.

Sample Album of Charts - http://imgur.com/a/tTn22



Requierments
-----------------------------
This Script Requires Microsoft Chart Controls for Microsoft .NET Framework 3.5
http://www.microsoft.com/en-us/download/details.aspx?id=14422



Tested on
-----------------------------
Windows 7 using PowerShell 3.0



Example Usage
-----------------------------
.\Get-DiskSpaceReport.ps1 .\list.txt