// there are duplicated labels here and i intend to keep them
@@warning("-30")

open Airtable

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
type recordSortParam<'recordT> = airtableRawSortParam
type tableSchemaField<'recordT> = {
  sortAsc: recordSortParam<'recordT>,
  sortDesc: recordSortParam<'recordT>,
}
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

// SCALARS

// RELATIONSHIP FIELDS
type singleRelRecordField<'relT> = {
  getRecord: unit => option<'relT>,
  useRecord: unit => option<'relT>,
}
type multipleRelRecordField<'relT> = {
  getRecords: array<recordSortParam<'relT>> => array<'relT>,
  useRecords: array<recordSortParam<'relT>> => array<'relT>,
}
