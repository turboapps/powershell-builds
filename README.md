## Build

1. On a clean packaging device, download and unzip the script repo: </br>
https://github.com/turboapps/powershell-builds/archive/refs/heads/main.zip

2. Launch the TurboImageBuilder.hta

3. Paste your Turbo Studio license into the text box and click Update.

4. Select an application that you want to build an image from the dropdown box and click Build Image.

5. Accept the UAC prompt.

6. Find the completed build in: "%userprofile%\Desktop\Package\TurboCapture\"
Capture.xappl - the unmodified configuration from the capture.
FinalCapture.xappl - the configuration including changes. Used to build the SVM.
Build.svm - the completed image.

## Test

This repository also contains test scripts for the applications (images) generated from the automatic build process. These scripts are designed to ensure the functionality and performance of the applications, focusing on key operations such as app launch, basic functions, file handling, and user assistance features.

The tests are executed using [SikuliX](http://sikulix.com/), a GUI-based testing tool that compares expected screenshots with the current display content. The test scripts are written in Python syntax. To run the tests, you must first install the Turbo client to pull images of SikuliX (`sikulix/sikulixide`) and JDK (`microsoft/openjdk`). Then, execute the `executor.bat` file located within each app folder. You may need to close the Explorer window for the folder. And the test environment should not contain the native version of that application.

The `_INCLUDE` folder houses common code and shared resources utilized by all test scripts. It is essential to include a `secrets.txt` file inside the Common folder for logging into the Turbo server. Additionally, a `secrets.txt` file can be placed within the resources of the app folder that needs to manage login credentials effectively.

Each app folder contains a `test.py` script within the `test.sikulix` directory. The script for the 7-Zip app is well-documented, serving as a useful example for understanding the script structure. When creating new test scripts, it is highly recommended to refer to the [SikuliX Documentation](https://sikulix-2014.readthedocs.io/en/latest/index.html) for guidance and best practices.