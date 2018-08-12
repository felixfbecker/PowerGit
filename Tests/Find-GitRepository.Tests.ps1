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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationCoreTest.ps1' -Resolve)

function Assert-ThisRepositoryFound {
    param(
        [LibGit2Sharp.Repository]
        $Repository
    )

    It 'should return this repository' {
        $Repository | Should Not BeNullOrEmpty
        $Repository.Info.WorkingDirectory | Should Be (Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve)
    }
}

function Assert-NoRepositoryReturned {
    param(
        [LibGit2Sharp.Repository]
        $Repository
    )

    It 'should return no repository' {
        $Repository | Should BeNullOrEmpty
    }
}

Describe 'Find-GitRepository when the current directory is under a repository root' {
    Push-Location -Path $PSScriptRoot
    try {
        $repo = Find-GitRepository
        Assert-ThisRepositoryFound -Repository $repo
    } finally {
        Pop-Location
    }
}

Describe 'Find-GitRepository when the current directory has no repository' {
    Clear-Error
    Push-Location -Path ([IO.Path]::GetTempPath())
    try {
        $repo = Find-GitRepository
        Assert-NoRepositoryReturned -Repository $repo
        It 'should write no errors' {
            $Global:Error.Count | Should Be 0
        }
    } finally {
        Pop-Location
    }
}

Describe 'Find-GitRepository when given a relative path' {
    Push-Location -Path $PSScriptRoot
    try {
        $repo = Find-GitRepository -Path (Join-Path '..' 'GitAutomationCore')
        Assert-ThisRepositoryFound -Repository $repo
    } finally {
        Pop-Location
    }
}

Describe 'Find-GitRepository when a path doesn''t exist' {
    Clear-Error
    $repo = Find-GitRepository -Path 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
    Assert-NoRepositoryReturned $repo
    It 'should write an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}

Describe 'Find-GitRepository when passed full path to repository root' {
    $repo = Find-GitRepository -Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve)
    Assert-ThisRepositoryFound -Repository $repo
}


Describe 'Find-GitRepository when current directory is a repository root' {
    Push-Location -Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve)
    try {
        $repo = Find-GitRepository
        Assert-ThisRepositoryFound -Repository $repo
    } finally {
        Pop-Location
    }
}

Describe 'Find-GitRepository when -Verify switch is used and a repository isn''t found' {
    Clear-Error
    $repo = Find-GitRepository -Path ([IO.Path]::GetTempPath()) -Verify -ErrorAction SilentlyContinue
    Assert-NoRepositoryReturned -Repository $repo
    It 'should write an error' {
        $Global:Error | Should Match 'not in a Git repository'
        $Global:Error | Should Match ([regex]::Escape(([IO.Path]::GetTempPath())))
    }
}

Describe 'Find-GitRepository when -Verify switch is used and a repository in current directory isn''t found' {
    Clear-Error
    Push-Location -Path ([IO.Path]::GetTempPath())
    try {
        $repo = Find-GitRepository -Verify -ErrorAction SilentlyContinue
        Assert-NoRepositoryReturned -Repository $repo
        It 'should write an error' {
            $Global:Error | Should Match 'not in a Git repository'
            $CurrentLocation = (Get-Location | Select-Object -ExpandProperty 'ProviderPath')
            $Global:Error | Should Match ([regex]::Escape($CurrentLocation))
        }
    } finally {
        Pop-Location
    }
}

Describe 'Find-GitRepository when -Verify switch is used and a repository is found' {
    Clear-Error
    $repo = Find-GitRepository -Path $PSScriptRoot -Verify
    Assert-ThisRepositoryFound -Repository $repo
    Assert-ThereAreNoErrors
}
