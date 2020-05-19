/// Transforme FHIR R4 files (bundle, transcation, batch)
/// to HS.FHIRServer.Interop.Request
Class FHIRTOSDA.File.Service Extends EnsLib.File.PassthroughService
{

Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	#dim tSC,tSC1 As %Status = $$$OK
	#dim tSource, tWorkArchive, iTarget, tOneTarget As %String
	#dim tSyncCommit As %Integer
	
	Set tSC=..resolveAndIndex(pInput) Quit:$$$ISERR(tSC) tSC


	Set inputQuickStream = ##class(HS.SDA3.QuickStream).%New()
	Set inputQuickStreamId = inputQuickStream.%Id()
	$$$ThrowOnError( inputQuickStream.CopyFrom(pInput))

    Set tRequest = ##class(HS.FHIRServer.Interop.Request).%New()
    Set tRequest.QuickStreamId = inputQuickStreamId

	Set tWorkArchive=(""'=..Adapter.ArchivePath)&&(..Adapter.ArchivePath=..Adapter.WorkPath || (""=..Adapter.WorkPath && (..Adapter.ArchivePath=..Adapter.FilePath)))
	$$$SyncCommitSet(tSyncCommit)
	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		If tWorkArchive {
			Set tSC1=..SendRequestAsync(tOneTarget,tRequest)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		} Else {
			#; If not archiving send Sync to avoid Adapter deleting file before Operation gets it
			Set tSC1=..SendRequestSync(tOneTarget,tRequest)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
	}

	/* 
		If we are going to go on to delete/move the file
		when ProcessInput returns success we need to delete
		the Stream property from pInput.
		Need to do after sending to all targets.
	*/

	If 'tWorkArchive && $$$ISOK(tSC) {
		Set tSC1 = ..removeStreamFromInput(pInput)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	}
	
	$$$SyncCommitClear(tSyncCommit)
	Quit tSC
}

}
