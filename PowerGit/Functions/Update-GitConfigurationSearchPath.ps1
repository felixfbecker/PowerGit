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

function Update-GitConfigurationSearchPath {
    [CmdletBinding()]
    param(
        [LibGit2Sharp.ConfigurationLevel]
        # The scope of the configuration. Nothing is updated unless `Global` is used.
        $Scope
    )

    Set-StrictMode -Version 'Latest'

    if ( $Scope -ne [LibGit2Sharp.ConfigurationLevel]::Global ) {
        return
    }

    if ( -not (Test-Path -Path 'env:HOME') ) {
        return
    }

    $homePath = Get-Item -Path 'env:HOME' | Select-Object -ExpandProperty 'Value'
    $homePath = $homePath -replace '\\', '/'

    [string[]]$searchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($Scope)
    if ( $searchPaths[0] -eq $homePath ) {
        return
    }

    $searchList = New-Object -TypeName 'Collections.Generic.List[string]'
    $searchList.Add($homePath)
    $searchList.AddRange($searchPaths)

    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths($Scope, $searchList.ToArray())
}