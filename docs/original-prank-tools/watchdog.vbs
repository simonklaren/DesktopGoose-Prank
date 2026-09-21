Option Explicit

Dim WshShell, Fso, ObjWMIService, ColProcessList
Dim GoosePath, LogPath, DebugMode, Command, ExitCode

Set WshShell = CreateObject("WScript.Shell")
Set Fso = CreateObject("Scripting.FileSystemObject")

goosePath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\GoosePrank\DesktopGoose\GooseDesktop.exe")
LogPath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\GoosePrank\watchdog.log")
DebugMode = False

If WScript.Arguments.Count > 0 Then
    DebugMode = (LCase(WScript.Arguments(0)) = "debug")
End If

LogMessage "Watchdog gestart. Debug=" & DebugMode
LogMessage "Goose-pad: " & GoosePath

If Not Fso.FileExists(GoosePath) Then
    ReportError "GooseDesktop.exe bestaat niet op:" & vbCrLf & GoosePath
    WScript.Quit 2
End If

Do
    On Error Resume Next

    Set ObjWMIService = GetObject("winmgmts:\\.\root\cimv2")
    If Err.Number <> 0 Then
        ReportError "Kan WMI niet openen." & vbCrLf & _
                    "Fout: 0x" & Hex(Err.Number) & vbCrLf & _
                    Err.Description
        Err.Clear
        WScript.Sleep 10000
    Else
        Set ColProcessList = ObjWMIService.ExecQuery( _
            "Select * from Win32_Process Where Name = 'GooseDesktop.exe'")

        If Err.Number <> 0 Then
            ReportError "Kan proceslijst niet uitlezen." & vbCrLf & _
                        "Fout: 0x" & Hex(Err.Number) & vbCrLf & _
                        Err.Description
            Err.Clear
        ElseIf ColProcessList.Count = 0 Then
            LogMessage "Goose draait niet; startpoging wordt uitgevoerd."

            Command = Chr(34) & GoosePath & Chr(34)
            ExitCode = WshShell.Run(Command, IIf(DebugMode, 1, 0), False)

            If Err.Number <> 0 Then
                ReportError "GooseDesktop.exe kon niet worden gestart." & vbCrLf & _
                            "Pad: " & GoosePath & vbCrLf & _
                            "Fout: 0x" & Hex(Err.Number) & vbCrLf & _
                            "Beschrijving: " & Err.Description & vbCrLf & vbCrLf & _
                            "0x800700D8 wijst meestal op een incompatibele of beschadigde executable."
                Err.Clear
            Else
                LogMessage "Startopdracht uitgevoerd. Run-resultaat: " & ExitCode
            End If
        ElseIf DebugMode Then
            LogMessage "Goose draait al."
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

    If DebugMode Then
        WScript.Echo Now & " | " & Message
    End If
End Sub

Sub ReportError(Message)
    LogMessage "FOUT | " & Replace(Message, vbCrLf, " | ")

    If DebugMode Then
        MsgBox Message, vbCritical, "Goose Watchdog"
    End If
End Sub

Function IIf(Expression, TruePart, FalsePart)
    If Expression Then
        IIf = TruePart
    Else
        IIf = FalsePart
    End If
End Function
