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

function ConvertTo-GitFullPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        # A path to convert to a full path.
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string] $Path,

        # A URI to convert to a full path. It can be a local path.
        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [uri] $Uri
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'Uri') {
        if ($Uri.Scheme) {
            return $Uri.ToString()
        }

        $Path = $Uri.ToString()
    }

    if ([IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    $Path = Join-Path -Path (Get-Location) -ChildPath $Path
    [IO.Path]::GetFullPath($Path)
}
