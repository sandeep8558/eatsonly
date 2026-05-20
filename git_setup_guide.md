# 🚀 EatsOnly Git Setup & Push Guide

This guide explains how to safely and securely push your **EatsOnly** project (`Laravel 13 cloud backend` + `Flutter POS/KDS client`) to Git (such as GitHub, GitLab, or Bitbucket).

---

## 🔒 Crucial Security First!

Before running any Git commands, **your API keys and credentials must be safe.** We have created a root-level `.gitignore` file that automatically excludes these highly sensitive files from being pushed to public repositories:

*   🔑 `rzp-key_live.csv` / `rzp-key_test.csv` (Razorpay credentials)
*   🗺️ `googlemapskey.txt` (Google Maps API key)
*   🔑 `keystore.txt` (Android/iOS keystore info)
*   📧 `email_api` (Mailgun API token)
*   📝 `cmd.txt` / `notes.txt` / `domains.txt` (Local scratchpads)

> [!WARNING]
> Never delete or modify `.gitignore` in a way that exposes these files. If you add new configuration or `.env` files in the future, ensure they are also listed in `.gitignore`.

---

## 🛠️ Step-by-Step Push Instructions

### 1️⃣ Initialize Git Locally
Open your terminal, navigate to the project directory, and initialize a new Git repository:

```bash
git init
```

### 2️⃣ Check Git Status (Recommended Verification)
Run the following command to see which files are ready to be tracked and verify that all sensitive files are successfully hidden by `.gitignore`:

```bash
git status
```
*You should see `app/`, `cloud/`, `wiki/`, `.gitignore`, and `CLAUDE.md` listed under **Untracked files**, but you should NOT see any credentials, `.env`, or `.csv` files.*

### 3️⃣ Stage All Files
Add all the project files to the Git staging area:

```bash
git add .
```

### 4️⃣ Create the Initial Commit
Commit your staged files locally with a descriptive message:

```bash
git commit -m "Initial commit: EatsOnly Laravel backend and Flutter POS/KDS client"
```

### 5️⃣ Create a Remote Repository
1. Go to your Git host (e.g., [GitHub](https://github.com)).
2. Log in and click **New Repository** (or **New**).
3. Name your repository (e.g., `eatsonly`).
4. **IMPORTANT**: Leave "Add a README", "Add .gitignore", and "Choose a license" **unchecked** (we already have these in our local project).
5. Click **Create repository**.
6. Copy the repository HTTPS or SSH URL (e.g., `https://github.com/your-username/eatsonly.git`).

### 6️⃣ Link Your Local Repository to the Remote
Run the following commands in your terminal to set your default branch to `main` and link your local repository to the remote URL you copied in the previous step:

```bash
# Rename the default branch to 'main'
git branch -M main

# Link your local repo to the remote repository (Replace URL with yours)
git remote add origin https://github.com/your-username/eatsonly.git
```

### 7️⃣ Push to Git
Push your local code to your remote repository:

```bash
git push -u origin main
```

---

## 💡 Quick Tips for Daily Workflow

Once the repository is pushed, use these standard commands for your daily edits:

```bash
# 1. View what changes you've made
git status

# 2. Stage the changes
git add .

# 3. Commit the changes locally
git commit -m "Refactor order processing logic"

# 4. Push changes to GitHub
git push
```
