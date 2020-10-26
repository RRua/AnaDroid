# AnaDroid

This tool was developed to be used by Android developers to test their apps' perfomance, using a wide set of testing frameworks with minimal effort. It can automatically test an application and its source code, collecting a vast number of metrics related to app performance, namely regarding energy performance.  AnaDroid offers a generic way of integrating the ability to measure the energy  and resource usage of Android applications. This tool can be used during the development process to test and monitor the execution of Android applications. AnaDroid was inpired by the [GreenDroid](https://github.com/greensoftwarelab/GreenDroid) framework, resulting in an extension of such tool in terms of features and supported testing frameworks and profilers.

 
AnaDroid is the ideal tool for testing applications in bulk and establishing comparisons between them, as it is able to record and define system and device states under test, ensuring that a possible comparison between comparable applications can be made due to having been evaluated under the same test conditions.
Optionally, the developer can share its results, using AnaDroid to send its data to  [GreenSource](http://greenlab.di.uminho.pt/greensource/) open-access repository.

## How it works

This tool can be used to perform both blackbox and whitebox testing. To estimate energy consumption, it uses Trepn Profiler or/and Greenscaler. In order to perform tests over an app, the user can select one of the following testing frameworks:
- Monkey;
- Monkeyrunner;
- JUnit (or any other junit-based, like Espresso or Robotium);
- [RERAN](https://www.androidreran.com/);
- [APP CRAWLER](https://developer.android.com/training/testing/crawler);



When using the whitebox approach, AnaDroid automatically instruments the application source code in order include calls to Energy profiler and perform method tracing. Then automatically builds the APK and installs it in an physical device. Then, using an pre-defined testing framework, is able to monitor the execution and invocation of source code blocks (methods/functions), estimating its energy and resources (hardware and sensors) usage/consumption.

## Extracted Metrics:
The AnaDroid framework is able to extract all of the following metrics. The dynamic metrics (+) can be extracted at different levels: Application, Test, Class or Method level.

(+) Current active keyboard

(-) Android APIs (APIs used from the Android SDK)

(-) JAVA APIs (APIs used from the Java SDK)

(-) External APIs (Other APIs(from the project sources or other project dependencies))

(+) Wifi State (If  Wifi was used)

(+) Mobile Data State (If mobile data was used)

(+) Screen State (If screen was turned on)

(+) Battery Status (Percentage of battery)

(+) Battery Temperature (degrees)

(+) Battery Charging (If Battery was charging)

(+) Battery Voltage

(+) Wifi RSSI Level (Level of RSSI)

(+) Bluetooth State (If Bluetooth was used)

(+) GPU Frequency (GPU frequency)

(+) CPU Load Frequency (CPU load frequency (per core))

(+) GPS State (if GPU was used)

(+) Elapsed Time 

(+) Total Energy (Total energy consumed)

(+) Memory (main memory consumed)

(+) Total Coverage (total method coverage)

(+) Nr of running processes (Number of other processes running simultaneously)

(-) Method length 

(-) Nr of method instructions

(-) Method locals

(-) Class variables

(-) Nr Args (number of arguments of methods)

(-) Nr of classes (number of classes)




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
### Set Environment variables

In order to AnaDroid can be automatically used in further sessions, you must set at least the following variables (if not present) to your .bashrc or .bash_profile file:
```
export ANADROID_PATH=<Absolute-path-to-AnaDroid-folder>
export PATH=$PATH:$ANADROID_PATH
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
- [Trepn Profiler](https://play.google.com/store/apps/details?id=com.quicinc.trepn).

This command will also setup your device (if connected to your machine) so it can be prepared to monitor the execution of Android applications. It will create a support directory in the device (virtual) external storage and install (via USB) some auxiliary applications:

## Set more Environment variables

In order to AnaDroid can be automatically used in further sessions, you must set the following variables so the AnaDroid framework can find the executables related included with the android sdk. Again, you can set these variables in your .bashrc or .bash_profile file:
```
export ANDROID_HOME=$HOME/android-sdk/ 
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH

```
cd AnaDroid
make install
```

## USAGE:

```
$ anaDroid  [-o|--orientation <orientation>] 
            [-p|--profiler <prof>] 
            [-f|--framework <frame>] 
            [-b|--build <bd>] 
            [-u|--url <url> ] 
            [-s|--silent <sil>] 
            [-d|--dir project_<dir> ]
```
