# healthshare-docker

## Defintion of directory

* distrib
    * where you put the tar.gz distribution package on redhat
    * eg : **HealthShare_UnifiedCareRecord_Insight_PatientIndex-2020.1-7015-0-lnxrhx64.tar.gz**

* keys
    * where you put your license key
    * eg : **iris.key** 
    
## Build the solution 

If experimental is enable 

````sh
docker build --build-arg HS_DIST=HealthShare_UnifiedCareRecord_Insight_PatientIndex-2020.1-7015-0-lnxrhx64.tar.gz --build-arg HS_KEY=iris.key --squash -t ucr:2020.1 .
````

else 

````sh
docker build --build-arg HS_DIST=HealthShare_UnifiedCareRecord_Insight_PatientIndex-2020.1-7015-0-lnxrhx64.tar.gz --build-arg HS_KEY=iris.key -t ucr:2020.1 .
````

## Build all

````sh
docker-compose build
````

## Setup

### /!\ For OSX and Windows /!\

Configure hostname of dockers as :
````objectscript
zn "%SYS"
Set ^%SYS("HealthShare","NetworkHostName")="host.docker.internal"
````
### UCR demo :

Open WebTerminal :

http://localhost:52773/terminal/

#### Automatique
````objectscript
zn "HSLIB"
do ##class(HS.Util.Installer).InstallDemo()
````
#### Manual 

Example :

* Install Bus? No//
* Install Patient Index? No//Yes
* Install Usage Dashboards? No//Yes
* Install XDSb Stable/OnDemand Document Push? No//
* Install XDSb Registry and Repository? No//
* Install DSUB Broker? No//
* Install PIX / PDQ? No//
* Install XDR Direct Recipient Service? No//
* Install Analytics Integration? No//Yes
* Add Trace Operations (debugging)? No//Yes
* Add Push Demo Data? No//Yes
* Set up Immunization, Surveillance, and Lab Reporting Demo? No//
* Set up eHealth Global demo? No//
* Install X12 Integration? No//
* Set the Registry as the Audit Production? Yes//
* Continue installation ?Yes//
````objectscript
zn "HSLIB"
do ##class(HS.Util.Installer).Install()

Yes
Yes





Yes
Yes
Yes

Yes



````

### MPI Lite

MPI Lite is the MPI embeded in the registry not in a different namespace.

````objectscript
zn "HSREGISTRY"
do ##class(HS.Util.Installer.Kit.HSPI).AddHub()
````

### ClinicalViewer

Open WebTerminal :

http://localhost:42773/terminal/

````objectscript
zn "VIEWERLIB"
do ##class(Viewer.Util.Installer).InstallCVDemo("RegistryHost", RegistryPort ) 
````

For OSX and Windows :

* "RegistryHost" = host.docker.internal
* RegistryPort = 52773

For Linux :

* "RegistryHost" = ucr
* RegistryPort = 52773

### Add data

#### Custom
````sh
cp /tmp/misc/hl7/CommunityHospital_Patients_500.dat /usr/healthshare/Data/HSEDGE1/HL7In
cp /tmp/misc/hl7/MercySouth_Patients_500.dat /usr/healthshare/Data/HSEDGE2/HL7In
````

#### Embeded
If you run ##class(HS.Util.Installer).InstallDemo() the system will
now create 4 gateways, HSREGISTRY, HSACCESS, HSEDGE1, and HSEDGE2.
HSEDGE1 and HSEDGE2 will accept HL7 v2.5 messages or SDA XML messages.

InstallDemo() will also run
  ##class(HS.Util.SampleData.HL7Scenarios).BuildScenarios()
and
  ##class(HS.Util.SampleData.SDAScenarios).BuildScenarios()
which will create HL7 and SDA data files in /usr/healthshare/Data/.
You can modify these methods and rerun them at any time.

To process HL7v2.5, copy the files (for example *.hl7 from /usr/healthshare/Data/)
into /usr/healthshare/Data/HSEDGE1/HL7In (or HSEDGE2)
````sh
cp /usr/healthshare/Data/*.hl7 /usr/healthshare/Data/HSEDGE1/HL7In
````
To process SDA, copy the files (for example *.xml from /usr/healthshare/Data/)
into /usr/healthshare/Data/HSEDGE1\SDAIn (or HSEDGE2)
````sh
cp /usr/healthshare/Data/*.xml /usr/healthshare/Data/HSEDGE1/SDAIn
````
To process X12, copy the files (for example *.x12 from /usr/healthshare/Data/)
into /usr/healthshare/Data/HSEDGE1\X12In (or HSEDGE2)
````sh
cp /usr/healthshare/Data/*.x12 /usr/healthshare/Data/HSEDGE1/X12In
````

### HL7Scenarios creates HL7 messages for 5 patients:

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
   Then you will see **2 records** for Marla linked together from different
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

### SDAScenarios creates SDA messages for 2 patients:

A. Steve Burns
   This is an actual record from a live database, de-identified.
   Steve is a baby boy with heart problems.
   He has been to the SDA hospital 5 times in 2008.
   He is Allergic to chicken and smoke, which causes him severe problems.
   His family has a history of heart disease.
   He was diagnosed with Congenital Malformation of Heart, and given a range
   of Medications to alleviate the symptoms.
   
B. Marla Gonzalez, as described above in HL7 scenario 4

### Push

Sample push subscriptions may also be included.  Notifications of all
transactions in all scenarios will be sent to a Sample receiving system 
via CCD records output to files in /usr/healthshare/Data/HSACCESS\OUT.  
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

### XDR.Direct

Running InstallBusDemo() will create a service to receive direct emails into the
clinical message center in the HSEDGE1 namespace, HS.Direct.SMTP.Services.
This is disabled by default.  If you want to use it, you'll need to enable it, and 
set it up to filter the emails so that only your emails get read in.  You can
modify the MatchFrom to contain something from your From account, or instead use
the MatchTo combined with a to address that ends in "+" followed by some string.
To demonstrate this, after doing the above changes, send an email to two addresses:
isc.direct.demo@gmail.com and hsdemo0.direct@gmail.com.  Attach a C-CDA document.

Feedback, comments and notification of errors and suggestions are welcome. 
