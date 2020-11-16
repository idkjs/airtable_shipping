open Belt
open Airtable
open SchemaDefinition
open Util

/*
These are the types necessary to implement a 
"Generic Schema" that can do all the actions our 
typed API can do. It's designed NOT to have all the 
type guarantees, as it's used by the generated schema
(also you can't store all the subtyped things neatly)

Basically there are scalar things and queryable things. 
In each case we wrap the record with all the possibly useful 
functions and then link the correct instances of those
to the matching, typed, field in the generated schema.
*/
type rec genericSchema = {
  // read or readwrite to any kind of non relationship field
  fields: Map.String.t<scalarishField>,
  // things that can just return query results
  tableish: Map.String.t<veryGenericQueryable<airtableRawRecord>>,
  // things which need a record to return a query result
  rels: Map.String.t<airtableRawRecord => veryGenericQueryable<airtableRawRecord>>,
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
and scalarishRecordFieldBuilder<'scalarish> = {
  // utility type for scalarish
  buildReadOnly: airtableRawRecord => readOnlyScalarRecordField<'scalarish>,
  buildReadWrite: airtableRawRecord => readWriteScalarRecordField<'scalarish>,
}
and veryGenericQueryable<'qType> = {
  // query single
  getRecord: unit => option<'qType>,
  useRecord: unit => option<'qType>,
  // query multiple
  getRecords: array<airtableRawSortParam> => array<'qType>,
  useRecords: array<airtableRawSortParam> => array<'qType>,
}

// allows any VGQ object to be wrapped into
// a fully typed record builder type
let mapVGQ: (veryGenericQueryable<'a>, 'a => 'b) => veryGenericQueryable<'b> = (orig, map) => {
  getRecord: p => orig.getRecord(p)->Option.map(map),
  useRecord: p => orig.useRecord(p)->Option.map(map),
  getRecords: p => orig.getRecords(p)->Array.map(map),
  useRecords: p => orig.useRecords(p)->Array.map(map),
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
type objResult<'at> = Result.t<'at, string>

/*
Return all the errors we can from schema creation in 
one go. This makes it faster to diagnose errors in the 
application due to missing fields--they crash right away
*/
let dereferenceGenericSchema: (
  airtableRawBase,
  array<airtableTableDef>,
) => Result.t<genericSchema, string> = (base, tdefs) => {
  // result based access for raw objects
  let getTable: (
    airtableRawBase,
    airtableObjectResolutionMethod,
  ) => Result.t<airtableRawTable, string> = (base, resmeth) => {
    switch resmeth {
    | ByName(name) =>
      getTableByName(base, name)->optionToError(`cannot dereference table by name ${name}`)
    }
  }

  let getView: (
    airtableRawBase,
    airtableObjectResolutionMethod,
    airtableObjectResolutionMethod,
  ) => Result.t<airtableRawView, string> = (base, tableres, viewres) => {
    getTable(base, tableres)->Result.flatMap(table =>
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
  ) => Result.t<airtableRawField, string> = (base, tableres, fieldres) => {
    getTable(base, tableres)->Result.flatMap(table =>
      switch fieldres {
      | ByName(name) =>
        getFieldByName(table, name)->optionToError(`cannot dereference field by name ${name}`)
      | PrimaryField => Ok(table.primaryField)
      }
    )
  }

  // everything from airtable comes back as a query result if you want it that way
  // this takes a function that provides one and creates a generic queryable thing
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

  /** 
  gather together all the results of recursion down the the schema tree

  most results are keyed with strings to feed into dictionary generators
 */
  let (allKeys, fieldPairs, allFieldsPairs, vgqs, relVgqs): (
    // all the string keys (must be unique--check that later)
    array<string>,
    // all scalarish fields
    array<(string, objResult<scalarishField>)>,
    array<(string, objResult<array<airtableRawField>>)>,
    // these lengthier results need to be
    // parameterized in order to actually return
    // something meaningful
    array<(
      string,
      // getfields
      objResult<(string => array<airtableRawField>) => veryGenericQueryable<airtableRawRecord>>,
    )>,
    array<(
      string,
      objResult<
        (
          // getfields
          string => array<airtableRawField>,
          // record for linked records
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
      let allStrings: array<(string, _)> => array<string> = arr => arr->Array.map(first)
      let tableVGQPair = (
        tdef.camelCaseTableName,
        getTable(base, tdef.resolutionMethod)->Result.flatMap(table => Ok(
          getAllFields =>
            buildVGQ(getTableRecordsQueryResult(table, getAllFields(tdef.camelCaseTableName))),
        )),
      )

      let viewVGQPairs =
        tdef.tableViews->Array.map(vdef => (
          vdef.camelCaseViewName,
          getView(base, tdef.resolutionMethod, vdef.resolutionMethod)->Result.flatMap(view => {
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
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)->Result.flatMap(field =>
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
            | _ => Error("throw this away")
            }
          ),
        ))
      let tableFieldPairs = tdef.tableFields->Array.map(fdef => {
        let allowedAirtableFieldTypes = fdef.fieldValueType->allowedAirtableFieldTypes
        let allowListStr = allowedAirtableFieldTypes |> joinWith(",")
        (
          // scalarish field stuff
          fdef.camelCaseFieldName,
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)->Result.flatMap(field => {
            if allowedAirtableFieldTypes->Array.some(atTypeName => {
              atTypeName->trimLower == field._type->trimLower
            }) {
              Ok({
                rawField: field,
                string: scalarishBuilder(field, getString),
                stringOpt: scalarishBuilder(field, getStringOption),
                int: scalarishBuilder(field, getInt),
                bool: scalarishBuilder(field, getBool),
                intBool: scalarishBuilder(field, getIntAsBool),
                momentOption: scalarishBuilder(field, getMomentOption),
                sortAsc: {field: field, direction: `asc`},
                sortDesc: {field: field, direction: `desc`},
              })
            } else {
              Error(
                `field ${field.name} has type of ${field._type} but only types [${allowListStr}] are allowed`,
              )
            }
          }),
        )
      })
      let allFieldsPair = {
        // throw away the errors--we get all of them from building up the other arrays
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
      (errors->Array.concat([`string key [${str}] appears multiple times in schema`]), encountered)
    } else {
      (errors, encountered->Set.String.add(str))
    }
  })

  let buildDict: array<(string, objResult<_>)> => (array<string>, Map.String.t<_>) = arrOfTup => {
    arrOfTup->Array.reduce(([], Map.String.empty), ((errStrings, theMap), (stringKey, result)) => {
      switch result {
      | Ok(thing) => (errStrings, theMap->Map.String.set(stringKey, thing))
      | Error(err) => (errStrings->Array.concat([err]), theMap)
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
  | _ => Error(allErrors |> joinWith("\n"))
  }
}

/**
These three marry the generic schema with the generated schema
by returning the typed version of what were' looking for 
in exchange for various closures 
*/

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

/*
Parse the schema definition into the merge vars defined below. 
*/
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

// the rel field declarations are used three separate places, so we need some
// configurability for building the declarations
let relFieldDeclBuilder: (string, string, bool, bool) => (string, string) = (
  targetRecordTypeName,
  invokeQueryable,
  // is this for a single record or multiple
  isSingle,
  // is the declaration wrapped in brackets
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

/*
Write out the type defs and structure defs for the schema. 
It tries to do this in a readable fashion by making relatively simple calls to existing
structures which are coded in ml rather than generated
*/
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

// warnings that complain about matching fields in mut recursive types
// and overlapping labels
// and we dgaf in this case... it's p much of intentional
@@warning("-30")
@@warning("-45")

type rec ${recursiveRecordTypeDeclarations} and ${recursiveTableTypeDeclarations}

type ${schemaTypeName} = {
  ${schemaInnerTypeDecl}
}

let rec ${recursiveRecordBuilderDeclarations}

let buildSchema: array<airtableTableDef> => ${schemaTypeName} = tdefs => {
  let base = useBase()
  switch(dereferenceGenericSchema(base,tdefs)) {
    | Error(errstr) => Js.Exn.raiseError(errstr)
    | Ok(gschem) => {
      ${schemaBuilderTableDeclarations}
    }
  }
}
  `
}
