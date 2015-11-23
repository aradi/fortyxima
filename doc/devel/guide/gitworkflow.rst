Git workflow
============

General workflow
----------------

For developing Fortyxima, we use the workflow as described by Vincent Driessen
in `A successful Git branching model
<http://nvie.com/posts/a-successful-git-branching-model/>`_. The main points for
most developers are:

* The `master` branch only contains official (tagged) releases.

* Development happens on the `develop` branch, which always contains a clean
  release-ready code.

* Every feature is developed in a separate feature branch. If the feature is
  mature enough (it works correclty, its code is clean, it is well documented
  and automatic tests has been created), the feature branch will be merged to
  the `develop` branch.

The main official public repository of Fortyxima only contains the branches
`master` and `develop` (and eventual short living intermediate branches like
`release` and `hotfix`). In order to add a feature, you have to do the following
steps:

#. Fork the official repository. (This step you have to do only once. If you've
   already forked the official repository, skip it.)

#. Derive a feature branch from the `develop` branch of your forked project.

#. Develop your feature in your feature branch.

#. Regularly update your `develop` branch from the official `develop` branch to
   make sure, your `develop` branch remains identical to the official one.

#. Regularly merge your `develop` branch into your feature branch, to make sure,
   your feature branch is based on the most recent state of the official
   `develop` branch.

#. When the feature is implemented, do steps 4 and 5 again. Then issue a
   pull request of your feature branch into the `develop` branch of the official
   repository.

#. Wait for feedback from the core developers, and apply possible
   improvments, to the feature branch, before it can be merged. Also make
   sure to keep your feature branch up to date with the official `develop` by
   executing steps 4 and 5.

#. When you obtain the notification, that your feature branch had been merged to
   the official `develop` branch, delete your feature branch in your personal
   repository. 

#. In order to develop the next feature, execute the steps above again,
   *starting from step 2*.


Below you find a detailed description of each step.

Forking the project
-------------------

#. Fork the desired project to *your personal* Bitbucket account. You find the
   `Fork` action in the menu indicated by three dots below the project logo.

#. In the settings menu of your personal fork, change the main branch from
   `master` to `develop`. (Since you will only contribute to the `develop`
   branch, you do not need to deal with the `master` branch at all.)

#. Check out your fork from Bitbucket to your local machine::

       git clone git@bitbucket.org:YOUR_USER_NAME/fortyxima.git

#. Check whether your local repository contains the `develop` branch, but
   not the `master` branch::

       cd fortyxima
       git branch

   Only `develop` should pop up in the list of branches, but not `master`.

#. Set up a mirror of the official reference repository::

       git remote add official git@bitbucket.org:dftbplus/fortyxima

#. Fetch the official remote::
      
       git fetch official

#. Check out the develop branch. (Actually, you should already be on that
   automatically, as you've set the default branch to be the develop branch)::

       git checkout develop

#. Reset your local develop branch to be identical to the official develop
   one::

       git reset --hard official/develop

  You should see no changes, as the two branches were identical. They should be
  always automatically remain identical, if you follow the strategy outlined in
  this document. Pull requests to the official repository are only accepted if
  they are derived from a develop-branch *identical* to the official one.


Developing your feature
-----------------------

If you have already forked the project for an other feature branch before,
execute Step 1 in section `Staying up to date with the official develop branch`_
before carrying out the following steps.  This way you make sure that your
`develop` branch is synchronized with the official one. Otherwise, you can start
directly with the steps below:

#. Create you own feature branch::

       git checkout -b some-new-feature

   You always have to create an extra branch derived from `develop`, if you
   develop a new feature.  You should never work on the develop branch directly,
   or merge anything from your feature branches into it. Its only purpose is to
   mirror the status of the official develop branch.

#. Develop your new feature in your local branch. Make check-ins, whenever
   it seems to be logical and useful::

       git commit -m "Some new thing added...."

#. If you want to share your development with others (or make a backup of your
   repository in the cloud), upload the current status of your local feature
   branch by pushing it to your personal repository::

       git push --set-upstream origin some-new-feature

   This also automatically connects the appropriate branch of your personal
   repository on Bitbucket (`origin/some-new-feature`) with your local branch
   (`some-new-feature`), so from now on, if you are on your `some-new-feature`
   branch, a simple::

       git push

   command without any additional options will be enough to transfer your recent
   changes on this branch to Bitbucket.


Staying up to date with the official develop branch
---------------------------------------------------

Time to time you should make sure, that your `develop` branch is up to date with
the official `develop` branch.

#. Pull the recent changes from the official develop branch into your local
   develop branch::

       git checkout develop
       git pull --ff-only official develop

   Upload the changes in your local develop branch to Bitbucket by issuing::

       git push origin develop

   Note: if the ``git pull --ff-only ...`` command fails, you probably have
   messed up your personal develop branch (despite all the warnings above), and
   it can not made to be identical to the official one any more. In that case,
   you can revert it via hard reset::

       git reset --hard official/develop

   You will then eventually have to derive a new feature branch from the
   resetted `develop` branch, and add your changes on `some-new-feature`
   manually to it. So better try not to polute your `develop` branch.

#. After pulling the recent changes from the official `develop` branch, change
   back to your feature branch, to make sure you do not commit anything into
   `develop`::

       git checkout some-new-feature

#. Update your feature branch to incorporate the recent changes on the official
   `develop` branch (which you've pulled before), by merging your local
   `develop` branch into `some-new-feature`::

       git merge develop

   If you encounter any conflicts, resolve them, and commit the merge to
   `some-new-feature`.



Merging back the changes into the official repository
-----------------------------------------------------

When you have finished the implementaiton of your feature and you would like to
get it merged into the official `develop` branch, issue a pull request.

#. First, make sure, that you have pulled the latest changes of the official
   develop branch to your local `develop` branch, and that you have merged those
   changes into your feature branch. (Follow the steps in the previous section.)

#. If not done yet, upload your feature branch to your personal repository
   on bitbucket::

       git push origin some-new-feature

   If your repository was set to private, make sure, that at least the  core
   developers have read access to it.

#. Issue a pull request on bitbucket for your some-new-feature branch. (Look for
   the upwards arrow in the left menu.) Make sure, that the target of your pull
   request the `develop` branch of the official repository
   (`dftbplus/fortyxima`).

#. Wait for the comments of core the developers, fix things you are asked for,
   and push the changes to your feature branch on bitbucket.

#. Once the discussion on your pull request is done, one of the developers with
   write permission to the official repository will merge your branch into the
   official `develop`-branch. Once this has happened, you should see your
   changes showing up there.


Deleting your feature branch
----------------------------

If your feature had been merged into the official code, you can delete your
feature branch locally and on Bitbucket as well:

#. In order to delete the feature branch locally, change to the develop branch
   (or any branch other than your feature branch) and delete your feature
   branch::

       git checkout develop
       git branch -d some-new-feature

#. In order to delete the feature branch on Bitbucket as well, use the command::

       git push origin --delete some-new-feature

This closes the development cycle of your old feature and opens a new one for
the next feature you are going to develop. You can then again create a new
branch for the new feature and develop your next extension starting with the
steps described in section `Developing your feature`_.
