#SingleInstance, Force
#Include %A_ScriptDir%\chrome.ahk
SetWorkingDir, %A_ScriptDir%

url := "https://google.com"

inif :=  Script() ".ini"
if fileexist(inif) {
	IniRead, pageid, % inif, app, pageid
}

Inst := new chrome(,url,,,51111)
page := Inst.GetPageURL(url)
MsgBox,,, % page.Evaluate("location.href").value,1

Inst := new chrome(,url,,,51111)
page := Inst.GetPageURL(url,4)
if page
	MsgBox,,, % page.Evaluate("location.href").value,1

Inst := new chrome(,"https://ipwho.is/",,,51111)
page := Inst.Activate()
MsgBox,,, % page.Evaluate("location.href").value,1

Inst := new chrome(,"https://msn.com/",,,51111)
page := Inst.Activate()
MsgBox,,, % page.Evaluate("location.href").value,1


ExitApp
Esc::ExitApp

Script(){
	return StrReplace(StrReplace(A_ScriptName,".ahk"),".exe")
}
