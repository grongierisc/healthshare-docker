/// Transforms vR4 Identifier to SDA3 HS.SDA3.PatientNumber
Class HS.FHIR.DTL.vR4.SDA3.Identifier.PatientNumber Extends Ens.DataTransformDTL [ DependsOn = (HS.FHIR.DTL.vR4.Model.Datatype.Identifier, HS.SDA3.PatientNumber), ProcedureBlock ]
{

Parameter IGNOREMISSINGSOURCE = 0;

Parameter REPORTERRORS = 0;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HS.FHIR.DTL.vR4.Model.Datatype.Identifier' targetClass='HS.SDA3.PatientNumber' create='existing' language='objectscript' >
<annotation> Transforms Identifier (vR4) to HS.SDA3.PatientNumber (SDA3) </annotation>
<if condition='source.assigner&apos;=""' >
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.Organization).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.assigner, .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Organization' action='set' >
<annotation> The Assigning Authority for the number </annotation>
</assign>
</true>
</if>
</true>
</if>
<if condition='source.period&apos;=""' >
<true>
<if condition='source.period.end&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.period.end)' property='value' action='set' />
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
<if condition='source.period&apos;=""' >
<true>
<if condition='source.period.start&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.period.start)' property='value' action='set' />
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
<assign value='##class(HS.FHIR.DTL.Util.Lookup).GetCodeForURI(source.system)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.ISOAssigningAuthority' action='set' >
<annotation> intended to contain the entire Hierarchic Designator (HD) structure, i.e. all of PID-3.4, not just PID-3.4.1
 --- SDA3 HS.SDA3.PatientNumber:ISOAssigningAuthority is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
<if condition='source.type&apos;=""' >
<true>
<assign value='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","identifier-type","HS.SDA3.PatientNumber:NumberType",source.type)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.NumberType' action='set' >
<annotation> The type of number (e.g. medical record, social security, driver&#39;s license)
 --- This mapping entry seeks a lookup table entry that can match a source value with a target value for this field. If the mapping cannot find the lookup table, or cannot find a matching entry in the lookup table, and it has a non-empty Default Value defined, it places its Default Value into the target field. Otherwise, the target receive no value from this mapping. 
 --- SDA3 HS.SDA3.PatientNumber:NumberType is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
</true>
</if>
<if condition='source.type&apos;=""' >
<true>
<if condition='source.type.coding.Count()&gt;0' >
<true>
<if condition='source.type.coding.(1).code&apos;=""' >
<true>
<if condition='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","identifier-type","HS.SDA3.PatientNumber:NumberType",source.type) = ""' >
<true>
<if condition='source.type.coding.(1).code&apos;=""' >
<true>
<assign value='source.type.coding.(1).code' property='target.NumberType' action='set' >
<annotation> The type of number (e.g. medical record, social security, driver&#39;s license)
 --- SDA3 HS.SDA3.PatientNumber:NumberType is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
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
<if condition='source.type&apos;=""' >
<true>
<if condition='source.type.text&apos;=""' >
<true>
<if condition='(source.type.coding = "") || (source.type.coding.Count() = 0) || (source.type.coding.(1).code = "")' >
<true>
<if condition='source.type.text&apos;=""' >
<true>
<assign value='source.type.text' property='target.NumberType' action='set' >
<annotation> The type of number (e.g. medical record, social security, driver&#39;s license)
 --- SDA3 HS.SDA3.PatientNumber:NumberType is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.value&apos;=""' >
<true>
<assign value='source.value' property='target.Number' action='set' >
<annotation> 
 --- SDA3 HS.SDA3.PatientNumber:Number is type %String with a maximum string length of *220*.    </annotation>
</assign>
</true>
</if>
<if condition='(target.NumberType = "MRN") &amp;&amp; (target.Organization = "")' >
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.Organization).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference("Synthea", .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Organization' action='set' >
<annotation>The Assigning Authority for the number Hack for synthea datas </annotation>
</assign>
</true>
</if>
</true>
</if>
</transform>
}

}
