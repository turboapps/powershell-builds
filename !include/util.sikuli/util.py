# Common operations used in app test scripts.
from sikuli import *

# Useful paths.
util_script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
desktop = os.path.join((os.environ["USERPROFILE"]), "Desktop")
start_menu = os.path.join((os.environ["APPDATA"]), "Microsoft", "Windows", "Start Menu", "Programs")
resources_path = os.path.join(util_script_path, os.pardir, "resources")

# Minimize a window
def minimize_app(appName):
    appToMin = App().focus(appName)
    if (appToMin.isValid(),10):
        type(Key.DOWN, Key.WIN)

# Maximize a window
def maximize_app(appName):
    appToMax = App().focus(appName)
    if (appToMax.isValid(),10):
        type(Key.UP, Key.WIN)

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
def adobe_adminconsole_login(username, password, optional = False):
    maximize_app("Admin Console")
    maximize_app("Adobe ID")
    if exists("adobe-login.png",20):
        click(Pattern("adobe-login.png").targetOffset(-113,-21))
        wait(3)
        type(username)
        wait(3)
        type(Key.ENTER)
        if exists("adobe_login_pass_dark.png",20):
            click("adobe_login_pass_dark.png")
        if exists("adobe_login_pass.png",20):
            click("adobe_login_pass.png")
        wait(3)
        type(password)
        wait(3)
        type(Key.ENTER)
        if exists("save-password-prompt.png",10):
            click(Pattern("save-password-prompt.png").targetOffset(141,-4))

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
def file_exists(path, try_limit):
    tried = 0
    while tried < try_limit:
        if os.path.exists(path):
            return True
        tried += 1
        time.sleep(10)
    return False

# Close the Windows firewall alert prompt.
def close_firewall_alert():
    if exists("firewall.png", 20):
        click(Pattern("firewall.png").targetOffset(212,67))

def build_ccd():
    # Read credentials from the secrets file.
    credentials = get_credentials(os.path.join(resources_path, "secrets.txt"))
    username = credentials.get("username")
    password = credentials.get("password")    
    # Launch the Adobe Admin Console, login and build the installer
    run('explorer "https://adminconsole.adobe.com"')
    close_firewall_alert()
    # Login to the Admin Console
    adobe_adminconsole_login(username, password)
    # Wait for the Packages link to load
    wait("packages-link.png")
    if exists("admin-console-welcome.png"):
        type(Key.ESC)
    wait(10)
    click("packages-link.png")
    #Build package and download Creative Cloud Desktop
    wait("create-a-package-button.png",10)
    click("create-a-package-button.png")
    click(Pattern("managed-package-checkbox.png").targetOffset(127,-2))
    click("next-button.png")
    wait("select-platform-dropdown.png")
    click(Pattern("select-platform-dropdown.png").targetOffset(72,8))
    wait("64bit-dropdown.png")
    click(Pattern("64bit-dropdown.png").targetOffset(-41,0))
    click("next-button.png")
    wait("search-button.png")
    click("search-button.png")
    type("creative cloud desktop")
    click(Pattern("select-ccd-app.png").targetOffset(161,0))
    click("next-button.png")
    click("next-button.png")
    click(Pattern("self-service-checkbox.png").targetOffset(-83,-2))
    click(Pattern("scroll-down.png").targetOffset(1,35))
    click(Pattern("remote-update-checkbox.png").targetOffset(-105,-1))
    click("next-button.png")
    type("CreativeCloudDesktop_x64")
    click("create-package-button.png")
    wait("folder-button.png",90)
    waitVanish("wait-preparing.png")