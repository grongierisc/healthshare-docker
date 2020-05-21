/// Transforme HS.SDA3.QuickStream to file
Class FHIRTOSDA.File.Operation Extends EnsLib.File.PassthroughOperation
{

Method OnMessage(pInput As Ens.StreamContainer, Output pResponse As %Persistent) As %Status
{
	//Get quickstream
	Set tQuick = ##class(HS.SDA3.QuickStream).%OpenId(pInput.AdditionalInfo.GetAt("QuickStreamId"))

	Set tFilename=##class(Ens.Util.File).CreateTimestamp("SDA")
	Set tSC=..Adapter.PutStream(tFilename, tQuick)
	Quit tSC
}

}
