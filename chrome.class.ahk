class Chrome
{
	static DebugPort := 9222
	__New(URLs=0, Profile=0, Port=0, Path=0){
		if(UID := WinExist("ahk_exe chrome.exe")){
			WinGet, VarPID, PID,% "ahk_id " UID
			this.PID := VarPID
			this.DebugPort := this.DebPort()
		}
		else {
			if !Path
				FileGetShortcut, %A_StartMenuCommon%\Programs\Google Chrome.lnk, Path
			path := Path ? Path : "C:\Program Files\Google\Chrome\Application\chrome.exe"
			urls := URLs ? URLs : "about:blank"
			port := Port ? Port : this.DebugPort
			prof := Profile ? Profile : "Default"
			chrome_cmd = "%path%" %urls% --remote-debugging-port=%port% --profile-directory="%prof%"
			Run, % chrome_cmd,,,VarPID
			Sleep 1000
			this.PID := VarPID
		}
	}
	DebPort(){
		for Item in ComObjGet("winmgmts:").ExecQuery("SELECT CommandLine FROM Win32_Process" . " WHERE Name = 'chrome.exe'") {
			if RegExMatch(Item.CommandLine, "--remote-debugging-port=(\d+)", Match)
				return StrReplace(Match,"--remote-debugging-port=")
		}
	}
	GetPage(url, fnCallback:=""){
		return new this.Page(this.Debug(url).wsdurl, fnCallback)
	}
	NewTab(url, fnCallback:=""){
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", "http://127.0.0.1:" this.DebugPort "/json/new?" url)
		http.send()
		Sleep 200
		return new this.Page(this.Debug(url).wsdurl, fnCallback)
	}
	Close(url){
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", "http://127.0.0.1:" this.DebugPort "/json/close/" this.Debug(url).id)
		http.send()
	}
	Activate(url){
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", "http://127.0.0.1:" this.DebugPort "/json/activate/" this.Debug(url).id)
		http.send()
	}
	Debug(url=1){
		n:=0,url := instr(url,"https://")=1 ? StrReplace(url,"https://") : StrReplace(url,"http://")
		for k,val in this.GetPageList()
			if (strlen(url)>2 && instr(val.url, url)) || (++n=url && instr(val.type, "page"))
				return {id : val.id, wsdurl : val.webSocketDebuggerUrl}
	}
	Kill(){
		Process, Close, % this.PID
	}
	GetPageList(res=1){
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", "http://127.0.0.1:" this.DebugPort "/json")
		http.send()
		return res ? this.Jxon_Load(http.responseText) : http.responseText
	}
	class Page
	{
		Connected := False
		ID := 0
		Responses := []
		__New(wsurl, fnCallback:="")
		{
			this.fnCallback := fnCallback
			this.BoundKeepAlive := this.Call.Bind(this, "Browser.getVersion",, False)
			if IsObject(wsurl)
				wsurl := wsurl.webSocketDebuggerUrl
			wsurl := StrReplace(wsurl, "localhost", "127.0.0.1")
			this.ws := {"base": this.WebSocket, "_Event": this.Event, "Parent": this}
			this.ws.__New(wsurl)
			while !this.Connected
				Sleep, 50
		}
		Call(DomainAndMethod, Params:="", WaitForResponse:=True)
		{
			if !this.Connected
				throw Exception("Not connected to tab")
			ID := this.ID += 1
			this.ws.Send(Chrome.Jxon_Dump({"id": ID, "params": Params ? Params : {}, "method": DomainAndMethod}))
			if !WaitForResponse
				return
			this.responses[ID] := False
			while !this.responses[ID]
				Sleep, 50
			; Get the response, check if it's an error
			response := this.responses.Delete(ID)
			if (response.error)
				throw Exception("Chrome indicated error in response",, Chrome.Jxon_Dump(response.error))
			
			return response.result
		}
		Evaluate(JS){
			response := this.Call("Runtime.evaluate",
			( LTrim Join
			{
				"expression": JS,
				"objectGroup": "console",
				"includeCommandLineAPI": Chrome.Jxon_True(),
				"silent": Chrome.Jxon_False(),
				"returnByValue": Chrome.Jxon_False(),
				"userGesture": Chrome.Jxon_True(),
				"awaitPromise": Chrome.Jxon_False()
			}
			))
			if (response.exceptionDetails)
				throw Exception(response.result.description,, Chrome.Jxon_Dump(response.exceptionDetails))
			
			return response.result
		}
		WaitForLoad(DesiredState:="complete", Interval:=100){
			while this.Evaluate("document.readyState").value != DesiredState
				Sleep, Interval
		}
		Event(EventName, Event){
			if this.Parent
				this := this.Parent
			if (EventName == "Open")
			{
				this.Connected := True
				BoundKeepAlive := this.BoundKeepAlive
				SetTimer, %BoundKeepAlive%, 15000
			}
			else if (EventName == "Message")
			{
				data := Chrome.Jxon_Load(Event.data)
				fnCallback := this.fnCallback
				if (newData := %fnCallback%(data))
					data := newData
				
				if this.responses.HasKey(data.ID)
					this.responses[data.ID] := data
			}
			else if (EventName == "Close")
			{
				this.Disconnect()
			}
			else if (EventName == "Error")
			{
				throw Exception("Websocket Error!")
			}
		}
		Disconnect(){
			if !this.Connected
				return
			this.Connected := False
			this.ws.Delete("Parent")
			this.ws.Disconnect()
			BoundKeepAlive := this.BoundKeepAlive
			SetTimer, %BoundKeepAlive%, Delete
			this.Delete("BoundKeepAlive")
		}
		class WebSocket{
			__New(WS_URL){
				static wb
				Gui, +hWndhOld
				Gui, New, +hWndhWnd
				this.hWnd := hWnd
				Gui, Add, ActiveX, vWB, Shell.Explorer
				Gui, %hOld%: Default
				WB.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'" . "content='IE=edge'><body></body>")
				while (WB.ReadyState < 4)
					sleep, 50
				this.document := WB.document
				this.document.parentWindow.ahk_savews := this._SaveWS.Bind(this)
				this.document.parentWindow.ahk_event := this._Event.Bind(this)
				this.document.parentWindow.ahk_ws_url := WS_URL
				Script := this.document.createElement("script")
				Script.text := "ws = new WebSocket(ahk_ws_url);`n"
				. "ws.onopen = function(event){ ahk_event('Open', event); };`n"
				. "ws.onclose = function(event){ ahk_event('Close', event); };`n"
				. "ws.onerror = function(event){ ahk_event('Error', event); };`n"
				. "ws.onmessage = function(event){ ahk_event('Message', event); };"
				this.document.body.appendChild(Script)
			}
			_Event(EventName, Event){
				this["On" EventName](Event)
			}
			Send(Data){
				this.document.parentWindow.ws.send(Data)
			}
			Close(Code:=1000, Reason:=""){
				this.document.parentWindow.ws.close(Code, Reason)
			}
			Disconnect(){
				if this.hWnd
				{
					this.Close()
					Gui, % this.hWnd ": Destroy"
					this.hWnd := False
				}
			}
		}
	}
	Jxon_Load(ByRef src, args*){
		static q := Chr(34)
		key := "", is_key := false
		stack := [ tree := [] ]
		is_arr := { (tree): 1 }
		next := q . "{[01234567890-tfn"
		pos := 0
		while ( (ch := SubStr(src, ++pos, 1)) != "" )
		{
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch, true)
			{
				ln := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
				col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))
				
				msg := Format("{}: line {} col {} (char {})"
				,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
				: (next == "'")     ? "Unterminated string starting at"
				: (next == "\")     ? "Invalid \escape"
				: (next == ":")     ? "Expecting ':' delimiter"
				: (next == q)       ? "Expecting object key enclosed in double quotes"
				: (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
				: (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
				: (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
				: [ "Expecting JSON value(string, number, [true, false, null], object or array)"
				, ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
				, ln, col, pos)
				
				throw Exception(msg, -1, ch)
			}
			is_array := is_arr[obj := stack[1]]
			if i := InStr("{[", ch)
			{
				val := (proto := args[i]) ? new proto : {}
				is_array? ObjPush(obj, val) : obj[key] := val
				ObjInsertAt(stack, 1, val)
				
				is_arr[val] := !(is_key := ch == "{")
				next := q . (is_key ? "}" : "{[]0123456789-tfn")
			}
			else if InStr("}]", ch)
			{
				ObjRemoveAt(stack, 1)
				next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
			}
			else if InStr(",:", ch)
			{
				is_key := (!is_array && ch == ",")
				next := is_key ? q : q . "{[0123456789-tfn"
			}
			else ; string | number | true | false | null
			{
				if (ch == q) ; string
				{
					i := pos
					while i := InStr(src, q,, i+1)
					{
						val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
						static end := A_AhkVersion<"2" ? 0 : -1
						if (SubStr(val, end) != "\")
							break
					}
					if !i ? (pos--, next := "'") : 0
						continue
					pos := i ; update pos
					val := StrReplace(val,"\/",  "/")
					, val := StrReplace(val,"\" . q,q)
					, val := StrReplace(val,"\b", "`b")
					, val := StrReplace(val,"\f", "`f")
					, val := StrReplace(val,"\n", "`n")
					, val := StrReplace(val,"\r", "`r")
					, val := StrReplace(val,"\t", "`t")
					i := 0
					while i := InStr(val, "\",, i+1)
					{
						if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
							continue 2
						xxxx := Abs("0x" . SubStr(val, i+2, 4))
						if (A_IsUnicode || xxxx < 0x100)
							val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
					}
					if is_key
					{
						key := val, next := ":"
						continue
					}
				}
				else ; number | true | false | null
				{
					val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
					static number := "number", integer := "integer"
					if val is %number%
					{
						if val is %integer%
							val += 0
					}
					else if (val == "true" || val == "false")
						val := %value% + 0
					else if (val == "null")
						val := ""
					else if (pos--, next := "#")
						continue
					pos += i-1
				}
				is_array? ObjPush(obj, val) : obj[key] := val
				next := obj==tree ? "" : is_array ? ",]" : ",}"
			}
		}
		return tree[1]
	}
	Jxon_Dump(obj, indent:="", lvl:=1){
		static q := Chr(34)
		if IsObject(obj)
		{
			static Type := Func("Type")
			if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "")
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))
			prefix := SubStr(A_ThisFunc, 1, InStr(A_ThisFunc, ".",, 0))
			fn_t := prefix "Jxon_True",  obj_t := this ? %fn_t%(this) : %fn_t%()
			fn_f := prefix "Jxon_False", obj_f := this ? %fn_f%(this) : %fn_f%()
			
			if (&obj == &obj_t)
				return "true"
			else if (&obj == &obj_f)
				return "false"
			is_array := 0
			for k in obj
				is_array := k == A_Index
			until !is_array
			static integer := "integer"
			if indent is %integer%
			{
				if (indent < 0)
					throw Exception("Indent parameter must be a postive integer.", -1, indent)
				spaces := indent, indent := ""
				Loop % spaces
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent
			this_fn := this ? Func(A_ThisFunc).Bind(this) : A_ThisFunc
			lvl += 1, out := "" ; Make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= ( ObjGetCapacity([k], 1) ? %this_fn%(k) : q . k . q ) ;// key
				.  ( indent ? ": " : ":" ) ; token + padding
				out .= %this_fn%(v, indent, lvl) ; value
				.  ( indent ? ",`n" . indt : "," ) ; token + indent
			}
			if (out != "")
			{
				out := Trim(out, ",`n" . indent)
				if (indent != "")
					out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
			}
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}
		else if (ObjGetCapacity([obj], 1) == "")
			return obj
		if (obj != "")
		{
			  obj := StrReplace(obj, "\", "\\")
			, obj := StrReplace(obj, "/", "\/")
			, obj := StrReplace(obj, q, "\" . q)
			, obj := StrReplace(obj, "`b", "\b")
			, obj := StrReplace(obj, "`f", "\f")
			, obj := StrReplace(obj, "`n", "\n")
			, obj := StrReplace(obj, "`r", "\r")
			, obj := StrReplace(obj, "`t", "\t")
			static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
			while RegExMatch(obj, needle, m)
				obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
		}
		return q . obj . q
	}
	Jxon_True(){
		static obj := {}
		return obj
	}
	Jxon_False(){
		static obj := {}
		return obj
	}
}
