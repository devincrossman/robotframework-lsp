[CmdletBinding()]
param(
    [switch]$SkipSubmoduleUpdate,
    [switch]$SkipPythonToolInstall,
    [switch]$SkipYarnInstall,
    [switch]$SkipCodegen,
    [switch]$SkipVendoring,
    [switch]$SkipPythonDist,
    [switch]$SkipVsix
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RobotframeworkLsDir = Join-Path $RepoRoot "robotframework-ls"
$RobotframeworkLsSrcDir = Join-Path $RobotframeworkLsDir "src"
$VenvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-ExternalCommand {
    param(
        [string]$StepName,
        [string]$WorkingDirectory,
        [string]$Executable,
        [string[]]$Arguments = @(),
        [hashtable]$Environment = @{}
    )

    Write-Step $StepName

    $previousEnvironment = @{}
    foreach ($entry in $Environment.GetEnumerator()) {
        $previousEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable(
            $entry.Key,
            [EnvironmentVariableTarget]::Process
        )
        [Environment]::SetEnvironmentVariable(
            $entry.Key,
            $entry.Value,
            [EnvironmentVariableTarget]::Process
        )
    }

    Push-Location $WorkingDirectory
    try {
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "$StepName failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
        foreach ($entry in $Environment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable(
                $entry.Key,
                $previousEnvironment[$entry.Key],
                [EnvironmentVariableTarget]::Process
            )
        }
    }
}

function Get-CommandPath {
    param([string]$CommandName)

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        return $null
    }
    return $command.Source
}

function Ensure-Command {
    param([string]$CommandName)

    $path = Get-CommandPath $CommandName
    if (-not $path) {
        throw "Required command '$CommandName' was not found on PATH."
    }
    return $path
}

function Ensure-VenvPython {
    if (Test-Path $VenvPython) {
        return $VenvPython
    }

    $bootstrapPython = Get-CommandPath "py"
    if (-not $bootstrapPython) {
        $bootstrapPython = Get-CommandPath "python"
    }
    if (-not $bootstrapPython) {
        throw "Could not find 'py' or 'python' to create .venv."
    }

    Invoke-ExternalCommand `
        -StepName "Create virtual environment" `
        -WorkingDirectory $RepoRoot `
        -Executable $bootstrapPython `
        -Arguments @("-m", "venv", ".venv")

    if (-not (Test-Path $VenvPython)) {
        throw "Virtual environment was not created at $VenvPython."
    }

    return $VenvPython
}

function Ensure-Yarn {
    $null = Ensure-Command "node"
    $corepackPath = Get-CommandPath "corepack"
    if ($corepackPath) {
        $corepackBin = Join-Path $RepoRoot ".corepack-bin"
        $corepackHome = Join-Path $RepoRoot ".corepack-home"

        New-Item -ItemType Directory -Force -Path $corepackBin | Out-Null
        New-Item -ItemType Directory -Force -Path $corepackHome | Out-Null

        [Environment]::SetEnvironmentVariable(
            "COREPACK_HOME",
            $corepackHome,
            [EnvironmentVariableTarget]::Process
        )
        $env:PATH = "$corepackBin;$env:PATH"

        Invoke-ExternalCommand `
            -StepName "Enable Corepack yarn shims" `
            -WorkingDirectory $RepoRoot `
            -Executable $corepackPath `
            -Arguments @("enable", "--install-directory", $corepackBin)

        $yarnPath = Get-CommandPath "yarn"
        if ($yarnPath) {
            return $yarnPath
        }

        throw "Yarn could not be activated via corepack."
    }

    $yarnPath = Get-CommandPath "yarn"
    if ($yarnPath) {
        return $yarnPath
    }

    throw "Neither 'corepack' nor 'yarn' was found on PATH."
}

function Get-ExtensionVersion {
    $packageJsonPath = Join-Path $RobotframeworkLsDir "package.json"
    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    return $packageJson.version
}

$venvPythonPath = Ensure-VenvPython
$gitPath = Ensure-Command "git"

$needsNodeTooling = -not $SkipYarnInstall -or -not $SkipVendoring -or -not $SkipVsix
if ($needsNodeTooling) {
    $null = Ensure-Yarn
}

if (-not $SkipSubmoduleUpdate) {
    Invoke-ExternalCommand `
        -StepName "Initialize submodules" `
        -WorkingDirectory $RepoRoot `
        -Executable $gitPath `
        -Arguments @("submodule", "update", "--init", "--recursive")
}

if (-not $SkipPythonToolInstall) {
    Invoke-ExternalCommand `
        -StepName "Install Python build tools" `
        -WorkingDirectory $RepoRoot `
        -Executable $venvPythonPath `
        -Arguments @("-m", "pip", "install", "--upgrade", "pip", "fire", "wheel", "setuptools")
}

if (-not $SkipYarnInstall) {
    Invoke-ExternalCommand `
        -StepName "Install extension dependencies" `
        -WorkingDirectory $RobotframeworkLsDir `
        -Executable (Ensure-Command "yarn") `
        -Arguments @("install")
}

if (-not $SkipCodegen) {
    Invoke-ExternalCommand `
        -StepName "Refresh generated files" `
        -WorkingDirectory $RobotframeworkLsDir `
        -Executable $venvPythonPath `
        -Arguments @("codegen\codegen_package.py") `
        -Environment @{ PYTHONPATH = "src" }
}

if (-not $SkipVendoring) {
    Invoke-ExternalCommand `
        -StepName "Vendor robocorp_ls_core" `
        -WorkingDirectory $RobotframeworkLsDir `
        -Executable $venvPythonPath `
        -Arguments @("-m", "dev", "vendor-robocorp-ls-core")

    Invoke-ExternalCommand `
        -StepName "Vendor robotframework_interactive" `
        -WorkingDirectory $RobotframeworkLsDir `
        -Executable $venvPythonPath `
        -Arguments @("-m", "dev", "vendor-robotframework-interactive")

    Invoke-ExternalCommand `
        -StepName "Vendor robotframework_output_stream" `
        -WorkingDirectory $RobotframeworkLsDir `
        -Executable $venvPythonPath `
        -Arguments @("-m", "dev", "vendor-robotframework-output-stream")
}

if (-not $SkipPythonDist) {
    Invoke-ExternalCommand `
        -StepName "Build Python source and wheel distributions" `
        -WorkingDirectory $RobotframeworkLsSrcDir `
        -Executable $venvPythonPath `
        -Arguments @("setup.py", "sdist", "bdist_wheel", "--universal")
}

$extensionVersion = Get-ExtensionVersion
$vsixOutputName = "robotframework-lsp-$extensionVersion.vsix"
$vsixOutputPath = Join-Path $RobotframeworkLsDir $vsixOutputName

if (-not $SkipVsix) {
    $vscePath = Get-CommandPath "vsce"
    if ($vscePath) {
        Invoke-ExternalCommand `
            -StepName "Build VSIX with installed vsce" `
            -WorkingDirectory $RobotframeworkLsDir `
            -Executable $vscePath `
            -Arguments @("package", "-o", $vsixOutputName)
    }
    else {
        $npxPath = Ensure-Command "npx"
        Invoke-ExternalCommand `
            -StepName "Build VSIX with npx vsce" `
            -WorkingDirectory $RobotframeworkLsDir `
            -Executable $npxPath `
            -Arguments @("--yes", "vsce@2.6.7", "package", "--no-yarn", "-o", $vsixOutputName)
    }
}

Write-Host ""
Write-Host "Build complete." -ForegroundColor Green
if (-not $SkipPythonDist) {
    Write-Host "Python dist: $(Join-Path $RobotframeworkLsSrcDir 'dist')" -ForegroundColor Green
}
if (-not $SkipVsix) {
    Write-Host "VSIX: $vsixOutputPath" -ForegroundColor Green
}
