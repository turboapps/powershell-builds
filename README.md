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

To run the tests, start by cloning this repository onto your local machine and installing the Turbo Client. Navigate to the `_INCLUDE` folder and locate the `Test` folder. Inside this folder, insert your Turbo Server API Key and domain information into the `placeholder_secrets.txt` file, and then rename it to `secrets.txt`. As the GUI-based tests are resolution-dependent, ensure the resolution is set to 1200 X 900. Next, navigate to the `Test` folder within the app folder you want to test and run the `executor.bat` file. For some apps, you need to edit the `secrets.txt` file inside the `resources` folder for the credentials. It may be necessary to close the Explorer window for the `Test` folder during the test and perform some cleanup tasks after the test. The test environment should not contain the native version of that application and a clean environment is recommended to use for the tests.

The tests are executed using [SikuliX](http://sikulix.com/), a GUI-based testing tool that compares expected screenshots with the current display content. The test scripts are written in Python syntax. Each app test folder contains a `test.py` script within the `test.sikulix` directory. The script for the 7-Zip app is well-documented, serving as a useful example for understanding the script structure. When creating new test scripts, it is highly recommended to refer to the [SikuliX Documentation](https://sikulix-2014.readthedocs.io/en/latest/index.html) for guidance and best practices. The `Test` folder inside the `_INCLUDE` folder houses common code and shared resources utilized by all test scripts.