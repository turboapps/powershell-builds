# Common operations used in app test scripts.

from sikuli import *

# Useful paths.
desktop = os.path.join((os.environ["USERPROFILE"]), "Desktop")
start_menu = os.path.join((os.environ["APPDATA"]), "Microsoft", "Windows", "Start Menu", "Programs")

# Operations before running app test.
def pre_test(hide_cmd = True):
    # OneDrive should not be captured
    assert(not os.path.exists(os.path.join(start_menu, "OneDrive (2).lnk")))

    # Hide the cmd window.
    if hide_cmd:
        App("cmd.exe").focus()
        type(Key.DOWN, Key.WIN)
        
    # Hide the java window (started by SikuliX).
    App("java.exe").focus()
    type(Key.DOWN, Key.WIN)

# Get credentials that will be used in a test from secrets.txt. That secret file locates under the "resources" folder of the corresponding app folder.
def get_credentials(path):
    credentials = {}
 
    with open(path, "r") as file:
        lines = file.readlines()
        for line in lines:
            key, value = line.strip().split(",")
            credentials[key] = value

    return credentials

# Get the path of the shortcut for the apps that have different shortcut names for different versions.
# Assume there is only one match inside the folder.
def get_shortcut_path_by_prefix(folder_path, prefix):
    files = os.listdir(folder_path)
    matching = [file for file in files if file.startswith(prefix)]
    return os.path.join(folder_path, matching[0])

# Close the Windows firewall alert prompt.
def close_firewall_alert():
    wait("firewall.png", 60)
    click(Pattern("firewall.png").targetOffset(212,67))

# Check if the most recently created Turbo container is terminated.
# It is usually the container for the app to be tested.
def check_running():
    assert("Running" not in run("turbo containers -l"))