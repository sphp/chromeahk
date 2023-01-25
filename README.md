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

chrome.Activate(url1)
sleep 1000
chrome.Activate(url2)
sleep 1000

page := chrome.NewTab("https://www.baidu.com/")
page.WaitForLoad()
sleep 1000
MsgBox % page.Evaluate("document.body.innerText").value

chrome.close("baidu.com")
sleep 1000

ExitApp
Return
```
