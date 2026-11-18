@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem =====================================================================
rem  Merge external JS files into the main HTML  (single-file output)
rem
rem  What it does:
rem   1. Finds the main HTML automatically - the .html file in this
rem      directory that contains a <script src=...image.js> reference.
rem   2. Replaces the two tags:
rem        <script src="./image.js"></script>
rem        <script src="./xlsx.full.min.js"></script>
rem      in place by inline <script> blocks holding the real JS code.
rem   3. The location is found by pattern matching, NOT by line number,
rem      so adding/removing/moving lines anywhere else in the HTML
rem      never breaks the merge (self-adaptive).
rem   4. Verifies: no external references to the two JS remain, and
rem      both JS contents are fully present in the result.
rem   5. Writes a NEW file (original .html / .js are never touched):
rem        - if the html file name contains the 3 Chinese chars
rem          "base-version" (ji-chu-ban), they are replaced by the
rem          3 Chinese chars "merged-version" (he-bing-ban);
rem        - otherwise "-merged-version" is appended to the name.
rem      Output is UTF-8 without BOM, CRLF line endings.
rem
rem  Usage: keep this .bat together with the .html and the two .js
rem  files in the same folder, then double-click it.
rem =====================================================================

echo.
echo === Merge external JS into HTML ===
echo.

where powershell >nul 2>nul
if errorlevel 1 (
    echo [ERROR] PowerShell not found. It is built into Windows 10/11.
    pause
    exit /b 1
)

if not exist "image.js" (
    echo [ERROR] image.js not found next to this script.
    pause
    exit /b 1
)

if not exist "xlsx.full.min.js" (
    echo [ERROR] xlsx.full.min.js not found next to this script.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $dir=(Get-Location).Path; $crlf=[string][char]13+[string][char]10; $lf=[string][char]10; function T([int[]]$c){ -join ($c | ForEach-Object { [char]$_ }) }; $M1=T 0x627E,0x5230,0x4E3B,0x6587,0x4EF6; $M2=T 0x5DF2,0x5185,0x8054; $M3=T 0x6821,0x9A8C,0x901A,0x8FC7; $M4=T 0x65E0,0x6B8B,0x7559,0x5916,0x90E8,0x5F15,0x7528; $M5='JS'+(T 0x5185,0x5BB9,0x5B8C,0x6574); $M6=T 0x5408,0x5E76,0x5B8C,0x6210; $M7=T 0x8F93,0x51FA; try { $htmlFile=$null; $htmlText=$null; foreach ($f in (Get-ChildItem -Path $dir -Filter *.html -File | Sort-Object Name)) { $t=[System.IO.File]::ReadAllText($f.FullName,[System.Text.Encoding]::UTF8); if ($t -match '<script\s+src=[^>]*image\.js') { $htmlFile=$f; $htmlText=$t; break } }; if (-not $htmlFile) { throw 'Main HTML not found: no .html file in this directory references external image.js.' }; Write-Host ('[1] '+$M1+': '+$htmlFile.Name); $utf8b=[System.Text.Encoding]::UTF8; $imgJs=[System.IO.File]::ReadAllText((Join-Path $dir 'image.js'),$utf8b); $xlsJs=[System.IO.File]::ReadAllText((Join-Path $dir 'xlsx.full.min.js'),$utf8b); function Norm($s){ $s=($s -replace [regex]::Escape($crlf),$lf); $s=($s -replace [regex]::Escape($lf),$crlf); return $s.Trim() }; $imgJs=Norm $imgJs; $xlsJs=Norm $xlsJs; $inlineImg='<script>'+$crlf+$imgJs+$crlf+'</script>'; $inlineXls='<script>'+$crlf+$xlsJs+$crlf+'</script>'; Write-Host ('[2] '+$M2+' image.js ('+[math]::Round($imgJs.Length/1KB,1)+' KB)'); Write-Host ('[2] '+$M2+' xlsx.full.min.js ('+[math]::Round($xlsJs.Length/1KB,1)+' KB)'); $m1=[regex]::Match($htmlText,'<script\s+src=[^>\r\n]*image\.js[^>\r\n]*>\s*</script>'); if (-not $m1.Success) { throw 'Reference tag for image.js not found in HTML.' }; $htmlText=$htmlText.Substring(0,$m1.Index)+$inlineImg+$htmlText.Substring($m1.Index+$m1.Length); $m2=[regex]::Match($htmlText,'<script\s+src=[^>\r\n]*xlsx\.full\.min\.js[^>\r\n]*>\s*</script>'); if (-not $m2.Success) { throw 'Reference tag for xlsx.full.min.js not found in HTML.' }; $htmlText=$htmlText.Substring(0,$m2.Index)+$inlineXls+$htmlText.Substring($m2.Index+$m2.Length); if ($htmlText -match '<script\s+src=[^>]*(image\.js|xlsx\.full\.min\.js)') { throw 'Verify failed: external reference still present.' }; if ($htmlText.IndexOf($imgJs) -lt 0) { throw 'Verify failed: image.js content missing from result.' }; if ($htmlText.IndexOf($xlsJs) -lt 0) { throw 'Verify failed: xlsx.full.min.js content missing from result.' }; Write-Host ('[3] '+$M3+' ('+$M4+', '+$M5+')'); $base=[System.IO.Path]::GetFileNameWithoutExtension($htmlFile.Name); $jcb=T 0x57FA,0x7840,0x7248; $hbb=T 0x5408,0x5E76,0x7248; if ($base.IndexOf($jcb) -ge 0) { $outBase=$base.Replace($jcb,$hbb) } else { $outBase=$base+'-'+$hbb }; $outPath=Join-Path $dir ($outBase+'.html'); $enc=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($outPath,$htmlText,$enc); $kb=[math]::Round(((Get-Item $outPath).Length/1KB),1); Write-Host ('[OK] '+$M6+', '+$M7+': '+$outPath+' ('+$kb+' KB)') } catch { Write-Host ('[PS-ERROR] '+$_.Exception.Message); exit 1 }"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
    echo [ERROR] Merge failed, exit code %RC%.
    pause
    exit /b 1
)

pause
endlocal
