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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

function GivenRepositoryWithFile {
    param(
        [string[]]
        $Name
    )
    $script:repoRoot = New-GitTestRepo
    foreach ($item in $Name) {
        New-Item -Path (Join-Path -Path $repoRoot -ChildPath $item) -Type 'File'
    }
    Add-GitItem -RepoRoot $repoRoot -Path $Name
    Save-GitCommit -RepoRoot $repoRoot -Message 'Commit to add test files'
}

function GivenIncorrectRepo {
    param(
        [string]
        $RepoName
    )
    $script:repoRoot = $RepoName
}

function GivenFileIsDeleted {
    param(
        [string[]]
        $Name
    )
    foreach ($item in $Name) {
        Remove-Item -Path (Join-Path -Path $repoRoot -ChildPath $item)
    }
}

function GivenFileToStage {
    param(
        [string[]]
        $Name
    )
    $script:filesToStage = $Name
}

function WhenFileIsStaged {
    $Global:Error.Clear()
    Remove-GitItem -RepoRoot $repoRoot -Path $filesToStage -ErrorAction SilentlyContinue
}

function WhenFileIsStagedByPipeline {
    $Global:Error.Clear()
    , $filesToStage | Remove-GitItem -RepoRoot $repoRoot -ErrorAction SilentlyContinue
}

function ThenFileShouldBeStaged {
    param(
        [string[]]
        $Path
    )

    foreach ( $pathItem in $Path ) {
        It ('should stage {0}' -f $pathItem) {
            $status = Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $pathItem
            $status.ChangedInIndex | Should -HaveCount 1
        }
    }
}

function ThenFileShouldNotBeStaged {
    param(
        [string[]]
        $Path
    )

    foreach ( $pathItem in $Path ) {
        It ('should not stage {0}' -f $pathItem) {
            $status = Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $pathItem 6>$null
            $status.ChangedInIndex | Should -BeNullOrEmpty
        }
    }
}

function ThenFileShouldBeDeleted {
    param(
        [string[]]
        $Path
    )

    foreach ( $pathItem in $Path ) {
        It ('should have deleted {0}' -f $pathItem) {
            Test-Path -Path (join-Path -Path $repoRoot -ChildPath $pathItem) | Should -be $false
        }
    }
}

function ThenNoErrorShouldBeThrown {
    $Global:Error | Should -BeNullOrEmpty
}
function ThenErrorShouldBeThrown {
    param(
        [String]
        $ExpectedError
    )
    It ('Should throw an error matching ''{0}''' -f $ExpectedError) {
        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -Not -BeNullOrEmpty
    }
}

Describe Remove-GitItem {
    Describe 'When File is moved from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileToStage -Name 'foo.bar'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When multiple Files are moved from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar', 'bar.fooo'
        GivenFileToStage  -Name 'foo.bar', 'bar.fooo'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar', 'bar.fooo'
        ThenFileShouldBeDeleted -Path 'foo.bar', 'bar.fooo'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When multiple Files are moved from git repository correctly via the pipeline' {
        GivenRepositoryWithFile -Name 'foo.bar', 'bar.fooo'
        GivenFileToStage  -Name 'foo.bar', 'bar.fooo'
        WhenFileIsStagedByPipeline
        ThenFileShouldBeStaged -Path 'foo.bar', 'bar.fooo'
        ThenFileShouldBeDeleted -Path 'foo.bar', 'bar.fooo'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When File is moved from git repository correctly via the pipeline' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileToStage -Name 'foo.bar'
        WhenFileIsStagedByPipeline
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When File is already removed from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileIsDeleted -Name 'foo.bar'
        GivenFileToStage  -Name 'foo.bar'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When File doesnt exist in the repository' {
        GivenRepositoryWithFile -Name 'a.file'
        GivenFileToStage  -Name 'different.file'
        WhenFileIsStaged
        ThenFileShouldNotBeStaged -Path 'different.file'
        ThenNoErrorShouldBeThrown
    }

    Describe 'When invalid repository is passed' {
        GivenIncorrectRepo -RepoName 'foobar'
        WhenFileIsStaged
        ThenErrorShouldBeThrown -ExpectedError 'Can''t find a repository in ''foobar'''
    }
}
