/// Transforms vR4 DiagnosticReport to SDA3 HS.SDA3.LabOrder
Class HS.FHIR.DTL.vR4.SDA3.DiagnosticReport.LabOrder Extends Ens.DataTransformDTL [ DependsOn = (HS.FHIR.DTL.vR4.Model.Resource.DiagnosticReport, HS.SDA3.LabOrder), ProcedureBlock ]
{

Parameter IGNOREMISSINGSOURCE = 0;

Parameter REPORTERRORS = 0;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HS.FHIR.DTL.vR4.Model.Resource.DiagnosticReport' targetClass='HS.SDA3.LabOrder' create='existing' language='objectscript' >
<annotation> Transforms DiagnosticReport (vR4) to HS.SDA3.LabOrder (SDA3) </annotation>
<if condition='source.basedOn&apos;=""' >
<true>
<if condition='source.basedOn.Count()&gt;0' >
<true>
<assign value='target' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.basedOn.GetAt(1), .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target' action='set' >
<annotation> 
 --- FHIR4 DiagnosticReport:basedOn is a *List*, and SDA3 HS.SDA3.LabOrder is *Single*. 
 --- For a list of objects mapped to a single object, when the transformation is FHIR to SDA, the transformation maps the first object from the source list to the target, and discards the others.   </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.code&apos;=""' >
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.Order).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.code, "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""' >
<true>
<assign value='$classmethod(DTL, "Transform", source.code, .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""' >
<true>
<assign value='tmp' property='target.OrderItem' action='set' >
<annotation> 
 --- In this case, report-codes is the Preferred FHIR4 ValueSet for codes, but if you need to express meanings not found in report-codes, you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.conclusion&apos;=""' >
<true>
<assign value='source.conclusion' property='target.Comments' action='set' />
</true>
</if>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.effectiveDateTime)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.FromTime' action='set' >
<annotation> Start of time range </annotation>
</assign>
</true>
</if>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.effectiveDateTime)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.ToTime' action='set' >
<annotation> End of time range </annotation>
</assign>
</true>
</if>
<if condition='source.effectivePeriod&apos;=""' >
<true>
<if condition='source.effectivePeriod.end&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.effectivePeriod.end)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.ToTime' action='set' >
<annotation> End of time range </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.effectivePeriod&apos;=""' >
<true>
<if condition='source.effectivePeriod.start&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.effectivePeriod.start)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.FromTime' action='set' >
<annotation> Start of time range </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.encounter&apos;=""' >
<true>
<assign value='""' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.encounter, .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.EncounterNumber' action='set' >
<annotation> A string that uniquely identifies an Encounter within a patient record.
 --- SDA3 HS.SDA3.LabOrder:EncounterNumber is type %String with a maximum string length of *220*.    </annotation>
</assign>
</true>
</if>
</true>
</if>
<if condition='source.issued&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.issued)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Result.ResultTime' action='set' />
</true>
</if>
</true>
</if>
<if condition='source.presentedForm&apos;=""' >
<true>
<if condition='(source.result = "") || (source.result.Count() = 0)' >
<true>
<if condition='source.presentedForm.Count()&gt;0' >
<true>
<assign value='##class(HS.SDA3.Result).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.presentedForm.(1), "HS.FHIR.DTL.vR4.SDA3.Attachment.Result")' property='DTL' action='set' />
<if condition='DTL&apos;=""' >
<true>
<assign value='$classmethod(DTL, "Transform", source.presentedForm.(1), .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""' >
<true>
<assign value='tmp' property='target.Result' action='set' >
<annotation> 
 --- FHIR4 DiagnosticReport:presentedForm is a *List*, and SDA3 HS.SDA3.LabOrder:Result is *Single*. 
 --- For a list of objects mapped to a single object, when the transformation is FHIR to SDA, the transformation maps the first object from the source list to the target, and discards the others.   </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.result&apos;=""' >
<true>
<foreach property='source.result()' key='st' >
<assign value='##class(HS.SDA3.LabResultItem).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.result.GetAt(st), .value, .aux)' property='value' action='set' />
<if condition='target.Result&apos;=""' >
<true>
<assign value='target.Result.ResultItems.Count()+1' property='index' action='set' />
</true>
<false>
<assign value='1' property='index' action='set' />
</false>
</if>
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Result.ResultItems' action='set' key='index' >
<annotation> A list of the lab result&#39;s items. </annotation>
</assign>
</true>
</if>
</foreach>
</true>
</if>
<if condition='source.specimen&apos;=""' >
<true>
<foreach property='source.specimen()' key='st' >
<assign value='##class(HS.SDA3.Specimen).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.specimen.GetAt(st), .value, .aux)' property='value' action='set' />
<assign value='target.Specimens.Count()+1' property='index' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Specimens' action='set' key='index' />
</true>
</if>
</foreach>
</true>
</if>
<assign value='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","diagnostic-report-status|4.0.1","HS.SDA3.LabOrder:Status",source.status)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Status' action='set' >
<annotation> 
 --- This mapping entry seeks a lookup table entry that can match a source value with a target value for this field. If the mapping cannot find the lookup table, or cannot find a matching entry in the lookup table, and it has a non-empty Default Value defined, it places its Default Value into the target field. Otherwise, the target receive no value from this mapping.    </annotation>
</assign>
</true>
</if>
<if condition='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","diagnostic-report-status|4.0.1","HS.SDA3.LabOrder:Status",source.status) = ""' >
<true>
<if condition='source.status&apos;=""' >
<true>
<assign value='source.status' property='target.Status' action='set' >
<annotation> 
 --- This mapping operates only when a table lookup to match an incoming FHIR code value with an appropriate SDA Code value fails. In that case, this mapping maps the source FHIR code value (unchanged) into an SDA CodeTableDetail Code value, and if the FHIR code was inside a Coding or CodeableConcept, it maps the FHIR display, system, and version values into appropriate SDA CodeTableDetail fields.    </annotation>
</assign>
</true>
</if>
</true>
</if>
<assign value='source.id' property='target.PlacerId' action='set' />
</transform>
}

}
