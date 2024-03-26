# The tests for 7-zip/7-zip and 7-zip/7-zip-x64 are the same.

# Import the package "util" which contains common operations.
# More information: https://sikulix-2014.readthedocs.io/en/latest/scripting.html#importing-other-sikuli-scripts-reuse-code-and-images
script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
common_path = os.path.join(script_path, os.pardir, os.pardir, os.pardir, "_INCLUDE", "Test", "util.sikuli")
sys.path.append(common_path)
import util
reload(util)
addImagePath(common_path) # This is needed to include screenshots from "util".

# Set the default waiting time.
setAutoWaitTimeout(20)

# Pre test operations.
util.pre_test()

# `turbo run` should launch the app.
wait("zip_add.png")
run("turbo stop test")

# Launch the app by Start menu shortcut.
run("explorer " + os.path.join(util.start_menu, "7-Zip", "7-Zip File Manager.lnk"))
wait("zip_add.png")

# Check the "help" of the app.
type(Key.F1)
click(Pattern("help.png").targetOffset(245,-23))

# Basic operations: zip.
click(Pattern("address_bar.png").targetOffset(20,0))
type(os.path.join(script_path, os.pardir, os.pardir, os.pardir, "_INCLUDE", "Test"))
type(Key.ENTER)
click("folder.png")
click("zip_add.png")
click(Pattern("format.png").targetOffset(56,-3))
click(Pattern("format_selection.png").targetOffset(-57,28))
click("more.png")
click("location_desktop.png")
click("save.png")
click("add_ok.png")
wait(10)
assert(os.path.exists(os.path.join(util.desktop, "util.sikuli.zip")))
type(Key.F4, Key.ALT)

# Basic operations: unzip.
run("explorer " + util.desktop)
rightClick("folder_zipped.png")
click("open_with.png")
click("open_with_7zip.png")
click("zip_extract.png")
click("extract_ok.png")
wait(10)
assert(os.path.exists(os.path.join(util.desktop, "util.sikuli")))
type(Key.F4, Key.ALT)
type(Key.F4, Key.ALT) # Close the Explorer window.

# Check if the container terminates after closing the app.
util.check_running()