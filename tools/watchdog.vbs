Option Explicit

Dim WshShell, Fso, ObjWMIService, ColProcessList
Dim GoosePath, LogPath, DebugFlagPath, DebugMode, Command, ExitCode

Set WshShell = CreateObject("WScript.Shell")
Set Fso = CreateObject("Scripting.FileSystemObject")

GoosePath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\GoosePrank\DesktopGoose-Prank\GooseDesktop.exe")
LogPath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\GoosePrank\watchdog.log")
DebugFlagPath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\GoosePrank\debug.enabled")
DebugMode = Fso.FileExists(DebugFlagPath)

If WScript.Arguments.Count > 0 Then
    DebugMode = (LCase(WScript.Arguments(0)) = "debug")
End If

LogMessage "Watchdog started. Debug=" & DebugMode
LogMessage "Goose path: " & GoosePath

If Not Fso.FileExists(GoosePath) Then
    ReportError "GooseDesktop.exe does not exist at:" & vbCrLf & GoosePath
    WScript.Quit 2
End If

Do
    On Error Resume Next
    Set ObjWMIService = GetObject("winmgmts:\\.\root\cimv2")
    If Err.Number <> 0 Then
        ReportError "Could not open WMI. Error: 0x" & Hex(Err.Number) & " " & Err.Description
        Err.Clear
    Else
        Set ColProcessList = ObjWMIService.ExecQuery("Select * from Win32_Process Where Name = 'GooseDesktop.exe'")
        If Err.Number <> 0 Then
            ReportError "Could not read the process list. Error: 0x" & Hex(Err.Number) & " " & Err.Description
            Err.Clear
        ElseIf ColProcessList.Count = 0 Then
            LogMessage "Goose is not running; starting it."
            Command = Chr(34) & GoosePath & Chr(34)
            ExitCode = WshShell.Run(Command, IIf(DebugMode, 1, 0), False)
            If Err.Number <> 0 Then
                ReportError "Could not start GooseDesktop.exe. Error: 0x" & Hex(Err.Number) & " " & Err.Description
                Err.Clear
            Else
                LogMessage "Start command result: " & ExitCode
            End If
        ElseIf DebugMode Then
            LogMessage "Goose is already running."
        End If
    End If
    On Error GoTo 0
    WScript.Sleep 10000
Loop

Sub LogMessage(Message)
    Dim LogFile
    On Error Resume Next
    Set LogFile = Fso.OpenTextFile(LogPath, 8, True)
    LogFile.WriteLine Now & " | " & Message
    LogFile.Close
    On Error GoTo 0
    If DebugMode Then WScript.Echo Now & " | " & Message
End Sub

Sub ReportError(Message)
    LogMessage "ERROR | " & Replace(Message, vbCrLf, " | ")
    If DebugMode Then MsgBox Message, vbCritical, "Goose Watchdog"
End Sub

Function IIf(Expression, TruePart, FalsePart)
    If Expression Then
        IIf = TruePart
    Else
        IIf = FalsePart
    End If
End Function
