Include (HS.Common, %ZHSLIB, hslibBuild)

IncludeGenerator (%occInclude, hslibBuild)

/// Installation tools for HealthShare
Class HS.Util.Installer Extends HS.HC.Util.Installer
{

Parameter Version = {$$$HSLIBmajorVersion};

Parameter MaintenanceVersion = {$$$HSLIBminorVersion};

ClassMethod ResetDemo() As %Status
{
	Write !,*7,"***Use ResetAll or UnInstallAll instead, followed by Install, InstallDemo, or InstallBusDemo",!
	Quit
}

/// Utility method for resetting everything in a demo installation
ClassMethod ResetAll(interactive As %Boolean = 1) As %Status
{
	new $namespace
	if interactive {
		Write !,*7,"This method calls individual reset methods on each HealthShare namespace.",!
		Write "If any HealthShare namespace is on a remote instance, re-run this method on each instance.",!
		Write !,"This is a utility method for demonstration reset and may change at any time.",!
		Write "This utility is not intended to return the system to the exact state of InstallDemo()",!
		Read !,"Do you wish to continue (n/y) ?  ",tContinue
		If $E($zcvt(tContinue,"U"))'="Y" Quit $$$OK
	}
	s $namespace="HSLIB" D ##CLASS(HS.Director).StopAll() 
	s pns="" 
	f  {
		s pns=$o(^%SYS("HealthShare","Instances",pns)) quit:pns=""  
		w !,pns s type=^%SYS("HealthShare","Instances",pns,"Type") w type 
		s installer = $p($lg(^%SYS("HealthShare","Instances",pns),1),"~",*-1) w installer
		s $namespace=pns d $classmethod(installer,"Reset")
	}
	D ##CLASS(HS.Director).StartAll() 
	Quit $$$OK
}

/// Interactive method to allow selective installation of demo components.  Can be called instead of
/// InstallDemo() or InstallBusDemo() for more fine grained control.
/// This requires a license to the Composite Health Record
ClassMethod Install()
{
	// Check if this method can be run on this instance (may have restrictions due to kit type)
	If '##class(%ZHSLIB.KitManager).HasAccessTo(.errorMessage, $Classname(), "Methods", "Install") {
		Write !, errorMessage
		Return $$$ERROR($$$GeneralError, errorMessage)
	}
	If '..CheckGetKey() {write !!,"License key not present, cannot install HealthShare" Quit}
	If '$$$HSLicensed("Composite Health Record") {Write !!,"Invalid License key" Quit}
	Read !,"Install Bus? No//",tAns
	Set:tAns="" tAns="N"
	If $E($zcvt(tAns,"U"),1)="Y" Set tVars("BUS")=1
	If $G(tVars("BUS")) {
		Read !,"Install XCA? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("XCAEQ")=1
	}
	If $G(tVars("XCAEQ")) {
		Set tVars("XDSb.Registry")=1,tVars("XDSb.Repository")=1
		Set tVars("XDS.NotifyAndQuery")=1,tVars("DSUB")=1
		Set tVars("OnDemand")=1
		Set:'$D(tVars("XCAHost")) tVars("XCAHost")=$ZCVT($$$HSNetworkHostName,"L")
		Write !?5,"XCA Host: ",tVars("XCAHost")," // " Read tAns
		Set:tAns'="" tVars("XCAHost")=tAns
		Read !?5,"XCA Port: ",tAns
		Set:tAns'="" tVars("XCAPort")=tAns
		Read !?5,"Use Alternate XCA OIDS? N // ",tAns
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("XCAAlt")=1
	}
	If $$$HSLicensed("Patient Index") {
		Read !,"Install Patient Index? No//",tAns
	} Else {Set tAns=""}
	Set:tAns="" tAns="N"
	If $E($zcvt(tAns,"U"),1)="Y" { Set tVars("HSPI")=1 }
	
	
	Read !,"Install Usage Dashboards? No//",tAns
	Set:tAns="" tAns="N" 
	If $E($zcvt(tAns,"U"),1)="Y"{ 
		Set tVars("OperationalDashboards")=1
	}

	If $$$HSLicensed("Composite Health Record"),$$$HSLicensed("Clinical Message Delivery") {
		Read !,"Install XDSb Stable/OnDemand Document Push? No//",tAns
	} Else {Set tAns=""}
	Set:tAns="" tAns="N"
	If $E($zcvt(tAns,"U"),1)="Y" {
		Set tVars("XDSb.Push")=1
		Set tVars("Push")=1 Write !,"Adding required Push Demo Data"
		Set tVars("XDSb.Registry")=1
		Set tVars("XDSb.Repository")=1 Write !,"Adding required XDSb Registry and Repository"
		Set tVars("OnDemand")=1
		Write !,"Adding required PIX / PDQ"  //which is required by XDSb Registry
	}

	If '$G(tVars("XDSb.Registry")) {
		Read !,"Install XDSb Registry and Repository? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("XDSb.Registry")=1,tVars("XDSb.Repository")=1 Write !,"Adding required PIX / PDQ"
	}
	
	If '$G(tVars("XDS.NotifyAndQuery")),$G(tVars("XDSb.Repository"))=1 {
		// No longer asking if NotifyAndQuery, always set it up
		Set tVars("XDS.NotifyAndQuery")=1,tVars("DSUB")=1 Write !,"Adding required DSUB"
	}
	
	#; if we install Notify and Query XDS Repository then DSUB is automatically included
	If '$G(tVars("DSUB")) {
		Read !,"Install DSUB Broker? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("DSUB")=1
	}
		
	#; if we install registry we automatically do PIX/PDQ
	If '$G(tVars("XDSb.Registry")) {
		Read !,"Install PIX / PDQ? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("PIXPDQ")=1
	}	
	
	If '$G(tVars("XDR.Direct")),$$$HSLicensed("Clinical Message Delivery") {
		Read !,"Install XDR Direct Recipient Service? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("XDR.Direct")=1
	}		

	If '$G(tVars("AnalyticsIntegration")),$$$HSLicensed("Active Analytics"),$$$CheckComponentStatus("HSAALIB") {
		Read !,"Install Analytics Integration? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y"{
			Set tVars("AnalyticsIntegration")=1
		}
	}

	#; Ask for BPPC if registry (and thus PIXPDQ) is enabled
	If $G(tVars("XDSb.Registry")) {
		Read !,"Install BPPC? No//",tAns
		Set tVars("BPPC")=$E($zcvt(tAns,"U"),1)="Y"
	}
	
	// Setup XUA Configuration 
	If $G(tVars("PIXPDQ"))||($G(tVars("XDSb.Registry"))) {
		Read !,"Install XUA? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y" Set tVars("XUA")=1
	}
	

	Read !,"Add Trace Operations (debugging)? No//",tAns
	Set:tAns="" tAns="N"
	If $E($zcvt(tAns,"U"),1)="Y" Set tVars("Trace")=1
	
	If '$G(tVars("Push")),$$$HSLicensed("Clinical Message Delivery") {
		Read !,"Add Push Demo Data? No//",tAns
		Set tVars("Push")=$E($zcvt(tAns,"U"),1)="Y"
	}
	
	If '$G(tVars("MU2Demo")),$$$HSLicensed("Clinical Message Delivery") {
		Read !,"Set up Immunization, Surveillance, and Lab Reporting Demo? No//",tAns
		Set tVars("MU2Demo")=$E($zcvt(tAns,"U"),1)="Y"
		If tVars("MU2Demo")&&'$G(tVars("Push")) Set tVars("Push")=1 Write !,"Adding required Push Demo Data"
	}
	
	Read !,"Set up eHealth Global demo? No//",tAns
	Set:tAns="" tAns="N" 
	If $E($zcvt(tAns,"U"),1)="Y"{
		Set tVars("eHGT")=1
	}
	
	If '$G(tVars("X12Integration")) {
		Read !,"Install X12 Integration? No//",tAns
		Set:tAns="" tAns="N"
		If $E($zcvt(tAns,"U"),1)="Y"{
			Set tVars("X12Integration")=1
		}
	}
	
	Read !,"Set the Registry as the Audit Production? Yes//",tAns
	Set:tAns="" tAns="Y"
	Set tVars("HubAuditProduction")=$E($ZCVT(tAns,"U"))="Y"
	
	Read !,"Continue with Installation? Yes//",tAns
	Set:tAns="" tAns="Y"
	If $E($zcvt(tAns,"U"))'="Y" Quit
	Set tSC = ..InstallSample(.tVars)
	IF $$$ISERR(tSC) W !,$system.Status.DisplayError(tSC)
	Do:$$$ISOK(tSC) ..Notes()
}

/// Install a basic demo system, without IHE components.
/// This requires a license to the Composite Health Record
/// <p>At the conclusion of the installation, Notes are displayed
/// in an interactive fashion. To supress the display of the notes,
/// set <var>pInteractive</var> to 0.
ClassMethod InstallDemo(ByRef pOptions, pInteractive As %Boolean = 1) As %Status
{
	// Check if this method can be run on this instance (may have restrictions due to kit type)
	If '##class(%ZHSLIB.KitManager).HasAccessTo(.errorMessage, $Classname(), "Methods", "InstallDemo") {
		Write !, errorMessage
		Return $$$ERROR($$$GeneralError, errorMessage)
	}
	If '..CheckGetKey() {write !!,"License key not present, cannot install HealthShare" Quit}
	If '$$$HSLicensed("Composite Health Record") {Write !!,"Invalid License key" Quit}
	If '$D(pOptions) {
		Set pOptions("Push")=1
	}
	Set:'$D(pOptions("HubAuditProduction")) pOptions("HubAuditProduction")=1
	Set:'$D(pOptions("OperationalDashboards")) pOptions("OperationalDashboards")=1
	If '$$$HSLicensed("Clinical Message Delivery") Kill pOptions("Push")
	If '$$$HSLicensed("Active Analytics")||'$$$CheckComponentStatus("HSAALIB") {
		Kill pOptions("AnalyticsIntegration")
	}
	Else {
		Set pOptions("AnalyticsIntegration")=1
	}
	Set tSC = ..InstallSample(.pOptions)
	if $$$ISERR(tSC) {
		write !!,$system.Status.DisplayError(tSC)
 	} elseif pInteractive { Do ..Notes() }
	quit tSC
}

/// Install a demo system including IHE components.
/// This requires a license to the Composite Health Record.
/// <p>At the conclusion of the installation, Notes are displayed
/// in an interactive fashion. To supress the display of the notes,
/// set <var>pInteractive</var> to 0.
ClassMethod InstallBusDemo(ByRef pOptions, pInteractive As %Boolean = 1) As %Status
{
	// Check if this method can be run on this instance (may have restrictions due to kit type)
	If '##class(%ZHSLIB.KitManager).HasAccessTo(.errorMessage, $Classname(), "Methods", "InstallBusDemo") {
		Write !, errorMessage
		Return $$$ERROR($$$GeneralError, errorMessage)
	}
	#; if pOptions is not defined we this is not being run from .Install() set common options
	If '..CheckGetKey() {write !!,"License key not present, cannot install HealthShare" Quit}
	If '$$$HSLicensed("Composite Health Record") {Write !!,"Invalid License key" Quit}
	If '$D(pOptions) {
		Set pOptions("BUS")=1
		Set pOptions("XCAEQ")=1
		Set pOptions("PIXPDQ")=1
		Set pOptions("XDSb.Registry")=1
		Set pOptions("XDSb.Repository")=1
		Set pOptions("Push")=1
		Set pOptions("DSUB")=1
		Set pOptions("OnDemand")=1
		Set pOptions("XDR.Direct")=1
		Set pOptions("XDS.NotifyAndQuery")=1
		Set pOptions("HubAuditProduction")=1
		Set pOptions("OperationalDashboards")=1
	}
	If '$$$HSLicensed("Clinical Message Delivery") Kill pOptions("Push"),pOptions("XDR.Direct")
	If '$$$HSLicensed("Clinical Message Delivery")||('$$$HSLicensed("Composite Health Record")) Kill pOptions("OnDemand")
	If '$$$HSLicensed("Active Analytics")||'$$$CheckComponentStatus("HSAALIB") {
		Kill pOptions("AnalyticsIntegration")
	}
	Else {
		Set pOptions("AnalyticsIntegration")=1
	}	
	Set tSC = ..InstallSample(.pOptions)
	if $$$ISERR(tSC) {
		write !!,$system.Status.DisplayError(tSC)
 	} elseif pInteractive { Do ..Notes() }
 	quit tSC
}

ClassMethod InstallSample(ByRef pOptions) As %Status
{
	Set pOptions("nothing")=1 ; make sure there's something in the array
	If $G(pOptions("XCAEQ")) {
		Set:$G(pOptions("XCAPort"))="" pOptions("XCAPort")="999999"
		Set:$G(pOptions("XCAHost"))="" pOptions("XCAHost")=$ZCVT($$$HSNetworkHostName,"L")
	}
	// if install health insight and want to push demo data, set PushHSAAUsers to 1
	if $G(pOptions("AnalyticsIntegration"))&&$G(pOptions("Push")) {Set pOptions("PushHSAAUsers")=1}
	//tweak the options to handle the subtleties of MPI secondary operations
	If $G(pOptions("XCA"))&&'$G(pOptions("XDS.NotifyAndQuery")) {Set pOptions("SecondaryXDSXCA")=1}
	ElseIf $G(pOptions("XCAEQ"))&&'$G(pOptions("XDS.NotifyAndQuery")) {Set pOptions("SecondaryXDSXCAEQ")=1}
	ElseIf $G(pOptions("XCA")) {Set pOptions("SecondaryXCA")=1}
	ElseIf $G(pOptions("XCAEQ")) {Set pOptions("SecondaryXCAEQ")=1}
	ElseIf $G(pOptions("XDS.NotifyAndQuery")) {Set pOptions("SecondaryXDS")=1}
	Set tSC= ##class(HS.Util.Installer.Kit.SampleDefinition).Install(.pOptions) Quit:$$$ISERR(tSC) tSC
	If $G(pOptions("XCAEQ")) {
		Set $namespace="HSREGISTRY"
		Set tSC = ##class(HS.Util.Installer.Kit.PostInstall.Demo.SetupXCA).RunHub(,$G(pOptions("XCAHost")),$G(pOptions("XCAPort")),$G(pOptions("XCAAlt")))
	}
	Quit tSC
}

ClassMethod Notes()
{
	set dir=##class(%File).NormalizeDirectory($system.Util.InstallDirectory()_"\Data")
	do ..DisplayNotes("DemoIntro",dir)
	read !?60,"<Enter>",y
	do ..DisplayNotes("DemoNotes",dir)
}

ClassMethod SetupPush(pNamespace As %String, pDemo As %Boolean) As %Status
{
	Write !,"Set up Push"
	Set tSC=##class(HS.Util.Installer.Hub).SetupPush(pNamespace,$P(pDemo,"^",2))
	Do ##class(HS.Util.Installer).Log(.tLogFile,"HS.Util.Installer.Hub","Install","Set up Push")
	Quit tSC
}

ClassMethod SetupFacility(pCode, pName, pExternalOrGateway) As %Status
{
	If ##class(HS.Facility.Config).%ExistsId(pCode) Quit $$$OK

	Write !,"Setup facility "_pCode
	Set tFacility=##class(HS.Facility.Config).%New()
	Set tFacility.FacilityCode=pCode
	Set tFacility.Name=pName
	If pExternalOrGateway = 1 {
		Set tFacility.ExternalHIE = 1
	} Else {
		Set tSC = ##class(HS.Gateway.Config).FindByName(pExternalOrGateway, .tGWID) Quit:$$$ISERR(tSC) tSC
		If tGWID="" Quit $$$ERROR($$$GeneralError,"Gateway not found: "_pExternalOrGateway) 
		Do tFacility.GatewaySetObjectId(tGWID)
	}
	Quit tFacility.%Save()
}

ClassMethod DisplayNotes(pXdata As %String = "DemoNotes", p1 As %String = "")
{
 if p1="" set p1=##class(%File).NormalizeDirectory($system.Util.InstallDirectory()_"\Data")
 set tSC=##class(Ens.Util.URLStream).GetURLStream("xdata://HS.Util.Installer:"_pXdata, .notes) Quit:$$$ISERR(tSC)
 set note=notes.Read(32000),note=$p(note,"<text>",2,99999),note=$p(note,"</text>")
 while note["{p1}" {set note=$p(note,"{p1}")_p1_$p(note,"{p1}",2,99999)}
 while $l(note) {
	set n1=$p(note,$c(13,10),1,24),note=$p(note,$c(13,10),25,99999)
	write !,n1
	if $l(note) read !?60,"<Enter>",y
 }
}

/// Install/Update (activate) a Hub in pNamespace
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallHub(pNamespace As %String, ByRef pVars) As %Status
{
	set tSC=##class(HS.Util.Installer.Hub).Install(pNamespace,.pVars)
	quit tSC
}

/// Install/Update (activate) a Bus in pNamespace
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallBus(pNamespace As %String, ByRef pVars) As %Status
{
	set tSC=##class(HS.Util.Installer.Bus).Install(pNamespace,.pVars)
	quit tSC
}

/// Install/Update (activate) an Access Gateway in pNamespace
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallAccessGateway(pNamespace As %String, ByRef pVars) As %Status
{
	set tSC=##class(HS.Util.Installer.AccessGateway).Install(pNamespace,.pVars)
	quit tSC
}

/// Install/Update (activate) an Edge Gateway in pNamespace
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallEdgeGateway(pNamespace As %String, ByRef pVars) As %Status
{
	set tSC=##class(HS.Util.Installer.EdgeGateway).Install(pNamespace,.pVars)
	quit tSC
}

/// Install/Update (activate) an ODS in pNamespace
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallODS(pNamespace As %String, ByRef pVars) As %Status
{
	set tSC=##class(HS.Util.Installer.FlashGateway).Install(pNamespace,.pVars)
	quit tSC
}

/// Install/Update (activate)  in pNamespace.
/// pVars allows you to override/change configuration parameters, which
/// will be updated in the HS.Util.Installer.ConfigItem database
ClassMethod InstallOperationalDashboards(pNamespace As %String = "", ByRef pVars) As %Status
{
	set tSC=##class(HSMOD.OperationalReporting.Installer.ReportingConfigItem).Install(pNamespace,.pVars)
	quit tSC
}

/// Uninstall all HealthShare components for this HSLIB
ClassMethod UnInstallAll(pPurgeFiles As %Boolean = 1) As %Status
{
	set tSC=$$$OK,$ZT="Trap"
	do {
	
		Write !,*7,"This method uninstalls each HealthShare component namespace.",!  // character *7 is BELL
		Write "If any HealthShare namespace is on a remote instance, re-run this method on each instance.",! 
		
		Read !,"Are you sure you want to uninstall all Healthshare components? No//",tAns
		Quit:$E($zcvt(tAns,"U"))'="Y"

		Set tSC= ##class(HS.Director).GetProductionList(##class(HS.Director).PRODUCTIONSTOPORDER(),.tList,0)
		Quit:$$$ISERR(tSC)
		Set (tGroup,tItem)=""
		For  {
			Set tGroup=$O(tList("O",tGroup)) Quit:tGroup=""
			For  {
				Set tItem=$O(tList("O",tGroup,tItem)) Quit:tItem=""
				Set tComponent = tList("O",tGroup,tItem)
				Set tConfigItem=##class(HS.Util.Installer.ConfigItem).%OpenId(tComponent.Name)
				If $IsObject(tConfigItem),tConfigItem.LastActivated="" Continue
				Set tSC2 = tComponent.UnInstall(tComponent.Name,pPurgeFiles)
				Set:$$$ISERR(tSC2) tSC = $$$ADDSC(tSC,tSC2)		

			}
		}
		Do ..DeleteOutstandingApps()
		Do ##class(HS.Util.Installer.ConfigItem).UnMapAllAuditDB(1)		
		Set tSC=##class(HS.Util.Installer.ConfigItem).DeleteHSAUDIT() Quit:$$$ISERR(tSC)
		If pPurgeFiles,'$system.Mirror.IsMember() Do ##class(HS.Util.Installer.ConfigItem).ClearSystemAPI()

	} while (0)
Exit
	quit tSC
Trap
	set $ZT="",tSC=$$$EnsSystemError
	goto Exit
}

/// method is not mirror aware, only done on uninstallall
ClassMethod DeleteOutstandingApps()
{
	New $namespace
	Set $namespace="%SYS"
	Set tRS=##Class(%ResultSet).%New()
	Set tRS.ClassName="Security.Applications"
	Set tRS.QueryName="List"
	Set tSC=tRS.Execute("*",2) Quit:$$$ISERR(tSC) tSC  /// list all CSP apps
	While tRS.Next() {
		Set tApp=tRS.Data("Name")
		Set tSC=##Class(Security.Applications).Get(tApp,.tProps) Quit:$$$ISERR(tSC)
		Set tNS=$G(tProps("NameSpace"))
		#; if the namespace exists we're good
		If tNS="" || (##CLASS(Config.Namespaces).Exists(tNS)) Continue
		Set tSC=##Class(Security.Applications).Delete(tApp) Quit:$$$ISERR(tSC)
	}
	Quit $$$OK
}

/// Create a directory
/// Deprecated - do not use
ClassMethod CreateDir(pPath As %String) As %Status
{
 set tSC=$$$OK
 set tOK=##class(%File).CreateDirectoryChain(pPath)  
 if 'tOK set tSC=$$$ERROR($$$DirectoryCannotCreate,pPath)
 quit tSC
}

/// Copy a directory
/// Deprecated - do not use
ClassMethod CopyDir(pSrc As %String, pTarget As %String) As %Status
{
 set %objlasterror = $$$OK,tSC=$$$OK
 set tOK=##class(%File).CopyDir(pSrc, pTarget,1)
 if 'tOK {
	if $$$ISERR(%objlasterror) {set tSC=%objlasterror}
	else {set tSC=$$$ERROR($$$FileCanNotCopy,pSrc,pTarget)}
 }
 quit tSC
}

/// Copy a file
ClassMethod CopyFile(pSrc As %String, pTarget As %String) As %Status
{
 set tSC=$$$OK
 set tOK=$zu(140,11,pSrc,pTarget) // 0 = success
 if tOK'=0 set tSC=$$$ERROR($$$FileCanNotCopy,pSrc,pTarget)
 quit tSC
}

XData DemoIntro
{
<text>
The HealthShare demo system is installed and running.
To process HL7v2.5, copy the files (for example *.hl7 from {p1})
into {p1}HSEDGE1\HL7In (or HSEDGE2)
To process SDA, copy the files (for example *.xml from {p1})
into {p1}HSEDGE1\SDAIn (or HSEDGE2)
To process X12, copy the files (for example *.x12 from {p1})
into {p1}HSEDGE1\X12In (or HSEDGE2)

Here are some notes about the data for demos (use Terminal logging to
save/print this info):
</text>
}

XData DemoNotes
{
<text>
If you run ##class(HS.Util.Installer).InstallDemo() the system will
now create 4 gateways, HSREGISTRY, HSACCESS, HSEDGE1, and HSEDGE2.
HSEDGE1 and HSEDGE2 will accept HL7 v2.5 messages or SDA XML messages.

InstallDemo() will also run
  ##class(HS.Util.SampleData.HL7Scenarios).BuildScenarios()
and
  ##class(HS.Util.SampleData.SDAScenarios).BuildScenarios()
which will create HL7 and SDA data files in {p1}.
You can modify these methods and rerun them at any time.

HL7Scenarios creates HL7 messages for 5 patients:

1. John Smith has two different MRN's at the facility PHLS,
   one at HC6 and one at CGH.
   He had 5 encounters at these 3 facilities during October 2008.
   (Icons): He has Abnormal Results and Allergies.
   He seems to be Diabetic, with a heart problem.
   He has Notes, Lab Results (CBC and Glucose, across
   facilities), Radiology (Angiography with short test result),
   Medications, Diagnoses, and Graphed Physical Exams (Vital
   signs).
   
2. Harold Simpson was brought by ambulance to an Emergency facility
   in September 2008, after he fell and hit his head.  He was treated
   in the Emergency room and then admitted for a 7-day stay. 
   A Radiology CAT scan showed major cerebral problems.
   There are several Documents describing his treatment and some
   Lab Results, Medications, and Physical Exams.
  
3. Eric Johnson had an outpatient visit to the Emergency facility in
   2007, followed by an outpatient consult at the CGH hospital and
   a short inpatient stay there.
   Then in 2008 he was treated at the Emergency department of CGH,
   after experiencing chest pain while out shopping.
   He is Allergic to Penicillin.
   He had a history of Diabetes, but not of Cardiac problems.
   Lab Tests CBC and Coags showed some abnormalities.
   Physical exams are recorded.
   He was diagnosed with Acute myocardial infarction, but he was given
   only Aspirin! 

4. Marla Gonzalez is back!
   In the Patient Search, enter Gonzalez and First-Name="M" (only).
   Then you will see 2 records for Marla linked together from different
   facilities (UMC and SDA), and an older record of an M.Gonzalez with
   the same DOB but no address, from an encounter at MGH in 2005.
   Probably the same, so select both.
   Most of this record contains real data from a (cardiac) patient,
   de-identified of course, and comes from the SDA ScenarioB.
   Marla is Allergic to seafood, and she has a range of Medical-, Social-
   and Family-History.
   She has some Documents concerning take-home medications and
   appointments.
   There is a small set of Lab Results, and 3 Radiology tests, each with
   a report.
   She has a lot of Medications.
   The Discharge Summary is an example of a PDF sent via a message and
   embedded in the HS database (as opposed to accessed via a URL), and the
   summary (now) matches the orders and results listed, and includes a
   copy of her ECG.

5. M. Gonzalez
   This is Marla's old record from MGH in 2005.
   At that time she was diagnosed with Hypertensive Heart Disease and
   underwent a Cholecystectomy.
   Under Notes, there is a photo jpg accessed via a URL, so you can confirm
   that this is indeed Marla.
   There is also a recording of her heartbeat (.wav) file URL, dating
   from this visit.


SDAScenarios creates SDA messages for 2 patients:

A. Steve Burns
   This is an actual record from a live database, de-identified.
   Steve is a baby boy with heart problems.
   He has been to the SDA hospital 5 times in 2008.
   He is Allergic to chicken and smoke, which causes him severe problems.
   His family has a history of heart disease.
   He was diagnosed with Congenital Malformation of Heart, and given a range
   of Medications to alleviate the symptoms.
   
B. Marla Gonzalez, as described above in HL7 scenario 4

Push

Sample push subscriptions may also be included.  Notifications of all
transactions in all scenarios will be sent to a Sample receiving system 
via CCD records output to files in {p1}HSACCESS\OUT.  
HL7 files will be created in that directory for Lab results.  
 
Notifications will also be sent in HL7 scenario #1 to the the clinical message
center and GMail account of Sam Farrell, the attending doctor for John Smith. 
You can log on as user sfarrell/demo to access Sam's clinical message center.
To read e-mail, log on to GMail with a username/password of hsdemo0/hspassword.
[For now you will need to be connected to ISC's exchange server for the 
e-mails to be sent.]

If you would like to demonstrate PDF files, you will need to change the 
delivery policy of the Alternate Clinician Policy for Sam Farrell to Alternate 
Policy (PDF).

Additional subscription policies are also loaded for the receiving
system as well as for individual and all clinicians.  These can be used for 
demonstrating additional system capabilities.

XDR.Direct

Running InstallBusDemo() will create a service to receive direct emails into the
clinical message center in the HSEDGE1 namespace, HS.Direct.SMTP.Services.
This is disabled by default.  If you want to use it, you'll need to enable it, and 
set it up to filter the emails so that only your emails get read in.  You can
modify the MatchFrom to contain something from your From account, or instead use
the MatchTo combined with a to address that ends in "+" followed by some string.
To demonstrate this, after doing the above changes, send an email to two addresses:
isc.direct.demo@gmail.com and hsdemo0.direct@gmail.com.  Attach a C-CDA document.

Feedback, comments and notification of errors and suggestions are welcome. 
</text>
}

}
