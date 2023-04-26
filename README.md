
<!--#echo json="package.json" key="name" underline="=" -->
ghabuild-minecraft-mod-editsign
===============================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Scripts for building EditSign on GitHub Actions.
<!--/#echo -->

* __Official download site:__
  https://www.curseforge.com/minecraft/mc-mods/edit-sign
  * If the official download site works for you, please download from there,
    so the mod authors get proper statistics on the populariy of their mod.
* __Mod repo:__
  https://github.com/Rakambda/EditSign



⚠ Builds from this repo are unofficial and unsupported! ⚠
---------------------------------------------------------

* For official downloads, see above.
* I'll try to help with bugs in the build process,
  but not with bugs in the mod.
* For anything about the mod itself, please refer to
  the original mod repo (see above).



How to use this repo
--------------------

1.  If you're looking for JARs and the official download site (see above)
    doesn't work for you, check if one of [these releases
    ](https://github.com/mk-pmb/ghabuild-minecraft-mod-editsign/releases)
    has them. If so, continue at the "Download" step below.
1.  If you're looking for config examples, check the branches of this repo.
1.  If you don't yet have "version info lines", obtain some as described
    [here](https://github.com/mk-pmb/minecraft-uncurse-mods/tree/master/known_mods/edit-sign).
1.  Fork this repo.
1.  Create a new branch.
1.  Edit `matrix.md`.
    1.  Replace its entire content with the table markup from the
        build matrix suggestions file.
    1.  In the data part of the table, keep only the table rows for the
        mod versions you want to build. Remove all other rows.
    1.  Save the file. Commit the changes.
1.  Invoke a GitHub Actions runnter on your new branch.
    * One easy way to do this, is to push your branch to your GitHub repo.
1.  Wait for the runner to complete.
1.  The run should have succeeded and should have produced one or more
    artifacts whose filenames end with `.jar.zip`.
1.  __Download__ the artifact files.
1.  Verify the license file(s) in each artifact file.
1.  Rename the artifact files to remove the trailing `.zip` from their names.
1.  Optionally, test those JARs in Minecraft.
1.  Optionally, share your JARs with the world.
    * An easy way to do so is to [create a release on GitHub.
      ](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository#creating-a-release)


<!--#toc stop="scan" -->




&nbsp;



License
-------

* Build scripts in this repo: [GPL-3.0-only](LICENSE.txt).
* Old versions of the mod are GPL-3.0-only.
* Modern versions of the mod usually are LGPL-3.0-only.
* Each artifact built contains text files with license information about
  the other files in the artifact.
* ⚠ Some versions of the binaries are built using files from Mojang.
  See [`LICENSE.mojang_taint.txt`](LICENSE.mojang_taint.txt).














<!-- -- -->
