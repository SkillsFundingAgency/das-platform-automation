# das-platform-automation

[![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/das-platform-automation?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=1538&branchName=master)

## Contents

<!-- TOC -->

- [das-platform-automation](#das-platform-automation)
    - [Contents](#contents)
    - [About](#about)
- [Helper Script Checklist](#helper-script-checklist)
- [Code Layout and Formatting](#code-layout-and-formatting)
    - [EditorConfig](#editorconfig)
        - [EditorConfig Installation](#editorconfig-installation)
        - [Using EditorConfig](#using-editorconfig)
        - [Troubleshooting EditorConfig](#troubleshooting-editorconfig)
    - [VS Code Settings](#vs-code-settings)
- [Documentation](#documentation)
    - [Comment Based Help](#comment-based-help)
    - [Naming Conventions](#naming-conventions)
- [Testing](#testing)
    - [Pester](#pester)
        - [Introduction](#introduction)
        - [How it's Used](#how-its-used)
        - [How to Write a Pester Unit Test](#how-to-write-a-pester-unit-test)
    - [PSScriptAnalyzer](#psscriptanalyzer)
        - [Introduction](#introduction-1)
        - [How it's Used](#how-its-used-1)
- [References and Further Reading](#references-and-further-reading)

<!-- /TOC -->

## About

This repository contains PowerShell helper scripts to be used locally and in Azure Pipelines for the Digital Apprenticeship Service (DAS). It also includes a checklist for creating new helper scripts, a code layout and formatting guide, script documentation and testing details.

# Helper Script Checklist

Use the following as a checklist for creating new helper scripts.

|Requirement| Description                     | Additional Notes
|-| - | - |
|Should| Work locally and on build agents.| Scripts should work on any environment not just build agents. |
|Should| Contain minimal yet descriptive inline comments. | Consider using Write-Verbose or Write-Debug, useful for progress or status information. |
|Should| Contain comment based help.| For example a Synopsis, Description and Example(s). |
|Should| Have a Pester unit test which passes all tests.| Save in Tests folder. |
|Should| Pester unit test filename to start UTxxx. | Increment by one. |
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
| EditorConfig | Provides an overview of how EditorConfig is used to enforce a consistent coding style. |
| VS Code Settings | Provides an overview of how settings.json can be used to enforce consistency for VS Code settings. |

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

## VS Code Settings

TO DO

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
| Pester | Provides an introduction to Pester and how it is used to test the infrastructure scripts.  |
| PSScriptAnalyzer | Provides an introduction to PSScriptAnalyzer and how it is used to check code quality.  |

## Pester

### Introduction

### How it's Used

### How to Write a Pester Unit Test

## PSScriptAnalyzer

### Introduction

### How it's Used

# References and Further Reading

| Reference | URL |
| -- | -- |
| The PowerShell Best Practices and Style Guide | https://poshcode.gitbooks.io/powershell-practice-and-style/ |
| Overview of PowerShell Code Quality | https://mathieubuisson.github.io/powershell-code-quality-pscodehealth/  |
