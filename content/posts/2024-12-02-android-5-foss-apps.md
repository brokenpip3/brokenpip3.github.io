+++
title = '5 F-droid apps that will change your android experience for good'
date = 2024-02-11T00:53:20+01:00
draft = "false"
toc = "true"
tags = [ "android", "f-droid", "foss", "newpipe", "termux", "aegis", "habits"]
+++

It's been a while since every time I need a general-purpose app, I always investigate which FOSS alternatives are present in F-Droid before the Google Play Store. Today, I'm going to present five of these software options that are changing my experience as an Android user, and I hope they will change yours as well.


## Wait, What is F-Droid Anyway?

![F-droid](/images/5-fdroid-apps/fdroid-logo.png)

F-Droid is a privacy-focused alternative to the Google Play Store. It's a community-driven repository that exclusively hosts open-source android apps. Unlike the Play Store, F-Droid apps prioritize user privacy, with no ads or tracking in the store, but also provides transparency through the [Anti-Features](https://f-droid.org/en/docs/Anti-Features/) system, which highlights any features in apps that may compromise user privacy or freedom.
You can download the apk from the official [site](https://f-droid.org/) and [verify](https://f-droid.org/docs/Verifying_Downloaded_APK/) it.

## Newpipe

![newpipe_sub](/images/5-fdroid-apps/newpipe_subs.png)

* [Fdroid store page](https://f-droid.org/packages/org.schabi.newpipe/)
* [Official site](https://newpipe.net/)
* [Code](https://github.com/TeamNewPipe/NewPipe/)
* [Donate](https://liberapay.com/TeamNewPipe/)

My life would probably be different without `newpipe`. No joking: Newpipe is **the** F-Droid app that everyone should try. It offers the authentic YouTube experience without any compromise (i.e., ads, sending data to Google). And any feature is supported **without the need for YouTube or any other kind of profile**. Let's see some of them:

* Listen to audio in the background and switch to video anytime (this is the killer feature that will transform any video into a podcast).
* Zero ads or tracking.
* Download, store, and tag videos.
* Subscribe to any YouTube channel, watch streams, and shorts (that I personally [hate](https://old.reddit.com/r/uBlockOrigin/comments/143mdqv/code_to_block_youtube_shorts_june_2023/jsem2mh/)).
* YouTube advanced features like subs and chapters.
* Create any playlist, enable notifications, view watch history, trending videos (that I have both disabled).
* Export/import all settings (so you can move your subs, settings, and playlist from one phone to another).
* And many more.

It's basically how the YouTube app experience should be (since now the creators' funding is coming from sponsors, community, and products), and it's part of my regular Android flow.

A couple of suggestions if you want to try it:

* Add the Newpipe repo in F-Droid to always have the latest version because the one in the general F-Droid repo is always outdated. Go to settings, repositories, add a new one, and use this [URL](https://archive.newpipe.net/fdroid/repo/?fingerprint=E2402C78F9B97C6C89E97DB914A2751FDA1D02FE2039CC0897A462BDB57E7501).

* There are several different options that you can tweak in the settings, but my suggestion is to:
    * Disable the search history.
    * Add the "What's New" as the welcome tab and remove others like trending.
    * Start adding some channels and create categories for each of them.

## Aegis

![aegis](/images/5-fdroid-apps/aegis.png)

* [Fdroid store page](https://f-droid.org/packages/org.schabi.newpipe/)
* [Official site](https://getaegis.app/)
* [Code](https://github.com/beemdevelopment/Aegis/tree/master)
* [Donate](https://www.buymeacoffee.com/beemdevelopment)

How many times have you needed a 2-factor authentication app and ended up using Google Authenticator or Microsoft Authenticator, perhaps even with cloud sync options? Or have you found yourself with several of them, each for a different purpose (like gaming portals, OAuth SaaS software, etc.)?

How many times have you lost your smartphone and ended up resetting all the 2-factor authentication for your accounts?

Aegis is the answer to all your questions. It's an open-source authenticator app that provides everything you need, including:

* Password and biometric login
* **Encrypted** backup and restore
* Categories, views, icons, and hide settings
* Several "import from other apps" options

My suggestion here is: always run scheduled encrypted backup and copy the files in your nas so you will never loose a single 2f access.

## Termux

![clang](/images/5-fdroid-apps/termux.jpg)

* [Fdroid store page](https://f-droid.org/packages/com.termux/)
* [Official site](https://termux.com/)
* [Code](https://github.com/termux/termux-app/)
* [Donate](https://termux.com/donate)

How many times have you thought, "Is it possible that to just run some SSH or network check commands, I need to install and trust several ad-filled apps?"

Termux is here to fix it for you. It's a powerful terminal emulator allowing you to run those commands on your smartphone or tablet. Short list of main features (I don't think I need to explain what a terminal emulator is):

* Install and run software from Debian repo with a simple package management system.
* Utilize powerful tools like git, ssh, tmux, and vim (anything that fit well on your screen)
* Use bash or zsh and write shell scripts to [automate](https://wiki.termux.com/wiki/Termux:Tasker) tasks on your device.

Pro tip:
  * you can even [extend](https://wiki.termux.com/wiki/Main_Page#Addons) Termux's functionality with additional packages.
  * if you are a `nix` guy (like me) there is a [fork](https://github.com/nix-community/nix-on-droid-app) for that.

## Loop Habit Tracker

![habits](/images/5-fdroid-apps/habits.png)

* [Fdroid store page](https://f-droid.org/en/packages/org.isoron.uhabits/)
* [Official site](https://loophabit.com/)
* [Code](https://github.com/iSoron/uhabits)
* [Donate](https://loophabit.com/donate)

Are you struggling to build and maintain healthy habits? Do you find it challenging to track your progress and stay motivated, or are you tired of using apps that restrict access to stats unless you pay?

Loop Habit Tracker is a simple and intuitive habit tracking app designed to address these issues. Its main features include:

* Setting up customizable habits to track your daily activities.
* Monitoring your progress with clear and insightful visualizations.
* Setting up notifications to ensure you stay on track with your habits.
* Exporting/importing all your data and settings.

## GymRoutines

![gym](/images/5-fdroid-apps/gymroutines.png)

* [Fdroid store page](https://f-droid.org/en/packages/com.noahjutz.gymroutines/)
* [Official site](https://noahjutz.com/gymroutines/)
* [Code](https://github.com/NoahJutz/GymRoutines)
* [Donate](https://liberapay.com/noahjutz) (currently suspended)

When dealing with gym exercises, wasting time subscribing to vendor apps or writing exercises down with pen and paper is not ideal.

GymRoutines simplifies this process by allowing you to:

* Create and customize your workout routines by selecting generic exercises.
* Easily track your sessions, starting from a routine.
* Log reps, weight, time, and distance.

It's simple yet effective, ensuring you don't waste time on your phone during your workout sessions! :D

## Conclusion

As you can see, all of these apps allow you to import/export data and do not track you while you are using them. If you find one of these apps useful, please consider donating to support their development, just like I do, to keep the ball rolling.
