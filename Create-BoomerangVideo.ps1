$tempPath        = "$($env:TEMP)\$($MyInvocation.MyCommand.Name)"
$inputFile       = $($args[0] -replace '"','')
$inputFileObject = Get-Item $inputFile
$outputFile      = "$($inputFile | Split-Path)\$($inputFileObject.BaseName)-Boomerang$($inputFileObject.Extension)"

$ffmpegPath   = "D:\Nextcloud\Eigene Dateien\Programmieren & Basteln\FFmpeg & Skripte\FFQueue_1_7_58\ffmpeg.exe"
$avs = "LoadPlugin(""C:\Users\Mark\Desktop\MeGUI\tools\lsmash\x64\LSMASHSource.dll"")
        input=LSMASHVideoSource(""$inputFile"", track=0)
        input+input.reverse()"

function Run-Command ([String]$commandName, $argumentList, [String]$stdOutPath="$tempPath\exifPS-StdOut.txt", [Switch]$wait=$false)
    {
        $commandName = """$commandName"""
        Write-Host "$commandName $argumentList" -ForegroundColor Cyan
        New-Variable -Name process -Value $null -Scope Global -Force
        $global:process = Start-Process -FilePath "$commandName" `
                                 -ArgumentList $argumentList `
                                 -Wait:$wait `
                                 -PassThru `
                                 -RedirectStandardError $tempPath\exifPS-StdErr.txt `
                                 -RedirectStandardOutput $stdOutPath `
                                 -ErrorAction Stop `
                                 -WindowStyle Hidden

        if ($wait -eq $true)
            {
                if ($global:process.ExitCode -ne 0)
                    {
                        Write-Host "      The following error has occured:" -ForegroundColor Red
                        Get-Content $tempPath\exifPS-StdErr.txt -Encoding UTF8
                        Read-Host "Press any key to continue or STRG+C to stop"
                    }

                 Remove-Item $tempPath\exifPS-StdErr.txt -Force
            }
    }

if (-Not (Test-Path $tempPath))
    {
        New-Item $tempPath -ItemType Directory | Out-Null
    }

$avs | Out-File $tempPath\$($MyInvocation.ScriptName).avs -Encoding ascii

Run-Command -commandName $ffmpegPath `
            -argumentList @("-i",
                #"""$tempPath\$($MyInvocation.ScriptName).avs""",
                """$inputFile""",
                "-c:v",
                #"libx265", #HEVC
                "libsvtav1"
                #"-x265-params", #HEVC
                #"deblock=4,4", #HEVC
                "-crf",
                "35",
                #"-preset", #HEVC
                "-preset:v",
                #"slower", #HEVC
                "4",
                "-pix_fmt",
                "yuv420p10le",
                "-svtav1-params",
                "input-depth=10:keyint=10s",
                #"-map",
                #"0:v:0",
                "-filter_complex",
                """[0:v]reverse,fifo[r];[0:v][r] concat=n=2:v=1 [v]""",
                "-map",
                """[v]""",
                "-map_metadata",
                "0",
                """$outputFile"""
                ) `
            -wait


# Cleanup
Write-Host "Removing temp files..."
Remove-Item $tempPath -Recurse -Force
