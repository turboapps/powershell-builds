script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
util_path = os.path.join(script_path, os.pardir, "util.sikuli")
resources_path = os.path.join(script_path, os.pardir, "resources")
sys.path.append(util_path)
import util
reload(util)
addImagePath(util_path) # This is needed to include screenshots from "util".

setAutoWaitTimeout(20)
util.minimize_app("java")

# Read credentials from the secrets file.
credentials = util.get_credentials(os.path.join(resources_path, "secrets.txt"))
username = credentials.get("username")
password = credentials.get("password")    
# Launch the Adobe Admin Console, login and build the installer
run('explorer "https://adminconsole.adobe.com"')
util.close_firewall_alert()
# Login to the Admin Console
util.adobe_adminconsole_login(username, password)

wait("wait-packages-link.png")
if exists("admin-console-welcome.png"):
    type(Key.ESC)
click("wait-packages-link.png")
#Build package and download Creative Cloud Desktop
wait("wait-create-package-button.png")
click("wait-create-package-button.png")
click(Pattern("click-managed-package.png").targetOffset(127,-2))
click("click-next.png")
wait("select-platform-dropdown.png")
click(Pattern("select-platform-dropdown.png").targetOffset(72,8))
wait("64bit-dropdown.png")
click(Pattern("64bit-dropdown.png").targetOffset(-41,0))
click("click-next.png")
wait("wait-mag-glass.png")
click("wait-mag-glass.png")
type("creative cloud desktop")
wait("version.png")
doubleClick(Pattern("version.png").targetOffset(38,11))
click("click-copy.png")
run('explorer "C:\\windows\\system32\\notepad.exe"') 
wait("wait-notepad.png")
type("v", Key.CTRL)
wait(2)
type("s", Key.CTRL)
wait(2)
type("%USERPROFILE%\\desktop\\version.txt")
type(Key.ENTER)
wait(5)
closeApp("Notepad")
closeApp("Edge")

