# existing chrome ahk

# Chrome WebSocket Remote Debugger

# example
```
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#Include %A_ScriptDir%\existing_chrome.ahk

chrome := new Chrome("https://google.com https://bing.com https://wiki.com")
winwait, Chrome

page := chrome.GetPage(1)
page.WaitForLoad()
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(2)
page.WaitForLoad()
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(3)
page.WaitForLoad()
MsgBox % page.Evaluate("document.body.innerText").value

ExitApp
Return
```
