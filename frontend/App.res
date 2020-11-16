@react.component
let make = () => {
  //let schema = buildSchemaHook()
  let schema = Schema.buildSchema(SchemaDefinitionUser.allTables)
  //Js.Console.log(schema)

  open Reducer
  let (state, dispatch) = React.useReducer(reducer, initialState)

  <div style={ReactDOM.Style.make(~padding="8px", ())}>
    <SearchBox state dispatch />
    <div style={ReactDOM.Style.make(~marginBottom="26px", ())} />
    <SkuOrderTrackingResults state dispatch schema />
    //<PipelineDialog state dispatch schema />
  </div>
}
