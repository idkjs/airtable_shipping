open Belt
open Schema

type action =
  | UpdateSearchString(string)
  | FocusOnTrackingRecord(skuOrderTrackingRecord)
  | UnfocusTrackingRecord
  // maybe not used
  | BlindFieldUpdate(Js.Promise.t<unit>)
  | UpdateWarehouseNotes(string)

type state = {
  searchString: string,
  focusOnTrackingRecordId: string,
  warehouseNotes: string,
}

let initialState: state = {
  searchString: "",
  focusOnTrackingRecordId: "",
  warehouseNotes: "",
}

let reducer = (state, action) =>
  switch action {
  | UpdateSearchString(str) => {...state, searchString: str}
  | FocusOnTrackingRecord(skotr) => {...state, focusOnTrackingRecordId: skotr.id}
  | UnfocusTrackingRecord => {...state, focusOnTrackingRecordId: ""}
  | BlindFieldUpdate(_) => state
  | UpdateWarehouseNotes(str) => {
      ...state,
      warehouseNotes: str,
    }
  }

let mapEvent: (action => 'typeofdispatch, 'eventT => action, 'event) => 'typeofdispatch = (
  dispatch,
  makeaction,
  event,
) => dispatch(makeaction(ReactEvent.Form.target(event)["value"]))

let useFocusedTrackingRecord: (state, schema) => option<skuOrderTrackingRecord> = (st, schema) => {
  schema.skuOrderTracking.rel.useRecordById(st.focusOnTrackingRecordId)
}
