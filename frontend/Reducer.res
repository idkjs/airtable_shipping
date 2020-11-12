type action = UpdateSearchString(string)

type state = {
  searchString: string,
  focusOnTrackingRecordId: string,
}

let initialState: state = {
  searchString: "",
  focusOnTrackingRecordId: "",
}

let reducer = (state, action) =>
  switch action {
  | UpdateSearchString(str) => {...state, searchString: str}
  }
