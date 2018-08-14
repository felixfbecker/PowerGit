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

## Cheat sheet

| `git`                                                    | PowerGit                                                          |
| -------------------------------------------------------- | ----------------------------------------------------------------- |
| `git clone https://github.com/felixfbecker/PowerGit.git` | `Copy-GitRepository https://github.com/felixfbecker/PowerGit.git` |
| `git status`                                             | `Get-GitRepositoryStatus`                                         |
| `git add README.md`                                      | `Add-GitItem README.md`                                           |
| `git commit -m "message"`                                | `Save-GitCommit -m "message"`                                     |
| `git log`                                                | `Get-GitCommit`                                                   |
| `git log --oneline`                                      | `Get-GitCommit \| Format-Table`                                    |
| `git log -p`                                             | `Get-GitCommit -p`                                                |

## Tips

- Run `(Get-Module PowerGit).ExportedCommands` to see a list of all available commands
- All commands have help through `Get-Help`
- PowerShell allows shortening commands if the abbreviation is umambiguous. That means you can write `Copy-GitRepo` instead of `Copy-GitRepository`
- Same for parameters: you can write `-m` instead of `-Message`, just like with native git
- Commands and parameters in PowerShell are case-insenstive. If you prefer writing everything lowercase, you can do that

## Output formats

PowerGit includes format views that resemble most [git pretty formats](https://git-scm.com/docs/pretty-formats) (Oneline, Short, Medium, Full, Fuller).
Just like with native `git`, by default "Medium" is used.
You can use a different format view by piping a commit object into `Format-List -View $view` (or short `fl -v`) where `$view` is one of the view names mentioned above (except Oneline, for which you must use `Format-List`)

To enable paging like with git, pipe into `Out-Host -Paging` (or short `oh -p`).
