# PowerGit

[![powershellgallery](https://img.shields.io/powershellgallery/v/PowerGit.svg)](https://www.powershellgallery.com/packages/PowerGit)
[![downloads](https://img.shields.io/powershellgallery/dt/PowerGit.svg?label=downloads)](https://www.powershellgallery.com/packages/PowerGit)
[![builds](https://img.shields.io/vso/build/felixfbecker/3de339ed-a9c4-4785-b858-fb695061bbf4/2.svg)](https://felixfbecker.visualstudio.com/PowerGit/_build/latest?definitionId=2&branch=master)
[![codecov](https://codecov.io/gh/felixfbecker/PowerGit/branch/master/graph/badge.svg)](https://codecov.io/gh/felixfbecker/PowerGit)
![license](https://img.shields.io/github/license/felixfbecker/PowerGit.svg)

`git` with the power of the object pipeline and familiar output formatting.  
Uses `LibGit2Sharp`, so does not require any git executable to be installed.

Forked from `GitAutomation` but made to work PSCore (Linux, macOS, Windows).

## Goals

- Utilize the object pipeline for outputs and inputs
- Provide default output formatting that matches native `git` output
- Follow PowerShell naming conventions
- Stay as close as possible to native `git` behaviour
- High test coverage
- Run cross-platform on Windows, macOS and Linux
- Interop with [PSGitHub](https://github.com/pcgeek86/PSGitHub)

## How to use

### Cloning

Use `Copy-GitRepository`. It works just like `git clone`, but with fancier progress reporting:

![Copy-GitRepository demo](./Screenshots/Copy-GitRepository.svg)

### Log

Use `Get-GitCommit` to query the commits in the repository.  

To page the output, make sure to pipe into `Out-Host -Paging` (short `oh -p`).

Multiple [git pretty formats](https://git-scm.com/docs/pretty-formats) are supported.
The default output mirrors the default git `medium` output:

![Get-GitCommit demo](./Screenshots/Get-GitCommit.svg)

`short`, `full` and `fuller` are supported as alternative list views, e.g. `Get-GitCommit | Format-List -View Fuller` (or short `fl -v fuller`).

For `oneline`, simply pipe to `Format-Table` (short `ft`).

![Get-GitCommit | Format-List -View Oneline demo](./Screenshots/Get-GitCommit-Oneline.svg)

Pass `-Patch` (short `-p`) like in native git to include colored diffs.

![Get-GitCommit -Patch demo](./Screenshots/Get-GitCommit-Patch.svg)

### Add

### Commit

### Push

### Pull

### Merge

### Rebase

### Compare

## Cheat sheet

| `git`                                                    | PowerGit                                                          |
| -------------------------------------------------------- | ----------------------------------------------------------------- |
| `git clone https://github.com/felixfbecker/PowerGit.git` | `Copy-GitRepository https://github.com/felixfbecker/PowerGit.git` |
| `git status`                                             | `Get-GitRepositoryStatus`                                         |
| `git add README.md`                                      | `Add-GitItem README.md`                                           |
| `git commit -m "message"`                                | `Save-GitCommit -m "message"`                                     |
| `git log`                                                | `Get-GitCommit`                                                   |
| `git log --oneline`                                      | `Get-GitCommit \| Format-Table`                                   |
| `git log -p`                                             | `Get-GitCommit -p`                                                |
| `git show be1db11`                                       | `Get-GitCommit be1db11 -Patch`                                    |
| `git rev-parse HEAD`                                     | `(Get-GitCommit HEAD).Sha`                                        |

## Tips

- Run `(Get-Module PowerGit).ExportedCommands` to see a list of all available commands
- All commands have help through `Get-Help`
- PowerShell allows shortening commands if the abbreviation is umambiguous. That means you can write `Copy-GitRepo` instead of `Copy-GitRepository`
- Same for parameters: you can write `-m` instead of `-Message`, just like with native git
- Commands and parameters in PowerShell are case-insenstive. If you prefer writing everything lowercase, you can do that
