open Belt
open AirtableRaw
open Util
open SchemaDefinition

type rec genericSchema = {
  tables: Map.String.t<genericQueryable<airtableRawTable>>,
  views: Map.String.t<genericQueryable<airtableRawView>>,
  fields: Map.String.t<scalarishField>,
  relFields: Map.String.t<relField>,
  allFields: Map.String.t<array<airtableRawField>>,
}
and relField = {
  getRelQueryResult: (
    genericSchema,
    airtableRawRecord,
    array<airtableRawSortParam>,
  ) => airtableRawRecordQueryResult,
}
and scalarishRecordFieldBuilder<'scalarish> = {
  buildReadOnly: airtableRawRecord => readOnlyScalarRecordField<'scalarish>,
  buildReadWrite: airtableRawRecord => readWriteScalarRecordField<'scalarish>,
}
and scalarishField = {
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
and genericQueryable<'atObj> = {
  rawAirtableObject: 'atObj,
  getQueryResult: (genericSchema, array<airtableRawSortParam>) => airtableRawRecordQueryResult,
}

let buildScalarishRecordFieldBuilder = (rawField, prepFn) => {
  buildReadOnly: rawRec => {
    read: encloseAndTypeScalarRead(rawField, prepFn, rawRec),
    render: encloseCellRenderer(rawField, rawRec),
  },
  buildReadWrite: rawRec => {
    read: encloseAndTypeScalarRead(rawField, prepFn, rawRec),
    render: encloseCellRenderer(rawField, rawRec),
  },
}
type objResult<'at> = result<string, 'at>

let dereferenceGenericSchema: (
  airtableRawBase,
  array<airtableTableDef>,
) => result<string, genericSchema> = (base, tdefs) => {
  let getTable: (
    airtableRawBase,
    airtableObjectResolutionMethod,
  ) => result<string, airtableRawTable> = (base, resmeth) => {
    switch resmeth {
    | ByName(name) =>
      getTableByName(base, name)->optionToError(`cannot dereference table by name ${name}`)
    }
  }

  let getView: (
    airtableRawBase,
    airtableObjectResolutionMethod,
    airtableObjectResolutionMethod,
  ) => result<string, airtableRawView> = (base, tableres, viewres) => {
    getTable(base, tableres)->resultAndThen(table =>
      switch viewres {
      | ByName(name) =>
        getViewByName(table, name)->optionToError(`cannot dereference view by name ${name}`)
      }
    )
  }

  let getField: (
    airtableRawBase,
    airtableObjectResolutionMethod,
    airtableFieldResolutionMethod,
  ) => result<string, airtableRawField> = (base, tableres, fieldres) => {
    getTable(base, tableres)->resultAndThen(table =>
      switch fieldres {
      | ByName(name) =>
        getFieldByName(table, name)->optionToError(`cannot dereference field by name ${name}`)
      | PrimaryField => Ok(table.primaryField)
      }
    )
  }

  let getAllFieldsFromMyOwnSelfLater: (genericSchema, string) => array<airtableRawField> = (
    gschem,
    key,
  ) => gschem.allFields->Map.String.getExn(key)

  // string keys on the outside of the results for the object
  let (allKeys, tablePairs, viewPairs, fieldPairs, allFieldsPairs, relFieldsPairs): (
    array<string>,
    array<(string, objResult<genericQueryable<airtableRawTable>>)>,
    array<(string, objResult<genericQueryable<airtableRawView>>)>,
    array<(string, objResult<scalarishField>)>,
    array<(string, objResult<array<airtableRawField>>)>,
    array<(string, objResult<relField>)>,
  ) =
    tdefs->Array.reduce(([], [], [], [], [], []), ((
      strAccum,
      tabAccum,
      viewAccum,
      fieldAccum,
      allFieldsAccum,
      relFieldsAccum,
    ), tdef) => {
      let allStrings: array<(string, _)> => array<string> = arr => arr->Array.map(first)
      let tablePair = (
        tdef.camelCaseTableName,
        getTable(base, tdef.resolutionMethod)->resultAndThen(table => Ok({
          rawAirtableObject: table,
          getQueryResult: (gschem, sorts) =>
            getTableRecordsQueryResult(
              table,
              gschem->getAllFieldsFromMyOwnSelfLater(tdef.camelCaseTableName),
              sorts,
            ),
        })),
      )
      let tableViewPairs = tdef.tableViews->Array.map(vdef => {
        (
          vdef.camelCaseViewName,
          getView(base, tdef.resolutionMethod, vdef.resolutionMethod)->resultAndThen(view => {
            Ok({
              rawAirtableObject: view,
              getQueryResult: (gschem, sorts) =>
                getViewRecordsQueryResult(
                  view,
                  gschem->getAllFieldsFromMyOwnSelfLater(tdef.camelCaseTableName),
                  sorts,
                ),
            })
          }),
        )
      })
      let (tableFieldPairs, relFieldsOptPairs) = tdef.tableFields->Array.map(fdef => {
        let field = getField(base, tdef.resolutionMethod, fdef.resolutionMethod)
        let allowedAirtableFieldTypes = fdef.fieldValueType->allowedAirtableFieldTypes
        let allowListStr = allowedAirtableFieldTypes |> joinWith(",")
        (
          (
            // scalarish field stuff
            fdef.camelCaseFieldName,
            field->resultAndThen(field => {
              if allowedAirtableFieldTypes->Array.some(atTypeName => {
                atTypeName->trimLower == field._type->trimLower
              }) {
                Ok({
                  rawField: field,
                  string: buildScalarishRecordFieldBuilder(field, getString),
                  stringOpt: buildScalarishRecordFieldBuilder(field, getStringOption),
                  int: buildScalarishRecordFieldBuilder(field, getInt),
                  bool: buildScalarishRecordFieldBuilder(field, getBool),
                  intBool: buildScalarishRecordFieldBuilder(field, getIntAsBool),
                  momentOption: buildScalarishRecordFieldBuilder(field, getMomentOption),
                  sortAsc: {field: field, direction: `asc`},
                  sortDesc: {field: field, direction: `desc`},
                })
              } else {
                Err(
                  `field ${field.name} has type of ${field._type} but only types [${allowListStr}] are allowed`,
                )
              }
            }),
          ),
          // relfield opt pair
          (fdef.camelCaseFieldName, field->resultAndThen(field => {
              switch fdef.fieldValueType {
              | RelFieldOption(relTableDef, _) =>
                Ok({
                  getRelQueryResult: (gschem, record, sorts) => {
                    let allFields = getAllFieldsFromMyOwnSelfLater(
                      gschem,
                      relTableDef.camelCaseTableName,
                    )

                    getLinkedRecordQueryResult(record, field, allFields, sorts)
                  },
                })
              | _ => Err("throw this away")
              }
            })),
        )
      })->Array.unzip
      let allFieldsPair = {
        // throw away the errors
        let (_, allFields) = tableFieldPairs->Array.map(second) |> partitionErrors
        (
          tdef.camelCaseTableName,
          Ok(allFields->Array.map(scalarishField => scalarishField.rawField)),
        )
      }
      //actually return the variously harvested values in this fat tuple
      (
        Array.concatMany([
          strAccum,
          [tdef.camelCaseTableName],
          tableViewPairs->allStrings,
          tableFieldPairs->allStrings,
        ]),
        tabAccum->Array.concat([tablePair]),
        viewAccum->Array.concat(tableViewPairs),
        fieldAccum->Array.concat(tableFieldPairs),
        allFieldsAccum->Array.concat([allFieldsPair]),
        relFieldsAccum->Array.concat(relFieldsOptPairs),
      )
    })

  let (repeatedKeyErrors, _) = allKeys->Array.reduce(([], Set.String.empty), ((
    errors,
    encountered,
  ), str) => {
    if encountered->Set.String.has(str) {
      (errors->Array.concat([`string key appears multiple times in schema: ${str}`]), encountered)
    } else {
      (errors, encountered->Set.String.add(str))
    }
  })

  let buildDict: array<(string, objResult<_>)> => (array<string>, Map.String.t<_>) = arrOfTup => {
    arrOfTup->Array.reduce(([], Map.String.empty), ((errStrings, theMap), (stringKey, result)) => {
      switch result {
      | Ok(thing) => (errStrings, theMap->Map.String.set(stringKey, thing))
      | Err(err) => (errStrings->Array.concat([err]), theMap)
      }
    })
  }

  let (tableErrors, tableMap) = buildDict(tablePairs)
  let (viewErrors, viewMap) = buildDict(viewPairs)
  let (fieldErrors, fieldMap) = buildDict(fieldPairs)
  let (_, allFieldMap) = buildDict(allFieldsPairs)
  let (_, relFieldMap) = buildDict(relFieldsPairs)
  let allErrors = Array.concatMany([repeatedKeyErrors, tableErrors, viewErrors, fieldErrors])

  switch allErrors {
  | [] =>
    Ok({
      tables: tableMap,
      views: viewMap,
      fields: fieldMap,
      allFields: allFieldMap,
      relFields: relFieldMap,
    })
  | _ => Err(allErrors |> joinWith("\n"))
  }
}

let getTable: (genericSchema, string) => genericQueryable<airtableRawTable> = (objs, key) =>
  objs.tables->Map.String.getExn(key)
let getView: (genericSchema, string) => genericQueryable<airtableRawView> = (objs, key) =>
  objs.views->Map.String.getExn(key)
let getField: (genericSchema, string) => scalarishField = (objs, key) =>
  objs.fields->Map.String.getExn(key)
let getAllFields: (genericSchema, string) => array<airtableRawField> = (objs, key) =>
  objs.allFields->Map.String.getExn(key)
let getRelField: (genericSchema, string) => relField = (objs, key) =>
  objs.relFields->Map.String.getExn(key)

let buildSingleRelRecordField: (
  genericSchema,
  relField,
  (genericSchema, airtableRawRecord) => 'recordT,
  airtableRawRecord,
) => singleRelRecordField<'relT> = (gschem, relF, wrapRec, rawRec) => {
  getRecord: _ =>
    relF.getRelQueryResult(gschem, rawRec, [])->getOrUseQueryResultSingle(false, wrapRec(gschem)),
  useRecord: _ =>
    relF.getRelQueryResult(gschem, rawRec, [])->getOrUseQueryResultSingle(true, wrapRec(gschem)),
}
let buildMultipleRelRecordField: (
  genericSchema,
  relField,
  (genericSchema, airtableRawRecord) => 'recordT,
  airtableRawRecord,
) => multipleRelRecordField<'relT> = (gschem, relF, wrapRec, rawRec) => {
  getRecords: _ =>
    relF.getRelQueryResult(gschem, rawRec, [])->getOrUseQueryResult(false, wrapRec(gschem)),
  useRecords: _ =>
    relF.getRelQueryResult(gschem, rawRec, [])->getOrUseQueryResult(true, wrapRec(gschem)),
}
let buildGetOrUseRecords: (
  genericSchema,
  genericQueryable<_>,
  (genericSchema, airtableRawRecord) => 'recordT,
  bool,
  array<recordSortParam<'recordT>>,
) => array<'recordT> = (gschem, gqbl, wrapRec, shouldUse, sorts) => {
  gqbl.getQueryResult(gschem, sorts)->getOrUseQueryResult(shouldUse, wrapRec(gschem))
}

type rec schemaMergeVars = {
  schemaTypeName: string,
  genericSchemaTypeName: string,
  genericSchemaVarName: string,
  rawRecordVarName: string,
  tableRecordMergeVars: array<tableRecordMergeVars>,
}
and tableRecordMergeVars = {
  // record type
  recordTypeName: string,
  recordBuilderFnName: string,
  recordVarNamesToTypes: array<(string, string)>,
  recordVarNamesToBuilderInvocation: array<(string, string)>,
  // table type
  tableSchemaAccessorName: string,
  getRecordsInvocation: string,
  useRecordsInvocation: string,
  tableTypeName: string,
  typeOfTableRecordAccess: string,
  tableVarNamesToBuilderInvocation: array<(string, string)>,
  tableVarNamesToTypes: array<(string, string)>,
  tableViewNamesToTypes: array<(string, string)>,
  tableViewNamesToBuilderInvocations: array<(string, string)>,
}
and fieldMergeVars = {
  recordVarName: string,
  tableVarName: string,
  recordFieldAccessorStructureType: string,
  recordFieldAccessorBuilderInvocation: string,
  typeOfTableField: string,
  tableFieldBuilderInvocation: string,
}

let getFieldMergeVars = (
  ~fieldDef: airtableFieldDef,
  ~genericSchemaVarName: string,
  ~rawRecordVarName: string,
  ~parentRecordTypeName: string,
) => {
  let getFieldInvocation = `getField(${genericSchemaVarName},"${fieldDef.camelCaseFieldName}")`
  let getRelFieldInvocation =
    `getRelField(${genericSchemaVarName},"${fieldDef.camelCaseFieldName}")`
  let (
    recordFieldAccessorStructureType,
    recordFieldAccessorBuilderInvocation,
  ) = switch fieldDef.fieldValueType {
  | ScalarRW(scalarish) => {
      let {reasonReadReturnTypeName, scalarishFieldBuilderAccessorName} = getScalarTypeContext(
        scalarish,
      )
      (
        `readWriteScalarRecordField<${reasonReadReturnTypeName}>`,
        `${getFieldInvocation}.${scalarishFieldBuilderAccessorName}.buildReadWrite(${rawRecordVarName})`,
      )
    }
  | FormulaRollupRO(scalarish) => {
      let {reasonReadReturnTypeName, scalarishFieldBuilderAccessorName} = getScalarTypeContext(
        scalarish,
      )
      (
        `readOnlyScalarRecordField<${reasonReadReturnTypeName}>`,
        `${getFieldInvocation}.${scalarishFieldBuilderAccessorName}.buildReadOnly(${rawRecordVarName})`,
      )
    }
  | RelFieldOption(relTableDef, isSingle) => {
      let {tableRecordTypeName, recordBuilderFnName} = getTableNamesContext(relTableDef)
      let (recordFieldTypeName, buildFieldFnName) = isSingle
        ? (`singleRelRecordField`, `buildSingleRelRecordField`)
        : (`multipleRelRecordField`, `buildMultipleRelRecordField`)
      (
        `${recordFieldTypeName}<${tableRecordTypeName}>`,
        `${buildFieldFnName}(${genericSchemaVarName},${getRelFieldInvocation},${recordBuilderFnName},${rawRecordVarName})`,
      )
    }
  }
  {
    recordVarName: fieldDef.camelCaseFieldName,
    tableVarName: `${fieldDef.camelCaseFieldName}Field`,
    recordFieldAccessorStructureType: recordFieldAccessorStructureType,
    recordFieldAccessorBuilderInvocation: recordFieldAccessorBuilderInvocation,
    typeOfTableField: `tableSchemaField<${parentRecordTypeName}>`,
    tableFieldBuilderInvocation: `{
      sortAsc: ${getFieldInvocation}.sortAsc,
      sortDesc: ${getFieldInvocation}.sortDesc,
    }`,
  }
}

let getSchemaMergeVars: array<airtableTableDef> => schemaMergeVars = tableDefs => {
  let genericSchemaTypeName = `genericSchema`
  let genericSchemaVarName = `gschem`
  let rawRecordVarName = `rawRec`

  {
    schemaTypeName: `schema`,
    genericSchemaTypeName: genericSchemaTypeName,
    genericSchemaVarName: genericSchemaVarName,
    rawRecordVarName: rawRecordVarName,
    tableRecordMergeVars: tableDefs->Array.map(tdef => {
      let {tableRecordTypeName, recordBuilderFnName} = getTableNamesContext(tdef)
      let getTableInvocation = `getTable(${genericSchemaVarName},"${tdef.camelCaseTableName}")`
      let buildGetOrUseInvocation = (getQueryableInvocation, shouldUse) => {
        let tOrF = shouldUse ? `true` : `false`
        `buildGetOrUseRecords(${genericSchemaVarName}, ${getQueryableInvocation}, ${recordBuilderFnName}, ${tOrF})`
      }
      let (
        recordVarNamesToTypes,
        recordVarNamesToBuilderInvocation,
        tableVarNamesToTypes,
        tableVarNamesToBuilderInvocation,
      ): (
        array<(string, string)>,
        array<(string, string)>,
        array<(string, string)>,
        array<(string, string)>,
      ) =
        tdef.tableFields->Array.map(fdef => {
          let fmv = getFieldMergeVars(
            ~fieldDef=fdef,
            ~genericSchemaVarName,
            ~rawRecordVarName,
            ~parentRecordTypeName=tableRecordTypeName,
          )
          (
            (fmv.recordVarName, fmv.recordFieldAccessorStructureType),
            (fmv.recordVarName, fmv.recordFieldAccessorBuilderInvocation),
            (fmv.tableVarName, fmv.typeOfTableField),
            (fmv.tableVarName, fmv.tableFieldBuilderInvocation),
          )
        })->unzipFour

      let (tableViewNamesToTypes, tableViewNamesToBuilderInvocations): (
        array<(string, string)>,
        array<(string, string)>,
      ) =
        tdef.tableViews->Array.map(vdef => {
          let getViewInvocation = `getView(${genericSchemaVarName},"${vdef.camelCaseViewName}")`
          (
            (vdef.camelCaseViewName, `tableSchemaView<${tableRecordTypeName}>`),
            (
              vdef.camelCaseViewName,
              `{getRecords: ${buildGetOrUseInvocation(
                getViewInvocation,
                false,
              )},
            useRecords: ${buildGetOrUseInvocation(getViewInvocation, true)},}`,
            ),
          )
        })->Array.unzip
      {
        //rec
        recordTypeName: tableRecordTypeName,
        recordBuilderFnName: recordBuilderFnName,
        recordVarNamesToTypes: recordVarNamesToTypes,
        recordVarNamesToBuilderInvocation: recordVarNamesToBuilderInvocation,
        // tab
        tableSchemaAccessorName: tdef.camelCaseTableName,
        getRecordsInvocation: buildGetOrUseInvocation(getTableInvocation, false),
        useRecordsInvocation: buildGetOrUseInvocation(getTableInvocation, true),
        tableTypeName: `${tdef.camelCaseTableName}Table`,
        typeOfTableRecordAccess: `array<${tableRecordTypeName}>`,
        tableVarNamesToBuilderInvocation: tableVarNamesToBuilderInvocation,
        tableVarNamesToTypes: tableVarNamesToTypes,
        tableViewNamesToTypes: tableViewNamesToTypes,
        tableViewNamesToBuilderInvocations: tableViewNamesToBuilderInvocations,
      }
    }),
  }
}

let codeGenSchema: schemaMergeVars => string = ({
  schemaTypeName,
  tableRecordMergeVars,
  genericSchemaTypeName,
  genericSchemaVarName,
  rawRecordVarName,
}) => {
  let fieldDecl: array<(string, string)> => string = arr => {
    arr->Array.map(((var, tdecl)) => `${var}: ${tdecl},`) |> joinWith("\n")
  }

  let recursiveRecordTypeDeclarations = tableRecordMergeVars->Array.map(({
    recordTypeName,
    recordVarNamesToTypes,
  }) => {
    // type of record
    `${recordTypeName} = {
      id: string,
      ${recordVarNamesToTypes->fieldDecl}
    }`
  }) |> joinWith(" and ")

  let recursiveTableTypeDeclarations = tableRecordMergeVars->Array.map(({
    tableTypeName,
    recordTypeName,
    typeOfTableRecordAccess,
    tableVarNamesToTypes,
    tableViewNamesToTypes,
  }) => {
    `${tableTypeName} = {
      getRecords: array<recordSortParam<${recordTypeName}>> => ${typeOfTableRecordAccess},
      useRecords: array<recordSortParam<${recordTypeName}>> => ${typeOfTableRecordAccess},
      ${tableViewNamesToTypes->fieldDecl}
      ${tableVarNamesToTypes->fieldDecl}
    }`
  }) |> joinWith(" and ")

  let schemaInnerTypeDecl =
    tableRecordMergeVars
    ->Array.map(({tableSchemaAccessorName, tableTypeName}) => (
      tableSchemaAccessorName,
      tableTypeName,
    ))
    ->fieldDecl

  let recursiveRecordBuilderDeclarations = tableRecordMergeVars->Array.map(({
    recordTypeName,
    recordBuilderFnName,
    recordVarNamesToBuilderInvocation,
  }) => {
    `${recordBuilderFnName}: (${genericSchemaTypeName}, airtableRawRecord) => ${recordTypeName} = (${genericSchemaVarName}, ${rawRecordVarName}) => {
      id: ${rawRecordVarName}.id,
      ${recordVarNamesToBuilderInvocation->fieldDecl}
    }`
  }) |> joinWith(" and ")

  let schemaBuilderTableDeclarations = tableRecordMergeVars->Array.map(({
    tableSchemaAccessorName,
    tableVarNamesToBuilderInvocation,
    tableViewNamesToBuilderInvocations,
    getRecordsInvocation,
    useRecordsInvocation,
  }) => {
    `${tableSchemaAccessorName}: {
        getRecords : ${getRecordsInvocation},
        useRecords : ${useRecordsInvocation},
        ${tableViewNamesToBuilderInvocations->fieldDecl}
        ${tableVarNamesToBuilderInvocation->fieldDecl}
    },`
  }) |> joinWith("\n")

  `
open AirtableRaw
open SchemaDefinition
open GenericSchema2

type rec ${recursiveRecordTypeDeclarations} and ${recursiveTableTypeDeclarations}

type ${schemaTypeName} = {
  ${schemaInnerTypeDecl}
}

let rec ${recursiveRecordBuilderDeclarations}

let buildSchema: ${genericSchemaTypeName} => ${schemaTypeName} = ${genericSchemaVarName} => {
  ${schemaBuilderTableDeclarations}
}
  `
}
