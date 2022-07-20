Class Demo.HL7Creator
{

/// Total of concurrent processes for some of the tasks
Parameter Workers = 10;

/// Allow bringing all the data to current date
Parameter DateShift = 1;

/// kick the hl7 creation
ClassMethod CreateAll(offset As %Integer = 0, workersEnabled As %Boolean = 1) As %Status
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        if $get(^IRISTemp("Loader")) {
            set sc = $$$ERROR($$$GeneralError,"code already running on job "_^IRISTemp("Loader"))
            quit
        }
        do DISABLE^%NOJRN
        set start = ##class(Demo.Loader).GetStartTime()
        kill ^IRISTemp("CovidDemo"),^IRISTemp("Monitor"),^IRISTemp("Monitor.Snap")
        
        set ^IRISTemp("Loader") = $job
        set ^IRISTemp("CovidDemo","usingWorkers") = $select(workersEnabled=1:..#Workers,1:1)
        set ^IRISTemp("CovidDemo","workers") = ..#Workers
        set ^IRISTemp("CovidDemo","workersError") = $$$OK
        set message = $$$FormatText("(date shift is %1)",$case(..#DateShift,1:"ON",:"OFF"))

        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[1/3] preparing codesets"

        if '$get(%DemoMonitor) {
            write #,$$$FormatText("[starting] using %1 worker(s) to generate HL7 %2",^IRISTemp("CovidDemo","usingWorkers"),message),!
            write "------------------------------------------------------------------",!
        }

        set startCodeSet = ##class(Demo.Loader).GetStartTime()
        $$$ThrowOnError(..PrepareCodeset())

        set maxDate = $order(^Demo.StageI("IdxDate",""),-1)
        set date = $order(^Demo.StageI("IdxDate",""))-1
        if offset'="*" set date = maxDate-offset-1

        set ^IRISTemp("CovidDemo","dateShift") = 0
        set:..#DateShift ^IRISTemp("CovidDemo","dateShift") = +$horolog-maxDate
        
        &SQL(SELECT COUNT(ID) INTO :totalForPeriod FROM Demo.Stage WHERE EntryDate BETWEEN :date AND :maxDate)

        if (totalForPeriod>0) {
            for i=1:1:..#Workers {
                set port = 7000+i
                job ##class(Demo.HL7Creator).SuperSender(port)
            }
        }
        $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
        hang 5
        set codeSetTime = ##class(Demo.Loader).GetExecTime(startCodeSet)

        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[2/3] using [[;white;]%1] worker(s) to generate HL7 for [[;white;]%2] entries %3",^IRISTemp("CovidDemo","usingWorkers"),totalForPeriod,message)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"

        if '$get(%DemoMonitor) {
            write "[1/3] preparing codesets",!
            write $$$FormatText("[2/3] using %1 worker(s) to generate HL7 for %2 entries",^IRISTemp("CovidDemo","usingWorkers"),totalForPeriod),!
            write "------------------------------------------------------------------",!
        }

        set startGenerationTime = ##class(Demo.Loader).GetStartTime()
        for {
            set date = $order(^Demo.StageI("IdxDate",date))
            quit:date=""
            set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("generating hl7 for [[;white;]%1]",$zdate(date,3))
            write:'$get(%DemoMonitor) $$$FormatText("[2/3] generating hl7 for %1",$zdate(date,3)),!
            
            set startTimeDate = ##class(Demo.Loader).GetStartTime()
            &SQL(SELECT COUNT(ID) INTO :totalForDate FROM Demo.Stage WHERE EntryDate = :date)
            set totalSoFar = 0
            set id = ""
            set newCycle = 1
            for {
                set id = $order(^Demo.StageI("IdxDate",date,id))
                quit:id=""
                if (newCycle) set ^IRISTemp("Monitor") = ^IRISTemp("Monitor")+2
                set newCycle = 0
                set total = $increment(total)

                set timeSoFar = ##class(Demo.Loader).GetExecTime(startTimeDate,2)
                set timeTotalSoFar = ##class(Demo.Loader).GetExecTime(start,2)
                set estimatedTime = (totalForPeriod-total)*timeTotalSoFar/total
                if (estimatedTime>0) {
                    set estimatedTime = ##class(Demo.Loader).FormatTime(estimatedTime)
                } else {
                    set estimatedTime = "[calculation]"
                }

                set ^IRISTemp("Monitor",^IRISTemp("Monitor")-2) = $$$FormatText("generating hl7 for [[;white;]%1] (entry [[;white;]%2] of [[;white;]%3] - exec.: %4)",$zdate(date,3),$increment(totalSoFar),totalForDate,##class(Demo.Loader).GetExecTime(startTimeDate))
                set ^IRISTemp("Monitor",^IRISTemp("Monitor")-1) = "------------------------------------------------------------------"
                set ^IRISTemp("Monitor",^IRISTemp("Monitor")) = $$$FormatText("total entry [[;white;]%1] of [[;white;]%2] ([[;white;]%3%] - estimated time: [[;white;]%4])",total,totalForPeriod,$fnumber((total/totalForPeriod*100),,2),estimatedTime)
                
                $$$ThrowOnError(..ProcessPatient(id))
                $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
            }
            set ^IRISTemp("Monitor") = ^IRISTemp("Monitor")-2
            $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
        }
        set generationTime = ##class(Demo.Loader).GetExecTime(startGenerationTime)

        if '$get(%DemoMonitor) {
            write "[3/3] awaiting TCP queue",!
        }
        set startQueueTime = ##class(Demo.Loader).GetStartTime()
        set ^IRISTemp("Monitor") = $increment(^IRISTemp("Monitor"))
        set ^IRISTemp("Monitor") = $increment(^IRISTemp("Monitor"))
        while ($data(^IRISTemp("CovidDemo","executing"))=11) {
            set idx = ""
            set queue = 0
            for {
                set idx = $order(^IRISTemp("CovidDemo","executing",idx))
                quit:idx=""
                set queue = $increment(queue)
            }
            set ^IRISTemp("Monitor",^IRISTemp("Monitor")-1) = "------------------------------------------------------------------"
            set ^IRISTemp("Monitor",^IRISTemp("Monitor")) = $$$FormatText("[3/3] awaiting TCP queue: [[;white;]%1]",queue)
        }
        set queueTime = ##class(Demo.Loader).GetExecTime(startQueueTime)

        set lastDate = $order(^Demo.StageI("IdxDate",""),-1)
        set ^IRISTemp("Monitor",(^IRISTemp("Monitor")-1)) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",^IRISTemp("Monitor")) = $$$FormatText("[[[;darkgreen;]completed]] generation done for offset %1 starting %2 %3",offset,$zdate(lastDate,3),message)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[1/3] codeset generation time: "_codeSetTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[2/3] hl7 generation time: "_generationTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[3/3] awaiting TCP queue time: "_queueTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "total execution time: "_##class(Demo.Loader).GetExecTime(start)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) =  "EOF"
        kill ^IRISTemp("CovidDemo")
        kill ^IRISTemp("Loader")

        if '$get(%DemoMonitor) {
            write "------------------------------------------------------------------",!
            write $$$FormatText("[completed] generation done for offset %1 starting %2 %3",offset,$zdate(lastDate,3),message),!
            write "------------------------------------------------------------------",!
            write "[1/3] codeset generation time: "_codeSetTime,!
            write "[2/3] hl7 generation time: "_generationTime,!
            write "[3/3] awaiting TCP queue time: "_queueTime,!
            write "------------------------------------------------------------------",!
            write "total execution time: "_##class(Demo.Loader).GetExecTime(start),!,!
        }
        kill %DemoMonitor
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[[;darkred;]ERROR]: "_$System.Status.GetErrorText(sc)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[[[;darkred;]aborted]]"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "execution time: "_##class(Demo.Loader).GetExecTime(start)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "EOF"
        kill ^IRISTemp("CovidDemo")
        kill ^IRISTemp("Loader")
        write:'$get(%DemoMonitor) !,$System.Status.GetErrorText(sc),!
        kill %DemoMonitor
    }
    return sc
}

/// prepara codeset based on HSAA_COVID19.ValueSets
ClassMethod PrepareCodeset() As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set ^IRISTemp("CovidDemo","codeset") = ""
        &SQL(DECLARE PrepareCodeset CURSOR FOR 
            SELECT ID, Category, CodingStandard, Code, "Description"
            INTO :id, :category, :coding, :code, :desc
            FROM HSAA_COVID19.ValueSets
            WHERE CodingStandard IN ('I10','SCT'))

        &SQL(OPEN PrepareCodeset)
        for {
            &SQL(FETCH PrepareCodeset)
            quit:SQLCODE

            if (category="COVID-19-Like Illness Value Set") {
                set ^IRISTemp("CovidDemo","covid-like") = $increment(^IRISTemp("CovidDemo","covid-like"))
                set ^IRISTemp("CovidDemo","covid-like",id) = $listbuild(coding,code,desc)
            } elseif ((category)'[("Vital Signs")) {
                set ^IRISTemp("CovidDemo","codeset") = $increment(^IRISTemp("CovidDemo","codeset"))
                set ^IRISTemp("CovidDemo","codeset",id) = $listbuild(coding,code,desc)
            }
        }
        &SQL(CLOSE PrepareCodeset)
    } catch (err) {
        set sc = err.AsStatus()
    }
    return sc
}

/// generate hl7 for a given patient 
ClassMethod ProcessPatient(id As %Integer) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set patientData = $get(^Demo.StageD(id))
        
        set patientData("extra","[facility]") = $listget(patientData,10)_" Hospital"
        set patientName = $listget(patientData,4)
        set patientData("extra","[street]") = $listget(patientData,8)
        set patientData("extra","[city]") = $listget(patientData,9)
        set patientData("extra","[state]") = $listget(patientData,11)
        set patientData("extra","[first-name]") = $piece(patientName,",",2)
        set patientData("extra","[last-name]") = $piece(patientName,",",1)
        set patientData("extra","[sex]") = $listget(patientData,5)
        set patientData("extra","[dob]") = $zstrip($zdate($listget(patientData,6)+$get(^IRISTemp("CovidDemo","dateShift")),3),"*p")
        set code = $zconvert($extract($listget(patientData,10),1,2)_$extract($listget(patientData,10),$length($listget(patientData,10))),"U")
        set patientData("extra","[mrn]") = code_($listget(patientData,3)+10000000000)
        set patientData("extra","[episode]") = code_(id+10000000000)
        set patientData("extra","[episode-type]") = $case($listget(patientData,15),1:"I",:$case($random(2),0:"O",:"E"))
        set patientData("extra","[test]") = $listget(patientData,13)
        set patientData("extra","[positive]") = $listget(patientData,12)
        set patientData("extra","[hospitalized]") = $listget(patientData,15)
        set patientData("extra","[icu]") = $listget(patientData,16)

        set startDate = $listget(patientData,2)-60
        set startTime = $random(86399)+1
        set endDate = startDate
        set endTime = $random(86399)+1
        if (endTime<startTime) {
            set endDate = endDate+1
        }
        if (patientData("extra","[hospitalized]")) {            
            set endDate = startDate+$random(5)+15
            if (patientData("extra","[icu]")) {   
                set endDate = startDate+$random(10)+20       
            }
        }
        set patientData("extra","[discharge-time]") = ""
        set:(endDate<+$horolog) patientData("extra","[discharge-time]") = $zstrip($zdate(endDate+$get(^IRISTemp("CovidDemo","dateShift")),3)_$ztime(endTime,1),"*p")

        set patientData("extra","[exec-time]") = $zstrip($zdate(startDate+$get(^IRISTemp("CovidDemo","dateShift")),3)_$ztime(startTime,1),"*p") 
        set patientData("extra","[dead]") = $case($listget(patientData,14),1:"Y",:"N")
        set patientData("extra","[doc-first-name]") = "Dr "_$listget(patientData,10)
        set patientData("extra","[doc-last-name]") = $char($random(25)+66)
        set patientData("extra","[doc-license]") = code_"-"_($ascii(patientData("extra","[doc-last-name]"))-64)

        // the less the number then greater the chance
        set chanceOfComorbidity = 4
        set chanceOfComorbidity = chanceOfComorbidity-patientData("extra","[hospitalized]")
        set chanceOfComorbidity = chanceOfComorbidity-patientData("extra","[icu]")
        set chanceOfComorbidity = chanceOfComorbidity-patientData("extra","[dead]")
        set patientData("extra","[comorbidity]") = ##class(Demo.Analyzer).SpecialBoolean(chanceOfComorbidity)

        if (patientData("extra","[hospitalized]")) {
            set hasSymptoms = 1
        } else {
            set hasSymptoms = ##class(Demo.Analyzer).SpecialBoolean(2)
        }
        set patientData("extra","[has-symptoms]") = hasSymptoms

        $$$ThrowOnError(..GenerateHL7(.patientData,id))
    } catch (err) {
        set sc = err.AsStatus()
    }
    return sc
}

/// generate the hl7 messages
ClassMethod GenerateHL7(ByRef patientData As %String, id As %Integer) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set placerID = $zstrip($ztimestamp,"*P")
        set fillerID = $zstrip($ztimestamp,"*P")
        set adt = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ADT").Data
        while 'adt.AtEnd {
            set seg = adt.ReadLine()
            set idx = ""
            for {
                set idx = $order(patientData("extra",idx),1,data)
                quit:idx=""
                set seg = $replace(seg,idx,data)
            }
            set msg($increment(msg)) = seg
        }

        // generate positive diagnosis
        if patientData("extra","[positive]") { 
            set covid(0) = $listbuild("SCT","840539006","Disease caused by 2019 novel coronavirus (disorder)")
            set covid(1) = $listbuild("SCT","840544004","Suspected disease caused by 2019 novel coronavirus (situation)")

            set dg1 = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||DG1").Data
            while 'dg1.AtEnd {
                set seg = dg1.ReadLine()
                set idx = ""
                for {
                    set idx = $order(patientData("extra",idx),1,data)
                    quit:idx=""
                    set seg = $replace(seg,idx,data)
                }
                set type = $random(2)
                set seg = $replace(seg,"[dia-coding]",$listget(covid(type),1))
                set seg = $replace(seg,"[dia-code]",$listget(covid(type),2))
                set seg = $replace(seg,"[dia-desc]",$listget(covid(type),3))
            }
            set msg($increment(msg)) = seg
        }

        // generate icu (completely not sure of this part)
        if patientData("extra","[icu]") {
            set coding = "CPT"
            
            set item(0) = $listbuild("31500","Intubation, endotracheal, emergency procedure")
            set item(1) = $listbuild("94662","Continuous negative pressure ventilation (CNP), initiation and management")
            set ventData = item($random(2))

            set pr1 = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||PR1").Data
            while 'pr1.AtEnd {
                set seg = pr1.ReadLine()
                set idx = ""
                for {
                    set idx = $order(patientData("extra",idx),1,data)
                    quit:idx=""
                    set seg = $replace(seg,idx,data)
                }

                set seg = $replace(seg,"[procedure-coding]",coding)
                set seg = $replace(seg,"[procedure-code]",$listget(ventData,1))
                set seg = $replace(seg,"[procedure-desc]",$listget(ventData,2))

                set msg($increment(msg)) = seg
            }
        }

        // generate symptoms
        if patientData("extra","[has-symptoms]") {
            
            set adt = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ADT").Data
            while 'adt.AtEnd {
                set seg = adt.ReadLine()
                set idx = ""
                for {
                    set idx = $order(patientData("extra",idx),1,data)
                    quit:idx=""
                    set seg = $replace(seg,idx,data)
                }
                set msg($increment(msg)) = seg
            }

            set symptom(0) = $listbuild("SCT","276885007","Body temperature",(98+$random(10)))
            set symptom(1) = $listbuild("SCT","431314004","Peripheral oxygen saturation",(80+$random(20)))
            set symptom(2) = $listbuild("SCT","86290005","Respiratory rate",(12+$random(20)))
            set symptomType = $random(3)

            set obx = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||OBX").Data
            while 'obx.AtEnd {
                set seg = obx.ReadLine()
                set idx = ""
                for {
                    set idx = $order(patientData("extra",idx),1,data)
                    quit:idx=""
                    set seg = $replace(seg,idx,data)
                }
                set seg = $replace(seg,"[obs-coding]",$listget(symptom(symptomType),1))
                set seg = $replace(seg,"[obs-code]",$listget(symptom(symptomType),2))
                set seg = $replace(seg,"[obs-desc]",$listget(symptom(symptomType),3))
                set seg = $replace(seg,"[obs-value]",$listget(symptom(symptomType),4))
            }
            set msg($increment(msg)) = seg
        }

        // generate cormobidity/risk factor data
        if patientData("extra","[comorbidity]") {
            set ppr = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||PPR").Data
            while 'ppr.AtEnd {
                set seg = ppr.ReadLine()
                set idx = ""
                for {
                    set idx = $order(patientData("extra",idx),1,data)
                    quit:idx=""
                    set seg = $replace(seg,idx,data)
                }
                set msg($increment(msg)) = seg
            }

            set categories = $random(5)+1
            set numComorbidities = $random($random(5)+1)+1
            for i=1:1:numComorbidities {
                do {
                    set itemToUse = $random(^IRISTemp("CovidDemo","codeset"))+1
                } while ($data(itemUser(itemToUse)))
                
                set item = ""
                set ctrlItem = 0
                for {
                    set item = $order(^IRISTemp("CovidDemo","codeset",item),1,itemData)
                    quit:item=""
                    quit:($increment(ctrlItem)>=itemToUse)
                }

                set prb = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||PRB").Data
                while 'prb.AtEnd {
                    set seg = prb.ReadLine()
                    set idx = ""
                    for {
                        set idx = $order(patientData("extra",idx),1,data)
                        quit:idx=""
                        set seg = $replace(seg,idx,data)
                    }
                    set seg = $replace(seg,"[dia-coding]",$listget(itemData,1))
                    set seg = $replace(seg,"[dia-code]",$listget(itemData,2))
                    set seg = $replace(seg,"[dia-desc]",$listget(itemData,3))
                }
                set msg($increment(msg)) = seg
            } 
        }

        // generate test
        set oru = ##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ORU").Data
        while 'oru.AtEnd {
            set seg = oru.ReadLine()
            set idx = ""
            for {
                set idx = $order(patientData("extra",idx),1,data)
                quit:idx=""
                set seg = $replace(seg,idx,data)
            }

            set seg = $replace(seg,"[placer-id]",placerID_"A")
            set seg = $replace(seg,"[filler-id]",fillerID_"A")

            set seg = $replace(seg,"[test-coding]","LN")
            set seg = $replace(seg,"[test-code]","94531-1")
            set seg = $replace(seg,"[test-desc]","SARS-CoV-2 (COVID-19) RNA panel")

            set seg = $replace(seg,"[result-coding]","LN")
            set seg = $replace(seg,"[result-code]","94500-6")
            set seg = $replace(seg,"[result-desc]","overall SARS-CoV-2 result")
            set seg = $replace(seg,"[result-value]",$case(patientData("extra","[positive]"),1:"Positive",:"Negative"))

            set msg($increment(msg)) = seg
        }
        
        set choice = (..ConvertStringToNumber(patientData("extra","[mrn]"))#10)+1
        set port = 7000+choice
        merge ^IRISTemp("CovidDemo","executing",$increment(^IRISTemp("CovidDemo","executing"))) = msg
        set ^IRISTemp("CovidDemo","done",port,^IRISTemp("CovidDemo","executing")) = ""

    } catch (err) {
        set sc = err.AsStatus()
    }
    return sc
}

ClassMethod SuperSender(port) As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        do DISABLE^%NOJRN
        set ^IRISTemp("CovidDemo","workers",port) = $job
        set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")-1

        set dev = "|TCP|"_port
        do {
            close dev
            open dev:("127.0.0.1":port):10
            $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
        } while ('$TEST)

        do { 
            if $data(^IRISTemp("CovidDemo","done",port))=10 {
                set top = 0
                set idx = ""
                for {
                    set idx = $order(^IRISTemp("CovidDemo","done",port,idx))
                    quit:idx=""
                    if $increment(ctrl)>=500 {
                        set ctrl = 0
                        hang 10
                        do {
                            close dev
                            open dev:("127.0.0.1":port):10
                            $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
                        } while ('$TEST)
                    }

                    kill msg
                    merge msg = ^IRISTemp("CovidDemo","executing",idx)
                    kill ^IRISTemp("CovidDemo","done",port,idx)
                    kill ^IRISTemp("CovidDemo","executing",idx)
                    
                    set (pos,line) = "" 
                    for {
                        set pos = $order(msg(pos),1,line)
                        quit:pos=""
                        use dev:10 write line_$char(13),!
                        $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
                    }
                    // force restart the for loop just in case
                    quit:$increment(top)=100 
                    $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
                }
                $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
            }
            $$$ThrowOnError($get(^IRISTemp("CovidDemo","workersError"),1))
        } while ($data(^IRISTemp("CovidDemo")))
        hang 10
        close dev
    } catch (err) {
        close dev
        set sc = err.AsStatus()
        set ^IRISTemp("CovidDemo","workersError") = sc
        kill ^IRISTemp("CovidDemo","workers",port)
    }
    kill ^IRISTemp("CovidDemo","workers",port)
    set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")+1
    return sc
}

ClassMethod ConvertStringToNumber(string As %String = "") As %Numeric
{
    set number = ""
    for i=1:1:$length(string) {
        set char = $extract(string,i)
        set number = number + $ascii(char)
    }
    return $get(number,1)
}

/// ADT message template
XData ADT
{
MSH|^~\&||[facility]|||||ADT^A08|||2.5
EVN|A08|[exec-time]
PID|||[mrn]^^^[facility]^MR||[last-name]^[first-name]||[dob]|[sex]|||[street]^^[city]^[state]|||||||||||||||||||[dead]
PV1||[episode-type]|||||[doc-license]^[doc-last-name]^[doc-first-name]|||||||EO|||||[episode]|||||||||||||||||||||||||[exec-time]|[discharge-time]
}

/// OBX segment template
XData OBX
{
OBX||NM|[obs-code]^[obs-desc]^[obs-coding]||[obs-value]||||||F|||[exec-time]
}

/// DG1 segment template
XData DG1
{
DG1||[dia-coding]|[dia-code]^[dia-desc]|[dia-desc]|[exec-time]|[dia-code]||||||||||[doc-license]^[doc-last-name]^[doc-first-name]
}

/// PR1 segment template
XData PR1
{
PR1|||[procedure-code]^[procedure-desc]^[procedure-coding]|[procedure-desc]|[exec-time]||||||[doc-license]^[doc-last-name]^[doc-first-name]
}

/// ORU message template
XData ORU
{
MSH|^~\&||[facility]|||||ORU^R01|||2.5
PID|||[mrn]^^^[facility]^MR||[last-name]^[first-name]||[dob]|[sex]|||[street]^^[city]^[state]
PV1||[episode-type]|||||[doc-license]^[doc-last-name]^[doc-first-name]|||||||EO|||||[episode]|||||||||||||||||||||||||[exec-time]|[discharge-time]
ORC||[placer-id]|[filler-id]||||^^^[exec-time]||[exec-time]|||[doc-license]^[doc-last-name]^[doc-first-name]|[facility]||||||||[facility]||||||||LAB
OBR||[placer-id]|[filler-id]|[test-code]^[test-desc]^[test-coding]|||[exec-time]|||||||[exec-time]|Nasal Swab|[doc-license]^[doc-last-name]^[doc-first-name]||||||[exec-time]|||F
OBX||ST|[result-code]^[result-desc]^[result-coding]||[result-value]||||||F|||[exec-time]
}

/// PPR message template
XData PPR
{
MSH|^~\&||[facility]|||||PPR^PC1|||2.5
PID|||[mrn]^^^[facility]^MR||[last-name]^[first-name]||[dob]|[sex]|||[street]^^[city]^[state]|||||||||||||||||||[dead]
PV1||[episode-type]|||||[doc-license]^[doc-last-name]^[doc-first-name]|||||||EO|||||[episode]|||||||||||||||||||||||||[exec-time]|[discharge-time]
}

/// PRB segment template
XData PRB
{
PRB||[exec-time]|[dia-code]^[dia-desc]^[dia-coding]|[dia-desc]
}

}
