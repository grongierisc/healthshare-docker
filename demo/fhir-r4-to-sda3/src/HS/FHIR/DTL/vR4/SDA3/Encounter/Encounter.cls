/// Transforms vR4 Encounter to SDA3 HS.SDA3.Encounter
Class HS.FHIR.DTL.vR4.SDA3.Encounter.Encounter Extends Ens.DataTransformDTL [ DependsOn = (HS.FHIR.DTL.vR4.Model.Resource.Encounter, HS.SDA3.Encounter), ProcedureBlock ]
{

/// This DTL XData block was generated. Do not modify it.
XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HS.FHIR.DTL.vR4.Model.Resource.Encounter' targetClass='HS.SDA3.Encounter' create='existing' language='objectscript' >
  <annotation>
    <![CDATA[ Transforms Encounter (vR4) to HS.SDA3.Encounter (SDA3) ]]>
  </annotation>
<if condition='0=1'>
<true>
<if condition='(source.hospitalization &apos;= "") &amp;&amp; (source.hospitalization.admitSource &apos;= "") &amp;&amp; (source.hospitalization.admitSource.coding.Count() > 0) &amp;&amp; (source.hospitalization.admitSource.coding.(1).code = "emd")'> 
<true>
<assign value='"1"' property='target.TransferredFromED' action='set' >
<annotation>
<![CDATA[ Whether this Encounter began in the Emergency Department before being transferred to the Inpatient Department. ]]>
</annotation>
</assign>
</true>
</if>
<if condition='source.class&apos;=""'> 
<true>
<if condition='source.class.code&apos;=""'> 
<true>
<assign value='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","v3-ActEncounterCode","HS.SDA3.Encounter:EncounterType",source.class.code)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.EncounterType' action='set' >
<annotation>
<![CDATA[ 
 --- This mapping entry seeks a lookup table entry that can match a source value with a target value for this field. If the mapping cannot find the lookup table, or cannot find a matching entry in the lookup table, and it has a non-empty Default Value defined, it places its Default Value into the target field. Otherwise, the target receive no value from this mapping. 
 --- SDA3 HS.SDA3.Encounter:EncounterType is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    ]]>
</annotation>
</assign></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.class&apos;=""'> 
<true>
<if condition='source.class.code&apos;=""'> 
<true>
<if condition='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","v3-ActEncounterCode","HS.SDA3.Encounter:EncounterType",source.class.code) = ""'> 
<true>
<if condition='source.class.code&apos;=""'> 
<true> 
<assign value='source.class.code' property='target.EncounterType' action='set' >
<annotation>
<![CDATA[ 
 --- SDA3 HS.SDA3.Encounter:EncounterType is type %String and it has no MAXLEN value set, so its maximum string length is *50*. 
 --- This mapping operates only when a table lookup to match an incoming FHIR code value with an appropriate SDA Code value fails. In that case, this mapping maps the source FHIR code value (unchanged) into an SDA CodeTableDetail Code value, and if the FHIR code was inside a Coding or CodeableConcept, it maps the FHIR display, system, and version values into appropriate SDA CodeTableDetail fields.    ]]>
</annotation>
</assign></true> 
</if> 

</true>
</if>
</true>
</if>
</true>
</if>
<if condition='source.hospitalization&apos;=""'> 
<true>
<if condition='source.hospitalization.admitSource&apos;=""'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.AdmissionSource).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.hospitalization.admitSource, "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""'> 
<true>
<assign value='$classmethod(DTL, "Transform", source.hospitalization.admitSource, .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""'> 
<true>
<assign value='tmp' property='target.AdmissionSource' action='set'  >
<annotation>
<![CDATA[ 
 --- In this case, encounter-admit-source is the Preferred FHIR4 ValueSet for codes, but if you need to express meanings not found in encounter-admit-source, you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    ]]>
</annotation>
</assign></true> 
</if>
</true>
</if>

</true>
</if>
</true>
</if>
<if condition='source.hospitalization&apos;=""'> 
<true>
<if condition='source.hospitalization.dischargeDisposition&apos;=""'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.SeparationMode).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.hospitalization.dischargeDisposition, "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""'> 
<true>
<assign value='$classmethod(DTL, "Transform", source.hospitalization.dischargeDisposition, .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""'> 
<true>
<assign value='tmp' property='target.SeparationMode' action='set'  >
<annotation>
<![CDATA[ The conditions under which the patient was discharged
 --- In this case, any FHIR4 code may be used; encounter-discharge-disposition shows Example codes, but you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    ]]>
</annotation>
</assign></true> 
</if>
</true>
</if>

</true>
</if>
</true>
</if>
<assign value='aux("transformer").GetIdentifier("Encounter", source.id)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.EncounterNumber' action='set' >
<annotation>
<![CDATA[ A string that uniquely identifies an Encounter within a patient record.
 --- SDA3 HS.SDA3.Encounter:EncounterNumber is type %String with a maximum string length of *220*.    ]]>
</annotation>
</assign></true> 
</if> 
<if condition='source.participant&apos;=""'>
<true>
<assign value='1' property='j1' action='set' />
<foreach property='source.participant()' key='k1' >
<if condition='source.participant.(k1).individual&apos;=""'> 
<true>
<if condition='(source.participant.(k1).type.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.(1).code = "ADM")'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.CareProvider).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.participant.(k1).individual, .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.AdmittingClinician' action='set' /></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.participant.(k1).individual&apos;=""'> 
<true>
<if condition='(source.participant.(k1).type.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.(1).code = "ATND")'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.CareProvider).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.participant.(k1).individual, .value, .aux)' property='value' action='set' />
<assign value='target.AttendingClinicians.Count()+1' property='index' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.AttendingClinicians' action='set' key='index'  /></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.participant.(k1).individual&apos;=""'> 
<true>
<if condition='(source.participant.(k1).type.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.(1).code = "CON")'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.CareProvider).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.participant.(k1).individual, .value, .aux)' property='value' action='set' />
<assign value='target.ConsultingClinicians.Count()+1' property='index' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.ConsultingClinicians' action='set' key='index'  /></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.participant.(k1).individual&apos;=""'> 
<true>
<if condition='(source.participant.(k1).type.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.Count() > 0) &amp;&amp; (source.participant.(k1).type.(1).coding.(1).code = "REF")'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.ReferralDoctor).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.participant.(k1).individual, .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.ReferringClinician' action='set' /></true> 
</if> 
</true>
</if>
</true>
</if>
</foreach>
</true>
</if>
<if condition='source.period&apos;=""'> 
<true>
<if condition='source.period.end&apos;=""'> 
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.period.end)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.ToTime' action='set' >
<annotation>
<![CDATA[ End of time range ]]>
</annotation>
</assign></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.period&apos;=""'> 
<true>
<if condition='source.period.start&apos;=""'> 
<true>
<assign value='##class(HS.FHIR.DTL.Util.Element.TypeCast).FHIRDateToSDA3(source.period.start)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.FromTime' action='set' >
<annotation>
<![CDATA[ Start of time range ]]>
</annotation>
</assign></true> 
</if> 
</true>
</if>
</true>
</if>
<if condition='source.priority&apos;=""'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.EncounterPriority).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.priority, "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""'> 
<true>
<assign value='$classmethod(DTL, "Transform", source.priority, .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""'> 
<true>
<assign value='tmp' property='target.Priority' action='set'  >
<annotation>
<![CDATA[ The priority of this visit (Emergency, Urgent, Elective, etc.)
 --- In this case, any FHIR4 code may be used; v3-ActPriority shows Example codes, but you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    ]]>
</annotation>
</assign></true> 
</if>
</true>
</if>

</true>
</if>
<if condition='source.reasonCode&apos;=""'> 
<true>
<if condition='source.reasonCode.Count()>0'> 
<true> 
<assign value='##class(HS.SDA3.CodeTableDetail.AdmitReason).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.reasonCode.(1), "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""'> 
<true>
<assign value='$classmethod(DTL, "Transform", source.reasonCode.(1), .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""'> 
<true>
<assign value='tmp' property='target.AdmitReason' action='set'  >
<annotation>
<![CDATA[ 
 --- FHIR4 Encounter:reasonCode is a *List*, and SDA3 HS.SDA3.Encounter:AdmitReason is *Single*. 
 --- For a list of objects mapped to a single object, when the transformation is FHIR to SDA, the transformation maps the first object from the source list to the target, and discards the others.
 --- In this case, encounter-reason is the Preferred FHIR4 ValueSet for codes, but if you need to express meanings not found in encounter-reason, you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    ]]>
</annotation>
</assign></true> 
</if>
</true>
</if>
</true> 
</if> 
</true>
</if>
<if condition='source.serviceProvider&apos;=""'> 
<true>
<assign value='##class(HS.SDA3.CodeTableDetail.HealthCareFacility).%New()' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.serviceProvider, .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""'> 
<true>
<assign value='value' property='target.HealthCareFacility' action='set' /></true> 
</if> 
</true>
</if>
<if condition='source.type&apos;=""'> 
<true>
<if condition='source.type.Count()>0'> 
<true> 
<assign value='##class(HS.SDA3.CodeTableDetail.AdmissionType).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.type.(1), "HS.FHIR.DTL.vR4.SDA3.CodeableConcept.CodeTableTranslated")' property='DTL' action='set' />
<if condition='DTL&apos;=""'> 
<true>
<assign value='$classmethod(DTL, "Transform", source.type.(1), .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""'> 
<true>
<assign value='tmp' property='target.AdmissionType' action='set'  >
<annotation>
<![CDATA[ 
 --- FHIR4 Encounter:type is a *List*, and SDA3 HS.SDA3.Encounter:AdmissionType is *Single*. 
 --- For a list of objects mapped to a single object, when the transformation is FHIR to SDA, the transformation maps the first object from the source list to the target, and discards the others.
 --- In this case, any FHIR4 code may be used; encounter-type shows Example codes, but you may use codes from any ValueSet. 
 --- SDA does not restrict code values to a particular set.    ]]>
</annotation>
</assign></true> 
</if>
</true>
</if>
</true> 
</if> 
</true>
</if>
</true>
</if>
</transform>
}

}
