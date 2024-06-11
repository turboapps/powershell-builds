script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
resources_path = os.path.join(script_path, os.pardir, "resources")

setAutoWaitTimeout(20)
### Read credentials from the secrets file###
secrets_file_path = os.path.join(resources_path, "secrets.txt")
print(secrets_file_path)
with open(secrets_file_path, 'r') as file:
    lines = file.readlines()
# Create a dictionary to store the credentials
credentials = {}
# Parse the lines and populate the dictionary
for line in lines:
    # Split each line into key and value
    key, value = line.strip().split(',')
    credentials[key] = value
# Retrieve values from the dictionary
username = credentials.get('username')
password = credentials.get('password')
###
# Test of `turbo run`
App("java.exe").focus()
type(Key.DOWN, Key.WIN) # Minimize cmd window

# URL handler
run('explorer "https://adminconsole.adobe.com/"')
setAutoWaitTimeout(20)
wait("adobe-sign-in.png")
type(username)
type(Key.ENTER)
wait("adobe-enter-password.png")
type(password)
type(Key.ENTER)
if exists("save-password.png"):
    click(Pattern("save-password.png").targetOffset(140,-10))
wait("wait-packages-link.png")
click("wait-packages-link.png")
#Build package and download Creative Cloud Desktop
click("wait-create-package-button.png")
click(Pattern("click-managed-package.png").targetOffset(127,-2))
click("click-next.png")
wait("select-platform.png")
click(Pattern("select-platform.png").targetOffset(72,8))
click("windows-x64-bit.png")
click("click-next.png")
wait("wait-mag-glass.png")
click("wait-mag-glass.png")
type("dreamweaver")
wait("version.png")
doubleClick(Pattern("version.png").targetOffset(58,-2))
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

