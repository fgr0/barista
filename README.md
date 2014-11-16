# Barista
A small [Caffeine](http://lightheadsw.com/caffeine/) clone written in Swift

## About

Barista is my first OS X Application and an attempt to create a fully transparent Caffeine clone, with Dark Mode support and using official APIs to prevent system sleep.

This app uses a wrapper around the IOPMlib C-APIs needed to create and control a power assertion. That means, that the assertions created by Barista will be registered with pmset (the system power management service).


### Characteristics
* (should) work only on OS X 10.10 Yosemite
* Behaviour is analogue to system status items like wifi or timemachine
* can prevent sleep _with or without_ allowing the monitor to shut off
* does __not__ prevent clamshell-sleep (as far as I know impossible to implement with public apis)
* should be considered __beta__ software
* does not (yet) have an icon



