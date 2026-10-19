param(
    [Parameter(Mandatory=$true)][string]$MinecraftSrgJar,
    [Parameter(Mandatory=$true)][string]$ForgeJar,
    [Parameter(Mandatory=$true)][string]$ModsDirectory,
    [Parameter(Mandatory=$true)][string]$LibrariesDirectory,
    [Parameter(Mandatory=$true)][string]$JdkDirectory,
    [string]$OutputDirectory = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$classes = Join-Path $project 'build/classes'
New-Item -ItemType Directory -Force $classes,$OutputDirectory | Out-Null
$nei = Join-Path $ModsDirectory 'NotEnoughItems-2.8.155-GTNH.jar'
$oc = Join-Path $ModsDirectory 'OpenComputers-1.12.64-GTNH.jar'
foreach ($inputJar in @($MinecraftSrgJar,$ForgeJar,$nei,$oc)) {
    if (!(Test-Path -LiteralPath $inputJar)) { throw "Missing build input: $inputJar" }
}
$libs = @(Get-ChildItem -LiteralPath $LibrariesDirectory -Recurse -Filter '*.jar' | ForEach-Object FullName)
$classpath = (@($MinecraftSrgJar,$ForgeJar,$nei,$oc) + $libs) -join ';'
$javac = Join-Path $JdkDirectory 'bin/javac.exe'
$java = Join-Path $JdkDirectory 'bin/java.exe'
$jar = Join-Path $JdkDirectory 'bin/jar.exe'
$sources = @(Get-ChildItem (Join-Path $project 'src/main/java') -Recurse -Filter '*.java' | ForEach-Object FullName)
# Compile directly against production SRG Minecraft names. No MCP->SRG remapping
# is needed, and a dev-names JAR cannot accidentally be shipped.
$argsFile = Join-Path $project 'build/javac.args'
$compilerArgs = @('--release','8','-encoding','UTF-8','-proc:none','-cp',$classpath,'-d',$classes) + $sources
$escapedArgs = $compilerArgs | ForEach-Object { '"' + $_.Replace('\','/').Replace('"','\"') + '"' }
[IO.File]::WriteAllLines($argsFile, $escapedArgs, [Text.UTF8Encoding]::new($false))
& $javac "@$argsFile"
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed' }
$tests = Join-Path $project 'build/tests'
$testSources = @(Get-ChildItem (Join-Path $project 'tests') -Filter '*.java' | ForEach-Object FullName)
$testArgs = @('--release','8','-encoding','UTF-8','-cp',"$classes;$classpath",'-d',$tests) + $testSources
$testArgsFile = Join-Path $project 'build/test-javac.args'
[IO.File]::WriteAllLines($testArgsFile, @($testArgs | ForEach-Object { '"' + $_.Replace('\','/') + '"' }), [Text.UTF8Encoding]::new($false))
& $javac "@$testArgsFile"
if ($LASTEXITCODE -ne 0) { throw 'Test compilation failed' }
& $java -cp "$classes;$tests" dev.dronf.neilevel.BridgeCommandTest
if ($LASTEXITCODE -ne 0) { throw 'Protocol tests failed' }
& $java -cp "$classes;$tests" dev.dronf.neilevel.ScreenReplyTest
if ($LASTEXITCODE -ne 0) { throw 'Screen reply tests failed' }
$inputArgsFile=Join-Path $project 'build/input-test.args'
$inputArgs=@('-cp',"$classes;$tests;$classpath",'dev.dronf.neilevel.FieldFocusTest')
[IO.File]::WriteAllLines($inputArgsFile,@($inputArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
& $java "@$inputArgsFile"
if ($LASTEXITCODE -ne 0) { throw 'Real Minecraft text-field input tests failed' }
$outputJar = Join-Path $OutputDirectory 'nei-level-maintainer-1.1.1.jar'
& $jar "-J-Djava.io.tmpdir=$project/build" cf $outputJar -C $classes dev -C (Join-Path $project 'src/main/resources') mcmod.info
if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
Get-FileHash -Algorithm SHA256 -LiteralPath $outputJar
Write-Output "Built $outputJar"
