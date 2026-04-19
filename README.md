<img src="https://github.com/xls69/re3-unix/blob/master/res/images/logo_1024.png?raw=true" alt="re3 logo" width="200">

# Message for Take-Two

*Whereas you, in your boundless greed, have seen fit to dismantle the entire GTA modding community and lay waste to the grandest projects of our shared childhood, hear now My decree: each time you strike down this repository, I shall raise it anew. Your DMCA notices, your lawsuits, your hired hounds of inquiry — none shall avail you. And should any among your little flock cheer on these deeds, let them know that a single bullet to the forehead should be their reward.*

## DISCLAIMER

**This fork of re3 specifically focuses on the UNIX platforms and does not guarantee compatibility with other platforms!**

## Intro

In this repository you'll find the fully reversed source code for GTA III ([master](https://github.com/xls69/re3-unix/tree/master/) branch) and GTA VC ([miami](https://github.com/xls69/re3-unix/tree/miami/) branch).

It has been tested and works on Linux, on x86, amd64.\
Rendering is handled by the RenderWare reimplementation [librw](https://github.com/xls69/librw) (OpenGL 2.1 or above, OpenGL ES 2.0 or above).\
Audio is done with OpenAL.

The project has also been ported to the [Dreamcast](https://dca3.net/).

## Installation

- re3 requires PC game assets to work, so you **must** own [a copy of GTA III](https://store.steampowered.com/app/12100/Grand_Theft_Auto_III/).
- Build re3.
- Copy **builded binary** and files from **gamefiles** folder to your GTA installation directory.

## Screenshots

![re3 2021-02-11 22-57-03-23](https://github.com/xls69/re3-unix/blob/master/res/images/re3_1.png)
![re3 2021-02-11 22-43-44-98](https://github.com/xls69/re3-unix/blob/master/res/images/re3_2.png)
![re3 2021-02-11 22-46-33-76](https://github.com/xls69/re3-unix/blob/master/res/images/re3_3.png)
![re3 2021-02-11 22-50-29-54](https://github.com/xls69/re3-unix/blob/master/res/images/re3_4.png)

## Improvements

We have implemented a number of changes and improvements to the original game.
They can be configured in `core/config.h`.
Some of them can be toggled at runtime, some cannot.

* Fixed a lot of smaller and bigger bugs
* User files (saves and settings) stored in GTA root directory
* Settings stored in re3.ini file instead of gta3.set
* Debug menu to do and change various things (Ctrl-M to open)
* Debug camera (Ctrl-B to toggle)
* Rotatable camera
* No loading screens between islands ("map memory usage" in menu)
* Skinned ped support (models from Xbox or Mobile)
* Rendering
  * Widescreen support (properly scaled HUD, Menu and FOV)
  * PS2 MatFX (vehicle reflections)
  * PS2 alpha test (better rendering of transparency)
  * PS2 particles
  * Xbox vehicle rendering
  * Xbox world lightmap rendering (needs Xbox map)
  * Xbox ped rim light
  * Xbox screen rain droplets
  * More customizable colourfilter
* Menu
  * Map
  * More options
  * Controller configuration menu
  * ...
* Can load DFFs and TXDs from other platforms, possibly with a performance penalty
* ...

## Modding

Asset modifications (models, texture, handling, script, ...) should work the same way as with original GTA for the most part.

Mods that make changes to the code (dll/asi, limit adjusters) will *not* work.
Some things these mods do are already implemented in re3 (much of SkyGFX, GInput, SilentPatch, Widescreen fix),
others can easily be achieved (increasing limis, see `config.h`),
others will simply have to be rewritten and integrated into the code directly.
Sorry for the inconvenience.

## Building from Source  

When using premake, you may want to point GTA_III_RE_DIR environment variable to GTA3 root folder if you want the executable to be moved there via post-build script.

Clone the repository with `git clone --recursive https://github.com/xls69/re3-unix.git`. Then `cd re3-unix` into the cloned repository.

<details><summary>Linux Premake</summary>

For Linux using premake, proceed: [Building on Linux](https://github.com/xls69/re3-unix/wiki/Building-on-Linux)

</details>

<details><summary>MacOS Premake</summary>

For MacOS using premake, proceed: [Building on MacOS](https://github.com/xls69/re3-unix/wiki/Building-on-MacOS)

</details>

<details><summary>FreeBSD</summary>

For FreeBSD using premake, proceed: [Building on FreeBSD](https://github.com/xls69/re3-unix/wiki/Building-on-FreeBSD)

</details>

> :information_source: premake has an `--with-lto` option if you want the project to be compiled with Link Time Optimization.

> :information_source: There are various settings in [config.h](https://github.com/xls69/re3-unix/tree/master/src/core/config.h), you may want to take a look there.

> :information_source: re3 uses completely homebrew RenderWare-replacement rendering engine; [librw](https://github.com/xls69/librw/). librw comes as submodule of re3, but you also can use LIBRW enviorenment variable to specify path to your own librw.

## Contributing
As long as it's not linux/cross-platform skeleton/compatibility layer, all of the code on the repo that's not behind a preprocessor condition(like FIX_BUGS) are **completely** reversed code from original binaries.  

We **don't** accept custom codes, as long as it's not wrapped via preprocessor conditions, or it's linux/cross-platform skeleton/compatibility layer.

We accept only these kinds of PRs;

- A new feature that exists in at least one of the GTAs (if it wasn't in III/VC then it doesn't have to be decompilation)  
- Game, UI or UX bug fixes (if it's a fix to original code, it should be behind FIX_BUGS)
- Platform-specific and/or unused code that's not been reversed yet
- Makes reversed code more understandable/accurate, as in "which code would produce this assembly".
- A new cross-platform skeleton/compatibility layer, or improvements to them
- Translation fixes, for languages original game supported
- Code that increase maintainability  

We have a [Coding Style](https://github.com/xls69/re3-unix/blob/master/CODING_STYLE.md) document that isn't followed or enforced very well.

Do not use features from C++11 or later.


## History

re3 was started sometime in the spring of 2018,
initially as a way to test reversed collision and physics code
inside the game.
This was done by replacing single functions of the game
with their reversed counterparts using a dll.

After a bit of work the project lay dormant for about a year
and was picked up again and pushed to github in May 2019.
At the time I (aap) had reversed around 10k lines of code and estimated
the final game to have around 200-250k.
Others quickly joined the effort (Fire_Head, shfil, erorcun and Nick007J
in time order, and Serge a bit later) and we made very quick progress
throughout the summer of 2019
after which the pace slowed down a bit.

Due to everyone staying home during the start of the Corona pandemic
everybody had a lot of time to work on re3 again and
we finally got a standalone exe in April 2020 (around 180k lines by then).

After the initial excitement and fixing and polishing the code further,
reVC was started in early May 2020 by starting from re3 code,
not by starting from scratch replacing functions with a dll.
After a few months of mostly steady progress we considered reVC
finished in December.

Since then we have started reLCS, which is currently work in progress.


## License

We don't feel like we're in a position to give this code a license.\
The code should only be used for educational, documentation and modding purposes.\
We do not encourage piracy or commercial use.\
Please keep derivate work open source and give proper credit.
