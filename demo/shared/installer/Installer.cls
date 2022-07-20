Class Demo.Installer
{

ClassMethod Install() As %Status
{
    set sc = $$$OK
    try {
        new $namespace
        set $namespace = "HSLIB"
        set ^Demo.Install(1,"start") = $zdatetime($horolog,3)
        set pre = " - "
        set sub = " >>> "
        set message = "%1%2: %3"
        set version = ##class(%ZHSLIB.HealthShareMgr).VersionInfo()
        write !,!," ------ Installation Started ------",!
        if version["HealthShare Unified Care Record" {
            write $$$FormatText(message,pre,$piece(version,"20",1),"installing code"),!

            // initialize demo utility
            write $$$FormatText(message,sub,"Initialize Demo Utility","")
            set sc = ..InitializeDemoUtility()
            write $select($$$ISERR(sc):$System.Status.GetErrorText(sc),1:"[complete]"),!
            quit:$$$ISERR(sc)
            
            // import code into HSANALYTICS
            write $$$FormatText(message,sub,"Import code into HSANALYTICS","")
            set sc = ..ImportCodeAnalytics("HSANALYTICS")
            write $select($$$ISERR(sc):$System.Status.GetErrorText(sc),1:"[complete]"),!
            quit:$$$ISERR(sc)

            // register UDAF into HSANALYTICS
            write $$$FormatText(message,sub,"Import code into HSANALYTICS","")
            set sc = ..RegisterUDAF("HSANALYTICS")
            write $select($$$ISERR(sc):$System.Status.GetErrorText(sc),1:"[complete]"),!
            quit:$$$ISERR(sc)

            // import code into HSEDGE1
            write $$$FormatText(message,sub,"Import code into HSEDGE1","")
            do ##class(HS.Director).StopAll()
            set sc = ..ImportCodeAnalytics("HSEDGE1")
            do ##class(HS.Director).StartAll()
            write $select($$$ISERR(sc):$System.Status.GetErrorText(sc),1:"[complete]"),!
            quit:$$$ISERR(sc)

        } else {
            write $piece(version,"20",1)_"is not a supported product.",!
            write " ------ Installation Aborted ------",!
            set ^Demo.Install(1,"aborted") = $zdatetime($horolog,3)
            quit
        }
        write " ----- Installation Completed -----",!
        set ^Demo.Install(1,"end") = $zdatetime($horolog,3)
    } catch (err) {
        write " ------ Installation Started ------",!
        write $System.Status.GetErrorText(err.AsStatus())
        set ^Demo.Install(1,"error") = $zdatetime($horolog,3)
        set ^Demo.Install(1,"error",1) = $System.Status.GetErrorText(err.AsStatus())
    }
    quit $$$OK
}

ClassMethod InitializeDemoUtility() As %Status
{
    set sc = $$$OK
    try { 
        do $zf(-1,"cp /shared/installer/setup.tar.gz /tmp/.")
        do $zf(-1,"cd /tmp; tar zxvf /tmp/setup.tar.gz")
        do $zf(-1,"find /tmp/setup/. -name ""._*"" -delete")
        do $zf(-1,"mv /tmp/setup /usr/irissys/csp/healthshare/hsanalytics/helper")
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod ImportCodeGeneral(namespace As %String) As %Status
{
    set sc = $$$OK
    try {
        new $namespace
        set $namespace = namespace
        set path = $$$FormatText("/code/%1/",$zconvert($namespace,"L"))
        do $System.OBJ.ImportDir(path,"*.xml","ck",,1)
        do $System.OBJ.ImportDir(path,"*.cls","ck",,1)

        hang 10
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod ImportCodeAnalytics(namespace As %String) As %Status
{
    set sc = $$$OK
    try {
        set sc = $$$ADDSC(sc,..ImportCodeGeneral(namespace))

        new $namespace
        set $namespace = namespace
        // build covid
        set sc = $$$ADDSC(sc,##class(HSAA.COVID19.Installer).RunSetupCOVID19Dashboards())
        hang 10
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod RegisterUDAF(namespace As %String) As %Status
{
    set sc = $$$OK
    try { 
        new $namespace
        set $namespace = namespace
        do $System.SQL.Execute("CALL AtScaleUDAF.Register()")
        do ##class(AtScaleUDAF.Utils).CreateDatabase("/usr/irissys/mgr/AtScale/")
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

}
