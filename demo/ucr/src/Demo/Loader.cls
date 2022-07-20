Class Demo.Loader Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
    set sc = $$$OK
    try {
        &HTML<<!DOCTYPE html>
        <html>>

        &HTML<<head>
        <script src="helper/jquery-3.3.1.min.js"></script>
        <script src="helper/jquery.terminal.min.js"></script>
        <link rel="stylesheet" href="helper/jquery.terminal.min.css"/>
        #(..HyperEventHead())#
        </head>
        <body>
        <script language="javascript">
            var interval;
            var startingFrom = 0;
            var wait = 3000;
            function monitorLog(){
                $('body').terminal({}).pause();
                $('body').terminal({}).clear();
                var ret = JSON.parse(#server(Demo.Loader.ProgressSnap())#);
                for (var i=0;i<ret.total;i++) {
                    var line = ret.entries[i];
                    if (line=="EOF") {
                        clearInterval(interval);
                        $('body').terminal({}).resume();
                    } else {
                        $('body').terminal({}).resume();
                        $('body').terminal({}).echo(line);
                        $('body').terminal({}).pause();
                    }
                }
            }
            var l = 0;
            var greet = 'Welcome to Health Insight Demo Loader'+
                    "\n------------------------------------------------------------------"+
                    "\nFor more execute 'help'."+
                    "\n------------------------------------------------------------------";
            $('body').terminal({
                help: function() {
                    this.echo();
                    this.echo("List of commands:");
                    this.echo("------------------------------------------------------------------");
                    this.echo("clear                 - reset the terminal");
                    this.echo("log                   - display old log if avaiable");
                    this.echo("prepare [path]        - consume covid data from mass.gov");
                    this.echo("                         note: covid.tar.gz has to be put on the provided path");
                    this.echo("                         note: [path] = default will trying to execute the configured path");
                    this.echo("load [offset]         - '*' will generate for all available data");
                    this.echo("                      - 'number' will offset the provided input from the last day with data");
                    this.echo("                         example: load 60 will offset 60 days from the last day with data");            
                    this.echo("generateHL7 [offset]  - '*' will generate hl7 for all available data");
                    this.echo("                      - 'number' will offset the provided input from the last day with data");
                    this.echo("                         example: generate 60 will offset 60 days from the last day with data");        
                    this.echo("                         note: not recommended for small machines (e.g.: personal) due to data footprint");
                    this.echo("generateHSAA [offset] - '*' will generate hsaa tables for all available data");
                    this.echo("                      - 'number' will offset the provided input from the last day with data");
                    this.echo("                         example: generate 60 will offset 60 days from the last day with data");        
                    this.echo("------------------------------------------------------------------");
                },
                clear: function() {
                    this.clear();
                },   
                test: function() {
                    this.echo("[launching loader]");
                    this.echo("[[[;darkred;]launching loader]]");
                    this.echo("[[[;darkgreen;]launching loader]]");
                    this.echo("[[[;white;]launching loader]]");
                },
                prepare: function(path) {
                    if (path=="default") {
                        var message = #server(Demo.Importer.Generate())#; 
                    } else {
                        var message = #server(Demo.Importer.Generate(path))#; 
                    }
                    this.echo(message);
                },               
                load: function(offset) {
                    if (offset=="*") {
                        var msg = "Do you want to generate all available data?\nThis will take a while";
                    } else if (Number.isInteger(offset)) {
                        var msg = "Do you want to generate with an offset off ("+offset+")?";
                    } else {
                        this.echo("[[[;darkred;]invalid command]]");
                        return;
                    }
                    if (!confirm(msg)) {
                        return;
                    }
                    this.clear();
                    this.echo("[[;white;][launching loader]]");
                    this.echo("------------------------------------------------------------------");
                    $('body').terminal({}).pause();
                    #server(Demo.Loader.Start(offset))#;
                    interval = setInterval(monitorLog,wait)
                },
                generateHL7: function(offset) {
                    if (offset=="*") {
                        var msg = "Do you want to generate hl7 to all available data?\nThis will take a while";
                    } else if (Number.isInteger(offset)) {
                        var msg = "Do you want to generate hl7 with an offset off ("+offset+")?";
                    } else {
                        this.echo("[[[;darkred;]invalid command]]");
                        return;
                    }
                    if (!confirm(msg)) {
                        return;
                    }
                    this.clear();
                    this.echo("[[;white;][launching loader]]");
                    this.echo("------------------------------------------------------------------");
                    $('body').terminal({}).pause();
                    #server(Demo.Loader.HL7(offset))#;
                    interval = setInterval(monitorLog,wait)
                },
                generateHSAA: function(offset) {
                    if (offset=="*") {
                        var msg = "Do you want to generate hsaa tables to all available data?\nThis will take a while";
                    } else if (Number.isInteger(offset)) {
                        var msg = "Do you want to generate hsaa tables with an offset off ("+offset+")?";
                    } else {
                        this.echo("[[[;darkred;]invalid command]]");
                        return;
                    }
                    if (!confirm(msg)) {
                        return;
                    }
                    this.clear();
                    this.echo("[[;white;][launching loader]]");
                    this.echo("------------------------------------------------------------------");
                    $('body').terminal({}).pause();
                    #server(Demo.Loader.HSAA(offset))#;
                    interval = setInterval(monitorLog,wait)
                },
                log: function() {
                    this.clear();
                    this.echo("[[;white;][launching log]]");
                    this.echo("------------------------------------------------------------------");
                    $('body').terminal({}).pause();
                    interval = setInterval(monitorLog,wait)
                }
            }, {
                greetings: greet
            });
        </script>
        </body>
        </html>>

    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    return sc
}

ClassMethod ProgressSnap() As %String
{
    do DISABLE^%NOJRN
    set sc = $$$OK
    set response = {}
    set response.total = 2
    set entries = []
    do entries.%Push("[no log available]")
    do entries.%Push("EOF")
    set response.entries = entries
    try {
        kill ^IRISTemp("Monitor.Snap")
        merge ^IRISTemp("Monitor.Snap") = ^IRISTemp("Monitor")
        set pos = $order(^IRISTemp("Monitor.Snap",""),-1)
        quit:pos=""
        if (^IRISTemp("Monitor.Snap",pos)'="EOF") {
            set ^IRISTemp("Monitor.Snap",$increment(^IRISTemp("Monitor.Snap"))) = "------------------------------------------------------------------"
            set ^IRISTemp("Monitor.Snap",$increment(^IRISTemp("Monitor.Snap"))) = "[running]"
        }
        set total = $get(^IRISTemp("Monitor.Snap"),0)
        quit:total=0
        set response.total = total
        set entries = []
        set pos = ""
        for {
            set pos = $order(^IRISTemp("Monitor.Snap",pos),1,line)
            quit:pos=""
            if (line="EOF") {
                kill ^IRISTemp("Monitor.Snap")
                kill ^IRISTemp("Monitor")
            }
            do entries.%Push(line)
        }
        set response.entries = entries
    } catch (err) {
        set response.total = 2
        do entries.%Push($System.Status.GetErrorText(err.AsStatus()))
        do entries.%Push("EOF")
        set response.entries = entries
    }
    return response.%ToJSON()
}

ClassMethod Start(offset As %String = 0) As %Status
{
    set sc = $$$OK
    try {
        set %DemoMonitor = 1
        if '$data(^IRISTemp("Loader")) {
            job ##class(Demo.Analyzer).RunAll(offset)
        }
    } catch (err) {
        kill %DemoMonitor
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    hang 5
    return sc
}

ClassMethod HL7(offset As %String = 0) As %Status
{
    set sc = $$$OK
    try {
        set %DemoMonitor = 1
        if '$data(^IRISTemp("Loader")) {
            job ##class(Demo.HL7Creator).CreateAll(offset)
        }
    } catch (err) {
        kill %DemoMonitor
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    hang 5
    return sc
}

ClassMethod HSAA(offset As %String = 0) As %Status
{
    set sc = $$$OK
    try {
        set %DemoMonitor = 1
        if '$data(^IRISTemp("Loader")) {
            job ##class(Demo.HSAACreator).CreateAll(offset)
        }
    } catch (err) {
        kill %DemoMonitor
        set sc = $$$ADDSC(sc,err.AsStatus())
    }
    hang 5
    return sc
}

ClassMethod GetDirectoryCount(path) As %Integer
{
    set total = 0
    set st = ##class(%SQL.Statement).%New()
    do st.%PrepareClassQuery("%File", "FileSet")
    set rs = st.%Execute(path)
    while rs.%Next() {
        set total = $increment(total)
    }
    return total
}

ClassMethod GetStartTime() As %String
{
    return $horolog
}

ClassMethod GetExecTime(start As %Integer, type As %String = 1) As %String
{
    set response = ""
    try {
        set execTime = $System.SQL.DATEDIFF("ss",start,$horolog)
        if type = 1 {
            set response = ..FormatTime(execTime)
        } else {
            set response = execTime
        }
    } catch (err) {        
        set response = "error: "_$System.Status.GetErrorText(err.AsStatus())
    }
    return response
}

ClassMethod FormatTime(input As %Integer) As %String
{
    set response = ""
    try {
        if (input>86399) {
            set days = $$$FormatText("%1 day(s) ",input\86399)
            set time = input#86399
        } else {
            set days = ""
            set time = input
        } 
        set response = $$$FormatText("%1%2",days,$ztime(time,1))
    } catch (err) {        
        set response = "error: "_$System.Status.GetErrorText(err.AsStatus())
    }
    return response
}

}
