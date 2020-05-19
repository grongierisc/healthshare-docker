/// Test.Util.Files contains commonly used methods for selecting operating system files.
/// Code was copied from QDHS.Util.Files and modified.
Class QDHS.Util.Files Extends %RegisteredObject
{

ClassMethod PromptForFiles(pDirPathAndName As %String = "", ByRef pFiles As %String, ByRef pPause As %String, pWildCard As %String = "") As %Status
{
	Set tSC=$$$OK

	Kill pFiles
	Set pFiles = 0
	Set pPause = ""

	Try {
		If pDirPathAndName="" Set tSC = $$$ERROR($$$GeneralError,"Directory path and name not specified") Quit

		Set tSC = ..GetFiles(pDirPathAndName, .tFiles, , pWildCard)
		If '$$$ISOK(tSC) Quit
		If tFiles=0 Set tSC = $$$ERROR($$$GeneralError,"No files found in "_pDirPathAndName) Quit 

		Set tAbort = 0
		Set tMaxOneCol = 19
		Set tNumCols = 2
		Set tTab1 = $Select(tNumCols=2:40,tNumCols=3:27,1:"")
		Set tTab2 = $Select(tNumCols=2:"",tNumCols=3:54,1:"")
		Set tMaxLen = $Select(tNumCols=2:35,tNumCols=3:20,1:70)
		If tFiles'>tMaxOneCol Set tPerColumn = tFiles
		If tFiles>tMaxOneCol Set tPerColumn = (tFiles/tNumCols) Set:tPerColumn["." tPerColumn=((tFiles\tNumCols)+1)
		Set tTab0A = $Select(tPerColumn>9:4,1:3)
		Set tTab1A = $Select((tPerColumn*2)>9:tTab1+4,1:tTab1+3)
		Set tTab2A = $Select((tPerColumn*2)>9:tTab2+4,1:tTab2+3)
	
		Write !!,"SELECT (Enter '?' for Help)",!
		If tFiles'>tMaxOneCol For i=1:1:tFiles Write !,i_". "_tFiles(i,"Name")
		If tFiles>tMaxOneCol {
			For i=1:1:tPerColumn {
				Set ti2=(i+tPerColumn),ti3=(i+(tPerColumn*2))
				Set tTemp = tFiles(i,"Name")
				If $Length(tTemp)>tMaxLen Set tTemp=$Extract(tTemp,1,(tMaxLen-3))_"..."
				Write !,i_".",?tTab0A,tTemp
				If tNumCols>1,$Data(tFiles(ti2,"Name")) {
					Set tTemp = tFiles(ti2,"Name")
					If $Length(tTemp)>tMaxLen Set tTemp=$Extract(tTemp,1,(tMaxLen-3))_"..."
					Write ?tTab1,ti2_".",?tTab1A,tTemp
				}
				If tNumCols>2,$Data(tFiles(ti3,"Name")) {
					Set tTemp = tFiles(ti3,"Name")
					If $Length(tTemp)>tMaxLen Set tTemp=$Extract(tTemp,1,(tMaxLen-3))_"..."
					Write ?tTab2,ti3_".",?tTab2A,tTemp
				}
			}
		}	
		For {
			Write !!,"? "
			Read tRead
			Set pPause = ""
			Set tRead = $ZCVT(tRead,"U")
			If tRead?.E1"#".N!(tRead?.E1"#P") Set pPause=$Piece(tRead,"#",2),tRead=$Piece(tRead,"#",1)
			If tRead=""!(tRead="*") Set tAbort = 1 Quit
			Set tValid = ..ValidateFileChoice(tRead, .tFiles)
			If tRead="?" Do ..ShowHelp()
			If tRead'="",tRead'="?",tValid=1 Set tFLOpt=tRead Quit
			If tRead'="?" Write "  Invalid entry"
		}
		If tAbort=1 Set tSC = $$$ERROR($$$GeneralError,"Aborted by user request.") Quit

		Set tCount = 0
	
		If tFLOpt["," {
			For j=1:1:$Length(tFLOpt,",") {
				Set i = $Piece(tFLOpt, ",", j)
				If i'="" Set tCount = tCount + 1 Merge pFiles(tCount) = tFiles(i) Set pFiles = tCount
			}
		} Else {
			If tFLOpt="ALL" Set tStart=1,tEnd=tFiles	
			If tFLOpt?1N.N Set tStart=tFLOpt,tEnd=tFLOpt
			If tFLOpt["-" Set tStart=$Piece(tFLOpt,"-",1),tEnd=$Piece(tFLOpt,"-",2)	
			For i = tStart:1:tEnd {
				Set tCount = tCount + 1
				Merge pFiles(tCount) = tFiles(i)
				Set pFiles = tCount
			}
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod ShowHelp()
{
	Write !
	Write !,"VALID RESPONSES:"
	Write !,"- Enter a single number to select one file."
	Write !,"- Enter 'ALL' to select all files."
	Write !,"- Enter a range of file numbers (x-y)."
	Write !,"- Enter a comma-delimited list of numbers."
	Write !,"- Enter '*' to abort the selection."
	Write !
	Quit
	
	// TODO: Do something about this file copy specific language.
	Write !,"COPYING LINE-BY-LINE:"
	Write !,"In most cases QDHS copies a file line-by-line to a new file. This is done to force the file service to process the files in lexical filename order, or to process in the order specified in a delimited list. Otherwise, the copy of each file is done using ##class(%Library.File).CopyFile."
	Write !
	Write !,"PAUSING BETWEEN FILES AND COPYING LINE-BY-LINE:"
	Write !,"- Copying a single file will NOT copy line-by-line."
	Write !,"- Copying more than one file will by default copy line-by-line, and by default will pause 1 second between each file."
	Write !,"- Suffix of '#P' will cause a prompt after copying each file."
	Write !,"- Suffix of '#' plus some number >0 will pause for that number of seconds after copying each file."
	Write !,"- Suffix of '#0' will incur no pause between files, and will NOT copy line-by-line."
	Quit
}

/// GetFiles returns an array of the files that are found in the
/// operating system directory pSourceDir.  File ".DS_Store" is
/// filtered out.
ClassMethod GetFiles(pSourceDir As %String, ByRef pFileArray As %String, pType As %String = "F", pWildCard As %String = "", pRecursive As %Boolean = 0) As %Status
{
	Set tSC=$$$OK

	Try {
		If $Data(pFileArray)=0 Set pFileArray = 0
		If $Data(pFileArray)>9,$Data(pFileArray)#10=0 Set tSC = $$$ERROR($$$GeneralError, "Invalid file array input") Quit
		
		If ##class(%Library.File).Exists(pSourceDir)=1,##class(%Library.File).DirectoryExists(pSourceDir)=0 {
			If $i(pFileArray)
			Set pFileArray(pFileArray,"PathAndName")=pSourceDir
			Set pFileArray(pFileArray,"Name")=##class(%Library.File).GetFilename(pSourceDir)
			Quit
		}
		
		Set tSortBy = ""
		Set tSC = ##class(%File).FileSetExecute(.tHandle, pSourceDir, pWildCard, tSortBy, 0, ",")

		If $$$ISOK(tSC) {
			Set tAtEnd = 0
			For {
				Set tSC = ##class(%File).FileSetFetch(.tHandle, .tRow, .tAtEnd)
				If '$$$ISOK(tSC)!($ListLength(tRow)<6) Quit
				Set tFile = $List(tRow, 6)
				Set tType = $List(tRow, 2)
				If tFile'=".DS_Store",tType'="",pType[tType,$Extract(tFile,*-3,*)'=".bak" {
					If $i(pFileArray)
					Set pFileArray(pFileArray, "Name") = tFile
					Set pFileArray(pFileArray, "PathAndName") = $List(tRow, 1)
				} ElseIf tType="D",pRecursive=1 {
					Set tSC = ..GetFiles($List(tRow, 1), .pFileArray, pType, pWildCard, pRecursive)
				}
				If tAtEnd Quit
			}	
			Set tSC = ##class(%File).FileSetClose(.tHandle)
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Moved the file choice validation here to make the code
/// easier to read.  Must be a number or numbers from the
/// file choice menu, or the word "ALL".  Multiple numbers
/// must be separated by comma, do not need to be in a
/// particular order, and may repeat.
ClassMethod ValidateFileChoice(pRead As %String, ByRef pFileArray As %String) As %Boolean
{
	Set tValid = 1

	Try {
		If pRead="?" Quit

		If $ZCVT(pRead,"U")="ALL" Quit

		If pRead?1N.N Set tValid=($Data(pFileArray(pRead))>0) Quit

		If $Translate(pRead, "-,1234567890")'="" Set tValid = 0 Quit

		If pRead["-" {
			If pRead[","!($Length(pRead, "-")>2) {
				Set tValid = 0
			} Else {
				Set tStart = $Piece(pRead, "-", 1)
				Set tEnd = $Piece(pRead, "-", 2)
				If +tStart<1!(+tEnd<1)!(tStart>pFileArray)!(tEnd>pFileArray)!(tStart>tEnd) Set tValid = 0
			}		
		} Else {
			For i=1:1:$Length(pRead, ",") {
				Set tPiece = $Piece(pRead, ",", i)
				If tPiece="" Set tValid = 0 Quit
				If $Data(pFileArray(tPiece))=0 Set tValid = 0 Quit		
			}
		}

	} Catch ex {
		Set tValid = 0
	}

	Quit tValid
}

/// CopyFiles copies the files in pFiles to the specified
/// file service file path or TCP service port and host.
/// This method assumes that the files in pFiles are either
/// all HL7 files or all SDA files.
/// <br>
/// <br>Input:
/// <br>- pFSPath = Ensemble file service path to copy to.
/// <br>- pFiles = Array of file paths and names to copy from.
/// <br>- pPause = Number of seconds to wait between the copy of each file.
/// <br>- pLineByLine = (applies only to use with file services) <b>1</b> means copy the files by opening each as input from the source
/// and opening it as output at the target, then copying over each line one at a time.
/// <b>0</b> means use ##class(%Library.File).CopyFile to copy the file.
/// <br>- pPort = TCP service TCP port
/// <br>- pHost = TCP service TCP host
/// <br>
/// <br>Output:
/// <br>- pFileCount = The number of files actually copied.
ClassMethod CopyFiles(pFSPath As %String = "", ByRef pFiles As %String = "", pPause As %Integer = 0, pLineByLine As %Boolean, ByRef pFileCount As %Integer, ByRef pPort As %String = "", ByRef pHost As %String = "") As %Status
{
	Set tSC=$$$OK

	Set pFileCount = 0

	Try {
		If pFSPath="",(pPort=""!(pHost="")) Set tSC = $$$ERROR($$$GeneralError,"Neither file path nor TCP port specified") Quit
		If pFSPath'="",(pPort'=""!(pHost'="")) Set tSC = $$$ERROR($$$GeneralError,"File path and TCP port specified") Quit
		If $Data(pFiles)'>9 Set tSC = $$$ERROR($$$GeneralError,"No files specified") Quit
		If pPause'="P",pPause'?1N.N Set tSC = $$$ERROR($$$GeneralError,"Invalid pause specified") Quit
		If $Data(pLineByLine)=0 Set pLineByLine=(pPause'="P"&(pPause'=0))

		If pPort'="" Set tSC = ..CopyFilesToTCP(.pFiles, pPause, .pFileCount, pPort, pHost)
		
		If pFSPath'="" Set tSC = ..CopyFilesToFS(pFSPath, .pFiles, pPause, pLineByLine, .pFileCount)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If '$$$ISOK(tSC) Set tSC = $$$ERROR($$$GeneralError, "CopyFiles failed - "_$system.Status.GetErrorText(tSC))

	Quit tSC
}

/// CopyFilesToFS copies the files specified in
/// pFiles to the file service file path pFSPath.
ClassMethod CopyFilesToFS(pFSPath As %String, ByRef pFiles As %String, pPause As %Integer = 0, pLineByLine As %Boolean, ByRef pFileCount As %Integer) As %Status
{
	Set tSC = $$$OK
	
	Try {
		For i = 1:1:pFiles {
			Set tSourcePathAndFile = pFiles(i, "PathAndName")
			Set tTargetPathAndFile = pFSPath_pFiles(i, "Name")
			Write !,"Copying "_pFiles(i, "Name")
			If pLineByLine=1 {
				Set tSC = ..CopyLineByLineToFS(tSourcePathAndFile, tTargetPathAndFile)
			} Else {
				Set tSC = ##class(%Library.File).CopyFile(tSourcePathAndFile, tTargetPathAndFile)
				If tSC=0 Set tSC = $$$ERROR($$$GeneralError,"Could not copy "_tSourcePathAndFile_" to "_tTargetPathAndFile)
			}
			If $$$ISOK(tSC) Set pFileCount = pFileCount + 1
			If pPause="P" Write !!,"Press RETURN to continue..." Read tRead
			If pPause?1N.N,pPause>0,i<pFiles Hang pPause
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// CopyLineByLineToFS copies a file by opening it as input
/// from the source and opening it as output at the target,
/// then copying over each line one at a time.
ClassMethod CopyLineByLineToFS(pSourcePathAndFile As %String, pTargetPathAndFile As %String) As %Status
{
	Set tSC=$$$OK

	Try {
		Open pSourcePathAndFile:"R":5 If '$Test Set tSC = $$$ERROR($$$GeneralError,"Could not open "_pSourcePathAndFile_" for input") Quit

		Open pTargetPathAndFile:"WNS":5 If '$Test Set tSC = $$$ERROR($$$GeneralError,"Could not open "_pTargetPathAndFile_" for output") Quit

		For i=1:1 Use pSourcePathAndFile Read tLine Use pTargetPathAndFile Write tLine,!

	} Catch ex {
		If $ZE'["ENDOF" Set tSC = ex.AsStatus()
	}

	Close pSourcePathAndFile
	Close pTargetPathAndFile

	Quit tSC
}

/// CopyFilesToTCP copies the contents of the files
/// specified in pFiles to the TCP pPort and pHost.
/// This method assumes that the files in pFiles are
/// either all HL7 files or all SDA files.
ClassMethod CopyFilesToTCP(ByRef pFiles As %String, pPause As %Integer = 0, ByRef pFileCount As %Integer, ByRef pPort As %String, ByRef pHost As %String) As %Status
{
	Set tSC = $$$OK
	
	Try {
		// Ad hoc alogrithm for randoming the device number.
		Set tNumber = 0
		For i = 1:1:$Length(pHost) Set tNumber = tNumber + $Ascii($Extract(pHost,i))
		Set tNumber = tNumber + pPort
		If $Length(tNumber)>5 Set tNumber = $Extract(tNumber, $Length(tNumber)-4, $Length(tNumber))

		Set tDevice = "|TCP|"_tNumber
		Open tDevice:(pHost:pPort:"S":$Char(28):32767:32767):5 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Cannot open TCP device "_tDevice) Quit
		Use tDevice

		For i = 1:1:pFiles {
			Use 0 Write !,"Copying "_pFiles(i, "Name")
			Set tSC = ..CopyToTCP(pFiles(i,"PathAndName"), tDevice, pPort, pHost, (i=pFiles))
			Use 0
			If '$$$ISOK(tSC) Quit
			Set pFileCount = pFileCount + 1
			If pPause="P" Write !!,"Press RETURN to continue..." Read tRead
			If pPause?1N.N,pPause>0,i<pFiles Hang pPause
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Close tDevice

	Quit tSC
}

/// CopyToTCP copies a file by opening it as input
/// the source and then assembling it into one big
/// string and sending that to a TCP service.  This
/// method assumes that pDevice is already opened.
ClassMethod CopyToTCP(pSourcePathAndFile As %String, pDevice As %String, pPort As %String, pHost As %String, pLastOne As %Boolean) As %Status
{
	Set tSC=$$$OK

	Try {
		Set tSC = ..GetMessageFileType(pSourcePathAndFile, .tDataType)
		If '$$$ISOK(tSC) Quit

		If tDataType="HL7" Set tSC = ..CopyHL7ToTCP(pSourcePathAndFile, pDevice, pPort, pHost)
		If tDataType="SDA" Set tSC = ..CopySDAToTCP(pSourcePathAndFile, pDevice, pPort, pHost) If pLastOne=1 Hang 2

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// GetMessageFileType determines whether the specified file
/// contains HL7 messages or SDA.  The logic is a bit
/// simplistic but it should be good enough for QDHS.
ClassMethod GetMessageFileType(pFile As %String, ByRef pType As %String) As %Status
{
	Set tSC=$$$OK

	Set pType = ""

	Try {
		Open pFile:"R":5 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Could not open "_pFile) Quit
	
		For {
			Use pFile Read tLine
			If tLine["<Container>" Set pType = "SDA" Quit
			If $Extract(tLine,1,3)="MSH" Set pType = "HL7" Quit
		}

	} Catch ex {
		If ex.Name'["ENDOF" Set tSC = ex.AsStatus()
	}

	Close pFile

	If pType="",$$$ISOK(tSC) Set tSC = $$$ERROR($$$GeneralError, "Unknown file type for "_pFile)

	Quit tSC
}

/// CopyHL7ToTCP copies the HL7 messages that are in pFile
/// to the TCP service at pHost/pPort.  This method assumes
/// that pDevice is already opened.  This method depends
/// on the HL7 TCP service to include these settings:
/// <br>- Framing = MLLP (Flexible might work too)
/// <br>- Ack Mode = Never
/// <br>- Batch Handling = Multi-Session Batch
/// <br>- Job Per Connection = False
/// <br>- Stay Connected = 10
ClassMethod CopyHL7ToTCP(pFile As %String, pDevice As %String, pPort As %String, pHost As %String) As %String
{
	Set tSC=$$$OK

	Set tStarted = 0
	Set tString = ""

	Try {
		Open pFile:"R":5 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Could not open "_pFile) Quit

		For {
			Use pFile Read tLine
			If $Extract(tLine,1,3)="MSH" {
				If tStarted=1 {
					Set tString = $Char(11)_tString_$Char(28,13)
					Use pDevice Write tString
					Use pDevice Write *-3
					Set tString = ""
					Use pDevice Read tAck:10 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Timeout reading ACK") Quit
				}
				If '$$$ISOK(tSC) Quit
				Set tStarted = 1
			}
			If '$$$ISOK(tSC) Quit
			If $Translate(tLine," "_$Char(9))'="" Set tString = tString_tLine_$Char(13)
		}

	} Catch ex {
		If ex.Name'["ENDOF" Set tSC = ex.AsStatus()
	}

	Close pFile

	If $$$ISOK(tSC),tString'="" {
		Set tString = $Char(11)_tString_$Char(28,13)
		Use pDevice Write tString
		Use pDevice Write *-3
		Use pDevice Read tAck:10 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Timeout reading ACK")
	}

	Quit tSC
}

/// CopySDAToTCP copies the contents of pFile to the SDA
/// TCP service at pHost/pPort.  This method assumes
/// that pFile contains only one SDA Container.  This
/// method assumes that pDevice is already opened.  This
/// method depends on the SDA TCP service to include
/// these settings:
/// <br>- StayConnected = 10
/// <br>- JobPerConnection = False
/// <br>- AcceptClassnames = HS.SDA.Container
ClassMethod CopySDAToTCP(pFile As %String, pDevice As %String, pPort As %String, pHost As %String) As %Status
{
	Set tSC=$$$OK

	Set tString = ""

	Try {
		Open pFile:"R":5 If '$Test Set tSC = $$$ERROR($$$GeneralError, "Could not open "_pFile) Quit

		For  Use pFile Read tLine If $Translate(tLine," "_$Char(9))'="" Set tString = tString_tLine

	} Catch ex {
		If ex.Name'["ENDOF" Set tSC = ex.AsStatus()
	}

	Close pFile

	If $$$ISOK(tSC),tString'="" {
		Set tLen=$Length(tString)
		Set tLenStr=$C(tLen\16777216,tLen\65536#256,tLen\256#256,tLen#256)
		Use pDevice Write tLenStr
		Use pDevice Write tString
		Use pDevice Write *-3
	}

	Quit tSC
}

}
