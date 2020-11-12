open Belt
open Util
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

/**
UI INTEGRATION
UI INTEGRATION
UI INTEGRATION
*/
module Input = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (
    ~value: string,
    ~onChange: ReactEvent.Form.t => 'a,
    ~style: ReactDOM.Style.t,
  ) => React.element = "Input"
}

module CellRenderer = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~field: airtableRawField, ~record: airtableRawRecord) => React.element =
    "CellRenderer"
}

module Dialog = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~onClose: unit => 'a) => React.element = "Dialog"
}

module Heading = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~children: React.element) => React.element = "Heading"
}

/**
RECORD STUFF
RECORD STUFF
RECORD STUFF
*/

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

// my functions
@bs.module("./schema/js_helpers")
external getString: (airtableRawRecord, airtableRawField) => string = "prepBareString"
@bs.module("./schema/js_helpers")
external getStringOption: (airtableRawRecord, airtableRawField) => option<string> =
  "prepStringOption"
@bs.module("./schema/js_helpers")
external getInt: (airtableRawRecord, airtableRawField) => int = "prepInt"
@bs.module("./schema/js_helpers")
external getBool: (airtableRawRecord, airtableRawField) => bool = "prepBool"
@bs.module("./schema/js_helpers")
external getIntAsBool: (airtableRawRecord, airtableRawField) => bool = "prepIntAsBool"
@bs.module("./schema/js_helpers")
external getMomentOption: (airtableRawRecord, airtableRawField) => option<airtableMoment> =
  "prepMomentOption"
@bs.module("./schema/js_helpers")
external getLinkedRecordQueryResult: (
  airtableRawRecord,
  airtableRawField,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "prepRelFieldQueryResult"
@bs.module("./schema/js_helpers")
external getTableRecordsQueryResult: (
  airtableRawTable,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "selectRecordsFromTableOrView"
@bs.module("./schema/js_helpers")
external getViewRecordsQueryResult: (
  airtableRawView,
  array<airtableRawField>,
  array<airtableRawSortParam>,
) => airtableRawRecordQueryResult = "selectRecordsFromTableOrView"

/*
USER SCHEMA DEFINTION TYPES
USER SCHEMA DEFINTION TYPES
USER SCHEMA DEFINTION TYPES
*/
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

/*
CODE GEN TYPES
CODE GEN TYPES
CODE GEN TYPES
CODE GEN TYPES
*/
type codeGenGlobals = {
  genericSchemaVarName: string,
  recordBuilderRawRecName: string,
  gsGetRawTableFnCall: string => string,
  gsGetAllFieldsFnCall: string => string,
  gsGetRawFieldFnCall: (string, string) => string,
  getRawViewFnCall: (string, string) => string,
}
let globals: codeGenGlobals = {
  let genericSchemaVarName = `gschem`
  {
    genericSchemaVarName: genericSchemaVarName,
    recordBuilderRawRecName: `rawRec`,
    gsGetRawTableFnCall: tableCamelName =>
      `gsGetRawTable(${genericSchemaVarName}, "${tableCamelName}")`,
    gsGetAllFieldsFnCall: tableCamelName =>
      `gsGetAllFieldsForTable(${genericSchemaVarName}, "${tableCamelName}")`,
    gsGetRawFieldFnCall: (tableCamelName, fieldCamelName) =>
      `gsGetRawField(${genericSchemaVarName}, "${tableCamelName}", "${fieldCamelName}")`,
    getRawViewFnCall: (tableCamelName, viewCamelName) =>
      `gsGetRawView(${genericSchemaVarName}, "${tableCamelName}", "${viewCamelName}")`,
  }
}

type fieldCodeGenContext = {
  innerRecordAccessorName: string,
  innerTableAccessorName: string,
  innerTableFieldTypeDef: string,
  innerRecordFieldTypeDef: string,
  allowedAirtableFieldTypes: array<string>,
  innerSchemaBuilderDeclaration: string,
  innerRecordBuilderDeclaration: string,
}
type tableCodeGenContext = {
  innerSchemaAccessorName: string,
  tableTypeName: string,
  recordTypeName: string,
  recordBuilderName: string,
  sortParameterTypeName: string,
  innerSchemaTypeDef: string,
}
type schemaCodeGenContext = {
  schemaTypeName: string,
  recordOuterTypeDefs: string,
  tableOuterTypeDefs: string,
  innerSchemaTableTypeDefs: string,
}
let commaSepDeclaration = thing => {
  if thing->Array.length > 0 {
    joinWith(",\n  ", thing) ++ ","
  } else {
    ""
  }
}
let parameterizeRecordSortParam: string => string = recordTypeName => {
  `recordSortParam<${recordTypeName}>`
}

let rec parseField: (string, string, airtableFieldDef) => fieldCodeGenContext = (
  tableCamelName,
  recordTypeName,
  fdef,
) => {
  let innerRecordAccessorName = fdef.camelCaseFieldName
  let innerTableAccessorName = `${innerRecordAccessorName}Field`
  let innerTableFieldTypeDef = `${innerTableAccessorName}: tableSchemaField<${recordTypeName}>`
  let scalarTypeNames: airtableScalarValueDef => (string, array<string>, string) = atsv => {
    let stringy = [`multilineText`, `richText`, `singleLineText`]
    switch atsv {
    | BareString => (`string`, stringy, `getString`)
    | StringOption => (`option<string>`, stringy, `getStringOption`)
    | Int => (`int`, [`number`], `getInt`)
    | Bool => (`bool`, [`checkbox`], `getBool`)
    | IntAsBool => (`bool`, [`number`], `getIntAsBool`)
    | MomentOption => (`option<airtableMoment>`, [`dateTime`], `getMomentOption`)
    }
  }
  let formulaAirtableTypes = [`formula`, `rollup`]
  let airtableRelTypes = [`multipleRecordLinks`]
  let gsGetRawFieldFnCall = globals.gsGetRawFieldFnCall(tableCamelName, fdef.camelCaseFieldName)
  let innerSchemaBuilderDeclaration =
    `${innerTableAccessorName}: buildTableSchemaField(${gsGetRawFieldFnCall})`
  let scalarFieldDecl: string => string = scalarReadFnName => {
    `{
      read: encloseAndTypeScalarRead(${globals.recordBuilderRawRecName}, ${gsGetRawFieldFnCall}, ${scalarReadFnName}),
      render: encloseCellRenderer(${globals.recordBuilderRawRecName}, ${gsGetRawFieldFnCall}),
     }`
  }
  let relFieldDecl: (string, string, bool) => string = (
    relRecordBuidlerName,
    relTableCamelName,
    isSingle,
  ) => {
    // it also needs the schema--ensnare it in that closure already
    let loadedRecordBuilder = `${relRecordBuidlerName}(${globals.genericSchemaVarName})`
    let gsAllRelFieldsFnCall = globals.gsGetAllFieldsFnCall(relTableCamelName)
    if isSingle {
      `{
        getRecord: getSingleRecordAsOption(
          ${globals.recordBuilderRawRecName}, 
          ${gsGetRawFieldFnCall}, 
          ${gsAllRelFieldsFnCall},
          false,
          ${loadedRecordBuilder}),
        useRecord: getSingleRecordAsOption(
          ${globals.recordBuilderRawRecName}, 
          ${gsGetRawFieldFnCall}, 
          ${gsAllRelFieldsFnCall},
          true,
          ${loadedRecordBuilder}),
       }`
    } else {
      `{
        getRecords: getMultiRecordAsArray(
          ${globals.recordBuilderRawRecName}, 
          ${gsGetRawFieldFnCall}, 
          ${gsAllRelFieldsFnCall},
          false,
          ${loadedRecordBuilder}),
        useRecords: getMultiRecordAsArray(
          ${globals.recordBuilderRawRecName}, 
          ${gsGetRawFieldFnCall}, 
          ${gsAllRelFieldsFnCall},
          true,
          ${loadedRecordBuilder}),
       }`
    }
  }

  {
    switch fdef.fieldValueType {
    | ScalarRW(scalarish) => {
        let (reasonTypeName, allowedTypes, scalarReadFnName) = scalarTypeNames(scalarish)
        {
          innerRecordAccessorName: innerRecordAccessorName,
          innerTableAccessorName: innerTableAccessorName,
          innerTableFieldTypeDef: innerTableFieldTypeDef,
          innerSchemaBuilderDeclaration: innerSchemaBuilderDeclaration,
          innerRecordFieldTypeDef: `${innerRecordAccessorName}: readWriteScalarRecordField<${reasonTypeName}>`,
          innerRecordBuilderDeclaration: `${innerRecordAccessorName}: ${scalarFieldDecl(
            scalarReadFnName,
          )}`,
          allowedAirtableFieldTypes: allowedTypes,
        }
      }
    | FormulaRollupRO(scalarish) => {
        let (reasonTypeName, _, scalarReadFnName) = scalarTypeNames(scalarish)
        {
          innerRecordAccessorName: innerRecordAccessorName,
          innerTableAccessorName: innerTableAccessorName,
          innerTableFieldTypeDef: innerTableFieldTypeDef,
          innerSchemaBuilderDeclaration: innerSchemaBuilderDeclaration,
          innerRecordFieldTypeDef: `${innerRecordAccessorName}: readOnlyScalarRecordField<${reasonTypeName}>`,
          innerRecordBuilderDeclaration: `${innerRecordAccessorName}: ${scalarFieldDecl(
            scalarReadFnName,
          )}`,
          allowedAirtableFieldTypes: formulaAirtableTypes,
        }
      }
    | RelFieldOption(relTable, isSingle) => {
        let relTableContext = parseTable(relTable)
        let (singleRelFieldName, multiRelFieldName) = (
          `singleRelRecordField`,
          `multipleRelRecordField`,
        )
        {
          innerRecordAccessorName: innerRecordAccessorName,
          innerTableAccessorName: innerTableAccessorName,
          innerTableFieldTypeDef: innerTableFieldTypeDef,
          innerSchemaBuilderDeclaration: innerSchemaBuilderDeclaration,
          innerRecordFieldTypeDef: `${innerRecordAccessorName}: ${isSingle
            ? singleRelFieldName
            : multiRelFieldName}<${relTableContext.recordTypeName}>`,
          innerRecordBuilderDeclaration: `${innerRecordAccessorName}: ${relFieldDecl(
            relTableContext.recordBuilderName,
            relTable.camelCaseTableName,
            isSingle,
          )}`,
          allowedAirtableFieldTypes: airtableRelTypes,
        }
      }
    }
  }
}

and parseTable: airtableTableDef => tableCodeGenContext = table => {
  let innerSchemaAccessorName = table.camelCaseTableName
  let tableTypeName = `${table.camelCaseTableName}TableSchema`
  let recordTypeName = `${table.camelCaseTableName}Record`
  {
    innerSchemaAccessorName: innerSchemaAccessorName,
    tableTypeName: tableTypeName,
    recordTypeName: recordTypeName,
    recordBuilderName: `${recordTypeName}Builder`,
    sortParameterTypeName: parameterizeRecordSortParam(recordTypeName),
    innerSchemaTypeDef: `${innerSchemaAccessorName}: ${tableTypeName}`,
  }
}
and parseSchema: array<airtableTableDef> => schemaCodeGenContext = tables => {
  schemaTypeName: `schema`,
  recordOuterTypeDefs: tables->Array.map(recordTypeDef) |> joinWith("\n"),
  tableOuterTypeDefs: tables->Array.map(tableTypeDef) |> joinWith("\n"),
  innerSchemaTableTypeDefs: tables->Array.map(table => {
    parseTable(table).innerSchemaTypeDef
  }) |> commaSepDeclaration,
}
and tableTypeDef: airtableTableDef => string = table => {
  let tcgc = parseTable(table)
  // DO NOT move this into the context object
  // it recurses into related tables, which then recurse back into IT
  // ... thenit blows the stack
  let innerTableViewTypeDefs = table.tableViews->Array.map(vdef => {
    `${vdef.camelCaseViewName}: tableSchemaView<${tcgc.recordTypeName}>`
  }) |> commaSepDeclaration
  let innerTableFieldTypeDefs = table.tableFields->Array.map(field => {
    parseField(table.camelCaseTableName, tcgc.recordTypeName, field).innerTableFieldTypeDef
  }) |> commaSepDeclaration
  `
${tcgc.tableTypeName} = {
  getRecords: array<${tcgc.sortParameterTypeName}> => array<${tcgc.recordTypeName}>,
  useRecords: array<${tcgc.sortParameterTypeName}> => array<${tcgc.recordTypeName}>,
  ${innerTableViewTypeDefs}
  ${innerTableFieldTypeDefs}
}`
}
and recordTypeDef: airtableTableDef => string = table => {
  let tcgc = parseTable(table)
  let innerRecordFieldTypeDefs = table.tableFields->Array.map(field => {
    parseField(table.camelCaseTableName, tcgc.recordTypeName, field).innerRecordFieldTypeDef
  }) |> commaSepDeclaration

  `
${tcgc.recordTypeName} = {
  id: string,
  ${innerRecordFieldTypeDefs}
}
`
}

let schemaTypeDef: array<airtableTableDef> => string = tables => {
  let schemaTypeName = `schema`
  let recordOuterTypeDefs = tables->Array.map(recordTypeDef) |> joinWith("\nand ")
  let tableOuterTypeDefs = tables->Array.map(tableTypeDef) |> joinWith("\nand")
  let innerSchemaTableTypeDefs = tables->Array.map(table => {
    parseTable(table).innerSchemaTypeDef
  }) |> commaSepDeclaration

  `
open Airtable

// warning 30 complains about matching fields in mut recursive types
// and we dgaf in this case... it's p much of intentional
@@warning("-30")


type rec ${recordOuterTypeDefs}
and ${tableOuterTypeDefs}

type ${schemaTypeName} = {
  ${innerSchemaTableTypeDefs}
}`
}

let rec schemaBuilderDef: array<airtableTableDef> => string = tdefs => {
  let innerSchemaBuilderDecls = tdefs->Array.map(tdef => {
    `${tdef.camelCaseTableName}: ${tableBuilderDef(tdef)}`
  }) |> commaSepDeclaration
  let recordBuilderDecls = tdefs->Array.map(recordBuilderDef) |> joinWith(" and ")
  `

let rec ${recordBuilderDecls}

let buildSchema: array<airtableTableDef> => schema = tdefs => {
  switch(buildGenericSchema(tdefs)) {
  | Err(errstr) => Js.Exn.raiseError(errstr)
  | Ok(${globals.genericSchemaVarName}) => {
    ${innerSchemaBuilderDecls}
  }  
  }
}
`
}
and tableBuilderDef: airtableTableDef => string = tdef => {
  let tctx = parseTable(tdef)
  let innerSchemaBuilderDeclarations =
    tdef.tableFields->Array.map(fdef =>
      parseField(tdef.camelCaseTableName, tctx.recordTypeName, fdef).innerSchemaBuilderDeclaration
    ) |> commaSepDeclaration

  let getRecordBody = (viewNameOption, shouldUse) => {
    let getQueryFnName =
      viewNameOption->Option.mapWithDefault(`getTableRecordsQueryResult`, _ =>
        `getViewRecordsQueryResult`
      )
    let getRawObjFnCall =
      viewNameOption->Option.mapWithDefault(
        globals.gsGetRawTableFnCall(tdef.camelCaseTableName),
        viewCamelName => globals.getRawViewFnCall(tdef.camelCaseTableName, viewCamelName),
      )
    let getRawFieldsFnCall = globals.gsGetAllFieldsFnCall(tdef.camelCaseTableName)
    `(sortParams) => 
    ${getQueryFnName}(
      ${getRawObjFnCall},
      ${getRawFieldsFnCall},
      sortParams)->getOrUseQueryResult(
        ${shouldUse
      ? "true"
      : "false"},
        ${tctx.recordBuilderName}(${globals.genericSchemaVarName})
        )`
  }

  let innerViewBuilderDeclarations = tdef.tableViews->Array.map(vdef => {
    `${vdef.camelCaseViewName}: {
      getRecords: ${getRecordBody(
      Some(vdef.camelCaseViewName),
      false,
    )},
      useRecords: ${getRecordBody(Some(vdef.camelCaseViewName), true)},
      },`
  }) |> joinWith("\n")

  `{
  getRecords: ${getRecordBody(None, false)},
  useRecords: ${getRecordBody(
    None,
    true,
  )},
  // don't put a comma after this, it comes from above
  ${innerViewBuilderDeclarations}
  ${innerSchemaBuilderDeclarations}
}`
}
and recordBuilderDef: airtableTableDef => string = tdef => {
  let tctx = parseTable(tdef)
  let innerRecordBuilderDeclarations = tdef.tableFields->Array.map(fdef => {
    parseField(tdef.camelCaseTableName, tctx.recordTypeName, fdef).innerRecordBuilderDeclaration
  }) |> commaSepDeclaration
  `
${tctx.recordBuilderName}: (genericSchema, airtableRawRecord) => ${tctx.recordTypeName} = (${globals.genericSchemaVarName}, ${globals.recordBuilderRawRecName}) => {
  id: ${globals.recordBuilderRawRecName}.id,
  ${innerRecordBuilderDeclarations}
}
`
}

let outputEntireSchemaAsString: array<airtableTableDef> => string = tables => {
  `
${schemaTypeDef(tables)}
${schemaBuilderDef(tables)}
`
}

/*
CORE DATATYPES INSIDE SCHEMAS
CORE DATATYPES INSIDE SCHEMAS
CORE DATATYPES INSIDE SCHEMAS
and helpful functions for implementing schemas
*/

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
  airtableRawRecord,
  airtableRawField,
  (airtableRawRecord, airtableRawField) => 'scalarish,
  unit,
) => 'scalarish = (rawRec, rawField, fn, _) => {
  fn(rawRec, rawField)
}
// cell renderer is even easier as it's completely polymorphic
let encloseCellRenderer: (airtableRawRecord, airtableRawField, unit) => React.element = (
  record,
  field,
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

let getOrUseQueryResult: (
  airtableRawRecordQueryResult,
  bool,
  airtableRawRecord => 'recordT,
) => array<'recordT> = (qres, shouldUse, wrap) => {
  (shouldUse ? useRecords(qres) : qres.records)->Array.map(wrap)
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

/*
GENERIC TABLE TYPE
*/

let getTable: (
  airtableRawBase,
  airtableObjectResolutionMethod,
) => result<string, airtableRawTable> = (o, rm) => {
  switch rm {
  | ByName(name) => getTableByName(o, name)->optionToError(`cannot dereference table ${name}`)
  }
}

let getView: (
  airtableRawTable,
  airtableObjectResolutionMethod,
) => result<string, airtableRawView> = (o, rm) => {
  switch rm {
  | ByName(name) => getViewByName(o, name)->optionToError(`cannot dereference view ${name}`)
  }
}

let getField: (
  airtableRawTable,
  airtableFieldResolutionMethod,
) => result<string, airtableRawField> = (o, rm) => {
  switch rm {
  | ByName(name) => getFieldByName(o, name)->optionToError(`cannot dereference field ${name}`)
  | PrimaryField => Ok(o.primaryField)
  }
}
let swallowTuple: (('a, result<'err, 'succ>)) => result<'err, ('a, 'succ)> = ((l, res)) => {
  switch res {
  | Err(err) => Err(err)
  | Ok(succ) => Ok(l, succ)
  }
}
type genericField = {
  field: airtableRawField,
  ctx: fieldCodeGenContext,
}

type genericTable = {
  table: airtableRawTable,
  views: Map.String.t<airtableRawView>,
  fields: Map.String.t<genericField>,
  ctx: tableCodeGenContext,
}

type genericSchema = {tables: Map.String.t<genericTable>}
let gsGetRawTable: (genericSchema, string) => airtableRawTable = (gs, tablecam) => {
  (gs.tables->Map.String.getExn(tablecam)).table
}
let gsGetAllFieldsForTable: (genericSchema, string) => array<airtableRawField> = (gs, tablecam) => {
  (gs.tables->Map.String.getExn(tablecam)).fields
  ->Map.String.valuesToArray
  ->Array.map(genfield => genfield.field)
}
let gsGetRawField: (genericSchema, string, string) => airtableRawField = (
  gs,
  tablecam,
  fieldcam,
) => {
  ((gs.tables->Map.String.getExn(tablecam)).fields->Map.String.getExn(fieldcam)).field
}
let gsGetRawView: (genericSchema, string, string) => airtableRawView = (gs, tablecam, viewcam) => {
  (gs.tables->Map.String.getExn(tablecam)).views->Map.String.getExn(viewcam)
}

let buildGenericField: (
  airtableRawTable,
  airtableFieldDef,
  string,
  string,
) => result<string, genericField> = (rawtab, fdef, tableCamelName, recordTypeName) => {
  switch getField(rawtab, fdef.resolutionMethod) {
  | Err(err) => Err(err)
  | Ok(field) => {
      let fdeets = parseField(tableCamelName, recordTypeName, fdef)
      if fdeets.allowedAirtableFieldTypes->Array.some(allow => allow == field._type) {
        Ok({
          field: field,
          ctx: fdeets,
        })
      } else {
        Err(
          `field[${field.name}]'s type [${field._type}] is not allowed. allowed types are [${fdeets.allowedAirtableFieldTypes |> joinWith(
            ",",
          )}]`,
        )
      }
    }
  }
}

let buildGenericTable: (airtableRawBase, airtableTableDef) => result<string, genericTable> = (
  base,
  tdef,
) => {
  let ctx = parseTable(tdef)
  switch getTable(base, tdef.resolutionMethod) {
  | Err(err) => Err(err)
  | Ok(table) =>
    let (viewErrors, viewTups) = tdef.tableViews->Array.map(vdef => {
      (vdef.camelCaseViewName, getView(table, vdef.resolutionMethod)) |> swallowTuple
    }) |> partitionErrors
    let (fieldErrors, fieldTups) = tdef.tableFields->Array.map(fdef => {
      (
        fdef.camelCaseFieldName,
        buildGenericField(table, fdef, tdef.camelCaseTableName, ctx.recordTypeName),
      ) |> swallowTuple
    }) |> partitionErrors
    switch Array.concat(viewErrors, fieldErrors) {
    | [] =>
      Ok({
        table: table,
        views: Map.String.fromArray(viewTups),
        fields: Map.String.fromArray(fieldTups),
        ctx: parseTable(tdef),
      })
    | lst => Err(lst |> joinWith("\n"))
    }
  }
}

let buildGenericSchema: array<airtableTableDef> => result<string, genericSchema> = tdefs => {
  let base = useBase()
  let (errstrs, gttups) =
    tdefs->Array.map(tdef =>
      (tdef.camelCaseTableName, buildGenericTable(base, tdef)) |> swallowTuple
    ) |> partitionErrors
  switch errstrs |> joinWith("\n") {
  | "" => Ok({tables: Map.String.fromArray(gttups)})
  | errstr => Err(errstr)
  }
}
