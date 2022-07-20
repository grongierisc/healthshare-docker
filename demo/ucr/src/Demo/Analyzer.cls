Class Demo.Analyzer
{

/// Total of concurrent processes for some of the tasks
Parameter Workers = 4;

/// Cases Rate Deviation to adjust numbers
/// confession: I can't remember why I created this in the first place, but it breaks without it
/// note: yes, I did remove the variables that were using it, but it goes on a lenghty loop that I do not care enough to investigate
Parameter CasesRateDeviation = .24;

/// - run ##class(Demo.Analyzer).RunAll("*") for all period since there is data
/// - run ##class(Demo.Analyzer).RunAll([offset]) to run the last [offset] days from the last date with data
/// example: - run ##class(Demo.Analyzer).RunAll(0) to run the last day
/// example: - run ##class(Demo.Analyzer).RunAll(30) to run the last 30 days
/// example: - run ##class(Demo.Analyzer).RunAll(30,0) to disable the workers and run single threaded
ClassMethod RunAll(offset As %String = 0, workersEnabled As %Boolean = 1, buildCube As %Boolean = 1) As %Status
{
    set sc = $$$OK
    try {
        do DISABLE^%NOJRN
        if $get(^IRISTemp("Loader")) {
            set sc = $$$ERROR($$$GeneralError,"code already running on job "_^IRISTemp("Loader"))
            quit
        }
        do DISABLE^%NOJRN
        set start = ##class(Demo.Loader).GetStartTime()
        // clean stage
        kill ^Demo.StageD,^Demo.StageI,^Demo.StageS,^IRISTemp("CovidDemo"),^IRISTemp("Monitor"),^IRISTemp("Monitor.Snap")
        set ^IRISTemp("Loader") = $job
        set ^IRISTemp("CovidDemo","usingWorkers") = $select(workersEnabled=1:..#Workers,1:1)
        set ^IRISTemp("CovidDemo","workers") = ..#Workers
        set ^IRISTemp("CovidDemo","workersError") = $$$OK
        write:'$get(%DemoMonitor) #,$$$FormatText("[starting] using %1 worker(s)",^IRISTemp("CovidDemo","usingWorkers")),!
        set totalPopulation = 0
        &SQL(SELECT SUM(Population)
            INTO :totalPopulation
            FROM (SELECT Population 
                FROM Demo_External.WeeklyCityTown
                WHERE CityTown NOT IN ('All of Massachusetts','Unknown','Unknown town')
                GROUP BY CityTown||1))
        set ^IRISTemp("CovidDemo","totalPopulation") = +totalPopulation

        $$$ThrowOnError(..LocationDistribution())
        $$$ThrowOnError(..PrepareAvgDistribution())
        set startPatient = ##class(Demo.Loader).GetStartTime()
        $$$ThrowOnError(..GeneratePatients())
        set patientTime = ##class(Demo.Loader).GetExecTime(startPatient)
        set startPrepare = ##class(Demo.Loader).GetStartTime()
        $$$ThrowOnError(..DailyDistribution(offset))
        $$$ThrowOnError(..PrepareData(workersEnabled))
        set prepareTime = ##class(Demo.Loader).GetExecTime(startPrepare)
        set startGenerate = ##class(Demo.Loader).GetStartTime()
        $$$ThrowOnError(..GenerateStageData(workersEnabled))

        &SQL(SELECT SUM(Test) AS Tests
            ,SUM(Positive) AS Positives
            ,SUM(Dead) AS Deaths
            ,SUM(Hospitalized) AS Hospitalized
            ,SUM(ICU) AS ICU
            INTO :totalTest, :totalPositive, :totalDeath, :totalHospitalized, :totalICU
            FROM Demo.Stage)
        &SQL(SELECT COUNT(*) INTO :totalPatients FROM (SELECT PID FROM Demo.Stage GROUP BY PID))
        set generationTime = ##class(Demo.Loader).GetExecTime(startGenerate)

        set cubeStart = ##class(Demo.Loader).GetStartTime()
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[4/4] building cube"
        write:'$get(%DemoMonitor) "[4/4] building cube",!
        if buildCube $$$ThrowOnError(##class(%DeepSee.Utils).%BuildCube("DemoStageAnalyzer",1,0))
        set cubeTime = ##class(Demo.Loader).GetExecTime(cubeStart)

        set lastDate = $order(^IRISTemp("CovidDemo","daily",""),-1)
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[complete] generation done for offset %1 starting %2",offset,$zdate(lastDate,3))
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 unique patients]",+totalPatients)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 positives]",+totalPositive)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 deaths]",+totalDeath)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 hospitalized]",+totalHospitalized)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 ICUs]",+totalICU)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("- [[;white;]#%1 tests]",+totalTest)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "open dashboards: https://hsdemo-atscale/hsucr/csp/healthshare/hsanalytics/_DeepSee.UserPortal.DashboardViewer.zen?DASHBOARD=Demo%2FCovid%2FAnalyzer%2FCovid%20Data%20Loader%20Analyzer.dashboard"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[[[;darkgreen;]completed]]"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[1/4] patient generation time: "_patientTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[2/4] data preparation time: "_prepareTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[3/4] data generation time: "_generationTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "[4/4] cube build execution time: "_cubeTime
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "total execution time: "_##class(Demo.Loader).GetExecTime(start)
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) =  "EOF"
        kill ^IRISTemp("CovidDemo")
        kill ^IRISTemp("Loader")

        if '$get(%DemoMonitor) {
            write $$$FormatText("[complete] generation done for offset %1 starting %2",offset,$zdate(lastDate,3)),!
            write "------------------------------------------------------------------",!
            write $$$FormatText("- #%1 unique patients",+totalPatients),!
            write $$$FormatText("- #%1 positives",+totalPositive),!
            write $$$FormatText("- #%1 deaths",+totalDeath),!
            write $$$FormatText("- #%1 hospitalized",+totalHospitalized),!
            write $$$FormatText("- #%1 ICUs",+totalICU),!
            write $$$FormatText("- #%1 tests",+totalTest),!
            write "------------------------------------------------------------------",!
            write "open dashboards: https://hsdemo-atscale/hsucr/csp/healthshare/hsanalytics/_DeepSee.UserPortal.DashboardViewer.zen?DASHBOARD=Demo%2FCovid%2FAnalyzer%2FCovid%20Data%20Loader%20Analyzer.dashboard",!
            write "------------------------------------------------------------------",!
            write "[1/4] patient generation time: "_patientTime,!
            write "[2/4] data preparation time: "_prepareTime,!
            write "[3/4] data generation time: "_generationTime,!
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

/// calculate population location distribution
ClassMethod LocationDistribution() As %Status [ Internal ]
{
    set sc = $$$OK
    try { 
        set totalPopulation = $get(^IRISTemp("CovidDemo","totalPopulation"))
        set rateDeviation = ..#CasesRateDeviation
        &SQL(DECLARE AgeGroup CURSOR FOR 
            SELECT CASE Age 
                WHEN '<5' THEN '01-04'
                WHEN '5-9' THEN '05-09'
                WHEN '80+' THEN '80-105'
                ELSE Age
                END As AgeGroup
                ,((SUM(CasesLast2Weeks)-(SUM(CasesLast2Weeks)*:rateDeviation))*100/(:totalPopulation*PoplationEstimatePct)) PercCovidPerAge
            INTO :ageGroup, :casesRate
            FROM Demo_External.AgeLast2Weeks
            WHERE Age NOT IN ('0-19','Unknown')
            GROUP BY Age)
        &SQL(OPEN AgeGroup)
        for {
            &SQL(FETCH AgeGroup)
            quit:SQLCODE
            set ageGroupList(ageGroup) = casesRate
        }
        &SQL(CLOSE AgeGroup)

        &SQL(DECLARE LocationDistribution CURSOR FOR 
            SELECT A.CityTown
                ,A.County
                ,(A.Population*100/:totalPopulation)/100 AS PopulationRate
                ,b.A04
                ,b.A59
                ,b.A1014
                ,b.A1519
                ,b.A2029
                ,b.A3039
                ,b.A4049
                ,b.A5059
                ,b.A6069
                ,b.A7079
                ,b.A80
                ,b.F
                ,b.M
                INTO :city, :county, :populationRate, :a04, :a59, :a1014, :a1519, :a2029, :a3039, :a4049, :a5059, :a6069, :a7079, :a80, :f, :m
                FROM Demo_External.WeeklyCityTown A LEFT JOIN Demo_External.Location B ON A.CityTown =  B.City
                WHERE A.CityTown NOT IN ('All of Massachusetts','Unknown','Unknown town')
                GROUP BY CityTown||1)
        &SQL(OPEN LocationDistribution)
        for {
            &SQL(FETCH LocationDistribution)
            quit:SQLCODE
            set ^IRISTemp("CovidDemo","loc",county,city,"population") = populationRate
            set ^IRISTemp("CovidDemo","loc",county,city,"population","gender","F") = f
            set ^IRISTemp("CovidDemo","loc",county,city,"population","gender","M") = m
            set ag("01-04") = a04
            set ag("05-09") = a59
            set ag("10-14") = a1014
            set ag("15-19") = a1519
            set ag("20-29") = a2029
            set ag("30-39") = a3039
            set ag("40-49") = a4049
            set ag("50-59") = a5059
            set ag("60-69") = a6069
            set ag("70-79") = a7079
            set ag("80-105") = a80

            set ageGroup = ""
            for {
                set ageGroup = $order(ag(ageGroup))
                quit:ageGroup=""
                set ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup) = ag(ageGroup)*populationRate
                set ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup,"caseRate") = ag(ageGroup)*ageGroupList(ageGroup)
                set ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup,"ageRate") = ag(ageGroup)
            }
        }
        &SQL(CLOSE LocationDistribution)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// get covid cases daily distribution
ClassMethod DailyDistribution(offset As %String) As %Status [ Internal ]
{
    set sc = $$$OK
    try { 
        kill dailyDistribution
        set totalPopulation = $get(^IRISTemp("CovidDemo","totalPopulation"))
        // min and max are determined by the data existent in "Weekly City Town.csv"
        &SQL(SELECT MIN("Date"), MAX("Date") 
            INTO :minDate, :maxDate
            FROM Demo_External.CasesByDateTestDate) 
        if offset'="*" set minDate = maxDate-offset
        &SQL(DECLARE DailyDistribution CURSOR FOR 
            SELECT A."Date"
            ,A.PositiveNew
            ,B.ConfirmedDeaths
            ,C.AllMolecularTests
            ,(D.NewCOVID19hospitalizations) AS Hospitalizations
            ,(D.NetNewnumberICU) AS ICU
            INTO :date, :newCases, :newDeaths, :newTests, :newHosps, :newICUs
            FROM Demo_External.CasesByDateTestDate A 
                LEFT JOIN Demo_External.DateofDeath B ON A."Date" = B.DateofDeath 
                LEFT JOIN Demo_External.TestingByDateTestDate C ON A."Date" = C."Date"
                LEFT JOIN Demo_External.HospitalizationfromHospitals D ON A."Date" = D."Date"
            WHERE A."Date" BETWEEN :minDate AND :maxDate
            ORDER BY 1)
        &SQL(OPEN DailyDistribution)
        for {
            &SQL(FETCH DailyDistribution)
            quit:SQLCODE
            set ^IRISTemp("CovidDemo","daily",date) = $listbuild(+newCases,+newDeaths,+newTests,+newHosps,+newICUs)
        } 
        &SQL(CLOSE DailyDistribution)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod PrepareAvgDistribution() As %Status
{
    set sc = $$$OK
    try {
        &SQL(SELECT SUM(TwoWeekCaseCounts) AS Cases
                    ,SUM(TotalTestsLastTwoWeeks) AS Tests
                INTO :cases, :tests
                FROM Demo_External.WeeklyCityTown)
        set ^IRISTemp("CovidDemo","avgDistributionAux","casesTotal") = cases
        set ^IRISTemp("CovidDemo","avgDistributionAux","testsTotal") = tests
        set county = ""
        for {
            set county = $order(^IRISTemp("CovidDemo","loc",county))
            quit:county=""
            set city = ""
            for {
                set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                quit:city=""
                &SQL(SELECT SUM(TwoWeekCaseCounts)/:cases AS Cases
                    ,SUM(TotalTestsLastTwoWeeks)/:tests AS Tests
                    INTO :actCasesCity, :actTestsCity
                    FROM Demo_External.WeeklyCityTown
                    WHERE CityTown = :city
                    AND County = :county)
                set ^IRISTemp("CovidDemo","avgDistributionAux","cases",county,city) = actCasesCity
                set ^IRISTemp("CovidDemo","avgDistributionAux","tests",county,city) = actCasesCity
            }
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// returns the distribution of cases for each city based on average for days where "Weekly City Town" does not have records
ClassMethod SpecificDistributionAvg(day As %String, Output list) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set list = ""
        set cases = +$get(^IRISTemp("CovidDemo","avgDistributionAux","casesTotal"))
        set tests = +$get(^IRISTemp("CovidDemo","avgDistributionAux","testsTotal"))

        // distribute cases
        set started = 0
        set rate = 1
        set there = 0
        do {
            kill list("cases")
            // increases the rate every attempt to allow the number of cases to get to near match
            if (started) { set rate = rate+.1 }
            set casesDay = $listget(^IRISTemp("CovidDemo","daily",day),1)
            set totalCases = ""
            
            set county = ""
            for {
                set county = $order(^IRISTemp("CovidDemo","loc",county))
                quit:county=""
                set city = ""
                for {
                    set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                    quit:city=""
                    set actCasesCity = $get(^IRISTemp("CovidDemo","avgDistributionAux","cases",county,city))*casesDay
                    set actCasesCity = $fnumber(actCasesCity*rate,,0)
                    set list("cases",day,county,city) = actCasesCity
                    set totalCases = $get(totalCases)+actCasesCity
                }
            }
            if ('started) { 
                if totalCases>=casesDay set check = "decrease"
                if totalCases<casesDay set check = "increase"
            }
            if (check="decrease") {
                if totalCases<=casesDay set there = 1
            } else {
                if totalCases>=casesDay set there = 1
            }
            set started = 1
        } while ('there)

        // distribute tests
        set started = 0
        set rate = 1
        set there = 0
        do {
            kill list("tests")
            // increases the rate every attempt to allow the number of cases to get to near match
            if (started) { set rate = rate+.1 }
            set testsDay = $listget(^IRISTemp("CovidDemo","daily",day),3)
            set totalTests = ""
            
            set county = ""
            for {
                set county = $order(^IRISTemp("CovidDemo","loc",county))
                quit:county=""
                set city = ""
                for {
                    set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                    quit:city=""
                    set actTestsCity = $get(^IRISTemp("CovidDemo","avgDistributionAux","tests",county,city))*testsDay
                    set actTestsCity = $fnumber(actTestsCity*rate,,0)
                    set list("tests",day,county,city) = actTestsCity
                    set totalTests = $get(totalTests)+actTestsCity
                }
            }
            if ('started) { 
                if totalTests>=testsDay set check = "decrease"
                if totalTests<testsDay set check = "increase"
            }
            if (check="decrease") {
                if totalTests<=testsDay set there = 1
            } else {
                if totalTests>=testsDay set there = 1
            }
            set started = 1
        } while ('there)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// returns the distribution of cases for each city for a given date
ClassMethod SpecificDistribution(day As %String, Output list) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set list = ""
        // get total of cases for the two weeks that the "date" is part of
        &SQL(SELECT TOP 1 SUM(TwoWeekCaseCounts) AS Cases
                    ,SUM(TotalTestsLastTwoWeeks) AS Tests
                    ,StartDate
                INTO :cases, :tests, :startDate
                FROM Demo_External.WeeklyCityTown
                WHERE StartDate <= :day
                    AND DATEDIFF('dd',:day,StartDate)>=-14)
        if (SQLCODE=100) {
            $$$ThrowOnError(..SpecificDistributionAvg(day,.list))
            quit
        }

        // distribute cases
        set started = 0
        set rate = 1
        set there = 0
        do {
            kill list("cases")
            // increases the rate every attempt to allow the number of cases to get to near match
            if (started) { set rate = rate+.1 }
            set casesDay = $listget(^IRISTemp("CovidDemo","daily",day),1)
            set totalCases = ""
            
            set county = ""
            for {
                set county = $order(^IRISTemp("CovidDemo","loc",county))
                quit:county=""
                set city = ""
                for {
                    set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                    quit:city=""
                    &SQL(SELECT TwoWeekCaseCounts/:cases*:casesDay AS Cases
                        INTO :actCasesCity
                        FROM Demo_External.WeeklyCityTown
                        WHERE StartDate <= :day
                        AND DATEDIFF('dd',:day,StartDate)>=-14
                        AND CityTown = :city
                        AND County = :county)
                    set actCasesCity = $fnumber(actCasesCity*rate,,0)
                    set list("cases",day,county,city) = actCasesCity
                    set totalCases = $get(totalCases)+actCasesCity
                }
            }
            if ('started) { 
                if totalCases>=casesDay set check = "decrease"
                if totalCases<casesDay set check = "increase"
            }
            if (check="decrease") {
                if totalCases<=casesDay set there = 1
            } else {
                if totalCases>=casesDay set there = 1
            }
            set started = 1
        } while ('there)

        // distribute tests
        set started = 0
        set rate = 1
        set there = 0
        do {
            kill list("tests")
            // increases the rate every attempt to allow the number of cases to get to near match
            if (started) { set rate = rate+.1 }
            set testsDay = $listget(^IRISTemp("CovidDemo","daily",day),3)
            set totalTests = ""
            
            set county = ""
            for {
                set county = $order(^IRISTemp("CovidDemo","loc",county))
                quit:county=""
                set city = ""
                for {
                    set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                    quit:city=""
                    &SQL(SELECT TotalTestsLastTwoWeeks/:tests*:testsDay AS Tests
                        INTO :actTestsCity
                        FROM Demo_External.WeeklyCityTown
                        WHERE StartDate <= :day
                        AND DATEDIFF('dd',:day,StartDate)>=-14
                        AND CityTown = :city
                        AND County = :county)
                    set actTestsCity = $fnumber(actTestsCity*rate,,0)
                    set list("tests",day,county,city) = actTestsCity
                    set totalTests = $get(totalTests)+actTestsCity
                }
            }
            if ('started) { 
                if totalTests>=testsDay set check = "decrease"
                if totalTests<testsDay set check = "increase"
            }
            if (check="decrease") {
                if totalTests<=testsDay set there = 1
            } else {
                if totalTests>=testsDay set there = 1
            }
            set started = 1
        } while ('there)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// generate temp global based on distributions (messy, sorry!)
ClassMethod Prepare(date As %Integer) As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        do DISABLE^%NOJRN
        set ^IRISTemp("CovidDemo","workers",date) = $job

        // for random cases
        set ag(0) = "01-04"
        set ag(1) = "05-09"
        set ag(2) = "10-14"
        set ag(3) = "15-19"
        set ag(4) = "20-29"
        set ag(5) = "30-39"
        set ag(6) = "40-49"
        set ag(7) = "50-59"
        set ag(8) = "60-69"
        set ag(9) = "70-79"
        set ag(10) = "80-105"
        
        set numbers = ^IRISTemp("CovidDemo","daily",date)
        $$$ThrowOnError(..SpecificDistribution(date,.list))
        quit:'$data(list)

        set cases = $listget(numbers,1)
        set deaths = $listget(numbers,2)
        set tests = $listget(numbers,3)
        set hosps = +$listget(numbers,4)
        set icus = +$listget(numbers,5)
        
        set county = ""
        for {
            set county = $order(^IRISTemp("CovidDemo","loc",county))
            quit:county=""
            set city = ""
            for {
                set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                quit:city=""
                
                set casesCity = list("cases",date,county,city)
                set testsCity = list("tests",date,county,city)
                
                set ^IRISTemp("CovidDemo","cases",date,county,city,"cases") = $fnumber(casesCity,,0)

                set ratio = 1000
                set totalC = 0
                set totalT = 0
                set idx = 0
            
                set iwant = 1 // yes, I was frustraded when I named this one
                set decrease = 0
                do {
                    set (calcCasesCity,calcTestsCity) = 0
                    set ageGroup = ""
                    for {
                        set ageGroup = $order(^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup),-1)
                        quit:ageGroup=""
                        set ageRate = ""
                        if $data(ageRates(date,ageGroup)) {
                            set ageRate = ageRates(date,ageGroup)
                        } else {
                            set ageRate = ..GetAgeGroupRate(date,ageGroup)*^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup,"ageRate")
                            // randomize in case rate is not available
                            if (+$get(ageRate)=0) { 
                                if '..SpecialBoolean(4) { 
                                    // if not under 15 and over 59
                                    set ageRate = ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ag($random(11)),"caseRate")
                                } else {
                                    if '..SpecialBoolean(4) { 
                                        // if not child
                                        set ageRate = ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ag($random(3)+8),"caseRate")
                                    } else { 
                                        // if child
                                        set ageRate = ^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ag($random(3)),"caseRate")
                                    }
                                }
                                set ageRate = ageRate*^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup,"ageRate")
                            }
                            set ageRates(date,ageGroup) = ageRate
                        }
                        set casesAgeGroup =  $fnumber(casesCity*ageRate*ratio/10,,0)
                        set testsAgeGroup =  $fnumber(testsCity*ageRate*ratio/10,,0)
                        set calcCasesCity = $get(calcCasesCity)+casesAgeGroup
                        set calcTestsCity = $get(calcTestsCity)+testsAgeGroup
                        set calcCasesCity = calcCasesCity-(calcCasesCity*decrease)
                        set calcTestsCity = calcTestsCity-(calcTestsCity*decrease)
                    }
                    set (casesFactor,testsFactor) = 0
                    set:calcCasesCity>0 casesFactor = calcCasesCity/casesCity
                    set:calcTestsCity>0 testsFactor = calcTestsCity/testsCity
                    set ageGroup = ""
                    set totalCalcC = 0
                    for {
                        set ageGroup = $order(^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup),-1)
                        quit:ageGroup=""
                        set (casesAgeGroup,testsAgeGroup) = 0
                        set ageRate = ageRates(date,ageGroup)
                        set:casesFactor>0 casesAgeGroup =  $fnumber((casesCity*ageRate*ratio/10)/casesFactor,,0)
                        set totalCalcC = totalCalcC+casesAgeGroup
                    }
                    if totalCalcC>=casesCity {
                        set iwant = 0
                    } elseif (casesCity=0) {
                        set iwant = 0
                    } else {
                        set decrease = decrease+.1
                    }
                } while (iwant)
                
                set ageGroup = ""
                for {
                    set ageGroup = $order(^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup),-1)
                    quit:ageGroup=""
                    set (casesAgeGroup,testsAgeGroup) = 0
                    set ageRate = ageRates(date,ageGroup)
                    set:casesFactor>0 casesAgeGroup = $fnumber((casesCity*ageRate*ratio/10)/casesFactor,,0)
                    set:testsFactor>0 testsAgeGroup = $fnumber((testsCity*ageRate*ratio/10)/testsFactor,,0)
                    
                    for i=1:1:casesAgeGroup {
                        quit:totalC>=casesCity
                        set alive = 1
                        
                        // randomize hospitalization
                        set hospitalized = 0
                        if ((hosps>0)&&(..SpecialBoolean(3))) {
                            set hospitalized = 1
                            set hosps = hosps-1
                            // randomize icu
                            if ((hospitalized)&&(icus>0)&&(..SpecialBoolean(2))) {
                                set hospitalized = 2
                                set icus = icus-1
                                // randomize death (more likely for icu)
                                if deaths {
                                    set dead = ..SpecialBoolean(2)
                                    if dead {
                                        set deaths = deaths-1
                                        set alive = 0
                                    }
                                }
                            } else {
                                // randomize death (less likely for non-icu)
                                if deaths {
                                    set dead = ..SpecialBoolean(3)
                                    if dead {
                                        set deaths = deaths-1
                                        set alive = 0
                                    }
                                }
                            }
                        } else {
                            // randomize death (even less likely for non-hospitalized)
                            if deaths {
                                set dead = ..SpecialBoolean(6)
                                if dead {
                                    set deaths = deaths-1
                                    set alive = 0
                                }
                            }
                        }

                        set cases = cases-1
                        set totalC = $increment(totalC)
                        
                        // for every positive I assume one test as well
                        set totalT = $increment(totalT) 
                        set testsAgeGroup = testsAgeGroup-1 // for each case record a test and substract from the total tests
                        set tests = tests-1

                        // randomize sex
                        set ^IRISTemp("CovidDemo","cases",date,county,city,ageGroup,$case($random(2),0:"F",1:"M"),"cases",$increment(idx)) = $listbuild(hospitalized,alive)
                    }
                    
                    for i=1:1:testsAgeGroup {
                        quit:totalT>=testsCity
                        set totalT = $increment(totalT)
                        set testsAgeGroup = testsAgeGroup-1
                        set tests = tests-1
                        set ^IRISTemp("CovidDemo","cases",date,county,city,ageGroup,$case($random(2),0:"F",1:"M"),"tests",$increment(idx)) = 1
                    }
                }
            }
        } 
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
        kill ^IRISTemp("CovidDemo","workers",date)
        set ^IRISTemp("CovidDemo","workersError") = sc
    }
    kill ^IRISTemp("CovidDemo","workers",date)
    set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")+1
    return sc
}

/// generate temp global based on distributions (messy, sorry!)
ClassMethod PrepareData(workersEnabled As %Boolean) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[2/4] preparing data using [[;white;]%1] worker(s)",^IRISTemp("CovidDemo","usingWorkers"))
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        // from first day
        set day = $order(^IRISTemp("CovidDemo","daily",""),1,numbers)
        // till last day
        set end = $order(^IRISTemp("CovidDemo","daily",""),-1,numbers)
        do {
            if workersEnabled {
                for i=1:1:^IRISTemp("CovidDemo","workers") {
                    if $data(^IRISTemp("CovidDemo","daily",day)) { 
                        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("preparing data for [[;white;]%1]",$zdate(day,3))
                        write:'$get(%DemoMonitor) $$$FormatText("[2/4] preparing data for %1",$zdate(day,3)),!
                        set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")-1
                        job ##class(Demo.Analyzer).Prepare(day)
                        set day = $increment(day)
                    } else {
                        set day = $increment(day)
                    }
                }
                hang 1
                $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
            } else {
                for day=day:1:end {
                    if $data(^IRISTemp("CovidDemo","daily",day)) { 
                        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("preparing data for [[;white;]%1]",$zdate(day,3))
                        write:'$get(%DemoMonitor) $$$FormatText("[2/4] preparing data for %1",$zdate(day,3)),!
                        $$$ThrowOnError(##class(Demo.Analyzer).Prepare(day))
                        set ^IRISTemp("CovidDemo","workers") = ..#Workers
                    }
                }
            }
        } while ((day<end)||(^IRISTemp("CovidDemo","workers")'=..#Workers))
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// decreases the likelihood of returning 1 the greater <var>it</var> gets
ClassMethod SpecialBoolean(it As %Integer = 1) As %Boolean
{
    set bool = 2
    try {
        for i=1:1:it {
            set bool = $random(bool)+1
            set test(bool)=""
        }
        set bool = bool-1
    } catch (err) {
        set bool = 0
    }
    return bool
}

/// generate stage data that can then be used to create the HL7 messages
ClassMethod GenerateStage(date As %Integer) As %Status [ Internal ]
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    try {
        do DISABLE^%NOJRN
        set ^IRISTemp("CovidDemo","workers",date) = $job

        set county = ""
        for {
            set county = $order(^IRISTemp("CovidDemo","cases",date,county))
            quit:county=""
            set city = ""
            for {
                set city = $order(^IRISTemp("CovidDemo","cases",date,county,city))
                quit:city=""
                set ageGroup = ""
                for {
                    set ageGroup = $order(^IRISTemp("CovidDemo","cases",date,county,city,ageGroup))
                    quit:ageGroup="" 
                    set gender = ""
                    for {
                        set gender = $order(^IRISTemp("CovidDemo","cases",date,county,city,ageGroup,gender))
                        quit:gender=""
                        set type = ""
                        for {
                            set type = $order(^IRISTemp("CovidDemo","cases",date,county,city,ageGroup,gender,type))
                            quit:type=""
                            set pos = ""
                            for {
                                set pos = $order(^IRISTemp("CovidDemo","cases",date,county,city,ageGroup,gender,type,pos),1,data)
                                quit:pos=""
                                set (positive,test,dead,hospitalized,icu) = 0
                                if (type="cases") {
                                    set positive = 1
                                    set test = 1
                                    set:'$listget(data,2) dead = 1
                                    set hospitalizedType = $listget(data,1)
                                    if hospitalizedType=1 {
                                        set hospitalized = 1
                                    }
                                    if hospitalizedType=2 {
                                        set hospitalized = 1
                                        set icu = 1
                                    }
                                } else {
                                    set test = 1
                                }
                                kill patient,idx
                                $$$ThrowOnError(..GetRandomPatient(county,city,ageGroup,gender,date,.idx,.patient))
                                continue:'$listvalid(patient)||(idx="")
                                set stage = ##class(Demo.Stage).%New()
                                set stage.EntryDate = date
                                set stage.PID = $listget(patient,1)
                                set stage.Name = $listget(patient,2)
                                set stage.DOB = $listget(patient,3)
                                set stage.Age = $listget(patient,4)
                                set stage.Gender = gender
                                set stage.Street = ##class(%PopulateUtils).Street()
                                set stage.City = city
                                set stage.County = county
                                set stage.State = "MA"
                                set stage.Positive = positive
                                set stage.Test = test
                                set stage.Dead = dead
                                set stage.Hospitalized = hospitalized
                                set stage.ICU = icu
                                $$$ThrowOnError(stage.%Save())
                                
                                if positive {
                                    set chanceOfReinfection = ..SpecialBoolean(1)
                                    if 'chanceOfReinfection {
                                        $$$ThrowOnError(..KillPatient(county,city,ageGroup,gender,idx))
                                    } else {
                                        $$$ThrowOnError(..InfectPatient(county,city,ageGroup,gender,idx,date))
                                    }
                                }

                                if dead {
                                    $$$ThrowOnError(..KillPatient(county,city,ageGroup,gender,idx))
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
        kill ^IRISTemp("CovidDemo","workers",date)
        set ^IRISTemp("CovidDemo","workersError") = sc
    }
    kill ^IRISTemp("CovidDemo","workers",date)
    set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")+1
    return sc
}

/// generate stage data that can then be used to create the HL7 messages
ClassMethod GenerateStageData(workersEnabled As %Boolean) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[3/4] generating stage data using [[;white;]%1] worker(s)",^IRISTemp("CovidDemo","usingWorkers") )
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = "------------------------------------------------------------------"
        
        // from first day
        set day = $order(^IRISTemp("CovidDemo","daily",""),1,numbers)
        // till last day
        set end = $order(^IRISTemp("CovidDemo","daily",""),-1,numbers)

        do {
            if workersEnabled {
                for i=1:1:^IRISTemp("CovidDemo","workers") {
                    if $data(^IRISTemp("CovidDemo","daily",day)) { 
                        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("generating stage data for [[;white;]%1]",$zdate(day,3))
                        write:'$get(%DemoMonitor) $$$FormatText("[3/4] generating stage data for %1",$zdate(day,3)),!
                        set ^IRISTemp("CovidDemo","workers") = ^IRISTemp("CovidDemo","workers")-1
                        job ##class(Demo.Analyzer).GenerateStage(day)
                        set day = $increment(day)
                    }
                }
                hang 1
                $$$ThrowOnError(^IRISTemp("CovidDemo","workersError"))
            } else {
                for day=day:1:end {
                    set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("generating stage data for [[;white;]%1]",$zdate(day,3))
                    write:'$get(%DemoMonitor) $$$FormatText("[3/4] generating stage data for %1",$zdate(day,3)),!
                    $$$ThrowOnError(##class(Demo.Analyzer).GenerateStage(day))
                    set ^IRISTemp("CovidDemo","workers") = ..#Workers
                }
            }
        } while ((day<end)||(^IRISTemp("CovidDemo","workers")'=..#Workers))
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// generate a pool of patients based on demographic distribution
ClassMethod GeneratePatients() As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        kill ^IRISTemp("Monitor")
        set ^IRISTemp("Monitor",$increment(^IRISTemp("Monitor"))) = $$$FormatText("[1/4] generating temporary patients: [[;white;]~%1] patients",$get(^IRISTemp("CovidDemo","totalPopulation")))
        write:'$get(%DemoMonitor) $$$FormatText("[1/4] generating temporary patients: ~%1 patients",$get(^IRISTemp("CovidDemo","totalPopulation"))),!
        set year = 365.25
        set today = +$now()
        set county = ""
        for {
            set county = $order(^IRISTemp("CovidDemo","loc",county))
            quit:county=""
            set city = ""
            for {
                set city = $order(^IRISTemp("CovidDemo","loc",county,city))
                quit:city=""
                set ageGroup = ""
                for {
                    set ageGroup = $order(^IRISTemp("CovidDemo","loc",county,city,"population","ageGroup",ageGroup),-1,ageRate)
                    quit:ageGroup=""
                    set maxDate = $fnumber(today-($piece(ageGroup,"-",1)*year),,0)
                    set minDate = $fnumber(today-($piece(ageGroup,"-",2)*year),,0)
                    set totalF = $fnumber($get(^IRISTemp("CovidDemo","totalPopulation"))*ageRate*^IRISTemp("CovidDemo","loc",county,city,"population","gender","F"),,0)
                    set totalM = $fnumber($get(^IRISTemp("CovidDemo","totalPopulation"))*ageRate*^IRISTemp("CovidDemo","loc",county,city,"population","gender","M"),,0)

                    // generate female based on location and age group
                    for i=1:1:totalF {
                        set dob = ##class(%PopulateUtils).Date(minDate,maxDate)
                        set age = $fnumber(((today-dob)/year),,0)
                        set name = ##class(%PopulateUtils).Name(2)
                        set idx = $increment(^IRISTemp("CovidDemo","patients",county,city,ageGroup,"F"))
                        set ^IRISTemp("CovidDemo","patients") = $increment(^IRISTemp("CovidDemo","patients"))
                        set ^IRISTemp("CovidDemo","patients",county,city,ageGroup,"F",idx) = $listbuild($increment(id),name,dob,age)
                    }

                    // generate male based on location and age group
                    for i=1:1:totalM {
                        set dob = ##class(%PopulateUtils).Date(minDate,maxDate)
                        set age = $fnumber(((today-dob)/year),,0)
                        set name = ##class(%PopulateUtils).Name(1)
                        set idx = $increment(^IRISTemp("CovidDemo","patients",county,city,ageGroup,"M"))
                        set ^IRISTemp("CovidDemo","patients") = $increment(^IRISTemp("CovidDemo","patients"))
                        set ^IRISTemp("CovidDemo","patients",county,city,ageGroup,"M",idx) = $listbuild($increment(id),name,dob,age)
                    }
                }
            }
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// get unique patient
ClassMethod GetRandomPatient(county As %String, city As %String, ageGroup As %String, gender As %String, date As %Integer, Output idx As %Integer, Output patient As %String) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set idx = ""
        set patient = ""
        quit:'$data(^IRISTemp("CovidDemo","patients",county,city,ageGroup,gender))
        set entries = $get(^IRISTemp("CovidDemo","patients",county,city,ageGroup,gender))
        quit:entries=""
        do {            
            set idx = $random(entries)+1
            set patient = $get(^IRISTemp("CovidDemo","patients",county,city,ageGroup,gender,idx))
            if ..IsPatientInfected(county,city,ageGroup,gender,idx,date) {
                set patient = ""
                set idx = ""
                if $increment(attempts)>(entries*2) { 
                    quit
                }
            }
        } while (patient="")
        kill ^IRISTemp("CovidDemo","pool")
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// remove patient from the pool
ClassMethod KillPatient(county As %String, city As %String, ageGroup As %String, gender As %String, idx As %Integer) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        quit:'$data(^IRISTemp("CovidDemo","patients",county,city,ageGroup,gender,idx))
        kill ^IRISTemp("CovidDemo","patients",county,city,ageGroup,gender,idx)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// check if patient is already infected
ClassMethod IsPatientInfected(county As %String, city As %String, ageGroup As %String, gender As %String, idx As %Integer, date As %String) As %Boolean [ Internal ]
{
    set infected = 0
    try {
        quit:'$data(^IRISTemp("CovidDemo","infected",county,city,ageGroup,gender,idx))
        set infectedDate = ^IRISTemp("CovidDemo","infected",county,city,ageGroup,gender,idx)
        if ((date-infectedDate)<60) { 
            set infected = 1
        } else { // remove infection if over 60 days of the infection date
            kill ^IRISTemp("CovidDemo","infected",county,city,ageGroup,gender,idx)
        }
    } catch (err) {
        set infected = 0
    }
    return infected
}

/// infect patient
ClassMethod InfectPatient(county As %String, city As %String, ageGroup As %String, gender As %String, idx As %Integer, date As %String) As %Status [ Internal ]
{
    set sc = $$$OK
    try {
        set ^IRISTemp("CovidDemo","infectedCtrl",county,city,ageGroup,gender,idx) = $increment(^IRISTemp("CovidDemo","infectedCtrl",county,city,ageGroup,gender,idx))
        if ^IRISTemp("CovidDemo","infectedCtrl",county,city,ageGroup,gender,idx)=3 { // do not allow more than 3 cases per patient
            $$$ThrowOnError(..KillPatient(county,city,ageGroup,gender,idx))
        } else {
            set ^IRISTemp("CovidDemo","infected",county,city,ageGroup,gender,idx) = date
        }
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

/// get rates infection rate for age group
ClassMethod GetAgeGroupRate(date As %Integer, ag As %String) As %Numeric [ Internal ]
{
    set sc = $$$OK
    set ageGroupList = ""
    try {
        set totalPopulation = $get(^IRISTemp("CovidDemo","totalPopulation"))
        set rateDeviation = ..#CasesRateDeviation
        &SQL(DECLARE GetAgeGroupRate CURSOR FOR 
            SELECT CASE Age 
                WHEN '<5' THEN '01-04'
                WHEN '5-9' THEN '05-09'
                WHEN '80+' THEN '80-105'
                ELSE Age
                END As AgeGroup
                ,((SUM(CasesLast2Weeks)-(SUM(CasesLast2Weeks)*:rateDeviation))*100/(:totalPopulation*PoplationEstimatePct)) PercCovidPerAge
            INTO :ageGroup, :casesRate
            FROM Demo_External.AgeLast2Weeks A
            WHERE Age NOT IN ('0-19','Unknown')
            AND A."Date" = (
                SELECT TOP 1 B."Date" FROM Demo_External.AgeLast2Weeks B
                WHERE B.StartDate <= :date
                AND DATEDIFF('dd',:date,B.StartDate)>=-14)
            GROUP BY Age)
        &SQL(OPEN GetAgeGroupRate)
        for {
            &SQL(FETCH GetAgeGroupRate)
            quit:SQLCODE
            set ageGroupList(ageGroup) = casesRate*1000
        }
        &SQL(CLOSE GetAgeGroupRate)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return $get(ageGroupList(ag))
}

}
