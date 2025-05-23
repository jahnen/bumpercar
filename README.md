# 🚗 bumpercar

**Update your R package dependencies with ease.**

`bumpercar` is a GitHub Action that automatically updates the versions of packages listed in the `DESCRIPTION` file of your R package repository. It creates a pull request with the updated dependencies based on the latest compatible versions from CRAN.

---

## 📦 Usage

Create a new workflow file to your R package repository: `.github/workflows/bumpercar.yml`

```yaml
name: Update R DESCRIPTION dependencies

on:
  schedule:
    - cron: "0 2 * * 1"  # Every Monday at 2am UTC
  workflow_dispatch:

jobs:
  bumpercar:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run bumpercar
        uses: jahnen/bumpercar@v1.1.0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## ✨ Features

- Parses your `DESCRIPTION` file (`Imports`, `Depends`, `Suggests`)
- Looks up the latest versions of R packages from CRAN
- Preserves compatibility by only bumping minor/patch versions
- Run `R CMD check` with updated DESCRIPTION: 
  - If `R CMD check` passed:
    - Creates a new Git branch and opens a pull request    
  - If `R CMD check` failed:
    - Create a new issue 

![스크린샷 2025-05-20 오후 4 14 44](https://github.com/user-attachments/assets/f004e36e-d54a-4296-8e85-7f71a4840d21)

![스크린샷 2025-05-20 오후 4 14 23](https://github.com/user-attachments/assets/60adcaca-e710-47be-bace-b10cbce7f9b3)

---

