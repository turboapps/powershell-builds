script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
util_path = os.path.join(script_path, os.pardir, "util.sikuli")
sys.path.append(util_path)
import util
reload(util)
addImagePath(util_path) # This is needed to include screenshots from "util".

setAutoWaitTimeout(20)
util.minimize_app("java")

appname = "prelude"
# Launch Admin Console, login and get the version for the app
util.get_adobeapp_version1(appname)
doubleClick(Pattern("version.png").targetOffset(38,-1))
util.get_adobeapp_version2(appname)