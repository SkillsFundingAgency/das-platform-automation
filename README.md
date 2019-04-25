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
    - [VS Code Settings](#vs-code-settings)
    - [Comment Based Help](#comment-based-help)
    - [PlatyPS](#platyps)
    - [Naming Conventions](#naming-conventions)
- [Testing](#testing)
    - [Pester](#pester)
    - [PSScriptAnalyzer](#psscriptanalyzer)
    - [PSCodeHealth](#pscodehealth)
- [References and Further Reading](#references-and-further-reading)

<!-- /TOC -->

## About
This repository contains PowerShell helper scripts to be used locally and in Azure Pipelines for the Digital Apprenticeship Service (DAS). It also includes a checklist for creating new helper scripts, a code layout and formatting guide, script documentation and testing details.

# Helper Script Checklist
Use the following as a checklist for creating new helper scripts.

|Requirement| Description                     | Additional Notes
|-| - | - |
|Should| Work locally and on build agents.| |
|Should| Contain minimal yet descriptive inline comments. | Consider using Write-Verbose or Write-Debug, useful for progress or status information. |
|Should| Contain comment based help.|     |
|Should| Have external help markdown documentation.| Generated using PlatyPS. |
|Should| Have a Pester unit test which passes all tests.| Save in Tests folder.     |
|Should| Pester unit test filename to start UTxxx | Increment by one. |
|Should| Use Az module cmdlets only.|     |
|Should| Follow the naming covention. | See [Naming Conventions](#naming-conventions)    |
|Should| Adhere to .editorconfig | Stored in .editorconfig |
|Should| Adhere to .vscode settings | Stored in .vscode/settings.json|
|Should| Use a forward slash in paths. | This is to ensure comptability on both Windows and Linux. |
|Should Not| Use aliases. |This can cause less readable code. |
|Should Not | Hard coded credentials (especially plain text) | Expose sensitive information. |
|Should Not | Use Write-Host. | As explained by [Jeffrey Snover](http://www.jsnover.com/blog/2013/12/07/write-host-considered-harmful/) and [Don Jones](https://www.itprotoday.com/powershell/what-do-not-do-powershell-part-1) |
| Should | Use -ErrorAction per cmdlet. |  |
|Should Not | Set global error actions. | Using a global error action, particularly to suppress errors will hinder troubleshooting.  |

# Code Layout and Formatting
This section provides an overview of the following:

| Section Header | Description |
| - | - |
| EditorConfig | EditorConfig is used to enforce a consistant readable format. |
| VS Code Settings | |
| Comment Based Help | |
| PlatyPS | Provides details of how to create comment based help and generate external help markdown using PlatyPS. |
| Naming Conventions | Provides a table containing the case type to use for identifiers as well as examples of each. |

## EditorConfig
In order to maintain a consistent coding style an EditorConfig file is used to define the coding style to be used. The file **.editorconfig** contains the required styles. The EditorConfig file defines styles such as indentation size, indentation style, newline rules and more.

### EditorConfig Installation

EditorConfig can be installed as a VS Code extension. Search for and install **EditorConfig for VS Code**. The VS Code Marketplace has more information [here](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig).

For further information on EditorConfig [EditorConfig](https://editorconfig.org/)

## VS Code Settings

TO DO

## Comment Based Help
Scripts and functions should contain comment based help that is compatible with **Get-Help**.

The help should consist of the following elements:

- Synopsis
- Description
- A parameter description for each parameter in the Param() block
- At least one example demonstrating how the script can be executed

For further information see [about_Comment_Based_Help](https://github.com/PowerShell/PowerShell-Docs/blob/staging/reference/5.1/Microsoft.PowerShell.Core/About/about_Comment_Based_Help.md)

INSERT EXAMPLE

## PlatyPS

All PowerShell scripts in the Infrastructure-Scripts folder must have external help documentation generated in markdown using the [PlatyPS](https://github.com/PowerShell/platyPS) module.

TO DO

ADD A PESTER TEST FOR THIS TO CHECK DOC EXISTS

## Naming Conventions
To ensure a consistant readable format, use the following naming conventions:

| Identifier                     | Case      | Example      |
| ------------------------------ | --------- | ------------ |
| Global variables               | Pascal    | $Global:$Variable |
| Parameter variables            | Pascal    | $ParameterVariable |
| Local Variables                | camel    | $localVariable, $this, $args |
| Language keywords              | lowercase    | foreach, -eq, try, catch, switch |
| Process block keywords | lowercase | begin, process, end |
| Keywords in comment-based help | UPPERCASE | .SYPNOSIS, .EXAMPLE |
| Two letter acronyms            | UPPERCASE acronym    | VMName |
| Three letter (or more) acronyms | Pascal    | AbcName |
| Constants / Built-in Variables | Pascal    | Microsoft maintains Pascal in their built-in variables, i.e. $PSVersionTable. Tab autocomplete in PowerShell for reference. |
| Constants / Built-in Variables - Exceptions | camel | Keep camel case for built-in variables, i.e. $true and $false. Tab autocomplete in PowerShell for reference. |
| Module Names                   | Pascal    ||
| Function or cmdlet names       | Pascal    ||
| Class Names                    | Pascal    ||
| Attribute Names                | Pascal    ||
| Public fields or properties    | Pascal    ||

# Testing

This section provides an overview of the following:

| Section Header | Description |
| - | - |
| Pester |  |
| PSScriptAnalyzer | |
| PSCodeHealth | |

## Pester

TO DO

## PSScriptAnalyzer

TO DO

## PSCodeHealth

TO DO

# References and Further Reading

| Reference | URL |
| -- | -- |
| The PowerShell Best Practices and Style Guide | https://poshcode.gitbooks.io/powershell-practice-and-style/ |
|  | |
