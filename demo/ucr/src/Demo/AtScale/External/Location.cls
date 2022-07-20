/// data from https://www.mass.gov/info-details/archive-of-covid-19-cases-in-massachusetts imported on 2021-11-23 18:12:10
/// file: /tmp/covid/Location.csv
Class Demo.External.Location Extends %Persistent [ ClassType = persistent, Not ProcedureBlock ]
{

/// City
Property City As %String(MAXLEN = 512) [ SqlColumnNumber = 2 ];

/// County
Property County As %String(MAXLEN = 512) [ SqlColumnNumber = 3 ];

/// Latitude
Property Latitude As %Numeric(SCALE = 4) [ SqlColumnNumber = 4 ];

/// Longitude
Property Longitude As %Numeric(SCALE = 4) [ SqlColumnNumber = 5 ];

/// State
Property State As %String(MAXLEN = 512) [ SqlColumnNumber = 6 ];

/// A04
Property A04 As %Numeric(SCALE = 4) [ SqlColumnNumber = 7 ];

/// A59
Property A59 As %Numeric(SCALE = 4) [ SqlColumnNumber = 8 ];

/// A1014
Property A1014 As %Numeric(SCALE = 4) [ SqlColumnNumber = 9 ];

/// A1519
Property A1519 As %Numeric(SCALE = 4) [ SqlColumnNumber = 10 ];

/// A2029
Property A2029 As %Numeric(SCALE = 4) [ SqlColumnNumber = 11 ];

/// A3039
Property A3039 As %Numeric(SCALE = 4) [ SqlColumnNumber = 12 ];

/// A4049
Property A4049 As %Numeric(SCALE = 4) [ SqlColumnNumber = 13 ];

/// A5059
Property A5059 As %Numeric(SCALE = 4) [ SqlColumnNumber = 14 ];

/// A6069
Property A6069 As %Numeric(SCALE = 4) [ SqlColumnNumber = 15 ];

/// A7079
Property A7079 As %Numeric(SCALE = 4) [ SqlColumnNumber = 16 ];

/// A80
Property A80 As %Numeric(SCALE = 4) [ SqlColumnNumber = 17 ];

/// F
Property F As %Numeric(SCALE = 4) [ SqlColumnNumber = 18 ];

/// M
Property M As %Numeric(SCALE = 4) [ SqlColumnNumber = 19 ];

Storage Default
{
<Data name="LocationDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>City</Value>
</Value>
<Value name="3">
<Value>County</Value>
</Value>
<Value name="4">
<Value>Latitude</Value>
</Value>
<Value name="5">
<Value>Longitude</Value>
</Value>
<Value name="6">
<Value>State</Value>
</Value>
<Value name="7">
<Value>A04</Value>
</Value>
<Value name="8">
<Value>A59</Value>
</Value>
<Value name="9">
<Value>A1014</Value>
</Value>
<Value name="10">
<Value>A1519</Value>
</Value>
<Value name="11">
<Value>A2029</Value>
</Value>
<Value name="12">
<Value>A3039</Value>
</Value>
<Value name="13">
<Value>A4049</Value>
</Value>
<Value name="14">
<Value>A5059</Value>
</Value>
<Value name="15">
<Value>A6069</Value>
</Value>
<Value name="16">
<Value>A7079</Value>
</Value>
<Value name="17">
<Value>A80</Value>
</Value>
<Value name="18">
<Value>F</Value>
</Value>
<Value name="19">
<Value>M</Value>
</Value>
</Data>
<DataLocation>^Demo.External.LocationD</DataLocation>
<DefaultData>LocationDefaultData</DefaultData>
<IdLocation>^Demo.External.LocationD</IdLocation>
<IndexLocation>^Demo.External.LocationI</IndexLocation>
<StreamLocation>^Demo.External.LocationS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
