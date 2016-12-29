If (-not (Get-Module Pester))
{
    Install-Module Pester -Scope CurrentUser -Confirm:$false
}

Import-Module Pester
Invoke-Pester