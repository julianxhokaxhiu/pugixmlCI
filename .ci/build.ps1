$env:_RELEASE_PATH = ".dist\build\x86-${env:_RELEASE_CONFIGURATION}"
if ($env:_BUILD_BRANCH -eq "refs/heads/master" -Or $env:_BUILD_BRANCH -eq "refs/tags/canary") {
  $env:_IS_BUILD_CANARY = "true"
}
elseif ($env:_BUILD_BRANCH -like "refs/tags/*") {
  $env:_BUILD_VERSION = $env:_BUILD_VERSION.Substring(0,$env:_BUILD_VERSION.LastIndexOf('.')) + ".0"
}
$env:_RELEASE_VERSION = "v${env:_BUILD_VERSION}"

Write-Output "--------------------------------------------------"
Write-Output "BUILD CONFIGURATION: $env:_RELEASE_CONFIGURATION"
Write-Output "RELEASE VERSION: $env:_RELEASE_VERSION"
Write-Output "--------------------------------------------------"

Write-Host "##vso[task.setvariable variable=_BUILD_VERSION;]${env:_BUILD_VERSION}"
Write-Host "##vso[task.setvariable variable=_RELEASE_VERSION;]${env:_RELEASE_VERSION}"
Write-Host "##vso[task.setvariable variable=_IS_BUILD_CANARY;]${env:_IS_BUILD_CANARY}"

Set-Location ${env:buildPath}\pugixml

git apply ${env:buildPath}\pugixmlCI\CMakeLists.patch

mkdir $env:_RELEASE_PATH | Out-Null
cmake -G "Visual Studio 16 2019" -A Win32 -DCMAKE_MSVC_RUNTIME_LIBRARY="$env:_MSVC_RUNTIME" -S . -B $env:_RELEASE_PATH
cmake --build $env:_RELEASE_PATH --config $env:_RELEASE_CONFIGURATION

mkdir ${env:buildPath}\.install\lib | Out-Null
mkdir ${env:buildPath}\.install\include | Out-Null
Move-Item $env:_RELEASE_PATH\${env:_RELEASE_CONFIGURATION}\pugixml.lib ${env:buildPath}\.install\lib
Move-Item src\pugixml.hpp ${env:buildPath}\.install\include
Move-Item src\pugiconfig.hpp ${env:buildPath}\.install\include

mkdir "${env:buildPath}\.dist" | Out-Null
Compress-Archive -Path ${env:buildPath}\.install\* -DestinationPath "${env:buildPath}\.dist\${env:_RELEASE_NAME}-${env:_RELEASE_VERSION}_${env:_RELEASE_CONFIGURATION}.zip"
