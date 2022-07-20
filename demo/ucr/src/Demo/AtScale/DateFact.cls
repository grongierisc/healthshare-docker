Class Demo.AtScale.DateFact Extends %Persistent
{

Property FullDate As %Date;

Property DayName As %String;

Property MonthYear As %Integer;

Property MonthName As %String;

Property Year As %Integer;

Index IdxDayName On DayName;

Index IdxMonthName On MonthName;

Index IdxMonthYear On MonthYear;

Index IdxYear On Year;

ClassMethod Populate() As %Status
{
    set tSC = $$$OK
    try {
        set start = $zdateh("1900-01-01",3)
        set end = $zdateh("2200-12-31",3)

        for date=start:1:end {
            set dateObj = ..%New()
            set dateObj.FullDate = date
            set dateObj.DayName = $zdate(date,12)
            set dateObj.MonthYear = $replace($piece($zdate(date,3),"-",1,2),"-","")
            set dateObj.MonthName = $piece($zdate(date,9)," ",1)
            set dateObj.Year = $piece($zdate(date,3),"-",1)
            $$$ThrowOnError(dateObj.%Save())
        }
    } catch(err) {
        set tSC = $$$ADDSC(tSC,err.AsStatus())
    }
    return tSC
}

Storage Default
{
<Data name="DateFactDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>FullDate</Value>
</Value>
<Value name="3">
<Value>DayName</Value>
</Value>
<Value name="4">
<Value>MonthYear</Value>
</Value>
<Value name="5">
<Value>MonthName</Value>
</Value>
<Value name="6">
<Value>Year</Value>
</Value>
</Data>
<DataLocation>^Demo.AtScale.DateFactD</DataLocation>
<DefaultData>DateFactDefaultData</DefaultData>
<IdLocation>^Demo.AtScale.DateFactD</IdLocation>
<IndexLocation>^Demo.AtScale.DateFactI</IndexLocation>
<StreamLocation>^Demo.AtScale.DateFactS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
