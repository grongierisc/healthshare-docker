Class Demo.Stage Extends %Persistent
{

Property EntryDate As %Date;

Property PID As %Integer;

Property Name As %String;

Property Gender As %String(DISPLAYLIST = ",Female,Male", VALUELIST = ",F,M");

Property DOB As %Date;

Property Age As %Integer;

Property Street As %String(MAXLEN = 250);

Property City As %String;

Property County As %String;

Property State As %String;

Property Positive As %Boolean;

Property Test As %Boolean;

Property Dead As %Boolean;

Property Hospitalized As %Boolean;

Property ICU As %Boolean;

Index IdxDate On EntryDate;

Storage Default
{
<Data name="StageDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>EntryDate</Value>
</Value>
<Value name="3">
<Value>PID</Value>
</Value>
<Value name="4">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>Gender</Value>
</Value>
<Value name="6">
<Value>DOB</Value>
</Value>
<Value name="7">
<Value>Age</Value>
</Value>
<Value name="8">
<Value>Street</Value>
</Value>
<Value name="9">
<Value>City</Value>
</Value>
<Value name="10">
<Value>County</Value>
</Value>
<Value name="11">
<Value>State</Value>
</Value>
<Value name="12">
<Value>Positive</Value>
</Value>
<Value name="13">
<Value>Test</Value>
</Value>
<Value name="14">
<Value>Dead</Value>
</Value>
<Value name="15">
<Value>Hospitalized</Value>
</Value>
<Value name="16">
<Value>ICU</Value>
</Value>
</Data>
<DataLocation>^Demo.StageD</DataLocation>
<DefaultData>StageDefaultData</DefaultData>
<IdLocation>^Demo.StageD</IdLocation>
<IndexLocation>^Demo.StageI</IndexLocation>
<StreamLocation>^Demo.StageS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
