Class FHIRTOSDA.Production Extends Ens.Production [ Not ProcedureBlock ]
{

XData ProductionDefinition
{
<Production Name="FHIRTOSDA.Production" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="Ens.Activity.Operation.Local" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="HS.FHIR.DTL.Util.HC.FHIR.SDA3.Process" Category="" ClassName="HS.FHIR.DTL.Util.HC.FHIR.SDA3.Process" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigName">FHIRTOSDA.File.Operation</Setting>
    <Setting Target="Host" Name="OutputToQuickStream">1</Setting>
    <Setting Target="Host" Name="FHIRMetadataSet">HL7v40 / Base HL7 Metadata for FHIR R4 (4.0.1)</Setting>
    <Setting Target="Host" Name="TransformClass">FHIRTOSDA.Transformer</Setting>
  </Item>
  <Item Name="FHIRTOSDA.File.Service" Category="" ClassName="FHIRTOSDA.File.Service" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">HS.FHIR.DTL.Util.HC.FHIR.SDA3.Process</Setting>
    <Setting Target="Adapter" Name="FilePath">/tmp/fhir-r4-to-sda3/in/</Setting>
  </Item>
  <Item Name="FHIRTOSDA.File.Operation" Category="" ClassName="FHIRTOSDA.File.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">../../Data/HSEDGE1/SDAIn/</Setting>
    <Setting Target="Adapter" Name="ArchivePath">/tmp/fhir-r4-to-sda3/out/</Setting>
  </Item>
</Production>
}

}
