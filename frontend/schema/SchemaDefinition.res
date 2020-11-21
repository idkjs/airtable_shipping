// there are duplicated labels here and i intend to keep them
@@warning("-30")

open Airtable
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
  // rel table, is single rel, scalar type of rel col, can write to it
  | RelFieldOption(airtableTableDef, bool, airtableScalarValueDef)
and airtableFieldResolutionMethod =
  | ByName(string)
  | PrimaryField
and airtableFieldDef = {
  resolutionMethod: airtableFieldResolutionMethod,
  camelCaseFieldName: string,
  fieldValueType: airtableFieldValueType,
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
  | RelFieldOption(_, _, _) => [`multipleRecordLinks`]
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
  useRecordById: string => option<'qType>,
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
    useRecordById: str => []->getQ->useLoadableHook->getRecordById(str),
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
  useRecordById: p => orig.useRecordById(p)->Option.map(map),
}

type recordSortParam<'recordT> = airtableRawSortParam
type singleRelField<'relT> = {
  getRecord: unit => option<'relT>,
  useRecord: unit => option<'relT>,
}
type recordId<'relT> = string
let nullRecordId: recordId<'relT> = ""

type multipleRelField<'relT> = {
  getRecords: array<recordSortParam<'relT>> => array<'relT>,
  useRecords: array<recordSortParam<'relT>> => array<'relT>,
  getRecordById: recordId<'relT> => option<'relT>,
  useRecordById: recordId<'relT> => option<'relT>,
}

let asMultipleRelField: veryGenericQueryable<'relT> => multipleRelField<'relT> = vgq => {
  getRecords: vgq.getRecords,
  useRecords: vgq.useRecords,
  getRecordById: vgq.getRecordById,
  useRecordById: vgq.useRecordById,
}
let asSingleRelField: veryGenericQueryable<'relT> => singleRelField<'relT> = vgq => {
  getRecord: vgq.getRecord,
  useRecord: vgq.useRecord,
}

type recordCreateUpdateParam<'recordT> = airtableObjectMapComponent
type genericTableSchemaField<'scalarT> = {
  sortAsc: airtableRawSortParam,
  sortDesc: airtableRawSortParam,
  buildObjectMapComponent: 'scalarT => airtableObjectMapComponent,
}
type tableSchemaField<'recordT, 'scalarT> = genericTableSchemaField<'scalarT>
type genericTableCRUDOperations<'recordT> = {
  create: array<recordCreateUpdateParam<'recordT>> => Js.Promise.t<recordId<'recordT>>,
  update: ('recordT, array<recordCreateUpdateParam<'recordT>>) => Js.Promise.t<unit>,
}
let buildGenericTableCRUDOperations: airtableRawTable => genericTableCRUDOperations<
  'recordT,
> = rawTable => {
  create: arr => rawTable->createRecordAsync(buildAirtableObjectMap(arr)),
  update: (reco, arr) => rawTable->updateRecordAsync(reco, buildAirtableObjectMap(arr)),
}
external mapGenericTableCRUDOperations: genericTableCRUDOperations<
  'a,
> => genericTableCRUDOperations<'b> = "%identity"
/*
let mapGenericTableCRUDOperations: (
  genericTableCRUDOperations<'a>,
  'a => 'b,
) => genericTableCRUDOperations<'b> = (gtco, wrp) => {
  create: gtco.create,
  update: gtco.update,
}*/

type genericTable<'recordT> = {
  vgq: veryGenericQueryable<'recordT>,
  crud: genericTableCRUDOperations<'recordT>,
}

type readOnlyScalarRecordField<'t> = {
  read: unit => 't,
  render: unit => React.element,
}

type readWriteScalarRecordField<'t> = {
  read: unit => 't,
  // don't need it yet
  //writeAsync: 't => Js.Promise.t<unit>,
  updateAsync: 't => Js.Promise.t<unit>,
  render: unit => React.element,
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
}
and scalarishRecordFieldBuilder<'scalarish> = {
  // utility type for scalarish
  buildReadOnly: airtableRawRecord => readOnlyScalarRecordField<'scalarish>,
  buildReadWrite: airtableRawRecord => readWriteScalarRecordField<'scalarish>,
  tableSchemaField: genericTableSchemaField<'scalarish>,
}

// fulfiil the scalarishRecordFieldBuilder interface when
// given a prep function
let scalarishBuilder: (
  airtableRawTable,
  airtableRawField,
  (airtableRawRecord, airtableRawField) => 'scalarish,
  'scalarish => _,
) => scalarishRecordFieldBuilder<'scalarish> = (rawTable, rawField, readPrepFn, writePrepFn) => {
  let bOMC: 'scalarish => airtableObjectMapComponent = s =>
    buildObjectMapComponent((rawField, writePrepFn(s)))
  {
    buildReadOnly: rawRec => {
      read: () => readPrepFn(rawRec, rawField),
      render: () => <CellRenderer field=rawField record=rawRec />,
    },
    buildReadWrite: rawRec => {
      read: () => readPrepFn(rawRec, rawField),
      updateAsync: value =>
        updateRecordAsync(rawTable, rawRec, buildAirtableObjectMap([bOMC(value)])),
      render: () => <CellRenderer field=rawField record=rawRec />,
    },
    tableSchemaField: {
      sortAsc: {field: rawField, direction: `asc`},
      sortDesc: {field: rawField, direction: `desc`},
      buildObjectMapComponent: bOMC,
    },
  }
}

let buildScalarishField: (airtableRawTable, airtableRawField) => scalarishField = (
  rawTable,
  rawField,
) => {
  rawField: rawField,
  string: scalarishBuilder(rawTable, rawField, getString, identity),
  stringOpt: scalarishBuilder(rawTable, rawField, getStringOption, stropt =>
    stropt->Option.mapWithDefault("", identity)
  ),
  int: scalarishBuilder(rawTable, rawField, getInt, identity),
  bool: scalarishBuilder(rawTable, rawField, getBool, identity),
  intBool: scalarishBuilder(rawTable, rawField, getIntAsBool, b => b ? 1 : 0),
  momentOption: scalarishBuilder(rawTable, rawField, getMomentOption, mopt =>
    mopt->Option.mapWithDefault("", moment => moment->format())
  ),
}
