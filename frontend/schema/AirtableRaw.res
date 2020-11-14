open Belt

/*
JS INTEGRATION TYPES AND EXTERNALS
JS INTEGRATION TYPES AND EXTERNALS
JS INTEGRATION TYPES AND EXTERNALS
*/
type airtableRawField = {
  name: string,
  @bs.as("type")
  _type: string,
}
type airtableRawView
type airtableRawTable = {primaryField: airtableRawField}
type airtableRawBase
type airtableRawRecord = {id: string}
type airtableRawRecordQueryResult = {records: array<airtableRawRecord>}
type airtableMoment
type airtableRawSortParam = {
  field: airtableRawField,
  direction: string,
}

// their functions
@bs.module("@airtable/blocks/ui")
external useBase: unit => airtableRawBase = "useBase"
@bs.module("@airtable/blocks/ui")
external useRecords: airtableRawRecordQueryResult => array<airtableRawRecord> = "useRecords"
@bs.send @bs.return(nullable)
external getTableByName: (airtableRawBase, string) => option<airtableRawTable> =
  "getTableByNameIfExists"
@bs.send @bs.return(nullable)
external getViewByName: (airtableRawTable, string) => option<airtableRawView> =
  "getViewByNameIfExists"
@bs.send @bs.return(nullable)
external getFieldByName: (airtableRawTable, string) => option<airtableRawField> =
  "getFieldByNameIfExists"

// this is ui thing, but we only use it in here
module CellRenderer = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~field: airtableRawField, ~record: airtableRawRecord) => React.element =
    "CellRenderer"
}

// my functions
@bs.module("./js_helpers")
external getString: (airtableRawRecord, airtableRawField) => string = "prepBareString"
@bs.module("./js_helpers")
external getStringOption: (airtableRawRecord, airtableRawField) => option<string> =
  "prepStringOption"
@bs.module("./js_helpers")
external getInt: (airtableRawRecord, airtableRawField) => int = "prepInt"
@bs.module("./js_helpers")
external getBool: (airtableRawRecord, airtableRawField) => bool = "prepBool"
@bs.module("./js_helpers")
external getIntAsBool: (airtableRawRecord, airtableRawField) => bool = "prepIntAsBool"
@bs.module("./js_helpers")
external getMomentOption: (airtableRawRecord, airtableRawField) => option<airtableMoment> =
  "prepMomentOption"
@bs.module("./js_helpers")
external getLinkedRecordQueryResult: (
  airtableRawRecord,
  airtableRawField,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "prepRelFieldQueryResult"
@bs.module("./js_helpers")
external getTableRecordsQueryResult: (
  airtableRawTable,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "selectRecordsFromTableOrView"
@bs.module("./js_helpers")
external getViewRecordsQueryResult: (
  airtableRawView,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "selectRecordsFromTableOrView"

let getOrUseQueryResult: (
  airtableRawRecordQueryResult,
  bool,
  airtableRawRecord => 'recordT,
) => array<'recordT> = (qres, shouldUse, wrap) => {
  (shouldUse ? useRecords(qres) : qres.records)->Array.map(wrap)
}

let getOrUseQueryResultSingle: (
  airtableRawRecordQueryResult,
  bool,
  airtableRawRecord => 'recordT,
) => option<'recordT> = (qres, shouldUse, wrap) => {
  getOrUseQueryResult(qres, shouldUse, wrap)->Array.get(0)
}

let getMultiRecordAsArray: (
  airtableRawRecord,
  airtableRawField,
  array<airtableRawField>,
  bool,
  airtableRawRecord => 'recordT,
  array<airtableRawSortParam>,
) => array<'recordT> = (rawR, rawF, allFs, shouldUse, wrap, sortPs) => {
  let query = getLinkedRecordQueryResult(rawR, rawF, allFs, sortPs)
  query->getOrUseQueryResult(shouldUse, wrap)
}

// add a unit to the call sig so this curries with the args provided to it
// into the call needed for getRecord and useRecord
let getSingleRecordAsOption: (
  airtableRawRecord,
  airtableRawField,
  array<airtableRawField>,
  bool,
  airtableRawRecord => 'recordT,
  unit,
) => option<'recordT> = (rawR, rawF, allFs, shouldUse, wrap, _) => {
  let recos = getMultiRecordAsArray(rawR, rawF, allFs, shouldUse, wrap, [])
  switch recos {
  | [] => None
  | [one] => Some(one)
  | _ => {
      Js.Console.error(`${rawF.name} field declared as single rel, but multiple rels found`)
      // this access returns an option, which is fine
      recos[0]
    }
  }
}
