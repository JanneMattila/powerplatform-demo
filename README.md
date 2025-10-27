# Power Platform Demo - Solution Groups

This repository contains the configuration and metadata for Solution Groups and their associated applications. Solution Groups are used to organize and manage deployments and extractions of related applications with dependency management.

## Overview

Two GitHub Actions workflows manage the Solution Groups:

1. **Deploy Solution** (`DeploySolution.yml`) - Deploys applications and shows their configuration
2. **Extract Solution** (`ExportSolution.yml`) - Updates application metadata with timestamps and commits changes

Both workflows support **cascading/dependent workflow triggering**, allowing automatic deployment or extraction of dependent applications.

## Directory Structure

```
SolutionGroups/
├── solution-groups.json          # Dependency mapping configuration
├── README.md                     # This documentation
├── ABC-SolutionGroup/            # Solution Group "ABC"
│   ├── App A.md                  # Application A configuration
│   ├── App B.md                  # Application B configuration
│   └── App C.md                  # Application C configuration
└── DEF-SolutionGroup/            # Solution Group "DEF"
    ├── App D.md                  # Application D configuration
    ├── App E.md                  # Application E configuration
    └── App F.md                  # Application F configuration
```

## Configuration File: solution-groups.json

The `solution-groups.json` file defines the dependency relationships between applications within each Solution Group.

**Structure:**
```json
{
    "<SolutionGroupName>": {
        "<App Name>": ["<Dependent App 1>", "<Dependent App 2>"],
        "<Another App>": []
    }
}
```

**Example:**
```json
{
    "ABC": {
        "App A": ["App B", "App C"],
        "App B": [],
        "App C": []
    }
}
```

This means:
- When "App A" is deployed/extracted with cascading enabled, it will trigger "App B" and "App C"
- "App B" and "App C" have no dependencies (empty arrays)

**Note:** The app names in `solution-groups.json` should **not** include number prefixes. The dropdown options in the workflows can include numbers for ordering (e.g., "1. LibraryTables"), but the JSON file uses the base app name without numbers.

## Workflows

### 1. Deploy Solution Workflow

**File:** `.github/workflows/DeploySolution.yml`

**Purpose:** Deploy applications and display their configuration

**Triggers:**
- **Manual (workflow_dispatch):** Select a solution from dropdown and run manually
- **Automatic (pull_request):** Triggered automatically when `*_unmanaged.zip` files are changed in the `SolutionGroups/` directory

**Features:**
- Select a solution from dropdown (e.g., "ABC -> 1. App A") for manual deployment
- Auto-detects solution from PR changes when triggered by pull request
- Reads and displays the application's `.md` configuration file
- Optionally triggers dependent application deployments
- Uses the branch/tag selected in GitHub Actions UI

**Manual Usage:**
1. Go to Actions → "Deploy Solution Group"
2. Click "Run workflow"
3. Select the solution to deploy (e.g., "ABC -> 1. App A")
4. Check "Trigger dependent workflows?" to enable cascading
5. Click "Run workflow"

**Automatic Usage:**
- When a pull request modifies any `*_unmanaged.zip` file in the `SolutionGroups/` directory, the workflow automatically triggers
- The workflow parses the solution group and app name from the file path
- Example: `SolutionGroups/Library/LibraryTables_unmanaged.zip` → deploys "Library -> LibraryTables"

**Example Flow:**
- Deploy "ABC -> 1. App A" with cascading enabled
  - Deploys App A
  - Automatically triggers deployment of App B
  - Automatically triggers deployment of App C

**Note:** The workflows support numbered app names in the dropdown (e.g., "1. App A", "2. App B") to make ordering clear in the UI. The processing logic automatically removes these number prefixes when matching against `solution-groups.json`.

Here are screenshots of the workflows in action:

Initiate deployment of App A which has the following configuration:

```json
{
  "ABC": {
    "App A": [
      "App B", 
      "App C"
    ],
    "App B": [],
    "App C": []
  }
}
```

![Initiate deployment of App A](./images/deploy-workflow1.png)

App A deployment in progress:

![App A deployment in progress](./images/deploy-workflow2.png)

App A deployment completed:

![App A deployment completed](./images/deploy-workflow3.png)

It has started deployment of App B (dependent of App A) and then it will deploy App C (dependent of App A).
Here is the end result after all deployments are done:

![Deployments completed](./images/deploy-workflow4.png)

### 2. Extract Solution Workflow

**File:** `.github/workflows/ExportSolution.yml`

**Purpose:** Update application metadata and commit changes

**Features:**
- Updates the first line of the application's `.md` file with timestamp and username
- Commits the change back to the repository
- Supports custom branch selection for exports
- Automatically creates the specified branch if it doesn't exist
- Optionally triggers dependent application extractions
- Creates an audit trail of extraction activities

**Usage:**
1. Go to Actions → "Extract Solution"
2. Click "Run workflow"
3. Select the solution to extract (e.g., "DEF -> 1. App D")
4. Enter a branch name (default: "export-solution")
   - If the branch exists, it will be used
   - If the branch doesn't exist, it will be created
   - **Cannot be "main" or "master"** (protected branches)
5. Check "Trigger dependent workflows?" to enable cascading
6. Click "Run workflow"

**What happens:**
- The workflow checks out or creates the specified branch
- Exports the solution from the Development environment
- The first line of the `.md` file is updated:
  ```markdown
  # DEF-SolutionGroup -> App D - Update 2025-10-07 14:30:45 by JanneMattila
  ```
- Changes are committed to the specified branch by `github-actions[bot]`
- If cascading is enabled, dependent apps are also extracted to the same branch

**Note:** The workflows support numbered app names in the dropdown to make ordering clear in the UI. The processing logic automatically removes these number prefixes.

Here are screenshots of the workflows in action:

Initiate extraction of App D which has the following configuration:

```json
{
  "DEF": {
    "App D": [
      "App E"
    ],
    "App E": [
      "App F"
    ],
    "App F": []
  }
}
```

![Initiate extraction of App D](./images/run-workflow1.png)

App D extraction in progress:

![App D extraction in progress](./images/run-workflow2.png)

App D extraction completed:

![App D extraction completed](./images/run-workflow3.png)

It has started extraction of App E (dependent of App D) and then it will extract App F (dependent of App E):

![App D extraction completed](./images/run-workflow4.png)

Here is the end result after all extractions are done:

![App D extraction completed](./images/run-workflow5.png)

## Branch Management for Exports

The Extract Solution workflow supports custom branch names, allowing you to organize exports into separate branches for different purposes:

### Branch Workflow

1. **Specify Branch Name**: When running the Extract Solution workflow, provide a branch name (e.g., "feature/library-updates", "export-solution", "dev-export")
2. **Automatic Branch Creation**: If the branch doesn't exist, it will be created automatically from the current branch
3. **Existing Branch Usage**: If the branch exists, it will be checked out and updated
4. **Cascading Exports**: All dependent app exports use the same branch, keeping related changes together
5. **Pull Request Ready**: After exports complete, you can create a PR from the export branch to merge changes

### Use Cases

**Feature Development:**
```
Branch: feature/library-updates
- Export Library -> LibraryTables
- Export Library -> LibraryApp (cascading)
- Create PR: feature/library-updates → main
```

**Regular Exports:**
```
Branch: export-solution (default)
- Regular development exports
- Review changes before merging
```

**Environment-Specific Exports:**
```
Branch: dev-export
- Development environment exports
- Isolated from production changes
```

### Benefits

- **Isolation**: Keep exports separate from other work
- **Review**: Review all exported changes in a PR before merging
- **History**: Clear branch history showing what was exported and when
- **Collaboration**: Multiple team members can export to different branches simultaneously
- **Safety**: No direct commits to main branch (enforced by validation)
- **Protection**: main and master branches are protected from direct exports

## Adding a New Solution Group

Follow these steps to add a new Solution Group (e.g., "GHI"):

### Step 1: Create the Directory Structure

```powershell
# Create the solution group directory
mkdir SolutionGroups\GHI-SolutionGroup
```

### Step 2: Create Application Files

Create a `.md` file for each application in the solution group:

```powershell
# Create application markdown files
"# GHI-SolutionGroup -> App G" | Out-File -FilePath "SolutionGroups\GHI-SolutionGroup\App G.md" -Encoding UTF8
"# GHI-SolutionGroup -> App H" | Out-File -FilePath "SolutionGroups\GHI-SolutionGroup\App H.md" -Encoding UTF8
"# GHI-SolutionGroup -> App I" | Out-File -FilePath "SolutionGroups\GHI-SolutionGroup\App I.md" -Encoding UTF8
```

**File format:**
```markdown
# <SolutionGroup>-SolutionGroup -> <AppName>

[Optional: Add application-specific configuration details here]
```

### Step 3: Update solution-groups.json

Add the new solution group to `SolutionGroups/solution-groups.json`:

```json
{
    "ABC": {
        "App A": ["App B", "App C"],
        "App B": [],
        "App C": []
    },
    "DEF": {
        "App D": ["App E"],
        "App E": ["App F"],
        "App F": []
    },
    "GHI": {
        "App G": ["App H"],
        "App H": ["App I"],
        "App I": []
    }
}
```

### Step 4: Update Workflow Files

Update **both** workflow files to include the new solution group options:

**Files to update:**
- `.github/workflows/DeploySolution.yml`
- `.github/workflows/ExportSolution.yml`

**Add these lines to the `options` section:**

```yaml
on:
  workflow_dispatch:
    inputs:
      solution:
        description: 'Solution to deploy'  # or 'Solution to extract'
        required: true
        type: choice
        options:
          - 'ABC -> 1. App A'
          - 'ABC -> 2. App B'
          - 'ABC -> 3. App C'
          - 'DEF -> 1. App D'
          - 'DEF -> 2. App E'
          - 'DEF -> 3. App F'
          - 'GHI -> 1. App G'  # Add these new lines
          - 'GHI -> 2. App H'
          - 'GHI -> 3. App I'
```

**Note:** You can add number prefixes (e.g., "1.", "2.") to the dropdown options to indicate ordering in the UI. The workflows automatically strip these prefixes when processing.

### Step 5: Commit and Push

```powershell
git add SolutionGroups/
git add .github/workflows/
git commit -m "Add new Solution Group: GHI with Apps G, H, and I"
git push
```

## Adding a New App to an Existing Solution Group

Follow these steps to add a new application to an existing Solution Group:

### Step 1: Create the Application File

```powershell
# Example: Add "App X" to the "ABC" solution group
"# ABC-SolutionGroup -> App X" | Out-File -FilePath "SolutionGroups\ABC-SolutionGroup\App X.md" -Encoding UTF8
```

### Step 2: Update solution-groups.json

Add the new app to the appropriate solution group in `SolutionGroups/solution-groups.json`:

**Before:**
```json
{
    "ABC": {
        "App A": ["App B", "App C"],
        "App B": [],
        "App C": []
    }
}
```

**After:**
```json
{
    "ABC": {
        "App A": ["App B", "App C"],
        "App B": [],
        "App C": [],
        "App X": []
    }
}
```

**If you want to add dependencies:**
```json
{
    "ABC": {
        "App A": ["App B", "App C", "App X"],
        "App B": [],
        "App C": [],
        "App X": []
    }
}
```
This makes "App X" a dependency of "App A".

### Step 3: Update Workflow Files

Update **both** workflow files:

**Files to update:**
- `.github/workflows/DeploySolution.yml`
- `.github/workflows/ExportSolution.yml`

**Add the new option:**

```yaml
options:
  - 'ABC -> 1. App A'
  - 'ABC -> 2. App B'
  - 'ABC -> 3. App C'
  - 'ABC -> 4. App X'  # Add this new line
  - 'DEF -> 1. App D'
  - 'DEF -> 2. App E'
  - 'DEF -> 3. App F'
```

**Note:** You can add number prefixes to indicate ordering in the UI. The workflows automatically strip these prefixes when processing.

### Step 4: Commit and Push

```powershell
git add SolutionGroups/ABC-SolutionGroup/App\ X.md
git add SolutionGroups/solution-groups.json
git add .github/workflows/
git commit -m "Add App X to ABC Solution Group"
git push
```

## Dependency Management

### Understanding Dependencies

Dependencies are defined as **one-way relationships** in `solution-groups.json`:

- **Parent App** → **Dependent Apps** (children)
- When you deploy/extract a parent app with cascading enabled, all dependent apps are processed automatically

### Automatic Deployment via Pull Requests

The Deploy Solution workflow can be automatically triggered when `*_unmanaged.zip` files are modified in a pull request:

1. **Create/Update Solution Files**: When you export solutions and commit the `*_unmanaged.zip` files to a branch
2. **Create Pull Request**: Open a PR with changes to files matching `SolutionGroups/**/*_unmanaged.zip`
3. **Automatic Trigger**: The Deploy Solution workflow automatically runs
4. **Auto-Detection**: The workflow detects the solution group and app name from the changed file path
   - Example: `SolutionGroups/Library/LibraryTables_unmanaged.zip` → deploys "Library -> LibraryTables"
5. **Deployment**: The solution is deployed to the appropriate environment (QA for non-main branches, Production for main branch)

**Benefits:**
- Automated deployment pipeline triggered by code changes
- Consistent deployment process for both manual and automatic triggers
- Clear audit trail through pull request history

### Example Dependency Chain

```json
{
    "DEF": {
        "App D": ["App E"],
        "App E": ["App F"],
        "App F": []
    }
}
```

**Execution order when deploying "App D" with cascading:**
1. Deploy App D
2. Trigger App E (dependent of App D)
3. Trigger App F (dependent of App E)

### Error Handling

Both workflows will **fail** if:
1. The application's `.md` configuration file is not found

Both workflows will **succeed** with informational messages if:
1. "Trigger dependent workflows" is enabled but the app has no dependencies defined (this is normal for leaf nodes in the dependency tree)

This ensures that configuration issues are caught early while allowing flexibility in workflow triggering.

## Best Practices

1. **Naming Convention:**
   - Solution Group directories: `<Name>-SolutionGroup/`
   - Application files: `<App Name>.md`
   - Keep names consistent with `solution-groups.json`

2. **File Headers:**
   - Always start `.md` files with: `# <SolutionGroup>-SolutionGroup -> <AppName>`
   - Extract workflow will update this header automatically

3. **Dependencies:**
   - Define dependencies in `solution-groups.json` even if empty (`[]`)
   - Test cascading with a single app before enabling for production
   - Be aware of circular dependencies (not currently prevented)

4. **Version Control:**
   - Always commit all changes together (directory, json, workflows)
   - Use descriptive commit messages
   - Test workflows after adding new solution groups/apps

## Troubleshooting

### Workflow fails with "Configuration file not found"
- Verify the file exists at: `SolutionGroups/<SolutionGroup>-SolutionGroup/<AppName>.md`
- Check for typos in folder names or file names
- Ensure file name matches exactly with `solution-groups.json` (including spaces)

### Workflow fails with "No dependent workflows found"
- This is actually not an error - it's an informational message
- Occurs when "Trigger dependent workflows" is checked but the app has no dependencies
- The workflow will succeed; this is normal for apps like "App C" or "App F" that are leaf nodes
- You can safely check "Trigger dependent workflows" for any app without worrying about this

### New app doesn't appear in dropdown
- Ensure you updated **both** workflow files (`.github/workflows/DeploySolution.yml` and `ExportSolution.yml`)
- Commit and push the workflow changes
- Refresh the Actions page in GitHub

### Extract workflow doesn't commit changes
- Check repository permissions in workflow settings
- Verify `permissions: contents: write` is set in the workflow file
- Ensure the `.md` file exists and is properly formatted
