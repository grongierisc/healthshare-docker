/// Transforms vR4 CarePlan to SDA3 HS.SDA3.CarePlan
Class HS.FHIR.DTL.vR4.SDA3.CarePlan.CarePlan Extends Ens.DataTransformDTL [ DependsOn = (HS.FHIR.DTL.vR4.Model.Resource.CarePlan, HS.SDA3.CarePlan), ProcedureBlock ]
{

Parameter IGNOREMISSINGSOURCE = 0;

Parameter REPORTERRORS = 0;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HS.FHIR.DTL.vR4.Model.Resource.CarePlan' targetClass='HS.SDA3.CarePlan' create='existing' language='objectscript' >
<annotation> Transforms CarePlan (vR4) to HS.SDA3.CarePlan (SDA3) </annotation>
<if condition='source.activity&apos;=""' >
<true>
<foreach property='source.activity()' key='st' >
<if condition='(source.activity.(st).outcomeCodeableConcept.Count() &gt; 0) || (source.activity.(st).outcomeReference.Count() &gt; 0)' >
<true>
<assign value='target.Outcomes.Count()+1' property='index' action='set' />
<assign value='##class(HS.SDA3.Outcome).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.activity.(st), "HS.FHIR.DTL.vR4.SDA3.CarePlan.activity.Outcome")' property='DTL' action='set' />
<if condition='DTL&apos;=""' >
<true>
<assign value='$classmethod(DTL, "Transform", source.activity.(st), .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""' >
<true>
<assign value='tmp' property='target.Outcomes' action='set' key='index' />
</true>
</if>
</true>
</if>
</true>
</if>
</foreach>
</true>
</if>
<if condition='source.activity&apos;=""' >
<true>
<foreach property='source.activity()' key='st' >
<if condition='source.activity.(st).detail &apos;= ""' >
<true>
<assign value='target.Interventions.Count()+1' property='index' action='set' />
<assign value='##class(HS.SDA3.Intervention).%New()' property='tmp' action='set' />
<assign value='aux("transformer").GetDTL(source.activity.(st), "HS.FHIR.DTL.vR4.SDA3.CarePlan.activity.Intervention")' property='DTL' action='set' />
<if condition='DTL&apos;=""' >
<true>
<assign value='$classmethod(DTL, "Transform", source.activity.(st), .tmp, .aux)' property='status' action='set' />
<if condition='tmp&apos;=""' >
<true>
<assign value='tmp' property='target.Interventions' action='set' key='index' />
</true>
</if>
</true>
</if>
</true>
</if>
</foreach>
</true>
</if>
<if condition='source.addresses&apos;=""' >
<true>
<foreach property='source.addresses()' key='st' >
<assign value='""' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.addresses.GetAt(st), .value, .aux)' property='value' action='set' />
<assign value='target.HealthConcernIds.Count()+1' property='index' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.HealthConcernIds' action='set' key='index' >
<annotation> 
 --- SDA3 HS.SDA3.CarePlan:HealthConcernIds is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
</foreach>
</true>
</if>
<if condition='source.careTeam&apos;=""' >
<true>
<if condition='source.careTeam.Count()&gt;0' >
<true>
<assign value='target' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.careTeam.GetAt(1), .value, .aux)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target' action='set' >
<annotation> 
 --- FHIR4 CarePlan:careTeam is a *List*, and SDA3 HS.SDA3.CarePlan is *Single*. 
 --- For a list of objects mapped to a single object, when the transformation is FHIR to SDA, the transformation maps the first object from the source list to the target, and discards the others.   </annotation>
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
 --- SDA3 HS.SDA3.CarePlan:EncounterNumber is type %String with a maximum string length of *220*.    </annotation>
</assign>
</true>
</if>
</true>
</if>
<if condition='source.goal&apos;=""' >
<true>
<foreach property='source.goal()' key='st' >
<assign value='""' property='value' action='set' />
<assign value='aux("transformer").TransformReference(source.goal.GetAt(st), .value, .aux)' property='value' action='set' />
<assign value='target.GoalIds.Count()+1' property='index' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.GoalIds' action='set' key='index' >
<annotation> 
 --- SDA3 HS.SDA3.CarePlan:GoalIds is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
</foreach>
</true>
</if>
<assign value='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","request-status|4.0.1","HS.SDA3.CarePlan:Status",source.status)' property='value' action='set' />
<if condition='value&apos;=""' >
<true>
<assign value='value' property='target.Status' action='set' >
<annotation> Currently, possible values are: &quot;A&quot; - Active, &quot;I&quot; - Inactive
 --- This mapping entry seeks a lookup table entry that can match a source value with a target value for this field. If the mapping cannot find the lookup table, or cannot find a matching entry in the lookup table, and it has a non-empty Default Value defined, it places its Default Value into the target field. Otherwise, the target receive no value from this mapping. 
 --- SDA3 HS.SDA3.CarePlan:Status is type %String and it has no MAXLEN value set, so its maximum string length is *50*.    </annotation>
</assign>
</true>
</if>
<if condition='##class(HS.FHIR.DTL.Util.Lookup).Code("vR4","SDA3","request-status|4.0.1","HS.SDA3.CarePlan:Status",source.status) = ""' >
<true>
<if condition='source.status&apos;=""' >
<true>
<assign value='source.status' property='target.Status' action='set' >
<annotation> Currently, possible values are: &quot;A&quot; - Active, &quot;I&quot; - Inactive
 --- SDA3 HS.SDA3.CarePlan:Status is type %String and it has no MAXLEN value set, so its maximum string length is *50*. 
 --- This mapping operates only when a table lookup to match an incoming FHIR code value with an appropriate SDA Code value fails. In that case, this mapping maps the source FHIR code value (unchanged) into an SDA CodeTableDetail Code value, and if the FHIR code was inside a Coding or CodeableConcept, it maps the FHIR display, system, and version values into appropriate SDA CodeTableDetail fields.    </annotation>
</assign>
</true>
</if>
</true>
</if>
<assign value='"From Synthea"' property='target.Type.Description' action='set' />
</transform>
}

}
