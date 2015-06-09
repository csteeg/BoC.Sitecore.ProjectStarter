param($installPath, $toolsPath, $package, $project)

[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

Write-Host "InstallPath: "$installPath
Write-Host "toolsPath: "$toolsPath
$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])

$projectPath = [System.IO.Path]::GetDirectoryName($project.FileName)
$solutionPath = [System.IO.Path]::GetDirectoryName($solution.FileName)
$slnFile = [System.IO.Path]::GetFullPath($solution.FileName)
$buildPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "build"))
$tempfolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "temp\extracted"))
$selectFileExe = [System.IO.Path]::Combine($toolsPath, "selectfile.exe")

Write-Host "projectPath: "$projectPath
Write-Host "buildPath: "$buildPath
Write-Host "tempfolder: "$tempfolder
Write-Host "selectFileExe: "$selectFileExe

$sitecoreZip = (& $selectFileExe "Zip files (*.zip)| *.zip" "Select sitecore zip installation") | Out-String
$sitecoreZip = $sitecoreZip.Trim()
Write-Host "sitecoreZip: "$sitecoreZip
If (!(Test-Path -LiteralPath "$sitecoreZip")){
    Write-Host "No sitecore zip file present!"
    Exit
}
Write-Host "Extracting sitecore from : "$sitecoreZip" to "$tempfolder
[System.IO.Compression.ZipFile]::ExtractToDirectory($sitecoreZip, $tempfolder)

If (Test-Path -LiteralPath $buildPath){
    Remove-Item -recurse -force -LiteralPath $buildPath
}
Write-Host "Creating build folder structure"
$extracted = Get-ChildItem $tempfolder -name
$extracted = $tempfolder + "\" + $extracted
Copy-Item -LiteralPath $extracted -destination $buildPath -Force
#Remove-Item -recurse -force -LiteralPath $tempfolder

Write-Host "Moving databases to App_Data folder"
Move-Item -LiteralPath $buildPath"\databases" -destination $buildPath"\website\App_Data" -Force

Write-Host "Creating csproj file"
#TODO: these should be downloaded
$debugProj = $buildPath + "\website\Debug.csproj";
Copy-Item -LiteralPath $toolsPath"\Debug.csproj" -Recurse -destination $debugProj -Force
(Get-Content $buildPath"\website\web.config").replace('configSource="App_Config\ConnectionStrings.config"','')|Set-Content $buildPath"\website\web.config"
Copy-Item -LiteralPath $buildPath"\website\web.config"  -destination $projectPath"\web.config" -Force

if (!$licenseFile){
    $licenseFile = (& $selectFileExe "Sitecore license file (license.xml)| license.xml" "Select sitecore license file") | Out-String
    $licenseFile = $licenseFile.Trim()
}
Copy-Item -LiteralPath $licenseFile -destination $buildPath"\data\license.xml" -Force
Copy-Item -LiteralPath $licenseFile -destination $tempfolder"\data\license.xml" -Force

Write-Host "Setting machinename '"$env:COMPUTERNAME"' to conditions in config files"
$replace = 'condition-machineName="' + $env:COMPUTERNAME+ '"'
$configFolder = [System.IO.Path]::Combine($projectPath, "App_Config")
$configFiles = Get-ChildItem $configFolder "*.config" -Recurse
foreach ($file in $configFiles)
{
    Write-Host "Replacing content in "$file.PSPath
    (Get-Content -LiteralPath $file.PSPath) | 
    Foreach-Object {$_ -replace 'condition-machineName="DEVELOPMACHINE"', $replace} | Set-Content -LiteralPath $file.PSPath
}

$projectParentPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($projectPath, ".."));

Write-Host "solutionPath     : "$solutionPath
Write-Host "projectParentPath: "$projectParentPath

$debugFolderProject = ($dte.solution.Projects | where ProjectName -eq "_debug");
if (!$debugFolderProject)
{
    $debugFolderProject = $solution.AddSolutionFolder("_debug")
}
$debugFolder = Get-Interface $debugFolderProject.Object ([EnvDTE80.SolutionFolder])

if ($solutionPath -eq $projectParentPath){
    Write-Host "Moving project to src folder"
    $project.Save()
    $newProjectFile = $project.FullName.Replace($solutionPath, $solutionPath+"\src")
    $newProjectPath = [System.IO.Path]::GetDirectoryName($newProjectFile)
    Write-Host "New project file will be "$newProjectFile" in "$newProjectPath
    New-Item -ItemType Directory -Force -Path $solutionPath"\src"
    
    $toremove = ($dte.solution.Projects | where ProjectName -eq $project.Name);
    Write-Host "Removing"$toremove.Name
    $dte.solution.Remove($toremove)
    
    Move-Item -LiteralPath $projectPath -destination $newProjectPath -Force

    $debugProjItem = $debugFolder.AddFromFile($debugProj) 
    $project = $solution.AddFromFile($newProjectFile)
    $projectPath = $newProjectPath
} else {
    $debugProjItem = $debugFolder.AddFromFile($debugProj) 
}

$kerneldll = $buildPath + "\website\bin\sitecore.kernel.dll"
Write-Host "Adding reference to "$kerneldll
$project.Object.References.Add($kerneldll)
$project.Object.References.Item("sitecore.kernel").CopyLocal = "False"

Install-Package BoC.Persistence.SitecoreGlass -ProjectName $project.Name
Install-Package BoC.InversionOfControl.SimpleInjector -ProjectName $project.Name
Install-Package Efocus.Sitecore.ConditionalConfig -ProjectName $project.Name
$project.ProjectItems.Item("App_Start").ProjectItems.Item("GlassMapperScCustom.cs").Delete()

Copy-Item -LiteralPath $toolsPath"\Content\Web.Debug.config" -destination $projectPath -Force
Copy-Item -LiteralPath $toolsPath"\Content\Web.Release.config" -destination $projectPath -Force