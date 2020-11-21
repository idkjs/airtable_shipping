open Belt
open Util
open AirtableUI
open Schema
open SkuOrderDialog

@react.component
let make = (
  ~state: Reducer.state,
  ~dispatch,
  ~schema: Schema.schema,
  ~skuOrderRecords: array<skuOrderRecord>,
) => {
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
          header: `Packed#`,
          accessor: so => so.quantityPacked.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Dest`,
          accessor: so => so.skuOrderBoxDest.scalar.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Recv?`,
          accessor: so => so.skuOrderIsReceived.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `Notes`,
          accessor: so => so.receivingNotes.render(),
          tdStyle: ReactDOM.Style.make(),
        },
        {
          header: `➡️`,
          accessor: so => parseRecordState(so, state, dispatch).activationButton,
          tdStyle: ReactDOM.Style.make(),
        },
      ]
    />
  </div>
}