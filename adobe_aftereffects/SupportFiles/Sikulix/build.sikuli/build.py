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
click(Pattern("search-button.png").targetOffset(-4,24))
type("after effects")
click(Pattern("select-app.png").targetOffset(163,-2))
click("next-button.png")
click("next-button.png")
click(Pattern("self-service-checkbox.png").targetOffset(-83,-2))
click(Pattern("scroll-down.png").targetOffset(1,35))
click(Pattern("remote-update-checkbox.png").targetOffset(-105,-1))
click("next-button.png")
type("AfterEffects_x64")
click("create-package-button.png")
app_downloader = os.path.join(os.environ['USERPROFILE'], "Downloads\\AfterEffects_x64_en_US_WIN_64_Downloader.exe")
if util.file_exists(app_downloader, 120):
    wait(5)
    run('explorer "' + app_downloader + '"')
    click(wait("downloader-continue.png",30))
    click(wait("downloader-close.png",600))
else:
    raise Exception("Timed out waiting for " + app_downloader)
wait(10)
closeApp("Edge")
