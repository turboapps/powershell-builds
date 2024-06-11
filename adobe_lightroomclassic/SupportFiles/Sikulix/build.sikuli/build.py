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
if exists("admin-console-signin.png"):
    type(username)
    type(Key.ENTER)
    wait("enter-password-prompt.png")
    type(password)
    type(Key.ENTER)
if exists("save-password-prompt.png"):
    click(Pattern("save-password-prompt.png").targetOffset(140,-2))
wait("packages-link.png")
click("packages-link.png")
#Build package and download Creative Cloud Desktop
click("create-a-package-button.png")
click(Pattern("managed-package-checkbox.png").targetOffset(127,-2))
click("next-button.png")
wait("select-platform-dropdown.png")
click(Pattern("select-platform-dropdown.png").targetOffset(72,8))
click("64bit-dropdown.png")
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
setAutoWaitTimeout(60)
wait("folder-button.png")
#Build package and download Photoshop
waitVanish("wait-preparing.png")
setAutoWaitTimeout(20)
click("create-a-package-button.png")
click(Pattern("managed-package-checkbox.png").targetOffset(127,-2))
click("next-button.png")
wait("select-platform-dropdown.png")
click(Pattern("select-platform-dropdown.png").targetOffset(72,8))
click("64bit-dropdown.png")
click("next-button.png")
wait("search-button.png")
click("search-button.png")
type("lightroom classic")
click(Pattern("select-app.png").targetOffset(162,1))
click("next-button.png")
click("next-button.png")
click(Pattern("self-service-checkbox.png").targetOffset(-83,-2))
click(Pattern("scroll-down.png").targetOffset(1,35))
click(Pattern("remote-update-checkbox.png").targetOffset(-105,-1))
click("next-button.png")
type("LightroomClassic_x64")
click("create-package-button.png")
setAutoWaitTimeout(90)
if exists("folder-button.png"):
    click(Pattern("folder-button.png").targetOffset(-14,0))
setAutoWaitTimeout(600)

adobefile_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\LightroomClassic_x64_en_US_WIN_64.zip")
while not os.path.exists(adobefile_path):
    wait(10)
closeApp("Edge")
