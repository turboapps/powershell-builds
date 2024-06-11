PREPARE THE CAPTURE DEVICE:

1. On a clean packaging Windows device, download and unzip the script repo: https://github.com/turboapps/powershell-builds/archive/refs/heads/main.zip
(Tip: Reference doc for preparing a clean capture device: https://hub.turbo.net/docs/studio/working-with-turbo-studio/clean-capture-system)

2. Install Turbo Studio: Download and install Turbo Studio to the default location from: https://turbo.net/download#enterprise-and-developer

3. Install Turbo Client: Only required if you want to Import the image after build and pushing to your Turbo Server
Download and install Turbo client from: https://turbo.net/download#client

4. 1080p Resolution:  Some of the builds use SikulixIDE to perform functions that require user interaction.  The Sikulix scripts use image recognition and may fail if the resolution on the capture device is not 1080p (1920x1080).

RUN THE IMAGE BUILDER:

1. Launch the TurboImageBuilder.hta

2. Paste your Turbo Studio license into the text box and click Update.
The license will be written to .\!include\License.txt

3. Select an application that you want to build an image from the dropdown box.

4. If you select an application that uses SikulixIDE you may need to supply a username and password for login to the vendor site.
The username and password will be written to .\SupportFiles\Sikulix\Resources\secrets.txt for use by the Sikulix script.

5. Import: (Optional) Check the "Import after build" box if you want the image to be imported to your local repo.
(Note: requires the Turbo Client to be installed)

6. Push: (Optional) Supply the "Turbo Server URL" and "Api Key" for your Turbo Server if you want the image to be pushed to your Hub upon successful build.  You must also check the Import box.
(Note: requires the Turbo Client to be installed)

7. Build: Click the "Build Image" button to run the Powershell script. Find the completed build in: %userprofile%\Desktop\Package\TurboCapture\
    Capture.xappl - the unmodified configuration from the capture.
    FinalCapture.xappl - the configuration including changes. Used to build the SVM.
    Build.svm - the completed image.

8. Logs: The build log file is written to %userprofile%\Desktop\Package\Log
