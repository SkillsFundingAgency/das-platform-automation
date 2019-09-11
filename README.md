# das-platform-automation
PowerShell helper scripts to be used locally and in Azure Pipelines for the Digital Apprenticeship Service (DAS). It includes the following:

- A checklist for creating new scripts including "shoulds" and "should not".
- Code layout and formatting guidance.
- Writing Pester tests and using PSScriptAnalyzer to ensure best practise.

|Build Status|
|-|
|[![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/das-platform-automation?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=1538&branchName=master)|

## Contents

<!-- TOC -->

- [das-platform-automation](#das-platform-automation)
    - [Contents](#contents)
- [Helper Script Checklist](#helper-script-checklist)
- [Code Layout and Formatting](#code-layout-and-formatting)
    - [EditorConfig](#editorconfig)
        - [EditorConfig Installation](#editorconfig-installation)
        - [Using EditorConfig](#using-editorconfig)
        - [Troubleshooting EditorConfig](#troubleshooting-editorconfig)
    - [Visual Studio Code Workspace Settings](#visual-studio-code-workspace-settings)
- [Documentation](#documentation)
    - [Comment Based Help](#comment-based-help)
    - [Naming Conventions](#naming-conventions)
- [Testing](#testing)
    - [Pester](#pester)
        - [Introduction](#introduction)
        - [How it's Used](#how-its-used)
    - [PSScriptAnalyzer](#psscriptanalyzer)
        - [Introduction](#introduction-1)
        - [How it's Used](#how-its-used-1)
- [GitHub Releases and Versioning](#github-releases-and-versioning)
    - [GitHub Releases](#github-releases)
        - [Azure DevOps GitHub Release Task](#azure-devops-github-release-task)
    - [Release Versioning](#release-versioning)
- [References and Further Reading](#references-and-further-reading)

<!-- /TOC -->

# Helper Script Checklist

Use the following as a checklist when creating new helper scripts:

|Requirement| Description                     | Additional Notes
|-| - | - |
|Should| Work locally and on build agents.| Scripts should work on any environment not just build agents. |
|Should| Contain minimal yet descriptive inline comments. | Consider using Write-Verbose or Write-Debug, useful for progress or status information. |
|Should| Contain comment based help.| For example a Synopsis, Description and Example(s). |
|Should| Have a Pester unit test which passes all tests.| Save under the tests folder. |
|Should| Prefix Pester test files with 'UT'. | See tests folder for examples. |
|Should| Pester test files to include the word 'Tests' before the '.ps1' extension in the filename. | See tests folder for examples. |
|Should| Use Az module cmdlets only.| This is the Microsoft intended PowerShell module for interacting with Azure. Replaces AzureRM module. |
|Should| Follow the naming covention. | See [Naming Conventions](#naming-conventions)    |
|Should| Adhere to .editorconfig. | Stored in .editorconfig |
|Should| Adhere to .vscode settings. | Stored in .vscode/settings.json|
|Should| Use a forward slash ('/') in paths. | This is to ensure compatibility on both Windows and Linux platforms. |
|Should| Use -ErrorAction per cmdlet. | This is to ensure useful errors are not suppressed globally. |
|Should NOT| Use aliases. | This can cause less readable code. |
|Should NOT | Hard code credentials (especially plain text). | Expose sensitive information. |
|Should NOT | Use Write-Host. | As explained by [Jeffrey Snover](http://www.jsnover.com/blog/2013/12/07/write-host-considered-harmful/) and [Don Jones](https://www.itprotoday.com/powershell/what-do-not-do-powershell-part-1) |
|Should NOT | Set global error actions. | Using a global error action, particularly to suppress errors will hinder troubleshooting.  |

# Code Layout and Formatting

This section provides an overview of the following:

| Section Header | Description |
| - | - |
| EditorConfig | Provides an overview of how EditorConfig is used to enforce a consistent coding style, as well as how to install and use the EditorConfig extension in Visual Studio Code.  |
| Visual Studio Code Workspace Settings | Provides an overview of how the Visual Studio Code (VS Code) Workspace Settings are used to ensure specific settings are shared across the team. This is to enforce consistency across VS Code installs. |

## EditorConfig

In order to maintain a consistent coding style, an EditorConfig file is used. The file `.editorconfig` contains the required styles. The EditorConfig file defines styles such as indentation size, indentation style, newline rules etc. The full list of supported properties in VS Code can be found [here.](https://github.com/editorconfig/editorconfig-vscode#supported-properties).

`Tip: Ensure this is applied before committing and/or raising a pull request`

### EditorConfig Installation

EditorConfig can be installed as a Visual Studio Code extension. Search for and install `EditorConfig for VS Code`. The VS Code Marketplace has more information [here](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig).

For further information view the official website [here.](https://editorconfig.org/)

### Using EditorConfig

The EditorConfig extension is activated whenever you open a new text editor, switch tabs into an existing one or focus into the editor you already have open. When activated, it uses EditorConfig to resolve the configuration for that particular file and applies any relevant editor settings.

The following styles are applied on save:

- end_of_line
- insert_final_newline
- trim_trailing_whitespace

The following styles are applied by using Format Document (Shift + Alt + F on Windows):

- indent_style
- indent_size
- tab_width

### Troubleshooting EditorConfig

To troubleshoot EditorConfig and see what is being applied to your file, click `OUTPUT` in Visual Studio Code and in the drop down select `Editorconfig`. This will provide an output of what EditorConfig is applying. The following is an example of a final newline being inserted:

~~~~
das-platform-automation/Infrastructure-Scripts/Get-AzStorageAccountConnectionString.ps1: Using EditorConfig core...
Infrastructure-Scripts/Get-AzStorageAccountConnectionString.ps1: setEndOfLine(LF)
Infrastructure-Scripts/Get-AzStorageAccountConnectionString.ps1: editor.action.trimTrailingWhitespace
Infrastructure-Scripts/Get-AzStorageAccountConnectionString.ps1: insertFinalNewline(LF)
~~~~

## Visual Studio Code Workspace Settings

The Visual Studio Code (VS Code) Workspace settings are located under the `.vscode/settings.json`. The settings are scoped to the open workspace and overrides the user scope. The settings are applied when the workspace is opened. The settings used are specific to PowerShell code formatting.

# Documentation

This section provides an overview of the following:

| Section Header | Description |
| - | - |
| Comment Based Help | Provides an overview of what help should be used in the infrastructure scripts. |
| Naming Conventions | Provides a table containing the case type to use for identifiers as well as examples of each. |

## Comment Based Help

Scripts and functions should contain comment based help that is compatible with **Get-Help**.

The help should consist of the following elements:

- Synopsis
- Description
- A parameter description for each parameter in the Param() block
- At least one example demonstrating how the script can be executed

For further information see [about_Comment_Based_Help](https://github.com/PowerShell/PowerShell-Docs/blob/staging/reference/5.1/Microsoft.PowerShell.Core/About/about_Comment_Based_Help.md)

## Naming Conventions

To ensure a consistant readable format, use the following naming conventions:

| Identifier                     | Case      | Example      |
| ------------------------------ | --------- | ------------ |
| Global variables               | Pascal    | $Global:$Variable |
| Parameter variables            | Pascal    | $ParameterVariable |
| Local Variables                | Pascal    | $LocalVariable |
| Language keywords              | lowercase    | foreach, -eq, try, catch, switch |
| Process block keywords | lowercase | begin, process, end |
| Keywords in comment-based help | UPPERCASE | .SYPNOSIS, .EXAMPLE |
| Two letter acronyms            | UPPERCASE acronym    | VMName |
| Three letter (or more) acronyms | Pascal    | AbcName |
| Constants / Built-in Variables | Pascal and uppercase acronym    | Microsoft maintains Pascal in their built-in variables, i.e. $PSVersionTable, $PSScriptRoot. Tab autocomplete in PowerShell for reference. |
| Constants / Built-in Variables - Exceptions | camel | Keep camel case for built-in variables, i.e. $true, $false, $null. Tab autocomplete in PowerShell for reference. |
| Module Names                   | Pascal    ||
| Function or cmdlet names       | Pascal    ||
| Class Names                    | Pascal    ||
| Attribute Names                | Pascal    ||
| Public fields or properties    | Pascal    ||

# Testing

This section provides an overview of the following:

| Section Header | Description |
| - | - |
| Pester | Provides an introduction to Pester, how it is used to test the infrastructure scripts and how to write a Pester test.  |
| PSScriptAnalyzer | Provides an introduction to PSScriptAnalyzer and how it is used to check code quality.  |

## Pester

### Introduction

Pester is a test framework for PowerShell. It provides a language that allows you to define test cases, and the `Invoke-Pester` cmdlet to execute these tests and report the results. It is used to run a series of automated tests to ensure a new piece of code passes the defined criteria.

Read more about [Pester](https://github.com/pester/Pester)

### How it's Used

Pester is used to automate testing of the scripts under `infrastructure-scripts`. while working with a local branch of das-platform-automation, Pester can be invoked locally without having to commit changes to the remote repository. This is useful to ensure tests pass before running a build in Azure Pipelines with a pull request to master or a merge of the branch into master.

By default, Invoke-Pester runs all *.Tests.ps1 files. For example, to run all Pester tests in the tests folder run the following:

~~~~powershell
# Change directory into tests folder
cd ..\das-platform-automation\tests\

# Run Pester
Invoke-Pester
~~~~

To run a specific test file:

~~~~powershell
# Change directory into tests folder
cd ..\das-platform-automation\tests\

# Run Pester
Invoke-Pester -Script .\UT.Get-AzStorageAccountConnectionString.Tests.ps1
~~~~

## PSScriptAnalyzer

### Introduction
PSScriptAnalyzer is a static code checker for Windows PowerShell modules and scripts. PSScriptAnalyzer checks the quality of Windows PowerShell code by running a set of rules. The rules are based on PowerShell best practices identified by PowerShell Team and the community.

Read more about [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)

### How it's Used

The script `QT001.Quality.Tests.ps1` under the tests folder imports all .ps1 files under the infrastructure-scripts folder, for each of those .ps1 files a Pester test called `Script code quality tests` is run to confirm that each script passes the included PSScriptAnalyzer rules. If one or more rule fails then the Pester test fails, and therefore the build in Azure DevOps will also fail.

You can also run PSScriptAnalyzer manually while writing scripts:

~~~~powershell
# Change directory into infrastructure-scripts folder
cd ..\das-platform-automation\infrastructure-scripts\

# Exclude rules as per the QT001.Qaulity.Tests.ps1 script
$Rules = Get-ScriptAnalyzerRule
$ExcludeRules = @(
    "PSAvoidUsingWriteHost",
    "PSAvoidUsingEmptyCatchBlock",
    "PSAvoidUsingPlainTextForPassword"
)

# Run PSScriptAnalyzer against example script with verbose output
Invoke-ScriptAnalyzer -Path .\Get-AzStorageAccountConnectionString.ps1 -ExcludeRule $ExcludeRules -Verbose
~~~~

# GitHub Releases and Versioning

This section provides an overview of the following:

| Section Header | Description |
| - | - |
| GitHub Releases | This section provides an overview of the das-platform-automation repository release and how to use the Azure DevOps GitHub Release Task within a release pipeline. |
| Release Versioning | This section provides an overview of how to ensure a consistent release versioning policy is used, and GitHub releases are appropriately incremented. |

## GitHub Releases

The das-platform-automation repository is published as a release on GitHub.com. Releases provide a list of changes made to a specific release as well as links to the assets available. Using GitHub releases enables the use of the Azure DevOps GitHub Release Task so that the scripts in das-platform-automation can be consumed within Azure Pipeline deployments.

### Azure DevOps GitHub Release Task

To use the das-platform-automation repository as a GitHub Release Task follow these steps:

- Edit a Pipeline
- Add a new Artifact to a Pipeline using the `GitHub Release Task` artifact type. 
- Select the appropriate `Service connection` in the dropdown. 
- Use the ellipses button to open the `Select a repository` picker window. 
- Search for `SkillsFundingAgency/das-platform-automation` and click the result.
- Click the `Add` button

You can now use assets in the das-platform-automation releases in Azure Pipelines tasks. 

## Release Versioning

To ensure a consistent release versioning policy the following can be used as a reference:

| Increment Type | When to use | How to use |
| -- | -- | -- |
| Major | Breaking changes to scripts | Add `+semver: major` to pull request title. |
| Minor | Addition of new scripts | Add `+semver: minor` to pull request title. |
| Patch | Non-breaking changes to existing scripts | Automatically incremented for every merge if a major or minor is not defined. |

[GitVersion](https://gitversion.readthedocs.io/en/latest/) is used to achieve release versioning. Read more about [Version Incrementing](https://gitversion.readthedocs.io/en/latest/more-info/version-increments/).

# References and Further Reading

| Reference | URL |
| -- | -- |
| The PowerShell Best Practices and Style Guide | https://poshcode.gitbooks.io/powershell-practice-and-style/ |
| Overview of PowerShell Code Quality | https://mathieubuisson.github.io/powershell-code-quality-pscodehealth/ |
| Pester GitHub| https://github.com/pester/Pester
| PSScriptAnalyzer | https://github.com/PowerShell/PSScriptAnalyzer
