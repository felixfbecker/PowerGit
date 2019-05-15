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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

$repoRoot = $null
$result = $null

function GivenBranch {
    param(
        $Name
    )

    New-GitBranch -RepoRoot $repoRoot -Name $Name
}

function GivenRepository {
    New-GitRepository -Path $repoRoot
    Add-GitTestFile -RepoRoot $repoRoot -Path 'first'
    Add-GitItem -Path 'first' -RepoRoot $repoRoot
    Save-GitCommit -Message 'first' -RepoRoot $repoRoot
}

function GivenTag {
    param(
        $Name
    )

    New-GitTag -RepoRoot $repoRoot -Name $Name
}

function Init {
    $script:repoRoot = $testDir.FullName
    $script:result = $null
}

function ThenNoErrors {
    It ('should write no errors') {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenReturnedFalse {
    It ('should not find the commit') {
        $result | Should -BeFalse
    }
}

function ThenReturnedTrue {
    It ('should find the commit') {
        $result | Should -BeTrue
    }
}

function WhenTestingRevision {
    param(
        $Revision,
        [Switch]
        $NoRepoRootParameter
    )

    $repoRootParam = @{ 'RepoRoot' = $repoRoot }
    if ($NoRepoRootParameter) {
        $repoRootParam = @{ }
    }

    $Global:Error.Clear()
    $script:result = Test-GitCommit -Revision $Revision @repoRootParam
}

Describe 'Test-GitCommit.when revision doesn''t exist' {
    Init
    GivenRepository
    WhenTestingRevision 'fubarsnafu'
    ThenReturnedFalse
    ThenNoErrors
}

Describe 'Test-GitCommit.when testing with SHA' {
    Init
    GivenRepository
    WhenTestingRevision (Get-GitCommit -Revision 'HEAD' -RepoRoot $repoRoot).Sha
    ThenReturnedTrue
    ThenNoErrors
}

Describe 'Test-GitCommit.when testing with truncated SHA' {
    Init
    GivenRepository
    WhenTestingRevision (Get-GitCommit -Revision 'HEAD' -RepoRoot $repoRoot).Sha.Substring(0, 7)
    ThenReturnedTrue
    ThenNoErrors
}

Describe 'Test-GitCommit.when using tag' {
    Init
    GivenRepository
    GivenTag 'fubarsnafu'
    WhenTestingRevision 'fubarsnafu'
    ThenReturnedTrue
    ThenNoErrors
}

Describe 'Test-GitCommit.when using branch' {
    Init
    GivenRepository
    GivenBranch 'some-branch'
    WhenTestingRevision 'some-branch'
    ThenReturnedTrue
    ThenNoErrors
}

Describe 'Test-GitCommit.when working in current directory' {
    Init
    GivenRepository
    GivenBranch 'some-branch'
    Push-Location -Path $repoRoot
    try {
        WhenTestingRevision 'some-branch' -NoRepoRootParameter
        ThenReturnedTrue
        ThenNoErrors
    } finally {
        Pop-Location
    }
}
