# 02-AD-Group-Manager-Vibe-Coding

This project demonstrates the creation of an Active Directory Group Membership Management tool using the **Vibe Coding / AI-Assisted Development** methodology. 

Having previously engineered this solution manually, the primary objective of this iteration was to evaluate efficiency gains, establish robust AI collaboration workflows, and master modern prompt engineering.

### Key Objectives:
- **Requirement Engineering:** Developing a deterministic and crystal-clear functional specification to guide AI models without ambiguity.
- **Advanced Prompt Engineering:** Constructing role-based, constrained prompts to ensure production-ready code generation with minimal hallucinations.
- **Workflow Optimization:** Leveraging AI as a high-velocity execution layer while retaining the human role as the Principal Architect and Code Reviewer.

### Efficiency & Key Takeaways
By combining domain-specific technical knowledge gained during the manual implementation with Google's Gemini model, the entire development lifecycle was compressed **from approximately one week to a single day**. 

This repository stands as proof that traditional programming knowledge combined with structured AI-assisted engineering represents the gold standard for modern IT automation and DevOps workflows.

## Key Features

* Interactive TUI Menu – Arrow-key navigation for intuitive group and option selection.
* Bulk Operations – Support for adding or removing multiple members simultaneously by providing a comma-separated list.
* Active Directory User Validation – Pre-execution validation using `Get-ADUser` wrapped in try/catch blocks to ensure user existence before group assignment.
* Permission & Error Handling – Prevents script crashes and gracefully handles insufficient AD permissions during modifications (Add/Remove-ADGroupMember) using advanced try/catch mechanisms.

## Prerequisites

Before running the script, ensure your environment meets the following requirements:

* **Operating System:** Windows 10/11 or Windows Server.
* **PowerShell:** PowerShell 5.1 or higher.
* **Active Directory Module:** The `ActiveDirectory` PowerShell module must be installed to execute the required domain cmdlets.
* **Domain Connectivity:** The script must be executed on a Domain Controller or a machine with an active remote connection to an Active Directory domain.

## Installation & Setup

1. Clone or download this repository to your local machine.
2. **IMPORTANT:** The `Show-ArrowMenuAI.ps1` file must reside in the exact same directory as the main `Manage-ADGroupMembersAI.ps1` script. 
   *(Note: If you decide to move this file to a different directory, you must manually update its path in the `1. ARCHITECTURAL DECOMPOSITION & IMPORT` section at the top of the main script or error will be displayed and program terminated).*

## Usage / How to Run

Open your PowerShell terminal, navigate to the script directory, and execute the script. 

You can run it with your custom Active Directory OU path:
```powershell
.\Manage-ADGroupMembersAI.ps1 -TargetPath "OU=User Groups,OU=Groups,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
```
**Note**: The -TargetPath parameter is pre-configured with a default value. If you do not provide a value
for this parameter, the script will automatically search for groups within that default path.