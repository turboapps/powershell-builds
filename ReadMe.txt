1. Paste your Turbo Studio License into "License.txt" in the ..\_INCLUDE folder.

2. Copy the application folder that you want to package and the ..\_INCLUDE folder to the same location on a clean VM.

3. From an elevated command prompt run:
powershell -executionpolicy bypass -file "<application_folder_path>\BuildTurboImage.ps1"

4. Find the completed build in: "%userprofile%\Desktop\Package\TurboCapture\"
Capture.xappl - the unmodified configuration from the capture.
FinalCapture.xappl - the configuration including changes. Used to build the SVM.
Build.svm - the completed image.