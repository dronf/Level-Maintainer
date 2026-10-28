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
$editorArgsFile=Join-Path $project 'build/editor-test.args'
$editorLibs=@($libs | Where-Object {$_ -notmatch '\\org\\lwjgl\\' -or $_ -match '\\2\.9\.4'})
$editorClasspath=(@($classes,$tests,$MinecraftSrgJar,$ForgeJar,$nei,$oc)+$editorLibs)-join ';'
$nativeDir=Join-Path $project 'build/natives'
New-Item -ItemType Directory -Force $nativeDir | Out-Null
$nativeJar=$libs | Where-Object {$_ -match 'lwjgl-platform.*2\.9\.4.*natives-windows'} | Select-Object -First 1
if (!$nativeJar) {throw 'Minecraft LWJGL 2 Windows natives required for the editor regression test'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($nativeJar)
try {foreach($entry in $zip.Entries){if($entry.Name -match '^lwjgl(64)?\.dll$'){[IO.Compression.ZipFileExtensions]::ExtractToFile($entry,(Join-Path $nativeDir $entry.Name),$true)}}} finally {$zip.Dispose()}
$editorArgs=@("-Dorg.lwjgl.librarypath=$nativeDir",'-cp',$editorClasspath,'dev.dronf.neilevel.EditorInputTest',(Join-Path $project 'build'))
[IO.File]::WriteAllLines($editorArgsFile,@($editorArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
& $java "@$editorArgsFile"
if ($LASTEXITCODE -ne 0) { throw 'Real editor input / button rendering tests failed' }
# Repeat the editor checks with the actual installed lwjgl3ify shared buffer.
$lwjgl3ify=Join-Path $ModsDirectory 'lwjgl3ify-3.0.37.jar'
if(Test-Path -LiteralPath $lwjgl3ify) {
    $compatArgs=@("-Dorg.lwjgl.librarypath=$nativeDir",'-cp',"$editorClasspath;$lwjgl3ify",'dev.dronf.neilevel.EditorInputTest',(Join-Path $project 'build'),'lwjgl3ify')
    $compatFile=Join-Path $project 'build/compat-test.args'
    [IO.File]::WriteAllLines($compatFile,@($compatArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
    & $java "@$compatFile"
    if ($LASTEXITCODE -ne 0) {throw 'Installed lwjgl3ify buffer isolation checks failed'}
    $sharedArgs=@('-cp',"$editorClasspath;$lwjgl3ify",'dev.dronf.neilevel.SharedBufferTest')
    $sharedFile=Join-Path $project 'build/shared-buffer-test.args'
    [IO.File]::WriteAllLines($sharedFile,@($sharedArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
    & $java "@$sharedFile"
    if ($LASTEXITCODE -ne 0) {throw 'Installed lwjgl3ify buffer leak regression failed'}
}
$pauseArgs=@("-Dorg.lwjgl.librarypath=$nativeDir",'-cp',$editorClasspath,'dev.dronf.neilevel.ManagerPauseTest',(Join-Path $project 'build'))
$pauseFile=Join-Path $project 'build/pause-test.args'
[IO.File]::WriteAllLines($pauseFile,@($pauseArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
& $java "@$pauseFile"
if ($LASTEXITCODE -ne 0) {throw 'Manager pause/resume checks failed'}
$syncArgs=@("-Dorg.lwjgl.librarypath=$nativeDir",'-cp',$editorClasspath,'dev.dronf.neilevel.ManagerSyncTest',(Join-Path $project 'build'))
$syncFile=Join-Path $project 'build/sync-test.args'
[IO.File]::WriteAllLines($syncFile,@($syncArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
& $java "@$syncFile"
if ($LASTEXITCODE -ne 0) {throw 'Manager batched sync checks failed'}
$hotkeyArgs=@("-Dorg.lwjgl.librarypath=$nativeDir",'-cp',$editorClasspath,'dev.dronf.neilevel.HotkeyTest')
$hotkeyFile=Join-Path $project 'build/hotkey-test.args'
[IO.File]::WriteAllLines($hotkeyFile,@($hotkeyArgs | ForEach-Object {'"'+$_.Replace('\','/')+'"'}),[Text.UTF8Encoding]::new($false))
& $java "@$hotkeyFile"
if ($LASTEXITCODE -ne 0) {throw 'Gameplay and NEI hotkey lifecycle checks failed'}
$outputJar = Join-Path $OutputDirectory 'nei-level-maintainer-1.4.0.jar'
& $jar "-J-Djava.io.tmpdir=$project/build" cf $outputJar -C $classes dev -C (Join-Path $project 'src/main/resources') mcmod.info
if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
Get-FileHash -Algorithm SHA256 -LiteralPath $outputJar
Write-Output "Built $outputJar"
