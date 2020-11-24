open PipelineDialog
open Util
open Schema
open Belt

module DataCorruption = {
  @react.component
  let make = (~formattedErrorText: string, ~closeCancel: unit => _) =>
    <PipelineDialog
      header=`Data Corruption`
      actionButtons=[
        <CancelButton onClick=closeCancel> {s(`Ok, We'll Fix It 😔`)} </CancelButton>,
      ]
      closeCancel>
      <Subheading>
        {`Review these items and make the necessary corrections to move on`->s}
      </Subheading>
      <pre> {formattedErrorText->s} </pre>
    </PipelineDialog>
}

module ReceiveUnserialedSku = {
  @react.component
  let make = (
    ~tracking: skuOrderTrackingRecord,
    ~skuOrder: skuOrderRecord,
    ~sku: skuRecord,
    ~skuReceivingQtyStr: string,
    ~onSkuReceivingQtyChange: ReactEvent.Form.t => unit,
    ~skuReceivingNotes: string,
    ~onSkuReceivingNotesChange: ReactEvent.Form.t => unit,
    ~closeCancel: unit => unit,
    ~saveClose: unit => unit,
    ~saveContinue: unit => unit,
  ) =>
    <PipelineDialog
      header={`Receive & QC: ${sku.skuName.read()}`}
      actionButtons=[
        <CancelButton onClick=closeCancel> {s(`Cancel`)} </CancelButton>,
        <SecondarySaveButton onClick=saveClose> {s(`Save and Close`)} </SecondarySaveButton>,
        <PrimarySaveButton onClick=saveContinue> {s(`Save and Continue`)} </PrimarySaveButton>,
      ]
      closeCancel>
      <Subheading> {`Tracking Number Receiving Notes`->s} </Subheading>
      {tracking.jocoNotes.render()}
      <VSpace px=20 />
      <Table
        rowId={() => `1`}
        elements=[()]
        columnDefs=[
          {
            header: `SKU`,
            accessor: () => sku.skuName.read()->s,
            tdStyle: ReactDOM.Style.make(),
          },
          {
            header: `Expected`,
            accessor: () => skuOrder.quantityExpected.read()->itos,
            tdStyle: ReactDOM.Style.make(~fontSize="1.5em", ()),
          },
          {
            header: `Qty To Receive`,
            accessor: () =>
              <input
                onChange=onSkuReceivingQtyChange
                type_="number"
                value={skuReceivingQtyStr}
                style={ReactDOM.Style.make(~fontSize="1.5em", ~width="77px", ())}
              />, //skuReceivingQtyInput,
            tdStyle: ReactDOM.Style.make(~width="88px", ()),
          },
          {
            header: `QC/Receiving Notes`,
            accessor: () =>
              <textarea
                style={ReactDOM.Style.make(~width="100%", ())}
                value=skuReceivingNotes
                onChange=onSkuReceivingNotesChange
                rows=6
              />, //skuReceivingNotesTextArea,
            tdStyle: ReactDOM.Style.make(~width="40%", ()),
          },
        ]
      />
      <VSpace px=40 />
    </PipelineDialog>
}
module Temp = {
  @react.component
  let make = (~closeCancel: unit => _) =>
    <PipelineDialog
      header=`beep`
      actionButtons=[
        <CancelButton onClick=closeCancel> {s(`Ok, We'll Fix It 😔`)} </CancelButton>,
      ]
      closeCancel>
      <Subheading> {`DER`->s} </Subheading>
    </PipelineDialog>
}
