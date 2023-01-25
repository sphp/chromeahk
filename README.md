# Modified chrome.ahk
https://github.com/G33kDude/Chrome.ahk
# Chrome WebSocket Remote Debugger
todo
# example
```
#NoEnv
#SingleInstance, Force
#Include %A_ScriptDir%\chrome.class.ahk
SetBatchLines, -1

chrome := new Chrome("https://google.com https://bing.com https://wiki.com")
sleep 2000
page := chrome.GetPage(1)
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(2)
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(3)
MsgBox % page.Evaluate("document.body.innerText").value

ExitApp
Return
```
