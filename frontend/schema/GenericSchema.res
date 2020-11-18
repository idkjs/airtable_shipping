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
  ) => Result.t<(airtableRawTable, airtableRawView), string> = (base, tableres, viewres) => {
    getTable(base, tableres)->Result.flatMap(table =>
      switch viewres {
      | ByName(name) =>
        getViewByName(table, name)->optionToError(`cannot dereference view by name ${name}`)
      }->Result.map(view => (table, view))
    )
  }

  let getField: (
    airtableRawBase,
    airtableObjectResolutionMethod,
    airtableFieldResolutionMethod,
  ) => Result.t<(airtableRawTable, airtableRawField), string> = (base, tableres, fieldres) =>
    getTable(base, tableres)->Result.flatMap(table =>
      switch fieldres {
      | ByName(name) =>
        getFieldByName(table, name)->optionToError(`cannot dereference field by name ${name}`)
      | PrimaryField => Ok(table.primaryField)
      }->Result.map(field => (table, field))
    )

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
          getView(base, tdef.resolutionMethod, vdef.resolutionMethod)
          ->Result.map(second)
          ->Result.flatMap(view => {
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
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)
          ->Result.map(second)
          ->Result.flatMap(field =>
            switch fdef.fieldValueType {
            | RelFieldOption(relTableDef, _, _) =>
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
          getField(base, tdef.resolutionMethod, fdef.resolutionMethod)->Result.flatMap(((
            table,
            field,
          )) => {
            if allowedAirtableFieldTypes->Array.some(atTypeName => {
              atTypeName->trimLower == field._type->trimLower
            }) {
              Ok(buildScalarishField(table, field))
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
  relFieldType: string,
  relFieldDeclaration: string,
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
let relFieldDeclBuilder: (string, string, bool) => (string, string) = (
  targetRecordTypeName,
  invokeQueryable,
  // is this for a single record or multiple
  isSingle,
) => (
  isSingle
    ? `singleRelField<${targetRecordTypeName}>`
    : `multipleRelField<${targetRecordTypeName}>`,
  isSingle ? `asSingleRelField(${invokeQueryable})` : `asMultipleRelField(${invokeQueryable})`,
)

let scalarFieldDeclBuilder: (airtableScalarValueDef, string, string, bool) => (string, string) = (
  scalarish,
  invokeGetField,
  rawRecordVarName,
  canWrite,
) => {
  let {reasonReadReturnTypeName, scalarishFieldBuilderAccessorName} = getScalarTypeContext(
    scalarish,
  )
  canWrite
    ? (
        `readWriteScalarRecordField<${reasonReadReturnTypeName}>`,
        `${invokeGetField}.${scalarishFieldBuilderAccessorName}.buildReadWrite(${rawRecordVarName})`,
      )
    : (
        `readOnlyScalarRecordField<${reasonReadReturnTypeName}>`,
        `${invokeGetField}.${scalarishFieldBuilderAccessorName}.buildReadOnly(${rawRecordVarName})`,
      )
}

type relRecordField<'relFieldT, 'scalarFieldT> = {
  rel: 'relFieldT,
  scalar: 'scalarFieldT,
}

let relRecordFieldDeclBuilder: ((string, string), (string, string)) => (string, string) = (
  (relFieldT, relFieldD),
  (scalarFieldT, scalarFieldD),
) => {
  (`relRecordField<${relFieldT},${scalarFieldT}>`, `{rel: ${relFieldD}, scalar: ${scalarFieldD}}`)
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
  | ScalarRW(scalarish) =>
    scalarFieldDeclBuilder(scalarish, getFieldInvocation, rawRecordVarName, true)
  | FormulaRollupRO(scalarish) =>
    scalarFieldDeclBuilder(scalarish, getFieldInvocation, rawRecordVarName, false)
  | RelFieldOption(relTableDef, isSingle, scalarDef) => {
      let {tableRecordTypeName, recordBuilderFnName} = getTableNamesContext(relTableDef)

      relRecordFieldDeclBuilder(
        relFieldDeclBuilder(
          tableRecordTypeName,
          getRelFieldInvocation(recordBuilderFnName),
          isSingle,
        ),
        scalarFieldDeclBuilder(scalarDef, getFieldInvocation, rawRecordVarName, false),
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
          )
          ((vdef.camelCaseViewName, typeStr), (vdef.camelCaseViewName, declStr))
        })->Array.unzip

      let (relFieldType, relFieldDeclaration) = relFieldDeclBuilder(
        tableRecordTypeName,
        getQueryableTableOrViewInvocation(tdef.camelCaseTableName),
        false,
      )

      {
        //rec
        recordTypeName: tableRecordTypeName,
        recordBuilderFnName: recordBuilderFnName,
        recordVarNamesToTypes: recordVarNamesToTypes,
        recordVarNamesToBuilderInvocation: recordVarNamesToBuilderInvocation,
        // tab
        tableSchemaAccessorName: tdef.camelCaseTableName,
        relFieldType: relFieldType,
        relFieldDeclaration: relFieldDeclaration,
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
    tableVarNamesToTypes,
    tableViewNamesToTypes,
    relFieldType,
  }) => {
    `${tableTypeName} = {
      rel: ${relFieldType},
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
    relFieldDeclaration,
  }) => {
    `${tableSchemaAccessorName}: {
        rel: ${relFieldDeclaration},
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
