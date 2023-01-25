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

url1 := "https://google.com"
url2 := "https://bing.com"

chrome := new Chrome(url1 " " url2)
sleep 1000

page := chrome.GetPage(1)
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(2)
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(url1)
MsgBox % page.Evaluate("document.body.innerText").value

page := chrome.GetPage(url2)
MsgBox % page.Evaluate("document.body.innerText").value

ExitApp
Return
```
