@react.component
let make = (~state: Reducer.state, ~dispatch) => {
  open Airtable
  <div>
    <div> <Heading> {React.string("Tracking Number Search")} </Heading> </div>
    <div style={ReactDOM.Style.make(~marginBottom="20px", ())}>
      <Input
        style={ReactDOM.Style.make()}
        value=state.searchString
        onChange={event =>
          dispatch(Reducer.UpdateSearchString(ReactEvent.Form.target(event)["value"]))}
      />
    </div>
  </div>
}
