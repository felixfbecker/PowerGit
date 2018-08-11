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

$output = $null

function GivenLocalRepository {
    param(
        $Path
    )

    New-GitRepository -Path $Path
}

function GivenThereAreNoErrors {
    $Global:Error.Clear()
}

function ThenRepositoryWasClonedTo {
    param(
        $Destination,

        [Switch]
        $WithNoOutput
    )

    It 'should succeed' {
        $Global:Error.Count | Should Be 0
    }
    It 'should clone the repository' {
        git -C $Destination status --porcelain 2>&1 | Should BeNullOrEmpty
        $LASTEXITCODE | Should Be 0
    }

    if ( $WithNoOutput ) {
        It 'should return no output' {
            $output | Should BeNullOrEmpty
        }
    } else {
        It 'should return [IO.DirectoryInfo] for repository' {
            $output | Should BeOfType ([IO.DirectoryInfo])
            $output.FullName | Should Be (Join-Path -Path $Destination -ChildPath '.git\')
        }
    }
}

function WhenCloningRepository {
    param(
        $Source,
        $To,
        [Switch]
        $PassThru
    )

    $script:output = Copy-GitRepository -Source $Source -DestinationPath $To -PassThru:$PassThru
}

Describe 'Copy-GitRepository when cloning a remote repository' {
    $destination = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'GitAutomationCore'
    GivenThereAreNoErrors
    WhenCloningRepository 'https://github.com/felixfbecker/stringscore' -To $destination
    ThenRepositoryWasClonedTo $destination -WithNoOutput
}

Describe 'Copy-GitRepository when cloning a repository with relative paths' {
    Push-Location -Path (Resolve-TestDrivePath)
    try {
        GivenLocalRepository 'fubar'
        GivenThereAreNoErrors
        WhenCloningRepository 'fubar' -To 'snafu'
        ThenRepositoryWasClonedTo (Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'snafu') -WithNoOutput
    } finally {
        Pop-Location
    }
}

Describe 'Copy-GitRepository when cloning a repository with the -PassThru switch' {
    $tempRoot = (Resolve-TestDrivePath)
    $destinationPath = Join-Path -Path $tempRoot -ChildPath 'asdhd'
    GivenLocalRepository 'fubar'
    GivenThereAreNoErrors
    WhenCloningRepository 'fubar' -To $destinationPath -PassThru
    ThenRepositoryWasClonedTo $destinationPath
}
