open Belt
open AirtableRaw
open Util
open SchemaDefinition

type genericSchema = {
  tables: Map.String.t<airtableRawTable>,
  views: Map.String.t<airtableRawView>,
  fields: Map.String.t<airtableRawField>,
  allFields: Map.String.t<array<airtableRawField>>,
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
  let (allKeys, tablePairs, viewPairs, fieldPairs, allFieldsPairs): (
    array<string>,
    array<(string, objResult<airtableRawTable>)>,
    array<(string, objResult<airtableRawView>)>,
    array<(string, objResult<airtableRawField>)>,
    array<(string, objResult<array<airtableRawField>>)>,
  ) =
    tdefs->Array.reduce(([], [], [], [], []), ((
      strAccum,
      tabAccum,
      viewAccum,
      fieldAccum,
      allFieldsAccum,
    ), tdef) => {
      let allStrings: array<(string, _)> => array<string> = arr => arr->Array.map(first)
      let tablePair = (tdef.camelCaseTableName, getTable(base, tdef.resolutionMethod))
      let tableViewPairs = tdef.tableViews->Array.map(vdef => {
        (vdef.camelCaseViewName, getView(base, tdef.resolutionMethod, vdef.resolutionMethod))
      })
      let tableFieldPairs = tdef.tableFields->Array.map(fdef => {
        (fdef.camelCaseFieldName, getField(base, tdef.resolutionMethod, fdef.resolutionMethod))
      })
      let allFieldsPair = {
        // throw away the errors
        let (_, allFields) = tableFieldPairs->Array.map(second) |> partitionErrors
        (tdef.camelCaseTableName, Ok(allFields))
      }
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
  let allErrors = Array.concatMany([repeatedKeyErrors, tableErrors, viewErrors, fieldErrors])

  switch allErrors {
  | [] =>
    Ok({
      tables: tableMap,
      views: viewMap,
      fields: fieldMap,
      allFields: allFieldMap,
    })
  | _ => Err(allErrors |> joinWith("\n"))
  }
}

let getTable: (genericSchema, string) => airtableRawTable = (objs, key) =>
  objs.tables->Map.String.getExn(key)
let getView: (genericSchema, string) => airtableRawView = (objs, key) =>
  objs.views->Map.String.getExn(key)
let getField: (genericSchema, string) => airtableRawField = (objs, key) =>
  objs.fields->Map.String.getExn(key)
let getAllFields: (genericSchema, string) => array<airtableRawField> = (objs, key) =>
  objs.allFields->Map.String.getExn(key)
