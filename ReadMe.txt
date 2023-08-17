1. On a clean packaging device, download and unzip the script repo: 
https://github.com/turboapps/powershell-builds/archive/refs/heads/main.zip

2. Launch the TurboImageBuilder.hta

3. Paste your Turbo Studio license into the text box and click Update.

4. Select an application that you want to build an image from the dropdown box and click Build Image.

5. Accept the UAC prompt.

6. Find the completed build in: "%userprofile%\Desktop\Package\TurboCapture\"
Capture.xappl - the unmodified configuration from the capture.
FinalCapture.xappl - the configuration including changes. Used to build the SVM.
Build.svm - the completed image.
