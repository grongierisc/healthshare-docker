/// this class uses publicly available covid related data from Massachusetts' goverment.
/// the data was extracted from the main XSLX into individual CSVs prior to importing.<br/>
/// the goal is to use the statistical information to help generate meaningful patient information
/// for analytics.
/// for more visit: <a href="https://www.mass.gov/info-details/archive-of-covid-19-cases-in-massachusetts">https://www.mass.gov/info-details/archive-of-covid-19-cases-in-massachusetts</a>
Class Demo.Importer
{

/// - run ##class(Demo.Importer).Generate(path) for class generation and data import<br/>
/// - run ##class(Demo.Importer).Generate(path,0) for class generation only<br/>
ClassMethod Generate(path As %String = "/irisdev/app/shared/installer/", import As %Boolean = 1, Output sc As %Status) As %String
{
    set sc = $$$OK
    set message = ""
    try {
        set file = path_"covid.tar.gz"
        if '##class(%File).Exists(file) {
            set sc = $$$ERROR($$$GeneralError,"covid.tar.gz file does not existing in "_path)
            quit
        }
        $$$ThrowOnError(..Prepare(.path))
        $$$ThrowOnError(..ReadDataDocumentation(path,.classes))
        $$$ThrowOnError(..ProfileCSV(.classes))        
        $$$ThrowOnError(..Delete())
        $$$ThrowOnError(..Location(path,.classes))
        $$$ThrowOnError(..GenerateClasses(.classes))
        if (import) $$$ThrowOnError(..Import(path,.classes))
        $$$ThrowOnError(..Clean())
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    if $$$ISERR(sc) {
        set message = $System.Status.GetErrorText(sc)
    } else {
        set message = "[covid data uploaded]"
    }
    return message
}

ClassMethod Prepare(ByRef path As %String = "/shared/installer/") As %Status
{
    set sc = $$$OK
    try {
        do $zf(-1,"rm -rf /tmp/covid")
        do $zf(-1,"cp "_path_"covid.tar.gz /tmp/.")
        do $zf(-1,"cd /tmp; tar zxf /tmp/covid.tar.gz")
        do $zf(-1,"find /tmp/covid/. -name ""._*"" -delete")
        set path = "/tmp/covid/"
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod Clean() As %Status
{
    set sc = $$$OK
    try {
        do $zf(-1,"rm -rf /tmp/covid*")
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// - run ##class(Demo.Importer).Delete() to remove classes and data
ClassMethod Delete() As %Status
{
    set sc = $$$OK
    try {
        set package = "Demo.External"
        &SQL(DECLARE X CURSOR FOR 
            SELECT DataLocation, IndexLocation, StreamLocation
            INTO :gblData, :gblIdx, :gblStream
            FROM "%Dictionary".StorageDefinition 
            WHERE parent %STARTSWITH :package)
        &SQL(OPEN X)
        for {
            &SQL(FETCH X)
            quit:SQLCODE
            kill @gblData
            kill @gblIdx
            kill @gblStream
        }
        &SQL(CLOSE X)
        &SQL(DELETE FROM "%Dictionary".ClassDefinition WHERE Name %STARTSWITH :package)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// - run ##class(Demo.Importer).Import(path) to load data, note that the classes have to be generated prior to this step
ClassMethod Import(path As %String = "/tmp/covid/", ByRef classes) As %Status
{
    set sc = $$$OK
    try {
        if '$data(classes) {
            $$$ThrowOnError(..ReadDataDocumentation(path,.classes))
            $$$ThrowOnError(..ProfileCSV(.classes))
            $$$ThrowOnError(..Delete())
            $$$ThrowOnError(..Location(path,.classes))
        }
        set class = ""
        for { 
            set class = $order(classes(class))
            quit:class=""
            set prop = ""
            set classname = "Demo.External."_class
            set fileName = classes(class,"file")
            set stream = ##class(%Stream.FileCharacter).%New()
            set sc = stream.LinkToFile(fileName)
            set ctrl = 0
            while 'stream.AtEnd { // map column positions for each file
                set line = stream.ReadLine()
                continue:$increment(ctrl)=1
                continue:$zstrip(line,"*CWP")=""
                set line = $$CSVtoList^%occLibrary(line)
                set obj = $classmethod(classname,"%New")
                set prop = ""
                for { 
                    set prop = $order(classes(class,"props",prop),1,pos)
                    quit:prop=""                
                    set value = $listget(line,pos)
                    set idx = $order(classes(class,"props",prop,"type",""),-1)
                    set type = $order(classes(class,"props",prop,"type",idx,""))
                    if (type="date") {
                        set value = $zstrip(value,"*WC")
                        set value = $piece(value,"/",1,2)_"/"_20_$piece(value,"/",3)
                        set $property(obj,classes(class,"props",prop,"name")) = $zdateh(value,1,,,,,,,"")
                    } elseif (type="number") {
                        set value = $zstrip($replace(value,",",""),"*WC")
                        if ($isvalidnum(value)) {
                            set $property(obj,classes(class,"props",prop,"name")) = +value
                        }
                    } else {
                        set $property(obj,classes(class,"props",prop,"name")) = value
                    }
                }    
                $$$ThrowOnError(obj.%Save())
                kill obj
            } 
        }

    } catch (err) { 
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// internal method to read Data Documentation.csv and map table and columns
ClassMethod ReadDataDocumentation(path As %String = "/tmp/covid/", Output classes) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set stream = ##class(%Stream.FileCharacter).%New()
        set stream.LineTerminator = $char(13)
        set sc = stream.LinkToFile(path_"Data Documentation.csv")
        set ignore = ..Ignore()
        while 'stream.AtEnd {
            set line = stream.ReadLine()
            continue:$increment(ctrl)=1
            continue:line=""
            set line = $$CSVtoList^%occLibrary(line)
            set fileName = $zstrip($listget(line,1),"*C")
            set className = $zstrip(fileName,"*WP")
            if (className'="") {
                set activeClass = className
                continue:$listfind(ignore,activeClass)
                set frequency = $zstrip($listget(line,5),"*CWP")
                set note = $listget(line,7)
                set classes(activeClass,"file") = path_fileName_".csv"
                set classes(activeClass,"frequency") = frequency
                set classes(activeClass,"note") = note
            }
            continue:$listfind(ignore,activeClass)
            set propertyName = $zstrip($listget(line,3),"*CWP")
            continue:propertyName=""
            set propertyIndex = $zconvert(propertyName,"L")
            set propertyCaption = $zstrip($listget(line,3),"*C")
            set propertyDesc = $listget(line,6)
            
            set classes(activeClass,"props",propertyIndex) = ""
            set classes(activeClass,"props",propertyIndex,"name") = propertyName
            set classes(activeClass,"props",propertyIndex,"caption") = propertyCaption
            set classes(activeClass,"props",propertyIndex,"description") = propertyDesc
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// age distribution manually entered based on https://censusreporter.org
ClassMethod Location(path As %String = "/tmp/covid/", ByRef classes) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set activeClass = "Location"
        set classes(activeClass) = ""
        set classes(activeClass,"file") = path_"Location.csv"
        
        set propertyIndex = "city"
        set classes(activeClass,"props",propertyIndex) = $increment(idx)
        set classes(activeClass,"props",propertyIndex,"name") = "City"
        set classes(activeClass,"props",propertyIndex,"caption") = "City"
        set classes(activeClass,"props",propertyIndex,"description") = "City"
        set classes(activeClass,"props",propertyIndex,"type",1,"string") = ""

        set propertyIndex = "county"
        set classes(activeClass,"props",propertyIndex) = $increment(idx)
        set classes(activeClass,"props",propertyIndex,"name") = "County"
        set classes(activeClass,"props",propertyIndex,"caption") = "County"
        set classes(activeClass,"props",propertyIndex,"description") = "County"
        set classes(activeClass,"props",propertyIndex,"type",1,"string") = ""

        set propertyIndex = "lat"
        set classes(activeClass,"props",propertyIndex) = $increment(idx)
        set classes(activeClass,"props",propertyIndex,"name") = "Latitude"
        set classes(activeClass,"props",propertyIndex,"caption") = "Latitude"
        set classes(activeClass,"props",propertyIndex,"description") = "Latitude"
        set classes(activeClass,"props",propertyIndex,"type",1,"number") = ""

        set propertyIndex = "long"
        set classes(activeClass,"props",propertyIndex) = $increment(idx)
        set classes(activeClass,"props",propertyIndex,"name") = "Longitude"
        set classes(activeClass,"props",propertyIndex,"caption") = "Longitude"
        set classes(activeClass,"props",propertyIndex,"description") = "Longitude"
        set classes(activeClass,"props",propertyIndex,"type",1,"number") = ""

        set propertyIndex = "state"
        set classes(activeClass,"props",propertyIndex) = $increment(idx)
        set classes(activeClass,"props",propertyIndex,"name") = "State"
        set classes(activeClass,"props",propertyIndex,"caption") = "State"
        set classes(activeClass,"props",propertyIndex,"description") = "State"
        set classes(activeClass,"props",propertyIndex,"type",1,"string") = ""

        set cols = $listbuild("A04","A59","A1014","A1519","A2029","A3039","A4049","A5059","A6069","A7079","A80","F","M")
        set ptr = 0
        while $listnext(cols,ptr,col) {
            set classes(activeClass,"props",col) = $increment(idx)
            set classes(activeClass,"props",col,"name") = col
            set classes(activeClass,"props",col,"caption") = col
            set classes(activeClass,"props",col,"description") = col
            set classes(activeClass,"props",col,"type",1,"number") = ""
        }

    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// internal method to profile each csv assigning column names and datatypes 
ClassMethod ProfileCSV(ByRef classes) As %Status [ Internal ]
{
    set sc = $$$OK
    try {

        set class = ""
        for { // loop through files
            set class = $order(classes(class))
            quit:class=""
            set fileName = classes(class,"file")
            set stream = ##class(%Stream.FileCharacter).%New()
            set sc = stream.LinkToFile(fileName)
            
            while 'stream.AtEnd { // map column positions for each file
                set line = stream.ReadLine()
                set line = $$CSVtoList^%occLibrary(line)
                set ptr = 0
                set pos = 0
                while $listnext(line,ptr,col) {               
                    set pos = $increment(pos)     
                    set colName = $zstrip(col,"*CWP")
                    set colIndex = $zconvert(colName,"L")
                    continue:colName=""
                    set classes(class,"props",colIndex) = pos
                    set classes(class,"props",colIndex,"name") = colName
                }
                quit
            }

            set prop = ""
            for { // remove columns not found in the csv
                set prop = $order(classes(class,"props",prop),1,found)
                quit:prop=""
                if (found="") {
                    kill classes(class,"props",prop)
                }
            }

            kill number,date,string,type
            set (ctrl) = 0
            do stream.Rewind()
            while 'stream.AtEnd { // profile data type
                quit:$increment(ctrl)>201
                set line = stream.ReadLine()
                continue:ctrl=1
                set line = $$CSVtoList^%occLibrary(line)

                set (prop,pos) = ""
                for { // evaluate every column
                    set prop = $order(classes(class,"props",prop),1,pos)
                    quit:prop=""
                    set data = $listget(line,pos)
                    if ($isvalidnum($zstrip($replace(data,",",""),"*WC"))) { // try to parse number
                        set number = $increment(type(prop,"number"))
                        set classes(class,"props",prop,"type",number,"number") = ""
                        set last = $order(classes(class,"props",prop,"type",number),-1)
                        kill:last'="" classes(class,"props",prop,"type",last)
                    } elseif (($zdateh(data,1,,,,,,,0))'=0) { // try to parse date
                        set date = $increment(type(prop,"date"))
                        set classes(class,"props",prop,"type",date,"date") = ""
                        set last = $order(classes(class,"props",prop,"type",date),-1)
                        kill:last'="" classes(class,"props",prop,"type",last)
                    } else { // else assume string
                        set string = $increment(type(prop,"string"))
                        set classes(class,"props",prop,"type",string,"string") = "" 
                        set last = $order(classes(class,"props",prop,"type",string),-1)
                        kill:last'="" classes(class,"props",prop,"type",last)
                    }
                }
            }
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// internal method to generate the classes and properties
ClassMethod GenerateClasses(ByRef classes) As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        set class = ""
        for { 
            set class = $order(classes(class))
            quit:class=""
            set prop = ""
            set cls = ##class(%Dictionary.ClassDefinition).%New()
            set classname = "Demo.External."_class
            set cls.Name = classname
            set cls.Description = "data from https://www.mass.gov/info-details/archive-of-covid-19-cases-in-massachusetts imported on "_$zdatetime($now(),3)
                _$char(13,10)_"file: "_classes(class,"file")
                _$select($get(classes(class,"frequency"))'="":"frequency: "_$char(13,10)_classes(class,"frequency"),1:"")
                _$select($get(classes(class,"note"))'="":"note: "_$char(13,10)_classes(class,"note"),1:"")
            set cls.ClassType = "persistent"
            set cls.Super = "%Persistent"
            $$$ThrowOnError(cls.%Save())
            for { 
                set prop = $order(classes(class,"props",prop),1,pos)
                quit:prop=""                
                set property = ##class(%Dictionary.PropertyDefinition).%New(classname)
                set property.parent = classname
                set property.Name = classes(class,"props",prop,"name")
                set property.Description = $get(classes(class,"props",prop,"description"))
                set property.SequenceNumber = pos+1
                set property.SqlColumnNumber = pos+1
                set idx = $order(classes(class,"props",prop,"type",""),-1)
                set type = $order(classes(class,"props",prop,"type",idx,""))
                set property.Type = $case(type,"number":"%Numeric","date":"%Date",:"%String")
                if (type="string") {
                    do property.Parameters.SetAt(512,"MAXLEN")
                } elseif (type="number") {
                    do property.Parameters.SetAt(4,"SCALE")
                }
                $$$ThrowOnError(property.%Save())
                if type="date" {
                    set index = ##class(%Dictionary.IndexDefinition).%New(classname)
                    set index.parent = classname
                    set index.Name = "Idx"_classes(class,"props",prop,"name")
                    set index.Properties = classes(class,"props",prop,"name")
                    $$$ThrowOnError(index.%Save())
                }
            }
            set null = $System.Device.GetNullDevice()
            open null:"WSN" use null set sc = $System.OBJ.Compile(classname,"cku") close null
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod Ignore() As %String [ CodeMode = expression ]
{
$listbuild(
        "AgeMeansLast2Weeks"
        ,"CasesByDateProbable"
        ,"Clusters"
        ,"CountsbySpecimenDateSero"
        ,"CTCWorkforce"
        ,"ContactTracing"
        ,"HigherEdCasesandTests"
        ,"IsolationandQuarantine"
        ,"LTCFacilities"
        ,"SexLast2Weeks"
        ,"WeeklyStatewide"
        ,"WeeklyTownReference"
    )
}

}
