
#Persistent
FileInstall .\JoystickWrapper.dll, .\JoystickWrapper.dll
FileInstall .\SharpDX.dll, .\SharpDX.dll
FileInstall .\SharpDX.DirectInput.dll, .\SharpDX.DirectInput.dll
FileInstall .\SharpDX.XInput.dll, .\SharpDX.XInput.dll
if( !FileExist(StrSplit(A_Scriptname, ".")[1]".ini"))
{
	MsgBox Config File not found, creating with defaults...
	filename :=	".\"StrSplit(A_Scriptname, ".")[1]".ini"
	FileInstall .\JoyOverlay-defaults.ini, %filename%
}


#Include .\JoystickWrapper.ahk
jw := new JoystickWrapper(".\JoystickWrapper.dll")
#NoEnv
OnExit, GuiClose
global axisLabel := {"X":1, "Y":2, "Z":3, "Rx":4, "Ry":5, "Rz":6, "S0":7, "S1":8}
global axisValue := {}

global debug :=0
global guid
global joyName
global inidata :={}
global pi := 3.141592


global configini := ".\"StrSplit(A_Scriptname, ".")[1]".ini"

global DeviceList := jw.GetDevices()
global pipslist 

LoadIniFunc(inidata)



;jw.GetAnyDeviceGuid()
if (guid ){
	Loop 8
	{
		jw.SubscribeAxis(guid, A_Index, Func("AxisFunc").Bind(A_Index))
	}
	
	;jw.SubscribeButton(guid, 1, Func("ButtonFunc").Bind("Button"))
	;jw.SubscribePov(guid, 1, Func("PovFunc").Bind("Pov"))
;jw.SubscribePovDirection(guid, 1, 1, Func("PovDirFunc").Bind("PovDirection"))
} else {
	MsgBox "No matching controllers found"
	ExitApp
}
SetTimer, Disp, off

;Set window position and title.

windowX := "200"
windowY := "200"
windowTitle := "JoyOverlay - "+ joyName

global W			:=inidata.configaxes.windowwidth
global H			:=inidata.configaxes.windowheight

global bgcolor  	:= inidata.configaxes.backgroundcolor
global axisweight	:= inidata.configaxes.axisweight
global pipweight	:= inidata.configaxes.pipweight
global axiscolor	:= inidata.configaxes.axiscolor
global pipcolor 	:= inidata.configaxes.pipcolor
Gui, -0x30000
Gui, Show, W%W% H%H% X%windowX% Y%windowY%, %windowTitle%


global hPenBG 		:= ArtCreatePenFunc(0, 1, bgcolor)
global hPenAxis 	:= ArtCreatePenFunc(0, axisweight, axiscolor)
global hPenRed  	:= ArtCreatePenFunc(0, axisweight, 0xFF2222)
global hPenBlue 	:= ArtCreatePenFunc(0, axisweight, 0x2222FF)
global hPenCursor	:= ArtCreatePenFunc(0, pipweight, pipcolor)

global hBrushBG := DllCall("CreateSolidBrush", "UInt", 0xFFFFFF - bgcolor, "Ptr")	;background


DllCall("ReleaseDC", "UInt", htx, "UInt", hdcMem) ; release any prior Device Context

global hdcWin := DllCall("GetDC", "UPtr", hwnd:=WinExist(windowTitle)) ; Get Device Context for screenspace draw in our Window
global hdcMem := DllCall("CreateCompatibleDC", "UPtr", hdcWin, "UPtr") ; Create Memory Device Context to hold our work in
global hbm := DllCall("CreateCompatibleBitmap", "UPtr", hdcWin, "int", W, "int", H, "UPtr") 
global hbmO := DllCall("SelectObject", "uint", hdcMem, "uint", hbm)
DllCall("SetROP2", "UInt", hdcMem, "UInt", 0x04)	;hex for SRCOPY mix mode


;update rate ~60Hz
SetTimer, Disp, 16
return

LoadIniFunc(ByRef container){
	
	MsgBox Loading config from %configini%`n(Config filename will follow name of executable file, for multiple instances.)
	IniRead, IniSections, % configini
	if debug
	{
		length := StrLen(IniSections)
		MsgBox IniSections Len= %length% `n%IniSections%
	} 
	Loop, PARSE, IniSections, `n
	{
		
		tempobj := {}
		tempobj:=IniParseSectionFunc(A_Loopfield)		
		if debug
		{
			count := tempobj.count()
			MsgBox tempobj count= %count%
		} 
		container[(A_Loopfield)] := tempobj ;, container.(A_Loopfield)))
		
		if debug
		{
			count := container.count()
			MsgBox container.count= %count%`nLoop = %A_Loopfield%
			
		} 
		
		if (A_Loopfield) = "configaxes"
		{
			
			for i, dev in DeviceList {
				
				if (InStr( dev.Name, container[(A_Loopfield)].search)){
					guid :=dev.Guid
					joyName := dev.Name
				}
				
			}		
			if debug
			{
				search := container[(A_Loopfield)].search
				MsgBox configaxes search= %search%
			} 
			
			
		}
		if container[(A_Loopfield)].enable = 1
		{
			if debug
			{
				enable := container[(A_Loopfield)].enable
				MsgBox %A_Loopfield% enable= %enable%
			} 
			if pipslist = 
			pipslist = %A_Loopfield%
			else
			pipslist = %pipslist%`n%A_Loopfield%
			if debug
			{
				
				MsgBox active pips= %pipslist%
			} 
		}
		
		
	}   
	
	return container
}

IniParseSectionFunc(SectionTarget) {
	LoadTo := {}
	IniRead ParseThis, % configini , % SectionTarget
	if debug 
	{
		length := StrLen(ParseThis)
		MsgBox Section: %SectionTarget% `nLength: %length%`n%ParseThis%
	}
	Loop, PARSE, ParseThis, `n
	{
		temparray := StrSplit(A_Loopfield, "=")
		
		;LoadTo := { (temparray.1):temparray.2}
		ObjRawSet(LoadTo, (temparray.1), temparray.2)
		tempload := LoadTo[(temparray.1)]
		if(debug =2){
			tempkey := temparray.1
			tempval := temparray.2
			MsgBox temp: %tempkey% = %tempval% `nLoadTo %tempkey% %tempload%
		} 
		
	}
	if debug
	{
		count := LoadTo.Count()
		Msgbox LoadTo Count = %count% 
	}
	return LoadTo
}


AxisFunc(ByRef axisIdx, value)
{
	axisValue[axisIdx] := value
}

AxisReduceFunc(ByRef axisvalue,range)
{
	tempdiv := 65535/range
	tempvalue := axisvalue/tempdiv
	return tempvalue
	
}



; DLL Art Calls 

ArtCreatePenFunc(style, weight, color){
	return DllCall("CreatePen", "UInt", style, "UInt", weight, "UInt",  0xFFFFFF - color)
}
ArtSelectFunc(ByRef tool){
	DllCall("SelectObject", "UInt", hdcMem, "UInt", tool)	;select pen
}
ArtRectFunc(ByRef pen,ByRef brush,startX,startY,endX,endY){
	DllCall("SelectObject", "UInt", hdcMem, "UInt",pen)
	DllCall("SelectObject", "UInt", hdcMem, "UInt",brush)
	DllCall("Rectangle", "UInt", hdcMem, "int", startX , "int", startY, "int", endX, "int", endY)
}
ArtMoveToFunc(coordX, coordY){
	DllCall("MoveToEx", "UInt", hdcMem, "int",coordX, "int",coordY, "UInt", NULL)
} 
ArtLineToFunc(coordX, coordY){
	DllCall("LineTo", "UInt", hdcMem, "int",coordX, "int",coordY)
}
ArtLineFromTo(ByRef tool,startX,startY,endX,endY){
	ArtSelectFunc(tool)
	ArtMoveToFunc(startX,startY)
	ArtLineToFunc(endX,endY)
} 

; draw pip funcs


Vec2PipFunc(shape,size,centerX,centerY){
	
	
	switch shape
	{
		case "+": ; +
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY, centerX + ((size/2)+1), centerY)
		ArtLineFromTo(hPenCursor,centerX, centerY - (size/2), centerX, centerY + ((size/2)+1))
		
		case "x":
		ArtLineFromTo(hPenCursor,centerX - (size/2),centerY - (size/2),  centerX + ((size/2)), centerY + ((size/2)))
		ArtLineFromTo(hPenCursor,centerX - (size/2),centerY + (size/2),  centerX + ((size/2)), centerY - ((size/2)))
		
		case "-":
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY, centerX + ((size/2)+1), centerY)
		
		case "A":
		ArtLineFromTo(hPenCursor,centerX, centerY, centerX -((size/2)+1), centerY + (size+1))
		ArtLineFromTo(hPenCursor,centerX, centerY, centerX +((size/2)+1), centerY + (size+1))
		ArtLineFromTo(hPenCursor,centerX-(size/2), centerY+(size), centerX +((size/2)+1), centerY + (size))
		
		case "V":
		ArtLineFromTo(hPenCursor,centerX, centerY, centerX -((size/2)+1), centerY - (size+1))
		ArtLineFromTo(hPenCursor,centerX, centerY, centerX +((size/2)+1), centerY - (size+1))
		
		case "T":
		ArtLineFromTo(hPenCursor,centerX, centerY, centerX, centerY - (size+1))
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY, centerX + ((size/2)+1), centerY)
		
		case "H":
		
		
		case "|":
		ArtLineFromTo(hPenCursor,centerX, centerY - (size/2), centerX, centerY + ((size/2)+1))
		
		case "[]": ; [  ]   
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY + (size/2), centerX - (size/2), centerY - ((size/2))) ; left bar
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY + (size/2), centerX + (size/2), centerY - ((size/2))) ; right bar
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY - (size/2), centerX - ((size/4)+1), centerY - (size/2)) ; topleft
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY - (size/2), centerX + ((size/4)+1), centerY - (size/2)) ; topright
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY + (size/2), centerX - ((size/4)+1), centerY + (size/2)) ; bottom left
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY + (size/2), centerX + ((size/4)+1), centerY + (size/2)) ; bottom right
		
		case "<>": ; lozenge/diamond <>
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY, centerX, centerY - (size/2))
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY, centerX, centerY - (size/2))
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY, centerX, centerY + (size/2))
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY, centerX, centerY + (size/2))
		
		case "[o]":
		ArtLineFromTo(hPenCursor,centerX-1, centerY, centerX+1, centerY)
		
		
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY - (size/2), centerX - ((size/4)+1), centerY - (size/2)) ; topleft h
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY - (size/2), centerX + ((size/4)+1), centerY - (size/2)) ; topright h
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY + (size/2), centerX - ((size/4)+1), centerY + (size/2)) ; bottom left h
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY + (size/2), centerX + ((size/4)+1), centerY + (size/2)) ; bottom right h
		
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY - (size/2), centerx - (size/2), centerY - ((size/4)+1)) ; topleft v
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY - (size/2), centerX + (size/2), centerY - ((size/4)+1)) ; topright v
		ArtLineFromTo(hPenCursor,centerX - (size/2), centerY + (size/2), centerX - (size/2), centerY + ((size/4)+1)) ; bottom left v
		ArtLineFromTo(hPenCursor,centerX + (size/2), centerY + (size/2), centerX + (size/2), centerY + ((size/4)+1)) ; bottom right v
		
		
		
		default:
		
	}
	
}

Cart2PolarFunc(x, y){
	radius := Sqrt((x*x)+(y*y))
	;theta  := tan( y/x +(x>=0?pi:0) )
	theta  := tan( y/x )
	thetadeg := theta * ( 180 /pi)
	temp := {"radius":radius, "theta":theta, "thetadeg":thetadeg}
	return temp
}

Polar2CartFunc(radius, theta, usedeg=0){
	if usedeg
	theta := theta * (pi/ 180)
	
	x := radius * Cos(theta)
	y := radius * Sin(theta)
	temp := {"x":x, "y":y}
	return temp 
}

PointRotateDegFunc(x, y, anglediff){
	polartemp := Cart2PolarFunc(y,x)
	newangle := polartemp.thetadeg - anglediff
	tempcart := Polar2CartFunc(polartemp.radius, newangle, 1)
	return tempcart
}
PointRotateDegFuncRev(x, y, anglediff, usedeg = 0){
	if usedeg
	theta := theta * (180/pi)
	newpoint.x := x*cos(theta) + y*sin(theta)
	newpoint.Y := x*sin(theta) - y*cos(theta)
	
	return newpoint
}

/* 
	PointTranslateDegFunc(x, y, radius, heading){
	polartemp := Cart2PolarFunc(x, y)
	newradius := polartemp.radius + radius
	tempcart := Polar2CartFunc(newradius, heading, 1)
	return tempcart	
	}
*/


RadPipFunc(shape,size,radius,heading){
	;oh no
		;oh no
		;oh nonono no no
		;heading;+= 180
	; heading should be +/- up to 180
	offset  := Polar2CartFunc(radius, heading, 1)
	switch shape
	{
		case "+":
		rotatedTop:= PointRotateDegFunc(0,-size/2,heading+0)
		rotatedBot:= PointRotateDegFunc(0,-size/2,heading+180)
		rotatedLeft:= PointRotateDegFunc(0,-size/2,heading+90)
		rotatedRight:= PointRotateDegFunc(0,-size/2,heading+270)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedTop.x, offset.y + (H/2)-rotatedTop.y, offset.x + (W/2) + rotatedBot.x, offset.y +(H/2)-rotatedBot.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedLeft.x, offset.y + (H/2)-rotatedLeft.y, offset.x + (W/2) + rotatedRight.x, offset.y +(H/2)-rotatedRight.y)
		
		case "<>":
		rotatedTop:= PointRotateDegFunc(0,-size/2,heading+0)
		rotatedBot:= PointRotateDegFunc(0,-size/2,heading+180)
		rotatedLeft:= PointRotateDegFunc(0,-size/2,heading+90)
		rotatedRight:= PointRotateDegFunc(0,-size/2,heading+270)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedTop.x, offset.y + (H/2)-rotatedTop.y, offset.x + (W/2) + rotatedLeft.x, offset.y +(H/2)-rotatedLeft.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedLeft.x, offset.y + (H/2)-rotatedLeft.y, offset.x + (W/2) + rotatedBot.x, offset.y +(H/2)-rotatedBot.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedBot.x, offset.y + (H/2)-rotatedBot.y, offset.x + (W/2) + rotatedRight.x, offset.y +(H/2)-rotatedRight.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedRight.x, offset.y + (H/2)-rotatedRight.y, offset.x + (W/2) + rotatedTop.x, offset.y +(H/2)-rotatedTop.y)
		
		case "x":
		rotatedTL:= PointRotateDegFunc(size/2,size/2,heading+45)
		rotatedTR:= PointRotateDegFunc(size/2,size/2,heading+90+45)
		rotatedBR:= PointRotateDegFunc(size/2,size/2,heading+180+45)
		rotatedBL:= PointRotateDegFunc(size/2,size/2,heading+270+45)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedTL.x, offset.y + (H/2)-rotatedTL.y, offset.x + (W/2) + rotatedBR.x, offset.y +(H/2)-rotatedBR.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2)+rotatedTR.x, offset.y + (H/2)-rotatedTR.y, offset.x + (W/2) + rotatedBL.x, offset.y +(H/2)-rotatedBL.y)
		
		; case "T":
			; rotatedRed := PointRotateDegFunc(-size/2,size,heading+0)
			; rotatedBlue := PointRotateDegFunc(size/2,size,heading+0)
		; ArtLineFromTo(hPenCursor, 	offset.x + (W/2) + rotatedBlue.x, offset.y +(H/2)-rotatedBlue.y, offset.x + (W/2) + rotatedRed.x, offset.y +(H/2)-rotatedRed.y)
		
		
		; ArtLineFromTo(hPenCursor,	offset.x + (W/2) + rotatedRed.x-rotatedBlue.x, offset.y + (H/2)-rotatedRed.y+RotatedBlue.y,offset.x + (W/2), offset.y + (H/2))
		
		
		case "V":
		rotatedRed := PointRotateDegFunc(-size/2,size,heading+0)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2), offset.y + (H/2), offset.x + (W/2) + rotatedRed.x, offset.y +(H/2)-rotatedRed.y)
		
		rotatedBlue := PointRotateDegFunc(size/2,size,heading+0)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2), offset.y + (H/2), offset.x + (W/2) + rotatedBlue.x, offset.y +(H/2)-rotatedBlue.y)
		
		case "A":
		
		rotatedstart := PointRotateDegFunc(-size/2,size,heading+180)
		rotatedend   := PointRotateDegFunc(size/2,size, heading+180)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2), offset.y + (H/2), offset.x + (W/2) + rotatedstart.x, offset.y +(H/2)-rotatedstart.y)
		ArtLineFromTo(hPenCursor,	offset.x + (W/2), offset.y + (H/2), offset.x + (W/2) + rotatedend.x, offset.y +(H/2)-rotatedend.y)
		ArtLineFromTo(hPenCursor, offset.x + (W/2) + rotatedstart.x, offset.y +(H/2)-rotatedstart.y, offset.x + (W/2) + rotatedend.x, offset.y +(H/2)-rotatedend.y)	
		
		
		default:
		
	} 
} 




;draw and update loop
Disp:
;draw rect to wipe
ArtRectFunc(hPenBG, hBrushBG, 0, 0, W, H)
;draw axis lines

ArtLineFromTo(hPenAxis, 0, H/2, W, H/2)
ArtLineFromTo(hPenAxis, W/2, 0, W/2, H)

; draw x Pip


Loop Parse, pipslist, `n
{
	centerX := W/2
	centerY := H/2
	thisHorizName	:= inidata[(A_Loopfield)].axishoriz
	thisVertName	:= inidata[(A_Loopfield)].axisvert
	thisInvertHoriz	:= inidata[(A_Loopfield)].inverthoriz
	thisInvertVert	:= inidata[(A_Loopfield)].invertvert
	thisShape 		:= inidata[(A_Loopfield)].style
	thisSize		:= inidata[(A_Loopfield)].size
	thisRadial		:= inidata[(A_Loopfield)].radial
	
	
	if thisRadial
	{
		thisAxis	:= inidata[(A_Loopfield)].axis
		thisMaxAngle:= inidata[(A_Loopfield)].maxangle
		thisRadius	:= inidata[(A_Loopfield)].radius
		thisInvert	:= inidata[(A_Loopfield)].invert
		
		if thisInvert
		scaledaxis	:= (270+thismaxangle) - AxisReduceFunc(axisValue[axislabel[thisAxis]],thisMaxAngle*2)
		else
		scaledaxis	:= (270-thismaxangle) + AxisReduceFunc(axisValue[axislabel[thisAxis]],thisMaxAngle*2)
		
		RadPipFunc(thisShape,thisSize,thisRadius,scaledaxis)
		
		
	}
	else 
	{
		if thisHorizName =Min
		thisHorizValue := 0
		else if thisHorizName =Mid
		thisHorizValue := W/2
		else if thisHorizName =Max
		thisHorizValue := W
		else
		{
			if(thisInvertHoriz)
			{
				thisHorizValue := W - AxisReduceFunc(axisValue[(axislabel[(thisHorizName)])],W)
			} 
			if(thisInvertHoriz=0){
				thisHorizValue := AxisReduceFunc(axisValue[(axislabel[(thisHorizName)])],W)
			}
		}
		
		if thisVertName =Max
		thisVertValue := 0
		else if thisVertName =Mid
		thisVertValue := H/2
		else if thisVertName =Min
		thisVertValue := H
		else
		{
			if(thisInvertVert)
			{
				thisVertValue := H - AxisReduceFunc(axisValue[(axislabel[(thisVertName)])],H)
			} 
			if(thisInvertVert=0){
				thisVertValue := AxisReduceFunc(axisValue[(axislabel[(thisVertName)])],H)
			}
		}
		
		Vec2PipFunc(thisShape,thisSize,thisHorizValue,thisVertValue)
	}
	
	
	
}


; update screen

DllCall("BitBlt", "uint", hdcWin, "int", 0, "int", 0, "int", W, "int", H, "uint", hdcMem, "int", 0, "int", 0, "uint", 0xCC0020)	;hex code for SRCOPY raster-op code
return

ExitSub:
GuiClose:
DllCall("DeleteObject", "Ptr", hPenBG)
DllCall("DeleteObject", "Ptr", hPenAxis)
DllCall("DeleteObject", "Ptr", hPenCursor)
DllCall("DeleteObject", "Ptr", hBrushBG)
DllCall("DeleteObject", "Ptr", hbm)
DllCall("DeleteObject", "Ptr", hbmO)
DllCall("DeleteDC", "Ptr", hdcMem)
DllCall("ReleaseDC", "Ptr", hwnd, "UInt", hdcWin)
ExitApp





