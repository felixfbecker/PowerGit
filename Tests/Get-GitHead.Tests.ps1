& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

Describe Get-GitHead {
    It 'should return the current branch' {
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'
        $branch = Get-GitHead -RepoRoot $repo -ErrorAction Stop
        $branch.Name | Should -Be 'master'
        $branch.Tip.Sha | Should -Be $c1.Sha
        $branch.IsCurrentRepositoryHead | Should -Be $true
    }

    It 'should throw an error when passed an invalid repository' {
        $branches = Get-GitHead -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue -ErrorVariable headErrors
        $branches | Should -BeNullOrEmpty
        $headErrors | Should -HaveCount 1
        $headErrors | Should -Match 'does not exist'
    }
}

