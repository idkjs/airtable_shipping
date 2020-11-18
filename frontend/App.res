open Schema
open Reducer
open Belt
open Util

@react.component
let make = () => {
  let schema = buildSchema(SchemaDefinitionUser.allTables)
  let (state, dispatch) = React.useReducer(reducer, initialState)

  let searchQuery = state.searchString->trimLower
  let isSearching = searchQuery != ""
  let trackingRecords: array<skuOrderTrackingRecord> =
    schema.skuOrderTracking.hasTrackingNumbersView.useRecords([
      schema.skuOrderTracking.isReceivedField.sortAsc,
    ])
    ->Array.map(sot => {
      // get in there and USE everything in a big mess of hooks
      // they should all be loaded up and ready to go when i want to GET
      // them later
      let _ =
        sot.skuOrders.rel.useRecords([])->Array.map(so =>
          so.skuOrderBoxDest.rel.useRecord()->Option.map(bd =>
            bd.boxes.rel.useRecords([])->Array.map(bx => bx.boxLines.rel.useRecords([]))
          )
        )
      sot
    })
    ->Array.keep(record => {
      //->Array.map(tracking => (tracking,tracking.skuOrders.useRecords([])))
      // keep everything if we don't have a search string, else get items that include the search query
      !isSearching || Js.String.includes(searchQuery, record.trackingNumber.read()->trimLower)
    })

  let skuOrderRecords: array<skuOrderRecord> = isSearching
  // we don't wanna show shit if we haven't narrowed the results
  // can only show sku orders for received tracking numbers
    ? trackingRecords
      ->Array.keep(sot => sot.isReceived.read())
      ->Array.map(sot => sot.skuOrders.rel.getRecords([]))
      ->Array.concatMany
    : []

  Js.Console.log(skuOrderRecords)

  <div style={ReactDOM.Style.make(~padding="8px", ())}>
    <SearchBox state dispatch />
    <div style={ReactDOM.Style.make(~marginBottom="26px", ())} />
    <SkuOrderTrackingResults state dispatch schema trackingRecords />
    <div style={ReactDOM.Style.make(~marginBottom="26px", ())} />
    <SkuOrderResults state dispatch schema skuOrderRecords />
    //<PipelineDialog state dispatch schema />
  </div>
}
