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

$repoRoot = $null
[LibGit2Sharp.Signature]$signature = $null

function GivenRepository {
    $script:repoRoot = New-GitTestRepo
}

function GivenSignature {
    $script:signature = New-GitSignature -Name 'Fubar Snafu' -EmailAddress 'fizzbuzz@example.com'
}

function Init {
    $script:repoRoot = $null
    $script:signature = $null
}

Describe 'Save-GitCommit when committing changes' {
    GivenRepository
    GivenSignature
    Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
    Add-GitItem -Path 'file1' -RepoRoot $repoRoot
    $commit = Save-GitCommit -Message 'fubar' -RepoRoot $repoRoot -Signature $signature
    It 'should return a commit object' {
        $commit.pstypenames | Where-Object { $_ -eq 'LibGit2Sharp.Commit' } | Should Not BeNullOrEmpty
    }
    It 'should commit everything' {
        git -C $repoRoot status --porcelain | Should BeNullOrEmpty
    }

    Context 'the commit object returned' {
        It 'should have an author' {
            $commit.Author | Should Not BeNullOrEmpty
            $commit.Author.Email | Should -Be $signature.Email
            $commit.Author.Name | Should -Be $signature.Name
            $commit.Committer | Should Not BeNullOrEmpty
            $commit.Committer | Should -Be $commit.Author
        }
        It 'should have a message' {
            $commit.Message | Should Not BeNullOrEmpty
            $commit.MessageShort | Should Not BeNullOrEmpty
            $commit.Message | Should -Be "fubar`n"
            $commit.MessageShort | Should -Be 'fubar'
        }

        It 'should have an ID' {
            $commit.Id | Should Not BeNullOrEmpty
            $commit.Sha | Should Not BeNullOrEmpty
            $commit.Id | Should -Be $commit.Sha
        }

        It 'should have an encoding' {
            $commit.Encoding | Should -Be 'UTF-8'
        }
    }
}

Describe 'Save-GitCommit when nothing to commit' {
    Clear-Error
    GivenRepository
    GivenSignature
    Save-GitCommit -Message 'fubar' -RepoRoot $repoRoot -Signature $signature
    $commit = Save-GitCommit -Message 'fubar' -RepoRoot $repoRoot -WarningAction SilentlyContinue
    It 'should commit nothing' {
        $commit | Should BeNullOrEmpty
    }
    It ('should write no errors') {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Save-GitCommit.when committing in the current directory' {
    GivenRepository
    Push-Location $repoRoot
    try {
        $commit = Save-GitCommit -Message 'fubar'
        It ('should commit') {
            $commit | Should -Not -BeNullOrEmpty
        }

        $commit.Sha | Should -Be (Get-GitCommit -Revision $commit.Sha -RepoRoot $repoRoot).Sha
    } finally {
        Pop-Location
    }
}
