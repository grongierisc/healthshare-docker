/// 
Class Demo.Cube.DemoStageAnalyzer Extends %DeepSee.CubeDefinition [ DependsOn = Demo.Stage, ProcedureBlock ]
{

/// Cube definition from Architect.
XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube xmlns="http://www.intersystems.com/deepsee" name="DemoStageAnalyzer" displayName="DemoStageAnalyzer" disabled="false" abstract="false" sourceClass="Demo.Stage" namedFactNums="true" countMeasureName="%COUNT" bucketSize="8" bitmapChunkInMemory="false" precompute="0" disableListingGroups="false" enableSqlRestrict="false">
  <dimension name="Age" disabled="false" hasAll="false" allCaption="All DOB" allDisplayName="DOB" sourceProperty="DOB" type="age" calendar="gregorian" iKnowType="entity" hidden="false" showHierarchies="default">
    <hierarchy name="Age" disabled="false" hidden="false">
      <level name="Age" disabled="false" timeFunction="Years" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="2">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="Gender" disabled="false" hasAll="false" allCaption="All Gender" allDisplayName="Gender" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false" hidden="false">
      <level name="Gender" disabled="false" sourceProperty="Gender" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="3">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="Location" disabled="false" hasAll="false" allCaption="All County" allDisplayName="County" type="data" calendar="gregorian" iKnowType="entity" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false" hidden="false">
      <level name="County" disabled="false" sourceProperty="County" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="4">
      </level>
      <level name="City" disabled="false" sourceProperty="City" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="5">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="Date" disabled="false" hasAll="false" allCaption="All EntryDate" allDisplayName="EntryDate" sourceProperty="EntryDate" type="time" calendar="gregorian" iKnowType="entity" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false" hidden="false">
      <level name="Year" disabled="false" timeFunction="Year" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="6">
      </level>
      <level name="Month" disabled="false" timeFunction="MonthYear" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="7">
      </level>
      <level name="Day" disabled="false" timeFunction="DayMonthYear" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="8">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="PID" disabled="false" hasAll="false" allCaption="All PID" allDisplayName="PID" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false" hidden="false">
      <level name="PID" disabled="false" sourceProperty="PID" list="false" useDisplayValue="true" useAsFilter="true" hidden="false" factNumber="9">
      </level>
    </hierarchy>
  </dimension>
  <measure name="Positive" disabled="false" sourceProperty="Positive" aggregate="COUNT" type="boolean" hidden="false" searchable="false" factNumber="1">
  </measure>
  <measure name="Hospitalized" disabled="false" sourceProperty="Hospitalized" aggregate="COUNT" type="boolean" hidden="false" searchable="false" factNumber="2">
  </measure>
  <measure name="ICU" disabled="false" sourceProperty="ICU" aggregate="COUNT" type="boolean" hidden="false" searchable="false" factNumber="3">
  </measure>
  <measure name="Death" disabled="false" sourceProperty="Dead" aggregate="COUNT" type="boolean" hidden="false" searchable="false" factNumber="4">
  </measure>
  <measure name="Test" disabled="false" sourceProperty="Test" aggregate="COUNT" type="boolean" hidden="false" searchable="false" factNumber="5">
  </measure>
  <calculatedMember name="AgeGroup0to4" displayName="AgeGroup: 0-4" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[1], [Age].[Age].[Age].&amp;[2], [Age].[Age].[Age].&amp;[3], [Age].[Age].[Age].&amp;[4]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup5to9" displayName="AgeGroup: 5-9" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[5], [Age].[Age].[Age].&amp;[6], [Age].[Age].[Age].&amp;[7], [Age].[Age].[Age].&amp;[8], [Age].[Age].[Age].&amp;[9]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup10to14" displayName="AgeGroup: 10-14" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[10], [Age].[Age].[Age].&amp;[11], [Age].[Age].[Age].&amp;[12], [Age].[Age].[Age].&amp;[13], [Age].[Age].[Age].&amp;[14]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup15to19" displayName="AgeGroup: 15-19" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[15], [Age].[Age].[Age].&amp;[16], [Age].[Age].[Age].&amp;[17], [Age].[Age].[Age].&amp;[18], [Age].[Age].[Age].&amp;[19]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup20to29" displayName="AgeGroup: 20-29" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[20], [Age].[Age].[Age].&amp;[21], [Age].[Age].[Age].&amp;[22], [Age].[Age].[Age].&amp;[23], [Age].[Age].[Age].&amp;[24], [Age].[Age].[Age].&amp;[25], [Age].[Age].[Age].&amp;[26], [Age].[Age].[Age].&amp;[27], [Age].[Age].[Age].&amp;[28], [Age].[Age].[Age].&amp;[29]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup30to39" displayName="AgeGroup: 30-39" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[30], [Age].[Age].[Age].&amp;[31], [Age].[Age].[Age].&amp;[32], [Age].[Age].[Age].&amp;[33], [Age].[Age].[Age].&amp;[34], [Age].[Age].[Age].&amp;[35], [Age].[Age].[Age].&amp;[36], [Age].[Age].[Age].&amp;[37], [Age].[Age].[Age].&amp;[38], [Age].[Age].[Age].&amp;[39]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup40to49" displayName="AgeGroup: 40-49" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[40], [Age].[Age].[Age].&amp;[41], [Age].[Age].[Age].&amp;[42], [Age].[Age].[Age].&amp;[43], [Age].[Age].[Age].&amp;[44], [Age].[Age].[Age].&amp;[45], [Age].[Age].[Age].&amp;[46], [Age].[Age].[Age].&amp;[47], [Age].[Age].[Age].&amp;[48], [Age].[Age].[Age].&amp;[49]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup50to59" displayName="AgeGroup: 50-59" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[50], [Age].[Age].[Age].&amp;[51], [Age].[Age].[Age].&amp;[52], [Age].[Age].[Age].&amp;[53], [Age].[Age].[Age].&amp;[54], [Age].[Age].[Age].&amp;[55], [Age].[Age].[Age].&amp;[56], [Age].[Age].[Age].&amp;[57], [Age].[Age].[Age].&amp;[58], [Age].[Age].[Age].&amp;[59]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup60to69" displayName="AgeGroup: 60-69" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[60], [Age].[Age].[Age].&amp;[61], [Age].[Age].[Age].&amp;[62], [Age].[Age].[Age].&amp;[63], [Age].[Age].[Age].&amp;[64], [Age].[Age].[Age].&amp;[65], [Age].[Age].[Age].&amp;[66], [Age].[Age].[Age].&amp;[67], [Age].[Age].[Age].&amp;[68], [Age].[Age].[Age].&amp;[69]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroup70to79" displayName="AgeGroup: 70-79" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[70], [Age].[Age].[Age].&amp;[71], [Age].[Age].[Age].&amp;[72], [Age].[Age].[Age].&amp;[73], [Age].[Age].[Age].&amp;[74], [Age].[Age].[Age].&amp;[75], [Age].[Age].[Age].&amp;[76], [Age].[Age].[Age].&amp;[77], [Age].[Age].[Age].&amp;[78], [Age].[Age].[Age].&amp;[79]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="AgeGroupOver80" displayName="AgeGroup: 80+" disabled="false" dimension="Age" valueExpression="%OR({[Age].[Age].[Age].&amp;[80], [Age].[Age].[Age].&amp;[81], [Age].[Age].[Age].&amp;[82], [Age].[Age].[Age].&amp;[83], [Age].[Age].[Age].&amp;[84], [Age].[Age].[Age].&amp;[85], [Age].[Age].[Age].&amp;[86], [Age].[Age].[Age].&amp;[87], [Age].[Age].[Age].&amp;[88], [Age].[Age].[Age].&amp;[89], [Age].[Age].[Age].&amp;[90], [Age].[Age].[Age].&amp;[91], [Age].[Age].[Age].&amp;[92], [Age].[Age].[Age].&amp;[93], [Age].[Age].[Age].&amp;[94], [Age].[Age].[Age].&amp;[95], [Age].[Age].[Age].&amp;[96], [Age].[Age].[Age].&amp;[97], [Age].[Age].[Age].&amp;[98], [Age].[Age].[Age].&amp;[99], [Age].[Age].[Age].&amp;[100], [Age].[Age].[Age].&amp;[101], [Age].[Age].[Age].&amp;[102], [Age].[Age].[Age].&amp;[103], [Age].[Age].[Age].&amp;[104], [Age].[Age].[Age].&amp;[105]})" hidden="false">
  </calculatedMember>
  <calculatedMember name="Patients" disabled="false" dimension="Measures" valueExpression="COUNT([PID].[H1].[PID].MEMBERS,EXCLUDEEMPTY)
" hidden="false">
  </calculatedMember>
</cube>
}

Parameter DOMAIN;

}
