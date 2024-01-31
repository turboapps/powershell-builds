setAutoWaitTimeout(10)
### Read credentials from the secrets file###
secrets_file_path = 'c:\\users\\admin\\Desktop\\sikulix\\resources\\secrets.txt'
# Read the secrets file
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

# Turn off prompt to download multiple files in Edge
run('explorer "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\msedge.exe"') 
wait(5)
type("edge://settings/content/automaticDownloads")
type(Key.ENTER)
click("1706654222871-1.png")
wait(2)
type(Key.F4, Key.ALT)
# URL handler
run('explorer "https://adminconsole.adobe.com/"')
wait("1706293893609.png")
type(username)
type(Key.ENTER)
wait("1706314796632.png")
type(password)
type(Key.ENTER)
wait("1706314979874.png")
click(Pattern("1706314979874.png").targetOffset(140,-2))
wait("1706314890422.png")
click("1706314890422.png")
#Build package and download Creative Cloud Desktop
click("1706315023502.png")
click(Pattern("1706315046731.png").targetOffset(127,-2))
click("1706315087105.png")
wait("1706315113574.png")
click(Pattern("1706315113574.png").targetOffset(72,8))
click("1706315171087.png")
click("1706315087105.png")
wait("1706315359363.png")
click("1706315359363.png")
type("creative cloud desktop")
click(Pattern("1706547836382.png").targetOffset(161,0))
click("1706315087105.png")
click("1706315087105.png")
click(Pattern("1706315561109.png").targetOffset(-83,-2))
click(Pattern("1706315626096.png").targetOffset(1,35))
click(Pattern("1706315682594.png").targetOffset(-105,-1))
click("1706315087105.png")
type("CreativeCloudDesktop_x64")
click("1706315766269.png")
setAutoWaitTimeout(200)
wait("1706551571758.png")
#Build package and download Photoshop
click("1706315023502.png")
click(Pattern("1706315046731.png").targetOffset(127,-2))
click("1706315087105.png")
wait("1706315113574.png")
click(Pattern("1706315113574.png").targetOffset(72,8))
click("1706315171087.png")
click("1706315087105.png")
wait("1706315359363.png")
click("1706315359363.png")
type("photoshop")
click(Pattern("1706315502394.png").targetOffset(160,1))
click("1706315087105.png")
click("1706315087105.png")
click(Pattern("1706315561109.png").targetOffset(-83,-2))
click(Pattern("1706315626096.png").targetOffset(1,35))
click(Pattern("1706315682594.png").targetOffset(-105,-1))
click("1706315087105.png")
type("Photoshop_x64")
click("1706315766269.png")
click(Pattern("1706548133262.png").targetOffset(-15,0))
while not os.path.exists('C:\\Users\\admin\\Downloads\\Photoshop_x64_en_US_WIN_64.zip'):
    wait(10)
