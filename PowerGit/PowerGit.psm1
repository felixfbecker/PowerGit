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

using namespace System.Runtime.InteropServices

Import-Module "$PSScriptRoot/Assemblies/LibGit2Sharp.dll"
Import-Module "$PSScriptRoot/Assemblies/PowerGit.dll"

# $sshCmd = Get-Command 'ssh' -ErrorAction Ignore
# if ($sshCmd) {
#     $sshPath = $sshCmd.Path
# } else {
#     $gitCmd = Get-Command -Name 'git.exe' -ErrorAction Ignore
#     if ($gitCmd) {
#         $sshPath = Split-Path -Path $gitCmd.Path -Parent
#         $sshPath = Join-Path -Path $sshPath -ChildPath '..\usr\bin\ssh.exe' -Resolve -ErrorAction Ignore
#     }
# }

# if ($sshPath) {
#     [PowerGit.SshExeTransport]::Unregister()
#     [PowerGit.SshExeTransport]::Register($sshPath)
# } else {
#     Write-Warning -Message ('SSH support is disabled. To enable SSH, please install Git for Windows. PowerGit uses the version of SSH that ships with Git for Windows.')
# }

Get-ChildItem -Path "$PSScriptRoot/Functions", "$PSScriptRoot/Completers" -File -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
