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
setAutoWaitTimeout(90)
if exists("folder-button.png"):
    click(Pattern("folder-button.png").targetOffset(-14,0))
#setAutoWaitTimeout(600)

adobefile_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\CreativeCloudDesktop_x64_en_US_WIN_64.zip")
while not os.path.exists(adobefile_path):
    wait(20)
closeApp("Edge")
