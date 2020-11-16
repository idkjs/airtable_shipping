// there are duplicated labels here and i intend to keep them
@@warning("-30")

open Airtable
open Belt

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

/**
GENERATED SCHEMA PROPERTIES
GENERATED SCHEMA PROPERTIES
*/
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
type singleRelRecordField<'relT> = {
  getRecord: unit => option<'relT>,
  useRecord: unit => option<'relT>,
}
type multipleRelRecordField<'relT> = {
  getRecords: array<recordSortParam<'relT>> => array<'relT>,
  useRecords: array<recordSortParam<'relT>> => array<'relT>,
  getRecordById: string => option<'relT>,
}

/**
SCHEMA GENERATION DEFINITIONS
SCHEMA GENERATION DEFINITIONS
You can actually change a lot about the core workings of the 
schema here
*/

// names of generated types which we use extensively
type tableNamesContext = {
  tableRecordTypeName: string,
  recordBuilderFnName: string,
}
let getTableNamesContext: airtableTableDef => tableNamesContext = tdef => {
  tableRecordTypeName: `${tdef.camelCaseTableName}Record`,
  recordBuilderFnName: `${tdef.camelCaseTableName}RecordBuilder`,
}

// used to typecheck the field types from the schema
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

// additional typing information for schema generation
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

/*
This is the base form of things that return records 
*/
type veryGenericQueryable<'qType> = {
  // query single
  getRecord: unit => option<'qType>,
  useRecord: unit => option<'qType>,
  // query multiple
  getRecords: array<airtableRawSortParam> => array<'qType>,
  useRecords: array<airtableRawSortParam> => array<'qType>,
  // query specific
  getRecordById: string => option<'qType>,
}

// everything from airtable comes back as a query result if you want it that way
// this takes a function that provides one and creates a generic queryable thing
let buildVGQ: (array<airtableRawSortParam> => airtableRawRecordQueryResult) => veryGenericQueryable<
  airtableRawRecord,
> = getQ => {
  let useQueryResult: (airtableRawRecordQueryResult, bool) => array<airtableRawRecord> = (q, use) =>
    use ? useRecords(q) : q.records
  {
    getRecords: params => params->getQ->useQueryResult(false),
    useRecords: params => params->getQ->useQueryResult(true),
    getRecord: () => []->getQ->useQueryResult(false)->Array.get(0),
    useRecord: () => []->getQ->useQueryResult(true)->Array.get(0),
    getRecordById: str => []->getQ->getRecordById(str),
  }
}

// allows any VGQ object to be wrapped into
// a fully typed record builder type ... the other thing we need
// in order to work with these abstractions
let mapVGQ: (veryGenericQueryable<'a>, 'a => 'b) => veryGenericQueryable<'b> = (orig, map) => {
  getRecord: p => orig.getRecord(p)->Option.map(map),
  useRecord: p => orig.useRecord(p)->Option.map(map),
  getRecords: p => orig.getRecords(p)->Array.map(map),
  useRecords: p => orig.useRecords(p)->Array.map(map),
  getRecordById: p => orig.getRecordById(p)->Option.map(map),
}

let asMultipleRelField: veryGenericQueryable<'relT> => multipleRelRecordField<'relT> = vgq => {
  getRecords: vgq.getRecords,
  useRecords: vgq.useRecords,
  getRecordById: vgq.getRecordById,
}
let asSingleRelField: veryGenericQueryable<'relT> => singleRelRecordField<'relT> = vgq => {
  getRecord: vgq.getRecord,
  useRecord: vgq.useRecord,
}

/*
This is the base form of things that don't return records 
*/
type rec scalarishField = {
  rawField: airtableRawField,
  string: scalarishRecordFieldBuilder<string>,
  stringOpt: scalarishRecordFieldBuilder<option<string>>,
  int: scalarishRecordFieldBuilder<int>,
  bool: scalarishRecordFieldBuilder<bool>,
  intBool: scalarishRecordFieldBuilder<bool>,
  momentOption: scalarishRecordFieldBuilder<option<airtableMoment>>,
  sortAsc: airtableRawSortParam,
  sortDesc: airtableRawSortParam,
}
and scalarishRecordFieldBuilder<'scalarish> = {
  // utility type for scalarish
  buildReadOnly: airtableRawRecord => readOnlyScalarRecordField<'scalarish>,
  buildReadWrite: airtableRawRecord => readWriteScalarRecordField<'scalarish>,
}

// fulfiil the scalarishRecordFieldBuilder interface when
// given a prep function
let scalarishBuilder: (
  airtableRawField,
  (airtableRawRecord, airtableRawField) => 'scalarish,
) => scalarishRecordFieldBuilder<'scalarish> = (rawField, prepFn) => {
  buildReadOnly: rawRec => {
    read: () => prepFn(rawRec, rawField),
    render: () => <CellRenderer field=rawField record=rawRec />,
  },
  buildReadWrite: rawRec => {
    read: () => prepFn(rawRec, rawField),
    render: () => <CellRenderer field=rawField record=rawRec />,
  },
}
