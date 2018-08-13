<#
.SYNOPSIS
Imports the PowerGit module.

.DESCRIPTION
The `Import-PowerGit.ps1` script imports the `PowerGit` module from this script's directory.
#>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

if ( (Get-Module -Name 'PowerGit') ) {
    Remove-Module -Name 'PowerGit' -Force
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PowerGit.psd1')