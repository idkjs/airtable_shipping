open Belt
open Util
open AirtableUI
open Schema
open SkuOrderTrackingDialog

@react.component
let make = (
  ~state: Reducer.state,
  ~dispatch,
  ~schema: Schema.schema,
  ~trackingRecords: array<skuOrderTrackingRecord>,
) => {
  // so this is a hook, remember
  let focusedTrackingRecordOpt = schema.skuOrderTracking.rel.useRecordById(
    state.focusOnTrackingRecordId,
  )
  <div>
    <Heading> {React.string("Tracking Numbers")} </Heading>
    <Table
      rowId={record => record.id}
      elements=trackingRecords
      columnDefs=[
        {
          header: `Received?`,
          accessor: record => {
            <span> {s(record.isReceived.read() ? `✅` : `❌`)} </span>
          },
          tdStyle: ReactDOM.Style.make(~width="5%", ~textAlign="center", ~fontSize="1.8em", ()),
        },
        {
          header: `Tracking Number`,
          accessor: record => record.trackingNumber.render(),
          tdStyle: ReactDOM.Style.make(~width="15%", ()),
        },
        {
          header: `JoCo Notes`,
          accessor: record => record.jocoNotes.render(),
          tdStyle: ReactDOM.Style.make(~width="35%", ()),
        },
        {
          header: `Warehouse Notes`,
          accessor: record => record.warehouseNotes.render(),
          tdStyle: ReactDOM.Style.make(~width="35%", ()),
        },
        {
          header: `Action`,
          accessor: record => parseRecordState(record, state, dispatch).activationButton,
          tdStyle: ReactDOM.Style.make(~textAlign="center", ()),
        },
      ]
    />
    {focusedTrackingRecordOpt->Option.mapWithDefault(React.null, record =>
      parseRecordState(record, state, dispatch).dialog
    )}
  </div>
}
