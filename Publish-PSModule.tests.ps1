$ScriptPath = $PSScriptRoot
Remove-Item $ScriptPath\Test-Module -Recurse -Force -ErrorAction SilentlyContinue

Describe "Testing Publish-PSModule module builds" {
    Context "Scratch build" {
        New-Item $ScriptPath\Test-Module\Source -ItemType Directory
        New-Item $ScriptPath\Test-Module\Source\Public -ItemType Directory
        New-Item $ScriptPath\Test-Module\Source\Private -ItemType Directory
        New-Item $ScriptPath\Test-Module\Source\Tests -ItemType Directory

        "#Include.txt" | Out-File $ScriptPath\Test-Module\Source\include.txt
        "Function Private-Function { <#this is a test#> }" | Out-File $ScriptPath\Test-Module\Source\Private\PrivateFunction.ps1
        "#Testfile" | Out-File $ScriptPath\Test-Module\Source\Tests\test.ps1
        $Module = @"
Function Test1 {
	#requires -Version 3.0
    #this is a test function
}

   Function Test2
{
    #Test function 2
}
#Function Get-It {
    #test function 3
#}
#   Function Save-it
{
}
Function Get-Me{
}

Function check-me { <#this is a test#> }
Function check-m2e{ <#this is a test#> }
"@
        $Module | Out-File $ScriptPath\Test-Module\Source\Public\PublicFunction.ps1
        It "Initial Build" {
            { & $ScriptPath\Publish-PSModule.ps1 -Path $ScriptPath\Test-Module } | Should Not Throw
        }
        It "Manifest exists" {
            Test-Path $ScriptPath\Test-Module\Test-Module.psd1 | Should Be True
        }
        It "Module exists" {
            Test-Path $ScriptPath\Test-Module\Test-Module.psm1 | Should Be True
        }
        It "Correct functions were exported" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psd1 -Pattern "FunctionsToExport = 'Test1', 'Test2', 'Get-Me', 'check-me', 'check-m2e'"
            $Search.Count | Should Be 1
        }
        It "PowerShellVersion set to 3.0" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psd1 -Pattern "PowerShellVersion = '3.0'"
            $Search.Count | Should Be 1
        }
        It "Private function exists in module" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "Function Private-Function { <#this is a test#> }"
            $Search.Count | Should Be 1
        }
        It "Spot check public function" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "Function check-me { <#this is a test#> }"
            $Search.Count | Should Be 1
        }
        It "Include.txt exists in module file" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "#Include.txt"
            $Search.Count | Should Be 1
        }
    }
    Context "Update existing build" {
        $Module = @"
Function Test1 {
    #this is a test function
}
Function Test2
{
    #Test function 2
}
"@
        $Module | Out-File $ScriptPath\Test-Module\Source\Public\PublicFunction.ps1
        It "Update Build" {
            { & $ScriptPath\Publish-PSModule.ps1 -Path $ScriptPath\Test-Module } | Should Not Throw
        }
        It "Should only be 2 functions now" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psd1 -Pattern "FunctionsToExport = 'Test1', 'Test2'"
            $Search.Count | Should Be 1
        }
        It "PowerShellVersion set to 2.0" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psd1 -Pattern "PowerShellVersion = '2.0'"
            $Search.Count | Should Be 1
        }
        It "Private function exists in module" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "Function Private-Function { <#this is a test#> }"
            $Search.Count | Should Be 1
        }
        It "Spot check public function" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "Function Test1 {"
            $Search.Count | Should Be 1
        }
        It "Include.txt exists in module file" {
            $Search = Select-String -Path $ScriptPath\Test-Module\Test-Module.psm1 -Pattern "#Include.txt"
            $Search.Count | Should Be 1
        }
    }
    Context "Specify Module Name build" {
        It "Update Build" {
            { & $ScriptPath\Publish-PSModule.ps1 -Path $ScriptPath\Test-Module -ModuleName MyModule } | Should Not Throw
        }
        It "Manifest exists" {
            Test-Path $ScriptPath\Test-Module\MyModule.psd1 | Should Be True
        }
        It "Module exists" {
            Test-Path $ScriptPath\Test-Module\MyModule.psm1 | Should Be True
        }
        It "Correct functions were exported" {
            $Search = Select-String -Path $ScriptPath\Test-Module\MyModule.psd1 -Pattern "FunctionsToExport = 'Test1', 'Test2'"
            $Search.Count | Should Be 1
        }
        It "PowerShellVersion set to 2.0" {
            $Search = Select-String -Path $ScriptPath\Test-Module\MyModule.psd1 -Pattern "PowerShellVersion = '2.0'"
            $Search.Count | Should Be 1
        }
        It "Private function exists in module" {
            $Search = Select-String -Path $ScriptPath\Test-Module\MyModule.psm1 -Pattern "Function Private-Function { <#this is a test#> }"
            $Search.Count | Should Be 1
        }
        It "Spot check public function" {
            $Search = Select-String -Path $ScriptPath\Test-Module\MyModule.psm1 -Pattern "Function Test1 {"
            $Search.Count | Should Be 1
        }
        It "Include.txt exists in module file" {
            $Search = Select-String -Path $ScriptPath\Test-Module\MyModule.psm1 -Pattern "#Include.txt"
            $Search.Count | Should Be 1
        }
    }
    Context "Duplicate function name build" {
        $Module = @"
Function Test1 {
    #this is a test function
}
Function Test1
{
    #Duplicate Function Name
}
"@
        $Module | Out-File $ScriptPath\Test-Module\Source\Public\PublicFunction.ps1
        It "Duplicate function name build should fail" {
            { & $ScriptPath\Publish-PSModule.ps1 -Path $ScriptPath\Test-Module } | Should Throw
        }
    }
}

#Clean up!
Start-Sleep -Milliseconds 500
Remove-Item $ScriptPath\Test-Module -Recurse -Force -ErrorAction SilentlyContinue