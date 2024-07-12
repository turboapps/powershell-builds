script_path = os.path.dirname(os.path.abspath(sys.argv[0])) 
resources_path = os.path.join(script_path, os.pardir, "resources")
setAutoWaitTimeout(20)
App("java.exe").focus()
type(Key.DOWN, Key.WIN) # Minimize cmd window
# URL handler
run('explorer "https://aka.ms/pbireportserver"')
wait(20)
closeApp("Edge")
wait(5)
# Launch the website a second time as it fails to load sometimes on first try
run('explorer "https://aka.ms/pbireportserver"')
wait(20)
setAutoWaitTimeout(40)
wait(Pattern("download-button.png").similar(0.75))
click(Pattern("download-button.png").similar(0.75))
wait(5)
wait(Pattern("download-checkbox.png").similar(0.80))
click(Pattern("download-checkbox.png").similar(0.80))
wait(Pattern("download-button.png").similar(0.75))
click(Pattern("download-button.png").similar(0.75))
setAutoWaitTimeout(600)
powerbi_path = os.path.join(os.environ['USERPROFILE'], "Downloads\\PBIDesktopSetupRS_x64.exe")
while not os.path.exists(powerbi_path):
    wait(10)
closeApp("Edge")

