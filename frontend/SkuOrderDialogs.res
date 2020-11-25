open PipelineDialog
open Util
open Schema
open Belt
open Reducer
open SkuOrderBox

type skuOrderDialogVars = {
  // data
  skuOrder: skuOrderRecord,
  sku: skuRecord,
  dest: boxDestinationRecord,
  tracking: skuOrderTrackingRecord,
  // actions
  dispatch: action => unit,
  closeCancel: unit => unit,
  updateQtyReceivedFromState: action,
  updateReceivingNotesFromState: action,
  updateSerialNumberFromState: action,
  markReceivedCheckbox: action,
  serializeSkuName: action,
  dialogClose: action,
  // display vars
  qtyToReceive: int,
  qtyToReceiveOnChange: ReactEvent.Form.t => unit,
  receivingNotes: string,
  receivingNotesOnChange: ReactEvent.Form.t => unit,
}

module ReceiveUnserialedSku = {
  @react.component
  let make = (~dialogVars: skuOrderDialogVars) => {
    let {
      skuOrder,
      sku,
      closeCancel,
      dispatch,
      updateQtyReceivedFromState,
      updateReceivingNotesFromState,
      dialogClose,
      tracking,
      qtyToReceive,
      qtyToReceiveOnChange,
      receivingNotes,
      receivingNotesOnChange,
    } = dialogVars

    <PipelineDialog
      header={`Receive & QC: ${sku.skuName.read()}`}
      actionButtons=[
        <CancelButton onClick=closeCancel> {s(`Cancel`)} </CancelButton>,
        <SecondarySaveButton
          onClick={() =>
            dispatch->multi([
              updateQtyReceivedFromState,
              updateReceivingNotesFromState,
              dialogClose,
            ])}>
          {s(`Save and Close`)}
        </SecondarySaveButton>,
        <PrimarySaveButton
          onClick={() =>
            dispatch->multi([updateQtyReceivedFromState, updateReceivingNotesFromState])}>
          {s(`Save and Continue`)}
        </PrimarySaveButton>,
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
                onChange=qtyToReceiveOnChange
                type_="number"
                value={qtyToReceive->Int.toString}
                style={ReactDOM.Style.make(~fontSize="1.5em", ~width="77px", ())}
              />,
            tdStyle: ReactDOM.Style.make(~width="88px", ()),
          },
          {
            header: `QC/Receiving Notes`,
            accessor: () =>
              <textarea
                style={ReactDOM.Style.make(~width="100%", ())}
                value=receivingNotes
                onChange=receivingNotesOnChange
                rows=6
              />,
            tdStyle: ReactDOM.Style.make(~width="40%", ()),
          },
        ]
      />
      <VSpace px=40 />
    </PipelineDialog>
  }
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
