# existing chrome.class.ahk

# Chrome WebSocket Remote Debugger

# example
```
#NoEnv
#SingleInstance, Force
#Include %A_ScriptDir%\chrome.class.ahk
SetBatchLines, -1

chrome := new Chrome("https://google.com https://bing.com https://wiki.com")

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
