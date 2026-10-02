script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
util_path = os.path.join(script_path, os.pardir, "util.sikuli")
sys.path.append(util_path)
import util
reload(util)
addImagePath(util_path) # This is needed to include screenshots from "util".

util.minimize_app("java")
setAutoWaitTimeout(20)
# Launch Admin Console, login and build the CreativeCloudDesktop installer
util.build_ccd()
util.build_adobe_app(Pattern("select-app.png").targetOffset(157,-2),"lightroom","Lightroom_x64")
click(wait("folder-button.png",90))

adobefile_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\Lightroom_x64_en_US_WIN_64.zip")
assert util.file_exists(adobefile_path, 600), "File not found after 5 minutes"
wait(15)
closeApp("Edge")
