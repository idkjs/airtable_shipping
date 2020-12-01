open Belt
open AirtableUI
open Schema
open SkuOrderDialogState

@react.component
let make = (
  ~state: Reducer.state,
  ~dispatch,
  ~schema: Schema.schema,
  ~skuOrderRecords: array<skuOrderRecord>,
) => {
  // so this is a hook, remember
  let focusSkuOrderOpt = schema.skuOrder.rel.useRecordById(state.focusOnSkuOrderRecordId)

  <div>
    <Heading> {React.string(`SKU Orders`)} </Heading>
    <Table
      rowId={record => record.id}
      elements=skuOrderRecords
      columnDefs=[
        {
          header: `Tracking #`,
          accessor: so => so.trackingRecord.scalar.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `SKU`,
          accessor: so => so.skuOrderSku.scalar.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Desc`,
          accessor: so => so.externalProductName.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Expect#`,
          accessor: so => so.quantityExpected.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Received#`,
          accessor: so => so.quantityReceived.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Packed#`,
          accessor: so => so.quantityPacked.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Dest`,
          accessor: so => so.skuOrderBoxDest.scalar.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        /* {
          header: `Receive Expected?`,
          accessor: so => so.skuOrderIsReceived.render(),
          tdStyle: ReactDOM.Style.make(~textAlign="center", ()),
        },
        {
          header: `Boxed?`,
          accessor: so => so.boxedCheckbox.render(),
          tdStyle: ReactDOM.Style.make(~textAlign="center", ()),
        }, */
        {
          header: `Notes`,
          accessor: so => so.receivingNotes.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Inspect`,
          accessor: so => parseRecordState(schema, so, state, dispatch).inspectionButton,
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `➡️ ➡️ ➡️`,
          accessor: so => parseRecordState(schema, so, state, dispatch).activationButton,
          tdStyle: ReactDOM.Style.make(),
        },
      ]
    />
    {focusSkuOrderOpt->Option.mapWithDefault(React.null, record =>
      parseRecordState(schema, record, state, dispatch).dialog
    )}
  </div>
}
