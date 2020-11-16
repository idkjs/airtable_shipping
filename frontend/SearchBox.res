@react.component
let make = (~state: Reducer.state, ~dispatch) => {
  open AirtableUI
  <div>
    <div> <Heading> {React.string("Tracking Number Search")} </Heading> </div>
    <div>
      <Input
        style={ReactDOM.Style.make()}
        value=state.searchString
        onChange={event =>
          dispatch(Reducer.UpdateSearchString(ReactEvent.Form.target(event)["value"]))}
      />
    </div>
  </div>
}
