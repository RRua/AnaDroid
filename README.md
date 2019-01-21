# AnaDroid

This tool was developed to be used by Android developers, as well as gather and centralize its results in an open-access repository named [GreenSource](http://greenlab.di.uminho.pt/greensource/). 

The AnaDroid offers a generic way of integrating the ability to measure the energy  and resources usage of Android applications. This tool can be used during the development process to test and monitor the execution of Android applications. It is the evolution of the [GreenDroid](https://github.com/greensoftwarelab/GreenDroid) framework. 

## What it does?
This tool automatically instruments the source code of Android Projects in order include calls to an energy profiler. Then automatically builds the APK and installs it in an physical device. Then, using an pre-defined testing framework, is able to monitor the execution and invocation of source code blocks (methods/functions), estimating its energy and resources (hardware and sensors) usage/consumption.

In the end of the execution,  it uninstalls the AUT (App Under Test) and presents the results to the developer. It also sends (if enabled) the results to the [GreenSource](http://greenlab.di.uminho.pt/greensource/) repository. 


## Current status:
We are extending this framework in order to be able to use more Android testing frameworks and Energy profilers. 


## Requirements

- *NIX based machine (MAC OS, Linux, etc)
- An Android physical device with these options enabled:
    - Developer mode;
        - USB debbuging;
        - Install via USB;
        - Stay awake.



## Installation

### Download
```
git clone https://github.com/RRua/AnaDroid.git
```
### Install
The ```make install``` command will setup the environment, installing the required tools to compile, build and run Android Projects.
The required tools are the following (if necessary):
- [GNU core utils](https://www.gnu.org/software/coreutils/);
- Java 8 or above;
- Python;
- Android Sdk;
- [SDKMAN](https://sdkman.io/);
- [Gradle](https://gradle.org/).

This command will also setup your device (if connected to your machine) so it can be prepared to monitor the execution of Android applications. It will create a support directory in the device (virtual) external storage and install (via USB) some auxiliary applications:
- [Simiasque](https://github.com/Orange-OpenSource/simiasque);
- [Trepn Profiler](https://play.google.com/store/apps/details?id=com.quicinc.trepn).

```
cd AnaDroid
make install
```
### Set Environment variables

In order to AnaDroid can be automatically used in further sessions, you must add at least the following instructions (if not present)in your .bashrc or .bash_profile file:
```
export ANADROID_PATH=<Absolute-path-to-AnaDroid-folder>
export PATH=$PATH:ANADROID_PATH
export ANDROID_HOME=$HOME/android-sdk/ 
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
```

## USAGE:

```
$ anaDroid  [-o|--orientation orientation] 
            [-p|--profiler prof] 
            [-f|--framework frame] 
            [-b|--build bd] 
            [-u|--url url ] 
            [-s|--silent sil] 
            [-d|--dir project_dir ]
```