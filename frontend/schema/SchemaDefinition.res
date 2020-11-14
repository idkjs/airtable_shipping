open AirtableRaw
open Belt
open Util

type rec airtableObjectResolutionMethod = ByName(string)
and airtableTableDef = {
  resolutionMethod: airtableObjectResolutionMethod,
  camelCaseTableName: string,
  tableFields: array<airtableFieldDef>,
  tableViews: array<airtableViewDef>,
}
and airtableViewDef = {
  resolutionMethod: airtableObjectResolutionMethod,
  camelCaseViewName: string,
}
and airtableScalarValueDef =
  | BareString
  | StringOption
  | Int
  | Bool
  | IntAsBool
  | MomentOption
and airtableFieldValueType =
  | ScalarRW(airtableScalarValueDef)
  | FormulaRollupRO(airtableScalarValueDef)
  | RelFieldOption(airtableTableDef, bool)
and airtableFieldResolutionMethod =
  | ByName(string)
  | PrimaryField
and airtableFieldDef = {
  resolutionMethod: airtableFieldResolutionMethod,
  camelCaseFieldName: string,
  fieldValueType: airtableFieldValueType,
}

let allowedAirtableFieldTypes: airtableFieldValueType => array<string> = fvt => {
  let stringy = [`multilineText`, `richText`, `singleLineText`]
  switch fvt {
  | FormulaRollupRO(_) => [`formula`, `rollup`]
  | RelFieldOption(_, _) => [`multipleRecordLinks`]
  | ScalarRW(scalarish) =>
    switch scalarish {
    | BareString => stringy
    | StringOption => stringy
    | Int => [`number`]
    | Bool => [`checkbox`]
    | IntAsBool => [`number`]
    | MomentOption => [`dateTime`]
    }
  }
}

type scalarTypeContext = {
  reasonReadReturnTypeName: string,
  scalarishFieldBuilderAccessorName: string,
}

let getScalarTypeContext: airtableScalarValueDef => scalarTypeContext = atsv => {
  switch atsv {
  | BareString => {
      reasonReadReturnTypeName: `string`,
      scalarishFieldBuilderAccessorName: `string`,
    }
  | StringOption => {
      reasonReadReturnTypeName: `option<string>`,
      scalarishFieldBuilderAccessorName: `stringOpt`,
    }
  | Int => {
      reasonReadReturnTypeName: `int`,
      scalarishFieldBuilderAccessorName: `int`,
    }
  | Bool => {
      reasonReadReturnTypeName: `bool`,
      scalarishFieldBuilderAccessorName: `bool`,
    }
  | IntAsBool => {
      reasonReadReturnTypeName: `bool`,
      scalarishFieldBuilderAccessorName: `intBool`,
    }
  | MomentOption => {
      reasonReadReturnTypeName: `option<airtableMoment>`,
      scalarishFieldBuilderAccessorName: `momentOption`,
    }
  }
}

type tableNamesContext = {
  tableRecordTypeName: string,
  recordBuilderFnName: string,
}

let getTableNamesContext: airtableTableDef => tableNamesContext = tdef => {
  tableRecordTypeName: `${tdef.camelCaseTableName}Record`,
  recordBuilderFnName: `${tdef.camelCaseTableName}RecordBuilder`,
}

type fieldCodeGenContext = {
  // field
  allowedAirtableFieldTypes: array<string>,
  // table
  tableFieldAccessorName: string,
  tableFieldType: string,
  //record
  innerRecordAccessorName: string,
  recordFieldType: string,
  parentRecordTypeName: string,
}

type tableRecordCodeGenContext = {
  // table stuff
  tableAccessorName: string,
  tableTypeName: string,
  sortParameterTypeName: string,
  // record stuff
  recordTypeName: string,
  recordBuilderName: string,
  fieldCodeGenContexts: array<fieldCodeGenContext>,
}

/*
TABLE SCHEMA FIELDS
So far these are just used for sorting
*/
type recordSortParam<'recordT> = airtableRawSortParam
type tableSchemaView<'recordT> = {
  getRecords: array<recordSortParam<'recordT>> => array<'recordT>,
  useRecords: array<recordSortParam<'recordT>> => array<'recordT>,
}
type tableSchemaField<'recordT> = {
  sortAsc: recordSortParam<'recordT>,
  sortDesc: recordSortParam<'recordT>,
}
let buildTableSchemaField: airtableRawField => tableSchemaField<'t> = raw => {
  sortAsc: {
    field: raw,
    direction: `asc`,
  },
  sortDesc: {
    field: raw,
    direction: `desc`,
  },
}

/*
RECORD FIELDS

*/
let encloseRecordIdRead: (airtableRawRecord, unit) => string = raw => {
  () => raw.id
}

// SCALARS
type readOnlyScalarRecordField<'t> = {
  read: unit => 't,
  render: unit => React.element,
}
type readWriteScalarRecordField<'t> = {
  read: unit => 't,
  // don't need it yet
  //writeAsync: 't => Js.Promise.t<unit>,
  render: unit => React.element,
}

// READING
// reading from scalars once you have the record is a ()=>'t call
let encloseAndTypeScalarRead: (
  airtableRawField,
  (airtableRawRecord, airtableRawField) => 'scalarish,
  airtableRawRecord,
  unit,
) => 'scalarish = (rawField, fn, rawRec, _) => {
  fn(rawRec, rawField)
}
// cell renderer is even easier as it's completely polymorphic
let encloseCellRenderer: (airtableRawField, airtableRawRecord, unit) => React.element = (
  field,
  record,
  _,
) => {
  <CellRenderer field record />
}

// RELATIONSHIP FIELDS
type singleRelRecordField<'relT> = {
  getRecord: unit => option<'relT>,
  useRecord: unit => option<'relT>,
}
type multipleRelRecordField<'relT> = {
  getRecords: array<recordSortParam<'relT>> => array<'relT>,
  useRecords: array<recordSortParam<'relT>> => array<'relT>,
}
