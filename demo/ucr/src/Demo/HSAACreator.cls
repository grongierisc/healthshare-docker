Include HSAA.HSAA

Class Demo.HSAACreator
{

/// Total of concurrent processes for some of the tasks
Parameter Workers = 8;

/// Allow bringing all the data to current date
Parameter DateShift = 1;

/// kick the HSAA creation
ClassMethod CreateAll(offset As %Integer = 0, workersEnabled As %Boolean = 1, buildCube As %Boolean = 1) As %Status
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

        if '$get(%DemoMonitor) {
            write #,$$$FormatText("[starting] using %1 worker(s) to generate HSAA %2",^IRISTemp("CovidDemo","usingWorkers"),message),!
            write "------------------------------------------------------------------",!
        }

        set cleanStart = ##class(Demo.Loader).GetStartTime()
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[1/4] cleaning HSAA"
        write:'$get(%DemoMonitor) "[1/4] cleaning HSAA",!
        job ##class(Demo.HSAACreator).CleanHSAA()
        hang 1
        do {
            // wait cleaning
            $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
        } while ($data(^IRISTemp("CovidDemo","CleanHSAA")))
        $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
        set cleanTime = ##class(Demo.Loader).GetExecTime(cleanStart)

        set startCodeSet = ##class(Demo.Loader).GetStartTime()
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[2/4] preparing codesets"
        $$$ThrowOnError(##class(Demo.HL7Creator).PrepareCodeset())

        set maxDate = $order(^Demo.StageI("IdxDate",""),-1)
        set day = $order(^Demo.StageI("IdxDate",""))
        if offset'="*" set day = maxDate-offset

        set ^IRISTemp("CovidDemo","dateShift") = 0
        set:..#DateShift ^IRISTemp("CovidDemo","dateShift") = +$horolog-maxDate
        
        &SQL(SELECT COUNT(ID) INTO :totalForPeriod FROM Demo.Stage WHERE EntryDate BETWEEN :day AND :maxDate)
        set codeSetTime = ##class(Demo.Loader).GetExecTime(startCodeSet)

        kill ^IRISTemp("Monitor")
        if '$get(%DemoMonitor) {
            write "[2/4] preparing codesets",!
            write $$$FormatText("[3/4] using %1 worker(s) to generate HSAA for %2 entries %3",^IRISTemp("CovidDemo","usingWorkers"),totalForPeriod,message),!
            write "------------------------------------------------------------------",!
        }

        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[3/4] using [[;white;]%1] worker(s) to generate HSAA for [[;white;]%2] entries %3",^IRISTemp("CovidDemo","usingWorkers"),totalForPeriod,message)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"

        set startGenerationTime = ##class(Demo.Loader).GetStartTime()
        do {
            if workersEnabled {
                for i=1:1:^IRISTemp("CovidDemo","workers") {
                    if $data(^Demo.StageI("IdxDate",day)) { 
                        &SQL(SELECT COUNT(ID) INTO :totalForDay FROM Demo.Stage WHERE EntryDate = :day)
                        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("generating HSAA for [[;white;]%1] (entry [[;white;]%2] of [[;white;]%3])",$zdate(day,3),1,totalForDay)
                        write:'$get(%DemoMonitor) $$$FormatText("[3/4] generating HSAA for %1",$zdate(day,3)),!
                        set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")-1
                        job ##class(Demo.HSAACreator).GenerateForDate(day,totalForDay,^IRISTemp("Monitor"))
                        set day = $increment(day)
                    } else {
                        set day = $increment(day)
                    }
                }
                hang 1
                $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
            } else {
                for day=day:1:maxDate {
                    if $data(^Demo.StageI("IdxDate",day)) { 
                        &SQL(SELECT COUNT(ID) INTO :totalForDay FROM Demo.Stage WHERE EntryDate = :day)
                        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("generating HSAA for [[;white;]%1] (entry [[;white;]%2] of [[;white;]%3])",$zdate(day,3),1,totalForDay)
                        write:'$get(%DemoMonitor) $$$FormatText("[3/4] generating HSAA for %1",$zdate(day,3)),!
                        $$$ThrowOnError(..GenerateForDate(day,totalForDay,^IRISTemp("Monitor")))
                        set ^IRISTemp("CovidDemo","workers") = ..#Workers
                    }
                }
            }
        } while ((day<maxDate)||(^IRISTemp("CovidDemo","workers")'=..#Workers))
        set generationTime = ##class(Demo.Loader).GetExecTime(startGenerationTime)

        set cubeStart = ##class(Demo.Loader).GetStartTime()
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[4/4] building cube"
        write:'$get(%DemoMonitor) "[4/4] building cube",!
        if buildCube $$$ThrowOnError(##class(HSAA.Cubes).RebuildAllCubes(0))
        set cubeTime = ##class(Demo.Loader).GetExecTime(cubeStart)

        kill ^IRISTemp("Monitor")
        set lastDate = $order(^Demo.StageI("IdxDate",""),-1)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[[[;darkgreen;]completed]] generation done for offset %1 starting %2 %3",offset,$zdate(lastDate,3),message)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[1/4] HSAA clean up time: "_cleanTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[2/4] codeset generation time: "_codeSetTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[3/4] HSAA generation time: "_generationTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[4/4] cube build execution time: "_cubeTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "total execution time: "_##class(Demo.Loader).GetExecTime(start)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) =  "EOF"
        kill ^IRISTemp("CovidDemo")
        kill ^IRISTemp("Loader")

        if '$get(%DemoMonitor) {
            write "------------------------------------------------------------------",!
            write $$$FormatText("[completed] generation done for offset %1 starting %2 %3",offset,$zdate(lastDate,3),message),!
            write "------------------------------------------------------------------",!
            write "[1/4] HSAA clean up time: "_cleanTime,!
            write "[2/4] codeset generation time: "_codeSetTime,!
            write "[3/4] HSAA generation time: "_generationTime,!
            write "[4/4] cube build execution time: "_cubeTime,!
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

ClassMethod CleanHSAA() As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    set ^IRISTemp("CovidDemo","CleanHSAA") = 1
    try {
        $$$ThrowOnError(##class(HSAA.Utils).ResetData())
   } catch (err) {
        set sc = err.AsStatus()
        set ^IRISTemp("CovidDemo","workersError") = sc
        kill ^IRISTemp("CovidDemo","CleanHSAA")
    }
    kill ^IRISTemp("CovidDemo","CleanHSAA")
    return sc
}

ClassMethod GenerateForDate(date As %Integer, totalForDay As %Integer, indexMonitor As %Integer) As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        do DISABLE^%NOJRN
        set ^IRISTemp("CovidDemo","workers",date) = $job
        set id = ""
        for {
            set id = $order(^Demo.StageI("IdxDate",date,id))
            quit:id=""
            set ^IRISTemp("Monitor",indexMonitor) = $$$FormatText("generating HSAA for [[;white;]%1] (entry [[;white;]%2] of [[;white;]%3])%4",$zdate(date,3),$increment(ctrl),totalForDay,$select(ctrl=totalForDay:"",1:" - active"))
            $$$ThrowOnError(..ProcessPatient(id))
            $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
        }
    } catch (err) {
        set sc = err.AsStatus()
        set ^IRISTemp("CovidDemo","workersError") = sc
        kill ^IRISTemp("CovidDemo","workers",date)
    }
    kill ^IRISTemp("CovidDemo","workers",date)
    set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")+1
    return sc
}

/// generate HSAA for a given patient 
ClassMethod ProcessPatient(id As %Integer) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set patientData = $get(^Demo.StageD(id))

        set code = $zconvert($extract($listget(patientData,10),1,2)_$extract($listget(patientData,10),$length($listget(patientData,10))),"U")
        set facility = $listget(patientData,10)_" Hospital"
        set enteredOnDate = $listget(patientData,2)+$get(^IRISTemp("CovidDemo","dateShift"))
        set enteredOnTime = $random(86399)+1
        set enteredOn = $zdate(enteredOnDate,3)_"T"_$ztime(enteredOnTime)

        // create patient
        set mrn = code_($listget(patientData,3)+10000000000)
        set patientID = $get(^IRISTemp("CovidDemo","patient",mrn))
        
        if (patientID="") {
            set patient = ##class(HSAA.Patient).%New()
            set patient.HSAAID = ..GetNextHSAAID()
            $$$ThrowOnError(patient.%Save())
            set patientID = patient.%Id()
            set ^IRISTemp("CovidDemo","patient",mrn) = patientID

            set patient.MPIID = ""
            set patient.Name.MRN = mrn
            set patientName = $listget(patientData,4)
            set patient.Name.GivenName = $piece(patientName,",",2)
            set patient.Name.FamilyName = $piece(patientName,",",1)
            set patient.Gender.Description = $case($listget(patientData,5),"F":"Female","M":"Male",:"Unknown")
            set patient.Gender.Code = $listget(patientData,5)

            set patient.BirthDate = $listget(patientData,6)+$get(^IRISTemp("CovidDemo","dateShift"))
            set patient.BirthTime = $zdate($listget(patientData,6),3)_"T"_$ztime($random(86399)+1)

            set patient.Address.Street = $listget(patientData,8)
            set patient.Address.City.Code = $listget(patientData,9)
            set patient.Address.City.Description = $listget(patientData,9)
            set patient.Address.State.Code = $listget(patientData,11)
            set patient.Address.State.Description = "Massachusetts"
            set patient.Deceased = $listget(patientData,14)

            set patient.EnteredOn = enteredOn
            do patient.EnteredAt2SetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
            $$$ThrowOnError(sc)
            $$$ThrowOnError(patient.%Save())
        }
        
        // create encounter
        set enc = ##class(HSAA.Encounter).%New()
        do enc.PatientSetObjectId(patientID)
        set enc.EncounterNumber = code_(id+10000000000)
        set enc.VisitNumber = code_(id+10000000000)
        do enc.HealthCareFacilitySetObjectId(..GetData("HSAA.HealthCareFacility",code,facility,.sc))
        do enc.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
        $$$ThrowOnError(sc)
        $$$ThrowOnError(enc.%Save())
        set encID = enc.%Id()

        set endDate = enteredOnDate
        set endTime = $random(86399)+1
        if (endTime<enteredOnTime) {
            set endDate = endDate+1 
        }

        set enc.EncounterType = $case($listget(patientData,15),1:"Inpatient",:$case($random(2),0:"Outpatient",:"Emergency"))
        if (enc.EncounterType="Inpatient") {            
            set endDate = enteredOnDate+$random(5)+15
            set enc.AdmissionType.Description = $select($listget(patientData,16)=1:"ICU",1:"Ward")
	        set enc.AdmissionType.Code = $extract(enc.AdmissionType.Description,1)

            // create procedure            
            if (enc.AdmissionType.Description="ICU") {
                set endDate = enteredOnDate+$random(10)+20
                set proc = ##class(HSAA.Procedure).%New()
                do proc.PatientSetObjectId(patientID)
                do proc.EncounterSetObjectId(encID)

                set coding = "CPT"
                set item(0) = $listbuild("31500","Intubation, endotracheal, emergency procedure")
                set item(1) = $listbuild("94002","Ventilation assist and management, initiation of pressure")
                set item(2) = $listbuild("94003","Volume preset ventilators for assisted or controlled breathing")
                set item(3) = $listbuild("94660","Continuous negative pressure ventilation (CNP)")
                set item(4) = $listbuild("94661","Ventilation (CNP), initiation and management")
                set item(5) = $listbuild("94662","Ventilation management")
                set ventData = item($random(6))
                
                set proc.Procedure.SDACodingStandard = coding
                set proc.Procedure.Code = $listget(ventData,1)
                set proc.Procedure.Description = $listget(ventData,2)
                
                set proc.ProcedureTime = enteredOn
                $$$ThrowOnError(proc.%Save())
            }
        } elseif (enc.EncounterType="Emergency") {  
            if ((endTime-enteredOnTime)>0) {
                set erTime = enteredOnTime+$random(endTime-enteredOnTime)
            } else {
                set erTime = $random(endTime)
            }
            set enc.EmergencyAdmitDateTime = $zdate(endDate,3)_"T"_$ztime(erTime)
        }
        
        set enc.StartTime = enteredOn
        if (endDate<+$horolog) {
            set enc.EndTime = $zdate(endDate,3)_"T"_$ztime(endTime)
            set:enc.EncounterType="Inpatient" enc.LOS = endDate-enteredOnDate
        }

        if (enc.EncounterType="Inpatient") {
            set hasSymptoms = 1
        } else {
            set hasSymptoms = ##class(Demo.Analyzer).SpecialBoolean(2)
        }
        if (hasSymptoms) {
            set item = ""
            set ctrlItem = 0
            set itemToUse = $random(^IRISTemp("CovidDemo","covid-like"))+1
            for {
                set item = $order(^IRISTemp("CovidDemo","covid-like",item),1,itemData)
                quit:item=""
                quit:($increment(ctrlItem)>=itemToUse)
            }
            set enc.AdmitReason.SDACodingStandard = $listget(itemData,1)
            set enc.AdmitReason.Code = $listget(itemData,2)
            set enc.AdmitReason.Description = $listget(itemData,3)
        }

        if (hasSymptoms) {
            set symptom(0) = $listbuild("SCT","276885007","Body temperature",(98+$random(10)))
            set symptom(1) = $listbuild("SCT","431314004","Peripheral oxygen saturation",(80+$random(20)))
            set symptom(2) = $listbuild("SCT","86290005","Respiratory rate",(12+$random(20)))
            for symCnt=0:1:$random(3) {
                set symptomType = ""
                do {
                    set symptomIdx = $random(3)
                    set:$data(symptom(symptomIdx)) symptomType = symptom(symptomIdx)
                } while(symptomType="")
                kill symptom(symptomIdx)

                set obs = ##class(HSAA.Observation).%New()
                do obs.PatientSetObjectId(patientID)
                do obs.EncounterSetObjectId(encID)
                set obs.EnteredOn = enteredOn
                set obs.ObservationTime = enteredOn
                set obs.ObservationCode.SDACodingStandard = $listget(symptomType,1)
                set obs.ObservationCode.Code = $listget(symptomType,2)
                set obs.ObservationCode.Description = $listget(symptomType,3)
                set obs.ObservationValue = $listget(symptomType,4)
                $$$ThrowOnError(obs.%Save())
            }
        }

        // create cormobidity/risk factor
        // the less the number then greater the chance
        set chanceOfComorbidity = 4
        set chanceOfComorbidity = chanceOfComorbidity-$listget(patientData,14)
        set chanceOfComorbidity = chanceOfComorbidity-$listget(patientData,15)
        set chanceOfComorbidity = chanceOfComorbidity-$listget(patientData,16)
        set comorbidity = ##class(Demo.Analyzer).SpecialBoolean(chanceOfComorbidity)
        
        if comorbidity {
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

                set prob = ##class(HSAA.Problem).%New()
                do prob.PatientSetObjectId(patientID)
                set prob.Status.Code = "A"
                set prob.Status.Description = "Active"
                set prob.Problem.SDACodingStandard = $listget(itemData,1)
                set prob.Problem.Code = $listget(itemData,2)
			    set prob.Problem.Description = $listget(itemData,3)
                $$$ThrowOnError(prob.%Save())
            } 
        }

        // create test
        set placerID = $zstrip($ztimestamp,"*P")

        set order = ##class(HSAA.Order).%New()
        do order.PatientSetObjectId(patientID)
        do order.EncounterSetObjectId(encID)
        set order.EncounterNumber = enc.EncounterNumber
        set order.PlacerId = placerID_"A"
        set labRnd = $random(9)+1
        set order.Specimen = $$$FormatText("Nasal Swab - %1",labRnd)
        set order.OrderCode.SDACodingStandard = "LN"
        set order.OrderCode.Code = $$$FormatText("94531%1-1",labRnd)
        set order.OrderCode.Description = $$$FormatText("SARS-CoV-2 (COVID-19) RNA panel - %1",labRnd)
        set order.OrderQuantity = 1
        set order.Type.Code = "LAB"
        set order.EnteredOn = $zdate(enteredOnDate+1,3)_"T"_$ztime($random(86399)+1)
        set order.FromTime = order.EnteredOn
        set order.EndTime = order.EnteredOn
        set order.StartTime = order.EnteredOn
        set order.ToTime = order.EnteredOn
        do order.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
        $$$ThrowOnError(order.%Save())
        set orderID = order.%Id()

        set lab = ##class(HSAA.LabResult).%New()
        do lab.PatientSetObjectId(patientID)
        do lab.OrderSetObjectId(orderID)
        set lab.ResultTime = order.EnteredOn
        set lab.ResultType = "AT"
        set lab.ResultStatus = "F"
        set lab.EnteredOn = order.EnteredOn
        $$$ThrowOnError(lab.%Save())
        set labID = lab.%Id()

        set test = ##class(HSAA.LabResultItem).%New()
        do test.PatientSetObjectId(patientID)
        do test.EncounterSetObjectId(encID)
        set test.EncounterNumber = enc.EncounterNumber
        do test.OrderSetObjectId(orderID)
        do test.LabResultSetObjectId(labID)
        set test.TestItemCode.SDACodingStandard = "LN"
        set test.TestItemCode.Code = $$$FormatText("94500%1-6",labRnd)
        set test.TestItemCode.Description = $$$FormatText("overall SARS-CoV-2 result - %1",labRnd)
        set test.PerformedAt.Address.City.Code = $listget(patientData,9)
        set test.PerformedAt.Address.City.Description = $listget(patientData,9)
        set test.PerformedAt.Address.State.Code = $listget(patientData,11)
        set test.PerformedAt.Address.State.Description = "Massachusetts"
        set test.ResultTime = order.EnteredOn
        set test.ResultValue = $case($listget(patientData,12),1:"Positive",0:"Negative")
        set test.TestItemStatus = "Final"
        do test.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
        set test.EnteredOn = order.EnteredOn
        $$$ThrowOnError(test.%Save())

        // create positive diagnosis
        if (test.ResultValue="Positive") {
            kill covid
            set covid(0) = $listbuild("SCT","840539006","Disease caused by 2019 novel coronavirus (disorder)")
            set covid(1) = $listbuild("SCT","840544004","Suspected disease caused by 2019 novel coronavirus (situation)")
            set covid(2) = $listbuild("I10","J12.82","Pneumonia due to coronavirus disease 2019")
            set covid(3) = $listbuild("I10","Z20.822","Contact with and (suspected) exposure to COVID-19")
        } else {
            kill covid
            set covid(0) = $listbuild("I10","Z20.822","Contact with and (suspected) exposure to COVID-19")
            set covid(1) = $listbuild("I10","Z11.52","Encounter for screening for COVID-19")
            set covid(2) = $listbuild("I10","Z86.16","Personal history of COVID-19")
            set covid(3) = $listbuild("SCT","840544004","Suspected disease caused by 2019 novel coronavirus (situation)")            
        }

        set type = $random(4)
        set diag = ##class(HSAA.Diagnosis).%New()	
        do diag.PatientSetObjectId(patientID)
        do diag.EncounterSetObjectId(encID)

        set diag.DiagnosisGroup = 250
        set diag.Status.Code = "A"
        set diag.Diagnosis.SDACodingStandard = $listget(covid(type),1)
        set diag.Diagnosis.Code = $listget(covid(type),2)
        set diag.Diagnosis.Description = $listget(covid(type),3)
        
        set diag.DiagnosisTime = enteredOn
        do diag.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
        $$$ThrowOnError(diag.%Save())
        $$$ThrowOnError(enc.%Save())

        // create random not meaningful orders
        set meds(0) = $listbuild("42312","Chlorthacin 500MG TABS")
        set meds(1) = $listbuild("55452","Sucside 30MG DROPS")
        set meds(2) = $listbuild("12563","Alfutrisin 0.5MG CREAM")
        set meds(3) = $listbuild("99812","Nitroramine 25MG TABS")
        set meds(4) = $listbuild("54392","Levogomar 100ML Syrup")
        set meds(5) = $listbuild("67821","Benazezolam 5MG TABS")
        set meds(6) = $listbuild("98456","Androvene Alocine 10MG CAPS")
        set meds(7) = $listbuild("31239","Lexitora Novaneva 5MG CREAM")
        set meds(8) = $listbuild("41028","Dextroretin Anefen 50MG TABS")
        set meds(9) = $listbuild("71284","Epinex Nasabazine 10MG CAPS")
        set meds(10) = $listbuild("69879","Xenaprofen 50ML Syrup")
        set meds(11) = $listbuild("60018","Diprodazole 75MG CAPS")
        set meds(12) = $listbuild("19834","Bacterinesin 10MG IV")
        set meds(13) = $listbuild("27533","Adozyme 20MG IV")
        set meds(14) = $listbuild("36112","Tiavorin 50MG CREAM")
        set meds(15) = $listbuild("34511","Zevanuma 50MG TABS")
        set meds(16) = $listbuild("11972","Argagestin Hyalulovir 25MG TABS")
        set meds(17) = $listbuild("28473","Alphagard Omniveset 100ML Syrup")
        set meds(18) = $listbuild("89832","Adofenib Agalsitate 10MG DROPS")
        set meds(19) = $listbuild("44321","Diclodocet Actemlofen 5MG DROPS")

        // random allergy to medication
        if ##class(Demo.Analyzer).SpecialBoolean(7) {
            set medIdx = $random(20)
            set med = meds(medIdx)
            kill meds(medIdx)
            set all = ##class(HSAA.Allergy).%New()
            do all.PatientSetObjectId(patientID)
            do all.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.tSC))
            set all.FromTime = enteredOn
            set all.DiscoveryTime = enteredOn
            set all.Status = "A"
            set all.Allergy.Code = $listget(med,1)
            set all.Allergy.Description = $$$FormatText("Allerty to %1",$piece($listget(med,2)," ",1,*-2))
            set all.AllergyCategory.Code = "8372234"
            set all.AllergyCategory.Description = "Allergy to medication"
            $$$ThrowOnError(all.%Save())
        }

        // random allergy to food
        if ##class(Demo.Analyzer).SpecialBoolean(4) {
            set foods(0) = "Banana"
            set foods(1) = "Nuts"
            set foods(2) = "Milk"
            set foods(3) = "Fish"
            set foods(4) = "Beans"
            set foods(5) = "Pepper"
            set foods(6) = "Chocolate"
            set foodIdx = $random(7)
            set food = foods(foodIdx)
            
            set all = ##class(HSAA.Allergy).%New()
            do all.PatientSetObjectId(patientID)
            set all.Status = "A"
            set all.Allergy.Code = "124390833"_foodIdx
            set all.Allergy.Description = $$$FormatText("Allerty to %1",food)
            set all.AllergyCategory.Code = "5372231"
            set all.AllergyCategory.Description = "Allergy to food"
            set all.EnteredOn = enteredOn
            set all.FromTime = enteredOn
            set all.DiscoveryTime = enteredOn
            do all.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.tSC))
            $$$ThrowOnError(all.%Save())
        }

        // create random not meaningful orders
        for medCnt=0:1:$random(3) {
            set med = ""
            do {
                set medIdx = $random(20)
                set:$data(meds(medIdx)) med = meds(medIdx)
            } while(med="")
            kill meds(medIdx)

            set placerID = $zstrip($ztimestamp,"*P")
            set order = ##class(HSAA.Order).%New()
            do order.PatientSetObjectId(patientID)
            do order.EncounterSetObjectId(encID)
            set order.EncounterNumber = enc.EncounterNumber
            set order.PlacerId = placerID_"A"
            set order.FillerId = placerID_"A"
            set order.OrderCode.SDACodingStandard = "RXNORM"
            set order.OrderCode.Code = $listget(med,1)
            set order.OrderCode.Description = $listget(med,2)
            set order.OrderQuantity = $random(5)+1
            set order.Type.Code = "MED"
            set order.EnteredOn = enteredOn
            set order.FromTime = enteredOn
            set order.EndTime = enteredOn
            set order.StartTime = enteredOn
            set order.ToTime = enteredOn
            do order.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.tSC))
            $$$ThrowOnError(order.%Save())
            set orderID = order.%Id()

            set medObj = ##class(HSAA.Medication).%New()
            do medObj.PatientSetObjectId(patientID)
            do medObj.OrderSetObjectId(orderID)
            set medObj.EncounterNumber = enc.EncounterNumber
            set medObj.DrugProduct.SDACodingStandard = "RXNORM"
            set medObj.DrugProduct.Code = $listget(med,1)
            set medObj.DrugProduct.Description = $listget(med,2)
            set medObj.DoseQuantity = $random(5)+1
            set strenght = $piece($listget(med,2)," ",*-1)
            set uom = $extract(strenght,$length(strenght)-1,*)
            set medObj.DoseUoM.Code = uom
            set medObj.DoseUoM.Description = uom
            do medObj.EnteredAtSetObjectId(..GetData("HSAA.EnteredAt",code,facility,.sc))
            set medObj.EnteredOn = enteredOn
            set medObj.FromTime = enteredOn
            set medObj.ToTime = enteredOn
            $$$ThrowOnError(medObj.%Save())
        }
    } catch (err) {
        set sc = err.AsStatus()
    }
    return sc
}

ClassMethod GetData(classname As %String, code As %String, description As %String, ByRef sc As %Status) As %Integer [ Internal ]
{
    set id = ""
    try {
        set idxCode = $$$FormatText(" %1",$zconvert(code,"U"))
        set idxDesc = $$$FormatText(" %1",$zconvert(description,"U"))
        set index = $$$FormatText("^%1I",classname)
        if '$data(@index@("CDSCSIx",idxCode,idxDesc," ")) {
            try {
                set obj = $classmethod(classname,"%New")
                set obj.Code = code
                set obj.Description = description
                set:classname="HSAA.HealthCareFacility" obj.Name = description
                $$$ThrowOnError(obj.%Save())
                set id = obj.%Id()
                kill obj
            } catch (conflict) {
                set id = $order(@index@("CDSCSIx",idxCode,idxDesc," ",""))
            }
        } else {
            set id = $order(@index@("CDSCSIx",idxCode,idxDesc," ",""))
        }
    } catch (err) {
        set sc = err.AsStatus()
    }
    return id
}

ClassMethod GetNextHSAAID() As %String [ CodeMode = expression ]
{
$increment($$$Global(HSAAID))
}

}
