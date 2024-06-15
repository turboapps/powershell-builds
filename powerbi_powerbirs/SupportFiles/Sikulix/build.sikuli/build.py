script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
resources_path = os.path.join(script_path, os.pardir, "resources")
setAutoWaitTimeout(20)
App("java.exe").focus()
type(Key.DOWN, Key.WIN) # Minimize cmd window
# URL handler
run('explorer "https://aka.ms/pbireportserver"')
wait(10)
setAutoWaitTimeout(20)
wait("download-button.png")
click("download-button.png")
wait(10)
wait("option-boxes.png")
click(Pattern("option-boxes.png").targetOffset(-114,2))
wait("download-button.png")
click("download-button.png")
setAutoWaitTimeout(600)
powerbi_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\PBIDesktopSetupRS_x64.exe")
while not os.path.exists(powerbi_path):
    wait(10)
closeApp("Edge")

