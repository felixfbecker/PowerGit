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

Describe 'Get-GitRepositoryStatus when getting status' {
    $repoRoot = New-GitTestRepo

    $modifiedPath = Join-Path -Path $repoRoot -ChildPath 'modified'
    '' | Set-Content -Path $modifiedPath

    $renamedPath = Join-Path -Path $repoRoot -ChildPath 'renamed'
    '' | Set-Content -Path $renamedPath

    $removedPath = Join-Path -Path $repoRoot -ChildPath 'removed'
    '' | Set-Content -Path $removedPath

    $missingPath = Join-Path -Path $repoRoot -ChildPath 'missing'
    '' | Set-Content -Path $missingPath

    $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
    It 'should show untracked files' {
        $status | Select-Object -ExpandProperty 'State' | ForEach-Object { $_ | Should -Be ([LibGit2Sharp.FileStatus]::NewInWorkdir) }
    }

    Add-GitItem -Path $modifiedPath -RepoRoot $repoRoot
    Add-GitItem -Path $renamedPath -RepoRoot $repoRoot
    Add-GitItem -Path $removedPath -RepoRoot $repoRoot
    Add-GitItem -Path $missingPath -RepoRoot $repoRoot

    $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
    It 'should show new files' {
        $status | Where-Object { $_.FilePath -ne 'untracked' } | Select-Object -ExpandProperty 'State' | ForEach-Object { $_ |  Should -Be ([LibGit2Sharp.FileStatus]::NewInIndex) }
    }

    Save-GitCommit -Message 'testing status' -RepoRoot $repoRoot

    'modified' | Set-Content -Path $modifiedPath

    It 'should show files modified in the working directory' {
        Get-GitRepositoryStatus -RepoRoot $repoRoot | Where-Object { $_.FilePath -eq 'modified' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::ModifiedInWorkdir)
    }

    Add-GitItem -Path $modifiedPath -RepoRoot $repoRoot
    It 'should show staged files' {
        Get-GitRepositoryStatus -RepoRoot $repoRoot | Where-Object { $_.FilePath -eq 'modified' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::ModifiedInIndex)
    }

    git -C $repoRoot rm $removedPath
    It 'should show removed files' {
        Get-GitRepositoryStatus -RepoRoot $repoRoot | Where-Object { $_.FilePath -eq 'removed' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromIndex)
    }

    Remove-Item -Path $missingPath
    It 'should show missing files' {
        Get-GitRepositoryStatus -RepoRoot $repoRoot | Where-Object { $_.FilePath -eq 'missing' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromWorkdir)
    }

    git -C $repoRoot mv $renamedPath (Join-Path -Path $repoRoot -ChildPath 'renamed2')
    It 'should show renamed files' {
        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
        $status | Where-Object { $_.FilePath -eq 'renamed' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromIndex)
        $status | Where-Object { $_.FilePath -eq 'renamed2' } | Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::RenamedInIndex)
    }
}

Describe 'Get-GitRepositoryStatus when items are ignored' {
    $repoRoot = New-GitTestRepo
    "file1`ndir1" | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath '.gitignore')
    '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file1')

    $dir1Path = Join-Path -Path $repoRoot -ChildPath 'dir1'
    New-Item -Path $dir1Path -ItemType 'Directory'
    '' | Set-Content -Path (Join-Path -Path $dir1Path -ChildPath 'file2') -Force

    Context 'IncludeIgnored switch isn''t used' {
        It 'should not show ignored files' {
            Get-GitRepositoryStatus -RepoRoot $repoRoot | Select-Object -ExpandProperty 'FilePath' | Should -Be '.gitignore'
        }
    }

    Context 'IncludeIgnored switch is used' {
        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot -IncludeIgnored
        It 'should show ignored files' {
            $status | Where-Object { $_.FilePath -eq '.gitignore' } | Should Not BeNullOrEmpty
            $status | Where-Object { $_.FilePath -eq 'file1' } | Should Not BeNullOrEmpty
        }
        It 'should show files under ignored directories' {
            $status | Where-Object { $_.FilePath -eq 'dir1/file2' } | Should Not BeNullOrEmpty
        }
    }
}

Describe 'Get-GitRepositoryStatus when run without a repo root parameter' {
    $repoRoot = New-GitTestRepo
    '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file1')
    $subDir = Join-Path -Path $repoRoot -ChildPath 'dir1'
    New-Item -Path $subDir -ItemType 'Directory'
    '' | Set-Content -Path (Join-Path -Path $subDir -ChildPath 'file2')
    Push-Location -Path $subDir
    try {
        $status = Get-GitRepositoryStatus
        It 'should get the status of all files in the repository' {
            $status | Where-Object { $_.FilePath -eq 'file1' } | Should Not BeNullOrEmpty
            $status | Where-Object { $_.FilePath -eq 'dir1/file2' } | Should Not BeNullOrEmpty
        }
    } finally {
        Pop-Location
    }
}

Describe 'Get-GitRepositoryStatus when getting status of explicit paths' {
    $repoRoot = New-GitTestRepo
    $file1Path = Join-Path -Path $repoRoot -ChildPath 'file1'
    '' | Set-Content -Path $file1Path
    '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file2')
    '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file3')


    Context 'Path parameter contains absolute paths' {
        It 'should get only paths specified' {
            Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $file1Path | Select-Object -ExpandProperty 'FilePath' | Should -Be 'file1'
        }
    }


    Push-Location -Path $repoRoot
    try {
        Context 'Path parameter is single path' {
            It 'should get only a specific path' {
                Get-GitRepositoryStatus -Path 'file1' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'file1'
            }
        }

        Context 'Path parameter is multiple paths' {
            It 'should get only paths specified' {
                Get-GitRepositoryStatus -Path 'file1', 'file2' | Select-Object -ExpandProperty 'FilePath' | Should Match 'file(1|2)'
            }
        }

        Context 'Path parameter contains wildcard paths' {
            It 'should get only paths specified' {
                Get-GitRepositoryStatus -Path '*1' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'file1'
            }
        }

        Context 'Path parameter contains relative path to current directory' {
            $dir1Path = Join-Path -Path $repoRoot -ChildPath 'dir1'
            New-Item -Path $dir1Path -ItemType 'directory'
            Push-Location -Path $dir1Path
            try {
                '' | Set-Content -Path 'file4'
                It 'should only get paths under that directory' {
                    Get-GitRepositoryStatus '.' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'dir1/file4' # Expect forward slashes from LibGit2Sharp
                }

                It 'should get paths under parent directory' {
                    $status = Get-GitRepositoryStatus '..'
                    $status | Select-Object -ExpandProperty 'FilePath' | Where-Object { $_ -match 'file(1|2|3)$' } | Should Not BeNullOrEmpty
                    $status | Select-Object -ExpandProperty 'FilePath' | Where-Object { $_ -match 'file4$' } | Should Not BeNullOrEmpty
                }
            } finally {
                Pop-Location
            }

            It 'should get specific item under a directory' {
                Get-GitRepositoryStatus 'dir1/file4' | Select-Object -ExpandProperty 'FilePath' | Should Not BeNullOrEmpty
            }
        }
    } finally {
        Pop-Location
    }

    Context 'Path parameter is relative path in another repository' {
        $dir1Path = Join-Path -Path $repoRoot -ChildPath 'dir1'
        '' | Set-Content -Path (Join-Path -Path $dir1Path -ChildPath 'file4')
        It 'should only get paths under that directory' {
            Get-GitRepositoryStatus 'dir1' -RepoRoot $repoRoot | Select-Object -ExpandProperty 'FilePath' | Should -Be 'dir1/file4' # Expect forward slashes from LibGit2Sharp
        }
    }
}

