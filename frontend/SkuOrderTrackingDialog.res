open AirtableUI
open Schema
open Util
open Reducer
open Belt
open PipelineDialog

type rec skuOrderTrackingState = {activationButton: React.element, dialog: React.element}
and dialogArgs = {temp: string}

module EditView = {
  @react.component
  let make = (
    ~record: skuOrderTrackingRecord,
    ~dispatch: action => unit,
    ~state: state,
    ~closeCancel: unit => _,
  ) =>
    <PipelineDialog
      header=`Edit Tracking Record`
      actionButtons=[
        <CancelWarningButton onClick=closeCancel>
          {s("Cancel and don't save")}
        </CancelWarningButton>,
        <PrimaryActionButton
          onClick={() => {
            dispatch(BlindFieldUpdate(record.warehouseNotes.updateAsync(state.warehouseNotes)))
            closeCancel()
          }}>
          {s("Cancel and don't save")}
        </PrimaryActionButton>,
      ]
      closeCancel>
      <textarea
        value=state.warehouseNotes
        onChange={event => dispatch(UpdateWarehouseNotes(ReactEvent.Form.target(event)["value"]))}
        cols=80
        rows=3
      />
    </PipelineDialog>
}
module Receive = {
  @react.component
  let make = (~record: skuOrderTrackingRecord, ~closeCancel: unit => _) =>
    <PipelineDialog header=`Receive Tracking Number` actionButtons=[] closeCancel>
      {s("Merp")}
    </PipelineDialog>
}

let parseRecordState: (skuOrderTrackingRecord, action => _, state) => skuOrderTrackingState = (
  sotr,
  dispatch,
  state,
) => {
  let dialogOpen = () => {
    dispatch(UpdateWarehouseNotes(sotr.warehouseNotes.read()))
    dispatch(FocusOnTrackingRecord(sotr))
  }
  let dialogClose = () => {
    dispatch(UnfocusTrackingRecord)
    dispatch(UpdateWarehouseNotes(""))
  }
  if sotr.isReceived.read() {
    {
      activationButton: <EditButton onClick=dialogOpen> {s(`Edit/View`)} </EditButton>,
      dialog: <EditView record=sotr dispatch state closeCancel=dialogClose />,
    }
  } else {
    {
      activationButton: <PrimaryActionButton onClick=dialogOpen>
        {s(`Receive`)}
      </PrimaryActionButton>,
      dialog: <Receive record=sotr closeCancel=dialogClose />,
    }
  }
}
