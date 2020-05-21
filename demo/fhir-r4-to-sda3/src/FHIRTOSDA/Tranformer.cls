Class FHIRTOSDA.Transformer Extends HS.FHIR.DTL.Util.API.Transform.FHIRToSDA3
{

Method TransformBundle(source As %DynamicObject) As HS.FHIR.DTL.Util.API.Transform.FHIRToSDA3 [ Internal, Private ]
{
    set tReturn = ##super(source)

    set tReturn.%container.SendingFacility = ..GetSendingFacility()
    set tReturn.%object = tReturn.%container
	
	return tReturn
}

}
