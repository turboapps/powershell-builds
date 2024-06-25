script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
util_path = os.path.join(script_path, os.pardir, "util.sikuli")
sys.path.append(util_path)
import util
reload(util)
addImagePath(util_path) # This is needed to include screenshots from "util".

setAutoWaitTimeout(20)
util.minimize_app("java")

# Launch Admin Console, login and build the CreativeCloudDesktop installer
util.build_ccd()

# Build the applcation installer
setAutoWaitTimeout(20)
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
type("animate")
click(Pattern("select-app.png").targetOffset(159,0))
click("next-button.png")
click("next-button.png")
click(Pattern("self-service-checkbox.png").targetOffset(-83,-2))
click(Pattern("scroll-down.png").targetOffset(1,35))
click(Pattern("remote-update-checkbox.png").targetOffset(-105,-1))
click("next-button.png")
type("Animate_x64")
click("create-package-button.png")
setAutoWaitTimeout(90)
if exists("folder-button.png"):
    click(Pattern("folder-button.png").targetOffset(-14,0))
setAutoWaitTimeout(600)

adobefile_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\Animate_x64_en_US_WIN_64.zip")
while not os.path.exists(adobefile_path):
    wait(10)
closeApp("Edge")
