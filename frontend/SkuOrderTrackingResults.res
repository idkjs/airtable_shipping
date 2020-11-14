@react.component
let make = (~state: Reducer.state, ~dispatch, ~schema: Schema.schema) => {
  open Belt
  open Util
  open AirtableUI
  open Schema

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
      trimmed == "" || Js.String.includes(trimmed, record.trackingNumber.read())
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
      ]
    />
  </div>
}
