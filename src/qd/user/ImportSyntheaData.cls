Class qd.user.ImportSyntheaData
{

/// Usage:  Set tSC = ##class(qd.User.ImportSyntheaData).ConvertAllFiles(tSourceDirectory, tOutputDirectory)
/// Converts all the CCDA files in tSourceDirectory to SDA files in tOutputDirectory
/// Will return an error if tSourceDirectory includes files that are not CCDA
ClassMethod ConvertCCDA(tSourceDirectory = "/tmp/misc/ccda", tTargetDirectory = "C:\Users\jparker\synthea\output\SDA") As %Status
{
	Set tSC = ..GetFilesFromSourceDirectory(tSourceDirectory,tTargetDirectory, .pArray)
	If $$$ISERR(tSC) {
		Return tSC
	}
	For tFileCount = 1:1:pArray {
		Set tCCDA = pArray(tFileCount,"PathAndName") // CCDA output file from Synthea
		Set tSDA = tTargetDirectory_"/"_pArray(tFileCount,"Name") // the name of the SDA file to create
		Set tXSL = "SDA3/CCDAv21-to-SDA.xsl" 
		w tCCDA,!
		w tSDA,!
		w tXSL,!
		Set tTransformer = ##class(HS.Util.XSLTTransformer).%New()
		Try {
			Set tSC = tTransformer.TransformFile(tCCDA, tXSL, tSDA)
			If $$$ISERR(tSC) {
				Return tSC
			}
		} 
		catch ex {
			Set tSC = ex.AsStatus()
		}		
	}
	Quit tSC
}

/// Usage:  Set tSC = ##class(qd.User.ImportSyntheaData).ConvertAllFiles(tSourceDirectory, tOutputDirectory)
/// Converts all the FHIR JSON files in tSourceDirectory to SDA files in tOutputDirectory
/// Will return an error if tSourceDirectory includes files that are not CCDA
/// *** This doesn't work yet ***
ClassMethod ConvertFHIR(tSourceDirectory = "C:\Users\jparker\synthea\output\fhir_dstu2", tTargetDirectory = "C:\Users\jparker\synthea\output\SDA") As %Status
{
	Set tSC = ..GetFilesFromSourceDirectory(tSourceDirectory, tTargetDirectory, .pArray)
	If $$$ISERR(tSC) {
		Quit tSC
	}
	For tFileCount = 1:1:pArray {
		Set tJSON = pArray(tFileCount,"PathAndName") // JSON output file from Synthea
		Set tSDA = tTargetDirectory_"\"_pArray(tFileCount,"Name") // the name of the SDA file to create
	}
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(tJSON)
	If $$$ISERR(tSC) {
		Quit tSC
	}
	Set tSC=##class(HS.FHIR.Utils).FHIRToHSFHIR("json",tStream,,.pHSFHIRObj,"HS.FHIR.Model")
	If $$$ISERR(tSC) {
		Quit tSC
	}
	
	
	Quit $$$OK
}

ClassMethod GetFilesFromSourceDirectory(pSourceDirectory As %String, pTargetDirectory As %String, ByRef pArray) As %Status
{
	If (##class(%File).DirectoryExists(pSourceDirectory)=0) {
		Quit $$$ERROR(5001,"Source directory does not exist  "_pSourceDirectory)
	}
	If (##class(%File).DirectoryExists(pTargetDirectory)=0) {
		Quit $$$ERROR(5001,"Target directory does not exist  "_pTargetDirectory)
	}
	
	Set tSC = ##class(QDHS.Util.Files).GetFiles(pSourceDirectory, .pArray)
	If $$$ISERR(tSC) {
		Quit tSC
	}
	Quit $$$OK
}

}
