open Belt
open Schema
open SchemaDefinition

type action =
  | UpdateSearchString(string)
  | FocusOnTrackingRecord(skuOrderTrackingRecord)
  | UnfocusTrackingRecord
  // maybe not used
  | BlindFieldUpdate(Js.Promise.t<unit>)
  | UpdateWarehouseNotes(string)
  | FocusOnOrderRecord(skuOrderRecord)
  | UnfocusOrderRecord
  | UpdateSKUReceivedQty(option<int>)
  | UpdateReceivingNotes(string)
  | UpdateSKUSerial(string)

type state = {
  // search for tracking
  searchString: string,
  // tracking receive
  warehouseNotes: string,
  focusOnTrackingRecordId: recordId<skuOrderTrackingRecord>,
  // sku order receive
  focusOnSkuOrderRecordId: recordId<skuOrderRecord>,
  skuQuantityReceived: option<int>,
  skuReceivingNotes: string,
  skuSerial: string,
}

let initialState: state = {
  searchString: "",
  warehouseNotes: "",
  focusOnTrackingRecordId: nullRecordId,
  focusOnSkuOrderRecordId: nullRecordId,
  skuQuantityReceived: None,
  skuReceivingNotes: "",
  skuSerial: "",
}

let reducer = (state, action) => {
  Js.Console.log(state)
  switch action {
  | UpdateSearchString(str) => {...state, searchString: str}
  | FocusOnTrackingRecord(skotr) => {...state, focusOnTrackingRecordId: skotr.id}
  | UnfocusTrackingRecord => {...state, focusOnTrackingRecordId: nullRecordId}
  | FocusOnOrderRecord(so) => {...state, focusOnSkuOrderRecordId: so.id}
  | UnfocusOrderRecord => {...state, focusOnSkuOrderRecordId: nullRecordId}
  | BlindFieldUpdate(_) => state
  | UpdateWarehouseNotes(str) => {
      ...state,
      warehouseNotes: str,
    }
  | UpdateSKUReceivedQty(i) => {
      ...state,
      skuQuantityReceived: i,
    }
  | UpdateReceivingNotes(s) => {
      ...state,
      skuReceivingNotes: s,
    }
  | UpdateSKUSerial(s) => {
      ...state,
      skuSerial: s,
    }
  }
}

let mapEvent: (action => unit, 'needed => action, string => 'needed, 'event) => unit = (
  dispatch,
  makeaction,
  convertaction,
  event,
) => ReactEvent.Form.target(event)["value"]->convertaction->makeaction->dispatch
