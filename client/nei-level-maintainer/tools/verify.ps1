param(
    [Parameter(Mandatory=$true)][string]$Jar,
    [Parameter(Mandatory=$true)][string]$MinecraftSrgJar,
    [Parameter(Mandatory=$true)][string]$ForgeJar,
    [Parameter(Mandatory=$true)][string]$ModsDirectory,
    [Parameter(Mandatory=$true)][string]$LibrariesDirectory,
    [Parameter(Mandatory=$true)][string]$AsmJar,
    [Parameter(Mandatory=$true)][string]$JdkDirectory
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$build = Join-Path $project 'build/verify'
New-Item -ItemType Directory -Force $build | Out-Null
& (Join-Path $JdkDirectory 'bin/javac.exe') --release 8 -cp $AsmJar -d $build (Join-Path $PSScriptRoot 'VerifyJar.java')
if ($LASTEXITCODE -ne 0) { throw 'Verifier compilation failed' }
$arguments = @('-Xverify:all','-cp',"$AsmJar;$build",'VerifyJar',$Jar,$MinecraftSrgJar,$ForgeJar)
$arguments += @(Get-ChildItem $ModsDirectory -Filter '*.jar' | ForEach-Object FullName)
$arguments += @(Get-ChildItem $LibrariesDirectory -Recurse -Filter '*.jar' | ForEach-Object FullName)
$argsFile = Join-Path $build 'verify.args'
$escaped = $arguments | ForEach-Object { '"' + $_.Replace('\','/').Replace('"','\"') + '"' }
[IO.File]::WriteAllLines($argsFile,$escaped,[Text.UTF8Encoding]::new($false))
& (Join-Path $JdkDirectory 'bin/java.exe') "@$argsFile"
if ($LASTEXITCODE -ne 0) { throw 'Artifact verification failed' }
