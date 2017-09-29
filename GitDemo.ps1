#---------------------------------------------------------------
#Definitions:
#Directory - folder used for storing files
#Repository - Directory where Git has been initialised to start version control
#.git - The repository is a hidden directory where Git operates.
#---------------------------------------------------------------
#To initialize a Git repository
git init

#Checks to see current project state, Run often
#Make sure to check what files and folders are staged by using it
git status

#To start tracking changes made by files, must add to staging area - also used to update what is currently in staging
git add GitDemo.ps1

#we can add all the new files using a wildcard with git add.
#Wildcards need quotes so that Git will receive the wildcard before our shell can interfere with it. 
git add '*.txt'

#---------------------------------------------------------------
#Staging Area: A place where we can group files together before we "commit" them to Git.
#Commit:    A "commit" is a snapshot of our repository. 
#           This way if we ever need to look back at the changes we've made (or if someone else does), we will see a nice timeline of all changes.

#The files listed in the Staging Area are not in the repository yet.

#staged:    Files are ready to be committed.
#unstaged:  Files with changes that have not been prepared to be committed.
#untracked: Files aren't tracked by Git yet. This usually indicates a newly created file.
#deleted:   Files has been deleted and is waiting to be removed from Git.

#add all:   type git add -A . where the dot stands for the current directory, so everything in and beneath it is added. 
#The -A ensures even file deletions are included.
#git reset: You can use git reset <filename> to remove a file or files from the staging area.

#git pull
#---------------------------------------------------------------

#To store our staged changes we run the commit command with a message describing what we've changed.
git commit -m "intial commit"

#git log remembers all changes that have been committed
#Use git log --summary to see more information for each commit.
git log

#git remote: typical to name your main one origin. best to have main repository to be on a remote server like GitHub
#To push our local repo to the GitHub server we'll need to add a remote repository.
#This command takes a remote name and a repository URL
git remote add origin https://github.com/DanielAyo/test.git

#To remove the same remote repository you enter:
git remote rm origin

#The push command tells Git where to put our commits when we're ready.
#The name of our remote is origin and the default local branch name is master. 
#The -u tells Git to remember the parameters, so that next time we can simply run git push and Git will know what to do
git push -u origin master    

#Set username and email associated with commit
git config --global user.name "Daniel Ayo"
git config --global user.email DanielAyo@users.noreply.github.com

#fix the identity used for this commit with:
git commit --amend --reset-author

#can check for changes on our GitHub repository and pull down any new changes by running:
git pull origin master

#git stash:
#Sometimes when you go to pull you may have changes you don't want to commit just yet. One option you have, other than commiting, is to stash the changes.
#Use the command 'git stash' to stash your changes, and 'git stash apply' to re-apply your changes after your pull.

#Use the command 'git stash' to stash your changes, and 'git stash apply' to re-apply your changes after your pull.
git diff HEAD

# try to keep related changes together in separate commits. 
# Using 'git diff' gives you a good overview of changes you have made and lets you add files or directories one at a time and commit them separately.

 #looking at changes within files that have already been staged.
 git diff --staged