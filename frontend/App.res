open Schema
open Reducer
open Belt
open Util
open Airtable

@react.component
let make = () => {
  let schema = buildSchema(SchemaDefinitionUser.allTables)
  let (state, dispatch) = React.useReducer(reducer, initialState)

  let searchQuery = state.searchString->trimLower
  let isSearching = searchQuery != ""
  let trackingRecords: array<skuOrderTrackingRecord> =
    schema.skuOrderTracking.hasTrackingNumbersView.useRecords([
      schema.skuOrderTracking.isReceivedField.sortAsc,
    ])->Array.keep(record => {
      //->Array.map(tracking => (tracking,tracking.skuOrders.useRecords([])))
      // keep everything if we don't have a search string, else get items that include the search query
      !isSearching || Js.String.includes(searchQuery, record.trackingNumber.read()->trimLower)
    })

  // descend 1 level down
  let _ =
    trackingRecords->Array.map(tracking => tracking.skuOrders.rel.getRecordsQueryResult([]))
      |> useMultipleQueries

  // descend 2 levels
  let _ =
    trackingRecords->Array.map(tracking =>
      tracking.skuOrders.rel.getRecords([])->Array.map(skuOrder => [
        skuOrder.skuOrderSku.rel.getRecordQueryResult(),
        skuOrder.trackingRecord.rel.getRecordQueryResult(),
        skuOrder.skuOrderBoxDest.rel.getRecordQueryResult(),
      ]) |> Array.concatMany
    )
    |> Array.concatMany
    |> useMultipleQueries

  // descend 3 levels
  let boxSortParams = [schema.box.boxNumberOnlyField.sortDesc]
  let _ =
    trackingRecords->Array.map(tracking =>
      tracking.skuOrders.rel.getRecords([])
      ->Array.map(skuOrder =>
        skuOrder.skuOrderBoxDest.rel.getRecord()->Option.map(boxDest =>
          boxDest.boxes.rel.getRecordsQueryResult(boxSortParams)
        )
      )
      ->Array.keepMap(identity)
    )
    |> Array.concatMany
    |> useMultipleQueries

  // descend 4 levels
  let _ =
    trackingRecords->Array.map(tracking =>
      tracking.skuOrders.rel.getRecords([])
      ->Array.map(skuOrder =>
        skuOrder.skuOrderBoxDest.rel.getRecord()->Option.map(boxDest =>
          boxDest.boxes.rel.getRecords(boxSortParams)->Array.map(box =>
            box.boxLines.rel.getRecordsQueryResult([])
          )
        )
      )
      ->Array.keepMap(identity) |> Array.concatMany
    )
    |> Array.concatMany
    |> useMultipleQueries

  let skuOrderRecords: array<skuOrderRecord> = isSearching
  // we don't wanna show shit if we haven't narrowed the results
  // can only show sku orders for received tracking numbers
    ? trackingRecords
      ->Array.keep(sot => sot.isReceived.read())
      ->Array.map(sot => sot.skuOrders.rel.getRecords([]))
      ->Array.concatMany
    : []

  //Js.Console.log(skuOrderRecords)

  <div style={ReactDOM.Style.make(~padding="8px", ())}>
    <SearchBox state dispatch />
    <div style={ReactDOM.Style.make(~marginBottom="26px", ())} />
    <SkuOrderTrackingResults state dispatch schema trackingRecords />
    <div style={ReactDOM.Style.make(~marginBottom="26px", ())} />
    <SkuOrderResults state dispatch schema skuOrderRecords />
    //<PipelineDialog state dispatch schema />
  </div>
}
