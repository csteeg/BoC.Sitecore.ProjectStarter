param($installPath, $toolsPath, $package, $project)

[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

function Unzip ($zipfile, $dst, $folderinzip='')
{
	Write-Host "Opening zipfile: "$zipfile
	$archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile);
	Try {
		$archive.Entries | ? { $_.FullName -like "$($folderinzip -replace '\\','/')/*" -and -not $_.FullName.EndsWith("/") } | % {
		  $file   = Join-Path $dst $_.FullName
		  $parent = Split-Path -Parent $file
		  if (-not (Test-Path -LiteralPath $parent)) {
			New-Item -Path $parent -Type Directory | Out-Null
		  }
		  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $file, $true)
		}
	}
	Finally
	{
		$archive.Dispose()
	}
}

Write-Host "InstallPath: "$installPath
Write-Host "toolsPath: "$toolsPath
$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])

$projectPath = [System.IO.Path]::GetDirectoryName($project.FileName)
$solutionPath = [System.IO.Path]::GetDirectoryName($solution.FileName)
$slnFile = [System.IO.Path]::GetFullPath($solution.FileName)
$buildPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "build"))
$sitecoreLibPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "lib\sitecore"))
$tempfolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "temp\extracted"))
$selectFileExe = [System.IO.Path]::Combine($toolsPath, "selectfile.exe")

Write-Host "projectPath: "$projectPath
Write-Host "buildPath: "$buildPath
Write-Host "sitecoreLibPath: "$sitecoreLibPath
Write-Host "tempfolder: "$tempfolder
Write-Host "selectFileExe: "$selectFileExe

Write-Host "Select your sitecore zip file (press ALT+TAB if you don't see an open-file dialog)"
$sitecoreZip = (& "$selectFileExe" "Zip files (*.zip)| *.zip" "Select sitecore zip installation") | Out-String
$sitecoreZip = $sitecoreZip.Trim()
Write-Host "sitecoreZip: "$sitecoreZip
If (!(Test-Path -LiteralPath "$sitecoreZip")){
    Write-Host "No sitecore zip file present!"
    Exit
}
If (Test-Path -LiteralPath $tempfolder){
    Remove-Item -recurse -force -LiteralPath $tempfolder
}

Write-Host "Extracting sitecore from : "$sitecoreZip" to "$tempfolder
[System.IO.Compression.ZipFile]::ExtractToDirectory($sitecoreZip, $tempfolder)

If (Test-Path -LiteralPath $buildPath){
    Remove-Item -recurse -force -LiteralPath $buildPath
}
Write-Host "Creating build folder structure"
$extracted = Get-ChildItem $tempfolder -name
$extracted = $tempfolder + "\" + $extracted
Write-Host "Copying "$extracted" to "$buildPath
Copy-Item -LiteralPath $extracted -destination $buildPath -Force -Recurse

Write-Host "Moving databases to App_Data folder"
Move-Item -LiteralPath $buildPath"\databases" -destination $buildPath"\website\App_Data" -Force

Write-Host "Creating csproj file"

$debugProj = $buildPath + "\website\SitecoreRunner.csproj";
Copy-Item -LiteralPath $toolsPath"\SitecoreRunner.csproj" -Recurse -destination $debugProj -Force
(Get-Content $buildPath"\website\web.config").replace('configSource="App_Config\ConnectionStrings.config"','')|Set-Content $buildPath"\website\web.config"
Copy-Item -LiteralPath $buildPath"\website\web.config"  -destination $projectPath"\web.config" -Force

Write-Host "Copying lib folder"
Copy-Item -LiteralPath $buildPath"\website\bin"  -destination $sitecoreLibPath -Force -Recurse

if (!$licenseFile){
    Write-Host "Select your license file (press ALT+TAB if you don't see an open-file dialog)"
    $licenseFile = (& "$selectFileExe" "Sitecore license file (license.xml)| license.xml" "Select sitecore license file") | Out-String
    $licenseFile = $licenseFile.Trim()
}
Copy-Item -LiteralPath $licenseFile -destination $buildPath"\data\license.xml" -Force
Copy-Item -LiteralPath $licenseFile -destination $extracted"\data\license.xml" -Force

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

$debugFolderProject = ($dte.solution.Projects | where ProjectName -eq "_projectstarter");
if (!$debugFolderProject)
{
    $debugFolderProject = $solution.AddSolutionFolder("_projectstarter")
}
$debugFolder = Get-Interface $debugFolderProject.Object ([EnvDTE80.SolutionFolder])
if ($solutionPath -eq $projectParentPath){
    Write-Host "Moving project to src folder"
    $project.Save()
    $isvs2015proj = $project.Object.References.Item("Microsoft.CodeDom.Providers.DotNetCompilerPlatform")
    if ($isvs2015proj) {
      Uninstall-Package Microsoft.CodeDom.Providers.DotNetCompilerPlatform -ProjectName $project.Name
      Uninstall-Package Microsoft.Net.Compilers -ProjectName $project.Name
    }
    
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
    
    if ($isvs2015proj) {
      Install-Package Microsoft.CodeDom.Providers.DotNetCompilerPlatform -ProjectName $project.Name
    }
    
} else {
    $debugProjItem = $debugFolder.AddFromFile($debugProj) 
}

$kerneldll = $sitecoreLibPath + "\sitecore.kernel.dll"
Write-Host "Adding reference to "$kerneldll
$project.Object.References.Add($kerneldll)
$project.Object.References.Item("sitecore.kernel").CopyLocal = "False"

$mvcdll = $sitecoreLibPath +"\sitecore.mvc.dll"
Write-Host "Adding reference to "$mvcdll
$project.Object.References.Add($mvcdll)
$project.Object.References.Item("sitecore.mvc").CopyLocal = "False"

$mvcanadll = $sitecoreLibPath +"\Sitecore.Mvc.Analytics.dll"
Write-Host "Adding reference to "$mvcanadll
$project.Object.References.Add($mvcanadll)
$project.Object.References.Item("Sitecore.Mvc.Analytics").CopyLocal = "False"

$analyticsdll = $sitecoreLibPath +"\Sitecore.Analytics.dll"
Write-Host "Adding reference to "$analyticsdll
$project.Object.References.Add($analyticsdll)
$project.Object.References.Item("Sitecore.Analytics").CopyLocal = "False"

$dte.Solution.Properties.Item("StartupProject").Value = $debugProjItem.Name
$project.ProjectItems("web.config").Properties("ItemType").Value = "Content"

$allprojs = (Get-Project -All)| ? UniqueName -notmatch "Tests.csproj|SitecoreRunner.csproj"

$solution.SolutionBuild.BuildDependencies | Foreach-Object { 
	if ($_.Project.Name -eq "SitecoreRunner") { 
		$bdeps = $_
		$allprojs | ForEach-Object { 
			Write-Host "Adding "$_.UniqueName" as a dependency"
			$bdeps.AddProject($_.UniqueName) 
		}
	}
}

$hasform = (Get-Project -All)| ? Name -eq "Sitecore.Foundation.Forms"
if ($hasform) {
	Write-Host "Select your sitecore Web Forms for Marketers zip file (press ALT+TAB if you don't see an open-file dialog)"
	$wffmZip = (& "$selectFileExe" "Zip files (*.zip)| *.zip" "Select Web Forms for Marketers zip installation") | Out-String
	$wffmZip = $wffmZip.Trim()
	Write-Host "wffmZip: "$wffmZip
	if (!(Test-Path -LiteralPath "$wffmZip")){
		Write-Host "No wffm zip file present!"
	} else {
		$wffmfolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($solutionPath, "SitecorePackages\Wffm\"))
		if (Test-Path -LiteralPath "$wffmfolder"){
			Remove-Item -recurse -force -LiteralPath $wffmfolder
		}
		$wffmtempfolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($wffmfolder, "_temp"))
		$wffmstep1folder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($wffmfolder, "_step1"))
		$wffmstep2folder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($wffmfolder, "_step2"))
		Write-Host "Extracting wffm from : $wffmZip to $wffmtempfolder"
		[System.IO.Compression.ZipFile]::ExtractToDirectory($wffmZip, $wffmtempfolder)

		$extractedwffm1 = Get-ChildItem $wffmtempfolder -name  | where {$_ -notmatch " CD "}
		if ($extractedwffm1 -eq "package.zip"){
			$packagezip = $extractedwffm1
		} else {
			$wffmZip = [System.IO.Path]::Combine($wffmtempfolder, $extractedwffm1)
			Write-Host "Extracting wffm from $extractedwffm1 to $wffmstep1folder"
			[System.IO.Compression.ZipFile]::ExtractToDirectory($wffmZip, $wffmstep1folder)

			$packagezip = [System.IO.Path]::Combine($wffmstep1folder, "package.zip")
		}
		Write-Host "Extracting wffm from $packagezip to $wffmstep2folder"
		#use custom unzip, package.zip has problems extracting: http://stackoverflow.com/questions/24941741/zip-entry-name-ends-in-directory-separator-character-but-contains-data
		Unzip $packagezip $wffmstep2folder "files"
		Copy-Item "$wffmstep2folder\files\bin\**" $sitecoreLibPath
		Move-Item $wffmzip "$wffmfolder"
		Remove-Item -recurse -force -LiteralPath $wffmtempfolder
		Remove-Item -recurse -force -LiteralPath $wffmstep2folder
		Remove-Item -recurse -force -LiteralPath $wffmstep1folder
	}
}

Install-Package Efocus.Sitecore.ConditionalConfig -ProjectName $project.UniqueName

Copy-Item -LiteralPath $toolsPath"\Content\Web.Debug.config" -destination $projectPath -Force
Copy-Item -LiteralPath $toolsPath"\Content\Web.Release.config" -destination $projectPath -Force