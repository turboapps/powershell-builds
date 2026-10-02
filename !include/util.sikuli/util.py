# Common operations used in app test scripts.
from sikuli import *
import time

# Useful paths.
util_script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
desktop = os.path.join((os.environ["USERPROFILE"]), "Desktop")
start_menu = os.path.join((os.environ["APPDATA"]), "Microsoft", "Windows", "Start Menu", "Programs")
resources_path = os.path.join(util_script_path, os.pardir, "resources")

# Minimize a window
def minimize_app(appName):
    appToMin = App().focus(appName)
    if appToMin.isValid():
        type(Key.DOWN, Key.WIN)

# Maximize a window
def maximize_app(appName, timeout=10):
    app = App.focus(appName)
    if not app.isValid():
        print("maximize_app: could not find/focus '%s'" % appName)
        return False

    # Wait for the focused window to be available
    win = None
    end = time.time() + timeout
    while time.time() < end:
        win = App.focusedWindow()
        if win is not None and win.w > 0:
            break
        wait(0.5)
    if win is None:
        print("maximize_app: no focused window for '%s'" % appName)
        return False

    scr = SCREEN
    # A maximized window is about the size of the screen, minus the taskbar
    # only maximize a window that is not already maximized
    if win.w < scr.w - 20 or win.h < scr.h - 80:
        type(Key.UP, Key.WIN)
        wait(0.5)
    return True

# Get credentials from secrets.txt. That secret file locates under the "resources" folder of the app script folder.
def get_credentials(path):
    credentials = {}
 
    with open(path, "r") as file:
        lines = file.readlines()
        for line in lines:
            key, value = line.strip().split(",")
            credentials[key] = value

    return credentials

# Log in for Adobe Creative Cloud.
def adobe_adminconsole_login():
    # Read credentials from the secrets file.
    credentials = get_credentials(os.path.join(resources_path, "secrets.txt"))
    username = credentials.get("username")
    password = credentials.get("password")    
    # Launch the Adobe Admin Console, login and build the installer
    run('explorer "https://adminconsole.adobe.com"')
    # close_firewall_alert()
    
    # Login to the Admin Console
    maximize_app("Edge")
    if exists("adobe-login.png",20):
        click(Pattern("adobe-login.png").targetOffset(-113,-21))
        wait(3)
        paste(username)
        wait(3)
        type(Key.ENTER)
        wait(5)
        paste(password)
        wait(3)
        type(Key.ENTER)
        wait(5)

# Get the path of the shortcut for the apps that have different shortcut names for different versions.
# Assume there is only one match inside the folder.
def get_shortcut_path_by_prefix(folder_path, prefix):
    files = os.listdir(folder_path)
    matching = [file for file in files if file.startswith(prefix)]
    return os.path.join(folder_path, matching[0])

# Given a partial file name and path find the file and return the path.
# Useful for searching for a shortcut that changes names eg. PowerBI RS.
def find_file(folder_path, partial_name):
    # Check if the folder path exists.
    if not os.path.exists(folder_path):
        return None   
    # Iterate over files in the folder.
    for file_name in os.listdir(folder_path):
        # Check if the partial name is in the file name.
        if partial_name in file_name:
            # Return the full path of the first matching file.
            return os.path.join(folder_path, file_name) 
    # If no matching file is found, return None.
    return None

# Check if a file exists. It checks every 10 seconds unitl `try_limit` is reached.
def file_exists(path, timeout):
    start = time.time()
    last_size = -1
    while time.time() - start < timeout:
        if os.path.exists(path):
            size = os.path.getsize(path)
            if size > 0 and size == last_size:
                return True
            last_size = size
        wait(10)
    return False

# Close the Windows firewall alert prompt.
def close_firewall_alert():
    if exists("firewall.png", 20):
        click(Pattern("firewall.png").targetOffset(212,67))

def build_ccd():
    # Login to the Admin Console
    adobe_adminconsole_login()
    build_adobe_app(Pattern("select-ccd-app.png").targetOffset(161,0),"creative cloud desktop","CreativeCloudDesktop_x64")
    wait("folder-button.png",90)
    waitVanish("wait-preparing.png")

def pick_adobe_app(adobe_app_name):
    # Wait for the Packages link to load
    wait(Pattern("packages-link.png").similar(0.90),30)
    click(Pattern("packages-link.png").similar(0.90))
    wait(5)
    #Build package and download Creative Cloud Desktop
    click(wait("create-a-package-button.png",10))
    wait(2)
    click(wait(Pattern("managed-package-checkbox.png").targetOffset(127,-2),10))
    wait(2)
    click("next-button.png")
    wait(2)
    click(wait(Pattern("select-platform-dropdown.png").targetOffset(72,8),10))
    wait(2)
    click(wait(Pattern("64bit-dropdown.png").targetOffset(-41,0),10))
    wait(2)
    click("next-button.png")
    wait(2)
    click(wait(Pattern("search-button.png").targetOffset(-5,23),10))
    wait(2)
    paste(adobe_app_name)
    wait(2)
    
def build_adobe_app(adobe_app_image,adobe_app_name,output_file_name):
    pick_adobe_app(adobe_app_name)
    click(adobe_app_image)
    click("next-button.png")
    click("next-button.png")
    click(Pattern("self-service-checkbox.png").targetOffset(-83,-2))
    click("scroll-down.png")
    wait(2)
    click(Pattern("remote-update-checkbox.png").targetOffset(-105,-1))
    wait(2)
    click(Pattern("create-folder-checkbox.png").targetOffset(-216,1))
    click("next-button.png")
    wait(3)
    paste(output_file_name)
    wait(3)
    click("create-package-button.png")

def get_adobeapp_version(adobe_app_name,version_image):
    pick_adobe_app(adobe_app_name)
    wait("version.png")
    doubleClick(version_image)
    wait(3)
    type("c", Key.CTRL)
    wait(2)
    run('explorer "C:\\windows\\system32\\notepad.exe"') 
    wait("wait-notepad.png",10)
    wait(2)
    click("wait-notepad.png")
    type("v", Key.CTRL)
    wait(2)
    type("s", Key.CTRL)
    wait(2)
    paste("%USERPROFILE%\\desktop\\version.txt")
    wait(2)
    type(Key.ENTER)
    wait(5)
    closeApp("Notepad")
    closeApp("Edge")
