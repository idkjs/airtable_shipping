open Belt
open Airtable
open SchemaDefinition
open Util

type rec genericSchema = {
  fields: Map.String.t<scalarishField>,
  tableish: Map.String.t<veryGenericQueryable<airtableRawRecord>>,
  rels: Map.String.t<airtableRawRecord => veryGenericQueryable<airtableRawRecord>>,
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
and veryGenericQueryable<'qType> = {
  getRecord: unit => option<'qType>,
  useRecord: unit => option<'qType>,
  getRecords: array<airtableRawSortParam> => array<'qType>,
  useRecords: array<airtableRawSortParam> => array<'qType>,
}

let mapVGQ: (veryGenericQueryable<'a>, 'a => 'b) => veryGenericQueryable<'b> = (orig, map) => {
  getRecord: p => orig.getRecord(p)->Option.map(map),
  useRecord: p => orig.useRecord(p)->Option.map(map),
  getRecords: p => orig.getRecords(p)->Array.map(map),
  useRecords: p => orig.useRecords(p)->Array.map(map),
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

  // string keys on the outside of the results for the object
  let (allKeys, fieldPairs, allFieldsPairs, vgqs, relVgqs): (
    array<string>,
    array<(string, objResult<scalarishField>)>,
    array<(string, objResult<array<airtableRawField>>)>,
    array<(
      string,
      objResult<(string => array<airtableRawField>) => veryGenericQueryable<airtableRawRecord>>,
    )>,
    array<(
      string,
      objResult<
        (
          string => array<airtableRawField>,
          airtableRawRecord,
        ) => veryGenericQueryable<airtableRawRecord>,
      >,
    )>,
  ) =
    tdefs->Array.reduce(([], [], [], [], []), ((
      strAccum,
      fieldAccum,
      allFieldsAccum,
      vgqAccum,
      relVgqAccum,
    ), tdef) => {
      let buildVGQ: (
        array<airtableRawSortParam> => airtableRawRecordQueryResult
      ) => veryGenericQueryable<airtableRawRecord> = getQ => {
        let useQueryResult: (airtableRawRecordQueryResult, bool) => array<airtableRawRecord> = (
          q,
          use,
        ) => use ? useRecords(q) : q.records
        {
          getRecords: params => params->getQ->useQueryResult(false),
          useRecords: params => params->getQ->useQueryResult(true),
          getRecord: () => []->getQ->useQueryResult(false)->Array.get(0),
          useRecord: () => []->getQ->useQueryResult(true)->Array.get(0),
        }
      }

      let allStrings: array<(string, _)> => array<string> = arr => arr->Array.map(first)
      let tableVGQPair = (
        tdef.camelCaseTableName,
        getTable(base, tdef.resolutionMethod)->resultAndThen(table => Ok(
          getAllFields =>
            buildVGQ(getTableRecordsQueryResult(table, getAllFields(tdef.camelCaseTableName))),
        )),
      )

      let viewVGQPairs =
        tdef.tableViews->Array.map(vdef => (
          vdef.camelCaseViewName,
          getView(base, tdef.resolutionMethod, vdef.resolutionMethod)->resultAndThen(view => {
            Ok(
              getAllFields => {
                buildVGQ(getViewRecordsQueryResult(view, getAllFields(tdef.camelCaseTableName)))
              },
            )
          }),
        ))

      let relVGQPair =
        tdef.tableFields->Array.map(fdef => (
          fdef.camelCaseFieldName,
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)->resultAndThen(field =>
            switch fdef.fieldValueType {
            | RelFieldOption(relTableDef, _) =>
              Ok(
                (getAllFields, record) =>
                  buildVGQ(
                    getLinkedRecordQueryResult(
                      record,
                      field,
                      getAllFields(relTableDef.camelCaseTableName),
                    ),
                  ),
              )

            | _ => Err("throw this away")
            }
          ),
        ))
      let tableFieldPairs = tdef.tableFields->Array.map(fdef => {
        let allowedAirtableFieldTypes = fdef.fieldValueType->allowedAirtableFieldTypes
        let allowListStr = allowedAirtableFieldTypes |> joinWith(",")
        (
          // scalarish field stuff
          fdef.camelCaseFieldName,
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)->resultAndThen(field => {
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
        )
      })
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
          viewVGQPairs->allStrings,
          tableFieldPairs->allStrings,
        ]),
        fieldAccum->Array.concat(tableFieldPairs),
        allFieldsAccum->Array.concat([allFieldsPair]),
        Array.concatMany([vgqAccum, [tableVGQPair], viewVGQPairs]),
        relVgqAccum->Array.concat(relVGQPair),
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

  let (fieldErrors, fieldMap) = buildDict(fieldPairs)
  let (_, allFieldMap) = buildDict(allFieldsPairs)
  let (vqgErrors, tableishMap) = buildDict(vgqs)
  let (_, relMap) = buildDict(relVgqs)
  let mapGetAllFields: ((string => array<airtableRawField>) => _) => _ = thing =>
    thing(allFieldMap->Map.String.getExn)

  let allErrors = Array.concatMany([repeatedKeyErrors, fieldErrors, vqgErrors])

  switch allErrors {
  | [] =>
    Ok({
      fields: fieldMap,
      tableish: tableishMap->Map.String.map(mapGetAllFields),
      rels: relMap->Map.String.map(mapGetAllFields),
    })
  | _ => Err(allErrors |> joinWith("\n"))
  }
}

let getField: (genericSchema, string) => scalarishField = (objs, key) =>
  objs.fields->Map.String.getExn(key)

let getQueryableTableOrView: (
  genericSchema,
  string,
  (genericSchema, airtableRawRecord) => 'recordT,
) => veryGenericQueryable<'recordT> = (gschem, keystr, wrap) => {
  let tbish = gschem.tableish->Map.String.getExn(keystr)
  // parameterize with a way to get all fields
  tbish->mapVGQ(wrap(gschem))
}

let getQueryableRelField: (
  genericSchema,
  string,
  (genericSchema, airtableRawRecord) => 'recordT,
  airtableRawRecord,
) => veryGenericQueryable<'recordT> = (gschem, keystr, wrap, rawRec) => {
  let rels = gschem.rels->Map.String.getExn(keystr)
  // parameterize with a way to get all fields
  rawRec->rels->mapVGQ(wrap(gschem))
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
  declareGetAndUse: string,
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

let relFieldDeclBuilder: (string, string, bool, bool) => (string, string) = (
  targetRecordTypeName,
  invokeQueryable,
  isSingle,
  inBrackets,
) => {
  let s_ = isSingle ? "" : "s"
  let (o_, c_) = inBrackets ? ("{", "}") : ("", "")
  (
    isSingle
      ? `singleRelRecordField<${targetRecordTypeName}>`
      : `multipleRelRecordField<${targetRecordTypeName}>`,
    `${o_}
      getRecord${s_}: ${invokeQueryable}.getRecord${s_},
      useRecord${s_}: ${invokeQueryable}.useRecord${s_}${c_}`,
  )
}
let getFieldMergeVars = (
  ~fieldDef: airtableFieldDef,
  ~genericSchemaVarName: string,
  ~rawRecordVarName: string,
  ~parentRecordTypeName: string,
) => {
  let getFieldInvocation = `getField(${genericSchemaVarName},"${fieldDef.camelCaseFieldName}")`
  let getRelFieldInvocation: string => string = wrapperName =>
    `getQueryableRelField(${genericSchemaVarName},"${fieldDef.camelCaseFieldName}", ${wrapperName}, ${rawRecordVarName})`
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
      let (recordFieldTypeName, fieldBuilder) = {
        let builderStr = s_ => {
          let rfd = getRelFieldInvocation(recordBuilderFnName)
          `{getRecord${s_}: ${rfd}.getRecord${s_},useRecord${s_}: ${rfd}.useRecord${s_}}`
        }
        isSingle
          ? (`singleRelRecordField`, builderStr(""))
          : (`multipleRelRecordField`, builderStr("s"))
      }
      (`${recordFieldTypeName}<${tableRecordTypeName}>`, fieldBuilder)
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
      let getQueryableTableOrViewInvocation: string => string = tableishNameStr =>
        `getQueryableTableOrView(${genericSchemaVarName},"${tableishNameStr}",${recordBuilderFnName})`
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
          let (typeStr, declStr) = relFieldDeclBuilder(
            tableRecordTypeName,
            getQueryableTableOrViewInvocation(vdef.camelCaseViewName),
            false,
            true,
          )
          let getViewInvocation = `getView(${genericSchemaVarName},"${vdef.camelCaseViewName}")`
          ((vdef.camelCaseViewName, typeStr), (vdef.camelCaseViewName, declStr))
        })->Array.unzip
      {
        //rec
        recordTypeName: tableRecordTypeName,
        recordBuilderFnName: recordBuilderFnName,
        recordVarNamesToTypes: recordVarNamesToTypes,
        recordVarNamesToBuilderInvocation: recordVarNamesToBuilderInvocation,
        // tab
        tableSchemaAccessorName: tdef.camelCaseTableName,
        declareGetAndUse: {
          let (_, dgau) = relFieldDeclBuilder(
            tableRecordTypeName,
            getQueryableTableOrViewInvocation(tdef.camelCaseTableName),
            false,
            false,
          )
          dgau
        },
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
    declareGetAndUse,
  }) => {
    `${tableSchemaAccessorName}: {
        ${declareGetAndUse},
        ${tableViewNamesToBuilderInvocations->fieldDecl}
        ${tableVarNamesToBuilderInvocation->fieldDecl}
    },`
  }) |> joinWith("\n")

  `
open Airtable
open SchemaDefinition
open GenericSchema

type rec ${recursiveRecordTypeDeclarations} and ${recursiveTableTypeDeclarations}

type ${schemaTypeName} = {
  ${schemaInnerTypeDecl}
}

let rec ${recursiveRecordBuilderDeclarations}

let buildSchema: array<airtableTableDef> => ${schemaTypeName} = tdefs => {
  let base = useBase()
  switch(dereferenceGenericSchema(base,tdefs)) {
    | Err(errstr) => Js.Exn.raiseError(errstr)
    | Ok(gschem) => {
      ${schemaBuilderTableDeclarations}
    }
  }
}
  `
}
