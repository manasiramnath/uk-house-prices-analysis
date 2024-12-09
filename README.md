# GitHub Template for R Projects

Author: Justin Beresford

Last Edit: September 2024

This repo serves as a template for project work, in addition to outlining some "best practices" for managing R projects using GitHub at Frontier. If you're already bought in, you can skip down to the [Set-up instructions](#set-up-instructions). 

An awful lot of this template is subjective and highly opinionated.  Any disagreements - no matter how big or small - get in touch on <a href="https://teams.microsoft.com/l/chat/0/0?users=justin.beresford@frontier-economics.com">Teams</a>, open an <a href="https://github01.frontier.local/Frontier/template_r/issues">issue</a>, or even better, write it up and raise a <a href="https://github01.frontier.local/Frontier/template_r/pulls">pull request</a>. If you don't know what that means, you're a good candidate for the <a href="https://github01.frontier.local/Frontier/template_r/blob/main//.github/git-tutorial.md">GitHub how to guide</a>. 

In addition to serving as a template, the repo also contains:

+ A <a href="https://github01.frontier.local/Frontier/template_r/blob/main//.github/github-best-practice.md">Github Best Practice</a> guide 
+ Some <a href="https://github01.frontier.local/Frontier/template_r/blob/main/.github/coding-standards.md">Coding Standards</a> and a discussion of our framework for automated styling and coding checks. 

# TL;DR

This a template repo for your R Projects. After some set-up, you'll have: 

+ <a href="https://github01.frontier.local/Frontier/template_r/blob/main/.RProfile">`.RProfile`</a>: which runs every time your restart (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>F10</kbd> in RStudio). This calls: 

  + <a href="https://github01.frontier.local/Frontier/template_r/blob/main/config/packages.R">`config/packages.R`</a>: a bunch of `library()` calls - so you don't have to be the person that imports the whole of tidyverse at the top of every script ;)

  + <a href="https://github01.frontier.local/Frontier/template_r/blob/main/config/settings.R">`config/settings.R`</a>: this defines directory links to three places:
    
     (i) `directory_raw`, the z-drive location of your raw data;
     
     (ii) `directory_processed`, the z-drive location of your processed data, and;
     
     (iii)  `directory_output`, the z-drive location of your charts and tables.
     
     Ideally we'd avoid non-relative file paths all-together, but this set up lets us clone privately while reading from, and writing to, the shared drive.
     

+ *Pre-commit hooks*:  complete with stylers (automated code formatting, in the tidyverse style) and linters (automated code quality checks, blocking you from committing bad code). 

+ Branch protection: the `main` branch of this repo is locked down. You can only add to it via Pull Request (PR), and only merge to main when the PR has been revieved and approved by a codeowner. 

  + <a href="https://github01.frontier.local/Frontier/template_r/blob/main/.github/CODEOWNERS">`.github/CODEOWNERS`</a>: all members of the GitHub team listed in CODEOWNERS will receive a review request when a PR is raised. This also makes it easy to work out who to contact if you come across an old repo. 

## GitHub Best Practice 

<a href="https://github01.frontier.local/Frontier/template_r/blob/main//.github/github-best-practice.md"> `github-best-practice.md`</a> is a GitHub best practice guide, including information on:
+ **Setting up a repo**: how, where, and what to call it.
+ **Contributing to the repo**: add, commit, push, and branching & merging.

## Coding standards
For now <a href="https://github01.frontier.local/Frontier/template_r/blob/main/.github/coding-standards.md">`coding-standards.md`</a> primarily goes through the pre-commit framework, which includes how to set-up and use:
+ **stylers**: automated code formatting in tidyverse style
+ **linters**: automated and enforced code quality checks


## A noteable exlcusion
For the time being, we are not recommending use of virtual environments for R. As a code writer, list the packages you need in `config/packages.R`. As a code user, please check, and regularly update, your version of R. You can download it from <a href="https://posit.co/download/rstudio-desktop/">the posit website</a> and in RStudio `tools > Global Options > General` will you point to your new download version. 

## Set-up instructions

1. Hit the green **Use this template** button at the top of this page. Select Frontier as the owner, give it a name and description. Public repos will be viewable by everyone at Frontier, whereas Private ones will only be viewable to those whom you give access later.
1. `git clone` the repo, somewhere private. I recommend making a new folder for all your clones, either in c (`~/repos`) or z (`/z/Resources/Personal/Your Name/repos`).
1. Have a quick a look at **`.RProfile`**. There's nothing to change here, but note that it's calling two scripts every time you restart (via <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>F10</kbd> in RStudio). The two scripts called are:
   1. **`.config/settings`**: this is where you make the connection between your local clone and the z drive. Update this line such that it points to the place on the Z drive where you want to store your raw and processed data:`proj_dir <- paste0(z_dir, "Projects-XX/PXX-XXXX/Work")`. Now, restarting RStudio empties your Envrionment *except for* folder paths. Use these with `file.path()` rather than `here()` to read and write data to `Z/projects`. 
   1. **`config/Packages.R`**: the packages used are all stored in one place, and called every time you restart. In combiniation with the previous step, you can now restart RStudio before running scripts, rather than dangerously adding `rm(list=ls())` to the top of each script. 
1. Make a <a href="https://github01.frontier.local/orgs/Frontier/teams">new GitHub team</a>, maybe named after your repo and give `maintain` access to the team (not individuals in the team)

Until now, everthing has been *required* for the repo to work effectively. These next steps are optional, but strongly recommended. 

1. Add the name of the github team you just created to the **`.github/CODEOWNERS`** file. All team members will automatically recieve notifications for Pull Request reviews. 

1. Set **branch protections** for your repo, forcing contributors to create a new branch and raise a PR rather than pushing to main directly. 
   + In your repo, go to `Settings > Branches > Add Rule` 
   + In `Branch name pattern` type `main`, then select the following:
      + Require a pull request before merging
      + Require approvals (1)
      + Dismiss stale pull request approvals when new commits  are pushed
      + Require review from Code Owners
      + Require status checks to pass before merging
      + Require conversation resolution before merging

    + Select any others you might like the sound of, then `Save Changes` at the bottom.

1. **Pre-commit hooks**. Precommit is built in Python, so you'll need that. If you don't have it, downloading miniconda is fast and easy. Instructions are in the<a href="https://github01.frontier.local/Frontier/ds-setup/blob/master/python-setup.md">ds-setup repo</a>. After following that, you'll have python, pip, and conda installed. 
   + In the terminal, run `conda install pre-commit`.
   + Head back to RStudio an run `install.packages("precommit")`
   + Finally run `precommit::use_precommit()`. This will create a `.pre-commit-config.yml` file if there isn't one already. You've already got one, so we're just telling R to use the one that's there. 
   
   On your next commit, you should see a bunch of automated code quality checks. There are three potential outcomes:

    :white_check_mark: your code passes first time and is ready to be pushed
    
    :construction: something in your code is automatically fixed by the hooks. In most cases, this will be enforecement of tidyverse styling. You will need to save the file that has been changed, `git add` it, then re-do the `git commit` to re-run the checks.  
    
    :x: Your code fails with an error message. Substantive changes can't be automated - you'll need to fix the code before you can commit and push to GitHub. 

<details>
  <summary>Top tip: an alias for your repo path</summary>

  A downside of cloning to `z/Resources/Projects/Your \Name/repo` is that getting there in GitBash becomes a pain. Setting up an alias means you can open VSCode to the correct folder in seconds - without touching your mouse. You'll just open GitBash, then `template_r` <kbd>&#8629;</kbd> then `code .`<kbd>&#8629;</kbd>

  Take make an alias for this template, open your `.bashrc` file, with `nano ~/.bashrc` and add `alias template_r="cd /z/Resources/Personal/Your\ Name/repos/template_r` to the bottom of the file. <kbd>ctrl</kbd><kbd>X</kbd> then <kbd>Y</kbd><kbd>&#8629;</kbd>to save an exit. Restart GitBash for this to take effect. 

</details>
