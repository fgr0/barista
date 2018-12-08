# Barista

Barista is a [Caffeine][] clone--a menu bar application that can prevent your
Mac from going to sleep. It was created in 2014 as a personal project to learn
Swift and macOS development.


## About

This application differs from the original [Caffeine][] and from other modern
alternatives in that it is build upon `IOPMlib`, the official API for
controlling the system sleep. It also has some unique features like being able
to prevent sleep *without* keeping the displays on and showing other
applications that are preventing your Mac from sleeping.

Since this application is mostly a personal experiment and not under regular
development, I suggest checking out Marcel Dierkes' [KeepingYouAwake][]. I can't
provide support for this application or provide any guarantees about its safety.
**Use at your own risk**. Regardless, if you find any issues or have
suggestions, feel free to open an issue or create a pull-request—any feedback
is welcome.


## Features

### Preventing sleep

Barista's main function is to prevent your Mac from sleeping. You can choose if
it will run forever, a set time, or until the next morning (3am). Per default it
will run until you manually disable it, but you can change the default in the
Preferences. The menu also has an 'Activate for...' option, where you can choose
how long to run for only this activation.

The app also differentiates between *Preventing Display Sleep* and *Preventing
Idle Sleep*. Both stop your Mac from sleeping, the difference is, that
*Preventing Display Sleep* also stops your Monitors from turning off where as
*Preventing Idle Sleep* will let your Monitors go to standby. This can be useful
in several situations, for example when you are downloading a big file or
running a long backup where you want to ensure that your Mac stays online but
you don't need your displays running.

On MacBooks, Barista can deactivate itself when the system switches from being
plugged in to battery or when the battery falls below a certain threshold. You
can control these settings and customize the threshold in the preferences.

### Monitoring

The second major feature of Barista is the ability to show other applications
that are preventing your Mac from going to sleep. By using ⌥-click on the menu bar
icon, a detailed list of other applications that are currently preventing the
system from sleeping is shown.

Using the Preferences you can also choose to show information about other
applications without having to use ⌥-click.


## Development

As mentioned, the app is fully written in Swift 4 and is mostly a crude wrapper
around Apple's `IOPMlib.h`, which is an old, poorly documented C API that could
really use an update. It is currently deployed against macOS 10.11, but I have
only tested it on 10.13, though I guess it should work on older versions.
Barista has no external dependencies.

I am trying to keep the project up to date using the newest version of Swift and
Xcode, though it might take me a couple of weeks or month to get around doing
it. Any help is greatly appreciated.


## Changelog

- [Version 1.3.0 Beta](../../tree/version-1.3.0) (*in development*):
  * [ ] Setup Project for Localization
  * [ ] Create German Translation


- **[Version 1.2.0 Beta](../../releases/tag/v1.2.0-beta)** (December 2018):
  * Switch Development to Xcode 10/Swift 4.2
  * Support macOS 10.14 Dark Mode
  * New Battery-related preferences:
    * Automatic deactivation when switching to battery power
    * Deactivate when falling below a user-chosen battery level

- [Version 1.1.0 Beta](../../releases/tag/v1.1.0-beta) (June 2018):
  * Show more sleep-preventing Applications (Time Machine)
  * Ability to show System Uptime and time since last wake.
  * Bugfixes and Project Cleanup

- [Version 1.0.0 Beta](../../releases/tag/v1.0.0-beta) (April 2018):
  * Complete rewrite
  * Added Preference window
  * Added *Monitoring* feature

## License

Barista is licensed under the [BSD-2-Clause license](./LICENSE.md).


[Caffeine]: http://lightheadsw.com/caffeine/
[KeepingYouAwake]: https://github.com/newmarcel/KeepingYouAwake
