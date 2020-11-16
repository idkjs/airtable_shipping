@react.component
let make = () => {
  //let schema = buildSchemaHook()
  let schema = Schema.buildSchema(SchemaDefinitionUser.allTables)
  Js.Console.log(schema)

  open Reducer
  let (state, dispatch) = React.useReducer(reducer, initialState)

  <div style={ReactDOM.Style.make(~padding="8px", ())}>
    <SearchBox state dispatch /> <SkuOrderTrackingResults state dispatch schema />
  </div>
}
