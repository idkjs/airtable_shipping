open Belt
open Schema
open SchemaDefinition
open Util
open SkuOrderBox

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
  | UpdateBoxSearchString(boxDestinationRecord, string)
  | UpdateQtyToBox(skuOrderRecord, potentialBox, int)
  | UpdateBoxNotes(skuOrderRecord, potentialBox, string)

type boxStuff = {qty: int, notes: string}
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
  boxSearchString: Map.String.t<string>,
  boxStuffMap: Map.String.t<boxStuff>,
}

let initialState: state = {
  searchString: "",
  warehouseNotes: "",
  focusOnTrackingRecordId: nullRecordId,
  focusOnSkuOrderRecordId: nullRecordId,
  skuQuantityReceived: None,
  skuReceivingNotes: "",
  skuSerial: "",
  boxSearchString: Map.String.empty,
  boxStuffMap: Map.String.empty,
}

let rec reducer = (state, action) => {
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
  | UpdateBoxSearchString(bdr, s) => {
      ...state,
      boxSearchString: state.boxSearchString->Map.String.update(bdr.destName.read(), _ => Some(s)),
    }
  | UpdateQtyToBox(skor, pb, qty) => {
      ...state,
      boxStuffMap: mapBoxStuff(state, skor, pb, bs => {...bs, qty: qty})->first,
    }
  | UpdateBoxNotes(skor, pb, notes) => {
      ...state,
      boxStuffMap: mapBoxStuff(state, skor, pb, bs => {...bs, notes: notes})->first,
    }
  }
  Js.Console.log(rv)
  rv
}
and mapBoxStuff: (
  state,
  skuOrderRecord,
  potentialBox,
  boxStuff => boxStuff,
) => (Map.String.t<boxStuff>, boxStuff) = (state, skor, pb, mapFn) => {
  let k = `${skor.id}_${pb.name}`
  // make it all gettable
  let dict =
    state.boxStuffMap->Map.String.update(k, bsopt => Some(
      bsopt->Option.mapWithDefault(
        {qty: skor.quantityExpected.read(), notes: pb.notes}->mapFn,
        mapFn,
      ),
    ))

  (dict, dict->Map.String.getExn(k)->mapFn)
}

let onChangeHandler: (action => unit, string => action, 'event) => unit = (
  dispatch,
  makeaction,
  event,
) => ReactEvent.Form.target(event)["value"]->makeaction->dispatch

let multi: (action => unit, array<action>) => unit = (dispatch, actions) => {
  let _ = actions->Array.map(dispatch)
}

let getQtyToBox = (state, skor, pb) => {
  mapBoxStuff(state, skor, pb, identity)->second->(bs => bs.qty)
}
let getBoxNotes = (state, skor, pb) => {
  mapBoxStuff(state, skor, pb, identity)->second->(bs => bs.notes)
}
let getSearchString = (state, bdr) => {
  state.boxSearchString->Map.String.get(bdr.destName.read())->Option.getWithDefault("")
}
