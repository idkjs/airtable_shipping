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
  dialogClose: action,
  persistQtyReceivedFromState: action,
  persistQtyReceivedOfOne: action,
  persistReceivingNotesFromState: action,
  persistIsReceivedCheckbox: action,
  persistSerialNumberAndSerializedSkuNameFromState: action,
  // display vars
  qtyToReceive: int,
  qtyToReceiveOnChange: ReactEvent.Form.t => unit,
  receivingNotes: string,
  receivingNotesOnChange: ReactEvent.Form.t => unit,
  serialNumber: string,
  serialNumberLooksGood: bool,
  serialNumberOnChange: ReactEvent.Form.t => unit,
  boxSearchString: boxDestinationRecord => string,
  boxSearchStringOnChange: (boxDestinationRecord, ReactEvent.Form.t) => unit,
  qtyToBox: potentialBox => int,
  qtyToBoxOnChange: (potentialBox, ReactEvent.Form.t) => unit,
  boxNotes: potentialBox => string,
  boxNotesOnChange: (potentialBox, ReactEvent.Form.t) => unit,
  boxesToDisplay: array<potentialBox>,
  selectedBox: option<potentialBox>,
  boxIsSelected: bool,
  noBoxSearchResults: bool,
}

module ReceiveUnserialedSku = {
  @react.component
  let make = (~dialogVars: skuOrderDialogVars) => {
    let {
      skuOrder,
      sku,
      closeCancel,
      dispatch,
      persistQtyReceivedFromState,
      persistReceivingNotesFromState,
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
          disabled={qtyToReceive > 0}
          onClick={() =>
            dispatch->multi([
              persistQtyReceivedFromState,
              persistReceivingNotesFromState,
              dialogClose,
            ])}>
          {s(qtyToReceive > 0 ? `Save and Close` : `Must Receive > 0`)}
        </SecondarySaveButton>,
        <PrimarySaveButton
          disabled={qtyToReceive > 0}
          onClick={() =>
            dispatch->multi([persistQtyReceivedFromState, persistReceivingNotesFromState])}>
          {s(qtyToReceive > 0 ? `Save and Continue` : `Must Receive > 0`)}
        </PrimarySaveButton>,
      ]
      closeCancel>
      <Subheading> {`Tracking Number Receiving Notes`->s} </Subheading>
      {tracking.jocoNotes.render()}
      <VSpace px=20 />
      <Table
        rowId={() => `${tracking.id}_rcvtab`}
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

module ReceiveSerialedSku = {
  @react.component
  let make = (~dialogVars: skuOrderDialogVars) => {
    let {
      sku,
      closeCancel,
      dispatch,
      persistQtyReceivedOfOne,
      persistReceivingNotesFromState,
      serialNumberLooksGood,
      persistSerialNumberAndSerializedSkuNameFromState,
      dialogClose,
      tracking,
      serialNumber,
      serialNumberOnChange,
      receivingNotes,
      receivingNotesOnChange,
    } = dialogVars
    <PipelineDialog
      header={`Enter Serial Number & QC: ${sku.skuName.read()}`}
      actionButtons=[
        <CancelButton onClick=closeCancel> {s(`Cancel`)} </CancelButton>,
        <SecondarySaveButton
          disabled={!serialNumberLooksGood}
          onClick={() =>
            dispatch->multi([
              persistSerialNumberAndSerializedSkuNameFromState,
              persistQtyReceivedOfOne,
              persistReceivingNotesFromState,
              dialogClose,
            ])}>
          {s(serialNumberLooksGood ? `Save and Close` : `Enter a serial number`)}
        </SecondarySaveButton>,
        <PrimarySaveButton
          disabled={!serialNumberLooksGood}
          onClick={() =>
            dispatch->multi([
              persistSerialNumberAndSerializedSkuNameFromState,
              persistQtyReceivedOfOne,
              persistReceivingNotesFromState,
            ])}>
          {s(serialNumberLooksGood ? `Save and Continue` : `Enter a serial number`)}
        </PrimarySaveButton>,
      ]
      closeCancel>
      <Subheading> {`Tracking Number Receiving Notes`->s} </Subheading>
      {tracking.jocoNotes.render()}
      <VSpace px=20 />
      <Subheading> {`Enter the serial number for this item`->s} </Subheading>
      <input
        onChange=serialNumberOnChange
        type_="text"
        value={serialNumber}
        style={ReactDOM.Style.make(~fontSize="1.5em", ~width="400px", ())}
      />
      <Subheading> {`Any notes on this item?`->s} </Subheading>
      <textarea
        style={ReactDOM.Style.make(~width="100%", ())}
        value=receivingNotes
        onChange=receivingNotesOnChange
        rows=6
      />
    </PipelineDialog>
  }
}

module BoxSku = {
  @react.component
  let make = (~dialogVars: skuOrderDialogVars) => {
    let {
      dispatch,
      sku,
      skuOrder,
      closeCancel,
      boxSearchString,
      boxSearchStringOnChange,
      qtyToBox,
      qtyToBoxOnChange,
      boxNotes,
      boxNotesOnChange,
      boxesToDisplay,
      selectedBox,
      boxIsSelected,
      noBoxSearchResults,
      dest,
      receivingNotes,
      receivingNotesOnChange,
    } = dialogVars

    let clearSearchBtn =
      <CancelButton onClick={() => UpdateBoxSearchString(dest, "")->dispatch}>
        {`Clear Search`->s}
      </CancelButton>

    <PipelineDialog
      header={`Box ${sku.skuName.read()}`}
      actionButtons=[<CancelButton onClick=closeCancel> {s(`Cancel`)} </CancelButton>]
      closeCancel>
      <Subheading> {`Narrow Box Results`->s} </Subheading>
      <input
        onChange={dest->boxSearchStringOnChange}
        type_="text"
        value={dest->boxSearchString}
        style={ReactDOM.Style.make(~fontSize="1.5em", ~width="400px", ())}
      />
      {clearSearchBtn}
      <Subheading> {`Pick a box to receive into`->s} </Subheading>
      {noBoxSearchResults
        ? <div> <p> {`No results found for query`->s} </p> {clearSearchBtn} </div>
        : <Table
            rowId={box => `${box.name}_selbo`}
            elements=boxesToDisplay
            columnDefs=[
              {
                header: `Empty?`,
                accessor: box => (box.isEmpty ? `✅🌈` : `⛔🙅`)->s,
                tdStyle: ReactDOM.Style.make(~fontSize="1.7em", ~textAlign="center", ()),
              },
              {
                header: `Box Name`,
                accessor: box => box.name->s,
                tdStyle: ReactDOM.Style.make(~fontSize="1.3em", ~textAlign="center", ()),
              },
              {
                header: `Status`,
                accessor: box => box.status->s,
                tdStyle: ReactDOM.Style.make(),
              },
              {
                header: `Box Notes`,
                accessor: box => box.notes->s,
                tdStyle: ReactDOM.Style.make(),
              },
              {
                header: `Action`,
                accessor: box => {
                  boxIsSelected
                    ? clearSearchBtn
                    : <PrimarySaveButton
                        onClick={() => UpdateBoxSearchString(dest, box.name)->dispatch}>
                        {`Select`->s}
                      </PrimarySaveButton>
                },
                tdStyle: ReactDOM.Style.make(~textAlign="center", ()),
              },
            ]
          />}
      {switch selectedBox {
      | None => ``->s
      | Some(box) =>
        <div>
          <Subheading> {(`Receive ${sku.skuName.read()} into ${box.name}`)->s} </Subheading>
          <Table
            rowId={box => `${box.name}_packbo`}
            elements=[box]
            columnDefs=[
              {
                header: `Sku`,
                accessor: _ => skuOrder.skuOrderSku.scalar.render(),
                tdStyle: ReactDOM.Style.make(),
              },
              {
                header: `Qty Unboxed`,
                accessor: _ =>
                  skuOrder.quantityReceived.read()
                  ->Option.mapWithDefault(0, rcv => rcv - skuOrder.quantityPacked.read())
                  ->itos,
                tdStyle: ReactDOM.Style.make(~fontSize="1.7em", ~textAlign="center", ()),
              },
              {
                header: `Box Qty`,
                accessor: pb =>
                  <input
                    onChange={pb->qtyToBoxOnChange}
                    type_="number"
                    value={pb->qtyToBox->Int.toString}
                    style={ReactDOM.Style.make(~fontSize="1.5em", ~width="77px", ())}
                  />,
                tdStyle: ReactDOM.Style.make(~fontSize="1.7em", ~textAlign="center", ()),
              },
              {
                header: `Boxing Notes`,
                accessor: pb =>
                  <textarea
                    style={ReactDOM.Style.make(~width="100%", ())}
                    value={pb->boxNotes}
                    onChange={pb->boxNotesOnChange}
                    rows=6
                  />,
                tdStyle: ReactDOM.Style.make(~width="40%", ()),
              },
              {
                header: `Box it`,
                accessor: pb =>
                  <PrimarySaveButton
                    onClick=closeCancel style={ReactDOM.Style.make(~padding="10px inherit", ())}>
                    {(`Receive ${pb->qtyToBox->Int.toString}`)->s} <br /> {(`into ${pb.name}`)->s}
                  </PrimarySaveButton>,
                tdStyle: ReactDOM.Style.make(),
              },
            ]
          />
          <Subheading> {`Review/Edit Receiving Notes for this entire SKUOrder`->s} </Subheading>
          <textarea
            style={ReactDOM.Style.make(~width="100%", ())}
            value=receivingNotes
            onChange=receivingNotesOnChange
            rows=6
          />
        </div>
      }}
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
