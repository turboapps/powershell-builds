reg add "HKEY_CURRENT_USER\Software\Classes\msteams" /f /ve /d "URL:msteams"
reg add "HKEY_CURRENT_USER\Software\Classes\msteams" /f /v "URL Protocol" /d ""
reg add "HKEY_CURRENT_USER\Software\Classes\msteams\shell\open\command" /f /ve /d "\"%localappdata%\\Microsoft\\Teams\\current\\Teams.exe\" \"%%1\""

reg add "HKEY_CURRENT_USER\Software\Classes\ms-teams" /f /ve /d "URL:ms-teams"
reg add "HKEY_CURRENT_USER\Software\Classes\ms-teams" /f /v "URL Protocol" /d ""
reg add "HKEY_CURRENT_USER\Software\Classes\ms-teams\shell\open\command" /f /ve /d "\"%localappdata%\\Microsoft\\Teams\\current\\Teams.exe\" \"%%1\""

reg add "HKEY_CURRENT_USER\Software\Classes\TeamsURL" /f