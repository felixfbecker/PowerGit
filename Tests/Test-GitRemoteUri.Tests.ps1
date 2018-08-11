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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationCoreTest.ps1' -Resolve)

Describe 'Test-GitRemoteUri' {
    It 'should return true for a valid remote' {
        $remoteRepo = New-GitTestRepo
        $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath
        Find-GitRepository -Path $localRepoPath

        $configPath = Join-Path $localRepoPath .git/config
        $url = Get-Content $configPath | Where-Object { $_ -match 'url = .*' } | ForEach-Object { $_.ToString().Remove(0, 7)}
        Test-GitRemoteUri -Uri $url | Should Be $true
    }

    It 'should return false for an invalid uri' {
        Test-GitRemoteUri -Uri 'ssh://git@stash.portal.webmd.com:7999/whs/bleeeh.git' | Should Be $false
    }
}