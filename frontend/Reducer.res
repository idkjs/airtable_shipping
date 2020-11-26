open Belt
open Schema
open SchemaDefinition

type action =
  | UpdateSearchString(string)
  | FocusOnTrackingRecord(skuOrderTrackingRecord)
  | UnfocusTrackingRecord
  // maybe not used
  | BlindFieldUpdate(unit => Js.Promise.t<unit>)
  | UpdateWarehouseNotes(string)
  | FocusOnOrderRecord(skuOrderRecord)
  | UnfocusOrderRecord
  | UpdateSKUReceivedQty(option<int>)
  | UpdateReceivingNotes(string)
  | UpdateSKUSerial(string)
  | UpdateBoxSearchString(string)

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
  // box
  boxSearchString: string,
}

let initialState: state = {
  searchString: "",
  warehouseNotes: "",
  focusOnTrackingRecordId: nullRecordId,
  focusOnSkuOrderRecordId: nullRecordId,
  skuQuantityReceived: None,
  skuReceivingNotes: "",
  skuSerial: "",
  boxSearchString: "",
}

let reducer = (state, action) => {
  let rv = switch action {
  | UpdateSearchString(str) => {...state, searchString: str}
  | FocusOnTrackingRecord(skotr) => {...state, focusOnTrackingRecordId: skotr.id}
  | UnfocusTrackingRecord => {...state, focusOnTrackingRecordId: nullRecordId}
  | FocusOnOrderRecord(so) => {...state, focusOnSkuOrderRecordId: so.id}
  | UnfocusOrderRecord => {...state, focusOnSkuOrderRecordId: nullRecordId}
  | BlindFieldUpdate(fn) => {
      //execute
      let _ = fn()
      state
    }
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
  | UpdateBoxSearchString(s) => {
      ...state,
      boxSearchString: s,
    }
  }
  Js.Console.log(rv)
  rv
}

let onChangeHandler: (action => unit, string => action, 'event) => unit = (
  dispatch,
  makeaction,
  event,
) => ReactEvent.Form.target(event)["value"]->makeaction->dispatch

let multi: (action => unit, array<action>) => unit = (dispatch, actions) => {
  let _ = actions->Array.map(dispatch)
}
