# das-platform-automation

## About
This repository contains PowerShell helper scripts to be used locally and in Azure DevOps for the Digital Apprenticeship Service (DAS). It also includes a checklist for creating new helper scripts, a standardised code and design style guideline, related documentation and testing overview.

# New Script Checklist
Use the following as a checklist for creating new helper scripts.

| Requirement                     | Notes      
| ------------------------------ | --------- |
| Work locally and on build agents.| |
| Contain descriptive inline comments. | |
| Comment based help.|     |
| External help markdown documentation.| Generate using PlatyPS. |
| Pester unit test.|      |
| Use only Az module cmdlets.|     |
| Follows the agreed naming covention. | See Naming Conventions section.    |
| Adheres to .editorconfig | Stored in .editorconfig | 
| Adheres to .vscode settings | Stored in .vscode/settings.json|

# Code Layout and Formatting
This section attempts to provide a guide that will ensure a consistant code layout and repeatable and readable format. This section includes the following:

| Section | Description |
| - | - |
| EditorConfig | EditorConfig is used to enforce a consistant readable format. |
| VS Code Settings | | 
| Documentation | Provides details of how to create comment based help and generate external help markdown using PlatyPS. |
| Naming Conventions | Provides a table containing the case type to use for identifiers as well as examples of each. |

## EditorConfig
In order to maintain a consistent coding style an EditorConfig file is used to define the coding style to be used. The file **.editorconfig** contains the required styles. The EditorConfig file defines styles such as indentation size, indentation style, newline rules and more. 

### EditorConfig Installation

EditorConfig can be installed as a VS Code extension. Search for and install **EditorConfig for VS Code**. The VS Code Marketplace has more information [here](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig). 

For further information on EditorConfig [EditorConfig](https://editorconfig.org/)

## VS Code Settings



## Documentation
### Comments
Scripts and functions should contain comment based help that is compatible with **Get-Help**.

The help should consist of the following elements:

- Synopsis
- Description
- A parameter description for each parameter in the Param() block
- At least one example demonstrating how the script can be executed

For further information see [about_Comment_Based_Help](https://github.com/PowerShell/PowerShell-Docs/blob/staging/reference/5.1/Microsoft.PowerShell.Core/About/about_Comment_Based_Help.md)

### PlatyPS External Help Markdown

All PowerShell scripts in Infrastructure-Scripts must have external help documentation generated in markdown using the [PlatyPS](https://github.com/PowerShell/platyPS) module. 

ADD A TEST TO CHECK FOR MARKDOWN OUTPUT IS PRESENT, IF NOT HERES HOW TO DO IT:

## Naming Conventions
To ensure a consistant readable format, use the following naming conventions.

| Identifier                     | Case      | Example      |
| ------------------------------ | --------- | ------------ |
| Module Names                   | Pascal    |              |
| Function or cmdlet names       | Pascal    |              |
| Class                          | Pascal    |              |
| Attribute Names                | Pascal    |              |
| Public fields or properties    | Pascal    |              |
| Global variables               | Pascal    |              |
| Constants                      | Pascal    |              |
| Language keywords              | lowercase     | foreach, -eq, try, catch, switch |
| Process block keywords | lowercase | begin, process |
| Keywords in comment-based help | UPPERCASE | .SYPNOSIS, .EXAMPLE    |
| Two letter acroynms            |           |              |
|                                |           |              |
|                                |           |              |
|                                |           |              |

# Best Practises




# Testing



### Pester

Mock class constructors where applicable. This will test changes to classes.

### PSScriptAnalyzer

# References and Further Reading

| Reference | URL |
| -- | -- |
| The PowerShell Best Practices and Style Guide | https://poshcode.gitbooks.io/powershell-practice-and-style/ |
|  | |






