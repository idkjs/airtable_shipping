@react.component
let make = (~state: Reducer.state, ~dispatch, ~schema: Schema.schema) => {
  open Belt
  open Util
  open AirtableUI
  open Schema
  open SkuOrderTrackingDialog

  let trackingRecords: array<skuOrderTrackingRecord> =
    schema.skuOrderTracking.hasTrackingNumbersView.useRecords([
      schema.skuOrderTracking.isReceivedField.sortAsc,
    ])
    ->Array.map(record => {
      // we grab these and toss em, for now
      // we'll pass them on to our children another way
      // this puts them in the airtable cache
      let _ = record.skuOrders.useRecords([])
      record
    })
    ->Array.keep(record => {
      let trimmed = state.searchString->Js.String.trim
      // keep everything if we don't have a search string, else get items that include the search query
      trimmed == "" || Js.String.includes(trimmed, record.trackingNumber.read())
    })

  // so this is a hook, remember
  let recordDialog =
    Reducer.useFocusedTrackingRecord(state, schema)->Option.mapWithDefault(React.string(""), r => {
      parseRecordState(r, dispatch, state).dialog
    })
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
          accessor: record => parseRecordState(record, dispatch, state).activationButton,
          tdStyle: ReactDOM.Style.make(~textAlign="center", ()),
        },
      ]
    />
    {recordDialog}
  </div>
}
