open Airtable
open SchemaDefinition
open GenericSchema

// warnings that complain about matching fields in mut recursive types
// and overlapping labels
// and we dgaf in this case... it's p much of intentional
@@warning("-30")
@@warning("-45")

type rec skuOrderTrackingRecord = {
  id: recordId<skuOrderTrackingRecord>,
  trackingNumber: readWriteScalarRecordField<string>,
  skuOrders: relRecordField<multipleRelField<skuOrderRecord>, readOnlyScalarRecordField<string>>,
  isReceived: readOnlyScalarRecordField<bool>,
  receivedTime: readWriteScalarRecordField<option<airtableMoment>>,
  jocoNotes: readWriteScalarRecordField<string>,
  warehouseNotes: readWriteScalarRecordField<string>,
}
and skuOrderRecord = {
  id: recordId<skuOrderRecord>,
  orderName: readOnlyScalarRecordField<string>,
  trackingRecord: relRecordField<
    singleRelField<skuOrderTrackingRecord>,
    readOnlyScalarRecordField<string>,
  >,
  skuOrderSku: relRecordField<singleRelField<skuRecord>, readOnlyScalarRecordField<string>>,
  skuOrderBoxDest: relRecordField<
    singleRelField<boxDestinationRecord>,
    readOnlyScalarRecordField<string>,
  >,
  quantityExpected: readWriteScalarRecordField<int>,
  quantityReceived: readWriteScalarRecordField<int>,
  quantityPacked: readOnlyScalarRecordField<int>,
  boxedCheckbox: readWriteScalarRecordField<bool>,
  externalProductName: readWriteScalarRecordField<string>,
  skuOrderIsReceived: readWriteScalarRecordField<bool>,
  skuOrderDestinationPrefix: readOnlyScalarRecordField<string>,
  receivingNotes: readWriteScalarRecordField<string>,
}
and skuRecord = {
  id: recordId<skuRecord>,
  skuName: readWriteScalarRecordField<string>,
  serialNumber: readWriteScalarRecordField<string>,
  isSerialRequired: readOnlyScalarRecordField<bool>,
  lifetimeOrderQty: readOnlyScalarRecordField<int>,
}
and boxDestinationRecord = {
  id: recordId<boxDestinationRecord>,
  destName: readOnlyScalarRecordField<string>,
  boxes: relRecordField<multipleRelField<boxRecord>, readOnlyScalarRecordField<string>>,
  currentMaximalBoxNumber: readOnlyScalarRecordField<int>,
  destinationPrefix: readWriteScalarRecordField<string>,
  boxOffset: readWriteScalarRecordField<int>,
  isSerialBox: readWriteScalarRecordField<bool>,
}
and boxRecord = {
  id: recordId<boxRecord>,
  boxName: readOnlyScalarRecordField<string>,
  boxLines: relRecordField<multipleRelField<boxLineRecord>, readOnlyScalarRecordField<string>>,
  boxDest: relRecordField<singleRelField<boxDestinationRecord>, readOnlyScalarRecordField<string>>,
  boxNumberOnly: readWriteScalarRecordField<int>,
  isMaxBox: readOnlyScalarRecordField<bool>,
  isToggledForPacking: readWriteScalarRecordField<bool>,
  isPenultimateBox: readOnlyScalarRecordField<bool>,
  isEmpty: readOnlyScalarRecordField<bool>,
}
and boxLineRecord = {
  id: recordId<boxLineRecord>,
  name: readOnlyScalarRecordField<string>,
  boxRecord: relRecordField<singleRelField<boxRecord>, readOnlyScalarRecordField<string>>,
  boxLineSku: relRecordField<singleRelField<skuRecord>, readOnlyScalarRecordField<string>>,
  boxLineSkuOrder: relRecordField<
    singleRelField<skuOrderRecord>,
    readOnlyScalarRecordField<string>,
  >,
  qty: readWriteScalarRecordField<int>,
}
and skuOrderTrackingTable = {
  rel: multipleRelField<skuOrderTrackingRecord>,
  crud: genericTableCRUDOperations<skuOrderTrackingRecord>,
  hasTrackingNumbersView: multipleRelField<skuOrderTrackingRecord>,
  trackingNumberField: tableSchemaField<skuOrderTrackingRecord, string>,
  skuOrdersField: tableSchemaField<skuOrderTrackingRecord, string>,
  isReceivedField: tableSchemaField<skuOrderTrackingRecord, bool>,
  receivedTimeField: tableSchemaField<skuOrderTrackingRecord, option<airtableMoment>>,
  jocoNotesField: tableSchemaField<skuOrderTrackingRecord, string>,
  warehouseNotesField: tableSchemaField<skuOrderTrackingRecord, string>,
}
and skuOrderTable = {
  rel: multipleRelField<skuOrderRecord>,
  crud: genericTableCRUDOperations<skuOrderRecord>,
  orderNameField: tableSchemaField<skuOrderRecord, string>,
  trackingRecordField: tableSchemaField<skuOrderRecord, string>,
  skuOrderSkuField: tableSchemaField<skuOrderRecord, string>,
  skuOrderBoxDestField: tableSchemaField<skuOrderRecord, string>,
  quantityExpectedField: tableSchemaField<skuOrderRecord, int>,
  quantityReceivedField: tableSchemaField<skuOrderRecord, int>,
  quantityPackedField: tableSchemaField<skuOrderRecord, int>,
  boxedCheckboxField: tableSchemaField<skuOrderRecord, bool>,
  externalProductNameField: tableSchemaField<skuOrderRecord, string>,
  skuOrderIsReceivedField: tableSchemaField<skuOrderRecord, bool>,
  skuOrderDestinationPrefixField: tableSchemaField<skuOrderRecord, string>,
  receivingNotesField: tableSchemaField<skuOrderRecord, string>,
}
and skuTable = {
  rel: multipleRelField<skuRecord>,
  crud: genericTableCRUDOperations<skuRecord>,
  skuNameField: tableSchemaField<skuRecord, string>,
  serialNumberField: tableSchemaField<skuRecord, string>,
  isSerialRequiredField: tableSchemaField<skuRecord, bool>,
  lifetimeOrderQtyField: tableSchemaField<skuRecord, int>,
}
and boxDestinationTable = {
  rel: multipleRelField<boxDestinationRecord>,
  crud: genericTableCRUDOperations<boxDestinationRecord>,
  destNameField: tableSchemaField<boxDestinationRecord, string>,
  boxesField: tableSchemaField<boxDestinationRecord, string>,
  currentMaximalBoxNumberField: tableSchemaField<boxDestinationRecord, int>,
  destinationPrefixField: tableSchemaField<boxDestinationRecord, string>,
  boxOffsetField: tableSchemaField<boxDestinationRecord, int>,
  isSerialBoxField: tableSchemaField<boxDestinationRecord, bool>,
}
and boxTable = {
  rel: multipleRelField<boxRecord>,
  crud: genericTableCRUDOperations<boxRecord>,
  boxNameField: tableSchemaField<boxRecord, string>,
  boxLinesField: tableSchemaField<boxRecord, string>,
  boxDestField: tableSchemaField<boxRecord, string>,
  boxNumberOnlyField: tableSchemaField<boxRecord, int>,
  isMaxBoxField: tableSchemaField<boxRecord, bool>,
  isToggledForPackingField: tableSchemaField<boxRecord, bool>,
  isPenultimateBoxField: tableSchemaField<boxRecord, bool>,
  isEmptyField: tableSchemaField<boxRecord, bool>,
}
and boxLineTable = {
  rel: multipleRelField<boxLineRecord>,
  crud: genericTableCRUDOperations<boxLineRecord>,
  nameField: tableSchemaField<boxLineRecord, string>,
  boxRecordField: tableSchemaField<boxLineRecord, string>,
  boxLineSkuField: tableSchemaField<boxLineRecord, string>,
  boxLineSkuOrderField: tableSchemaField<boxLineRecord, string>,
  qtyField: tableSchemaField<boxLineRecord, int>,
}

type schema = {
  skuOrderTracking: skuOrderTrackingTable,
  skuOrder: skuOrderTable,
  sku: skuTable,
  boxDestination: boxDestinationTable,
  box: boxTable,
  boxLine: boxLineTable,
}

let rec skuOrderTrackingRecordBuilder: (
  genericSchema,
  airtableRawRecord,
) => skuOrderTrackingRecord = (gschem, rawRec) => {
  id: rawRec.id,
  trackingNumber: getField(gschem, "trackingNumber").string.buildReadWrite(rawRec),
  skuOrders: {
    rel: asMultipleRelField(
      getQueryableRelField(gschem, "skuOrders", skuOrderRecordBuilder, rawRec),
    ),
    scalar: getField(gschem, "skuOrders").string.buildReadOnly(rawRec),
  },
  isReceived: getField(gschem, "isReceived").intBool.buildReadOnly(rawRec),
  receivedTime: getField(gschem, "receivedTime").momentOption.buildReadWrite(rawRec),
  jocoNotes: getField(gschem, "jocoNotes").string.buildReadWrite(rawRec),
  warehouseNotes: getField(gschem, "warehouseNotes").string.buildReadWrite(rawRec),
}
and skuOrderRecordBuilder: (genericSchema, airtableRawRecord) => skuOrderRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  orderName: getField(gschem, "orderName").string.buildReadOnly(rawRec),
  trackingRecord: {
    rel: asSingleRelField(
      getQueryableRelField(gschem, "trackingRecord", skuOrderTrackingRecordBuilder, rawRec),
    ),
    scalar: getField(gschem, "trackingRecord").string.buildReadOnly(rawRec),
  },
  skuOrderSku: {
    rel: asSingleRelField(getQueryableRelField(gschem, "skuOrderSku", skuRecordBuilder, rawRec)),
    scalar: getField(gschem, "skuOrderSku").string.buildReadOnly(rawRec),
  },
  skuOrderBoxDest: {
    rel: asSingleRelField(
      getQueryableRelField(gschem, "skuOrderBoxDest", boxDestinationRecordBuilder, rawRec),
    ),
    scalar: getField(gschem, "skuOrderBoxDest").string.buildReadOnly(rawRec),
  },
  quantityExpected: getField(gschem, "quantityExpected").int.buildReadWrite(rawRec),
  quantityReceived: getField(gschem, "quantityReceived").int.buildReadWrite(rawRec),
  quantityPacked: getField(gschem, "quantityPacked").int.buildReadOnly(rawRec),
  boxedCheckbox: getField(gschem, "boxedCheckbox").bool.buildReadWrite(rawRec),
  externalProductName: getField(gschem, "externalProductName").string.buildReadWrite(rawRec),
  skuOrderIsReceived: getField(gschem, "skuOrderIsReceived").bool.buildReadWrite(rawRec),
  skuOrderDestinationPrefix: getField(gschem, "skuOrderDestinationPrefix").string.buildReadOnly(
    rawRec,
  ),
  receivingNotes: getField(gschem, "receivingNotes").string.buildReadWrite(rawRec),
}
and skuRecordBuilder: (genericSchema, airtableRawRecord) => skuRecord = (gschem, rawRec) => {
  id: rawRec.id,
  skuName: getField(gschem, "skuName").string.buildReadWrite(rawRec),
  serialNumber: getField(gschem, "serialNumber").string.buildReadWrite(rawRec),
  isSerialRequired: getField(gschem, "isSerialRequired").intBool.buildReadOnly(rawRec),
  lifetimeOrderQty: getField(gschem, "lifetimeOrderQty").int.buildReadOnly(rawRec),
}
and boxDestinationRecordBuilder: (genericSchema, airtableRawRecord) => boxDestinationRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  destName: getField(gschem, "destName").string.buildReadOnly(rawRec),
  boxes: {
    rel: asMultipleRelField(getQueryableRelField(gschem, "boxes", boxRecordBuilder, rawRec)),
    scalar: getField(gschem, "boxes").string.buildReadOnly(rawRec),
  },
  currentMaximalBoxNumber: getField(gschem, "currentMaximalBoxNumber").int.buildReadOnly(rawRec),
  destinationPrefix: getField(gschem, "destinationPrefix").string.buildReadWrite(rawRec),
  boxOffset: getField(gschem, "boxOffset").int.buildReadWrite(rawRec),
  isSerialBox: getField(gschem, "isSerialBox").bool.buildReadWrite(rawRec),
}
and boxRecordBuilder: (genericSchema, airtableRawRecord) => boxRecord = (gschem, rawRec) => {
  id: rawRec.id,
  boxName: getField(gschem, "boxName").string.buildReadOnly(rawRec),
  boxLines: {
    rel: asMultipleRelField(getQueryableRelField(gschem, "boxLines", boxLineRecordBuilder, rawRec)),
    scalar: getField(gschem, "boxLines").string.buildReadOnly(rawRec),
  },
  boxDest: {
    rel: asSingleRelField(
      getQueryableRelField(gschem, "boxDest", boxDestinationRecordBuilder, rawRec),
    ),
    scalar: getField(gschem, "boxDest").string.buildReadOnly(rawRec),
  },
  boxNumberOnly: getField(gschem, "boxNumberOnly").int.buildReadWrite(rawRec),
  isMaxBox: getField(gschem, "isMaxBox").intBool.buildReadOnly(rawRec),
  isToggledForPacking: getField(gschem, "isToggledForPacking").bool.buildReadWrite(rawRec),
  isPenultimateBox: getField(gschem, "isPenultimateBox").intBool.buildReadOnly(rawRec),
  isEmpty: getField(gschem, "isEmpty").intBool.buildReadOnly(rawRec),
}
and boxLineRecordBuilder: (genericSchema, airtableRawRecord) => boxLineRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  name: getField(gschem, "name").string.buildReadOnly(rawRec),
  boxRecord: {
    rel: asSingleRelField(getQueryableRelField(gschem, "boxRecord", boxRecordBuilder, rawRec)),
    scalar: getField(gschem, "boxRecord").string.buildReadOnly(rawRec),
  },
  boxLineSku: {
    rel: asSingleRelField(getQueryableRelField(gschem, "boxLineSku", skuRecordBuilder, rawRec)),
    scalar: getField(gschem, "boxLineSku").string.buildReadOnly(rawRec),
  },
  boxLineSkuOrder: {
    rel: asSingleRelField(
      getQueryableRelField(gschem, "boxLineSkuOrder", skuOrderRecordBuilder, rawRec),
    ),
    scalar: getField(gschem, "boxLineSkuOrder").string.buildReadOnly(rawRec),
  },
  qty: getField(gschem, "qty").int.buildReadWrite(rawRec),
}

let buildSchema: array<airtableTableDef> => schema = tdefs => {
  let base = useBase()
  switch dereferenceGenericSchema(base, tdefs) {
  | Error(errstr) => Js.Exn.raiseError(errstr)
  | Ok(gschem) => {
      skuOrderTracking: {
        rel: asMultipleRelField(
          getQueryableTableOrView(gschem, "skuOrderTracking", skuOrderTrackingRecordBuilder),
        ),
        crud: getTableCrudOperations(gschem, "skuOrderTracking"),
        hasTrackingNumbersView: asMultipleRelField(
          getQueryableTableOrView(gschem, "hasTrackingNumbersView", skuOrderTrackingRecordBuilder),
        ),
        trackingNumberField: getField(gschem, "trackingNumber").string.tableSchemaField,
        skuOrdersField: getField(gschem, "skuOrders").string.tableSchemaField,
        isReceivedField: getField(gschem, "isReceived").intBool.tableSchemaField,
        receivedTimeField: getField(gschem, "receivedTime").momentOption.tableSchemaField,
        jocoNotesField: getField(gschem, "jocoNotes").string.tableSchemaField,
        warehouseNotesField: getField(gschem, "warehouseNotes").string.tableSchemaField,
      },
      skuOrder: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "skuOrder", skuOrderRecordBuilder)),
        crud: getTableCrudOperations(gschem, "skuOrder"),
        orderNameField: getField(gschem, "orderName").string.tableSchemaField,
        trackingRecordField: getField(gschem, "trackingRecord").string.tableSchemaField,
        skuOrderSkuField: getField(gschem, "skuOrderSku").string.tableSchemaField,
        skuOrderBoxDestField: getField(gschem, "skuOrderBoxDest").string.tableSchemaField,
        quantityExpectedField: getField(gschem, "quantityExpected").int.tableSchemaField,
        quantityReceivedField: getField(gschem, "quantityReceived").int.tableSchemaField,
        quantityPackedField: getField(gschem, "quantityPacked").int.tableSchemaField,
        boxedCheckboxField: getField(gschem, "boxedCheckbox").bool.tableSchemaField,
        externalProductNameField: getField(gschem, "externalProductName").string.tableSchemaField,
        skuOrderIsReceivedField: getField(gschem, "skuOrderIsReceived").bool.tableSchemaField,
        skuOrderDestinationPrefixField: getField(
          gschem,
          "skuOrderDestinationPrefix",
        ).string.tableSchemaField,
        receivingNotesField: getField(gschem, "receivingNotes").string.tableSchemaField,
      },
      sku: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "sku", skuRecordBuilder)),
        crud: getTableCrudOperations(gschem, "sku"),
        skuNameField: getField(gschem, "skuName").string.tableSchemaField,
        serialNumberField: getField(gschem, "serialNumber").string.tableSchemaField,
        isSerialRequiredField: getField(gschem, "isSerialRequired").intBool.tableSchemaField,
        lifetimeOrderQtyField: getField(gschem, "lifetimeOrderQty").int.tableSchemaField,
      },
      boxDestination: {
        rel: asMultipleRelField(
          getQueryableTableOrView(gschem, "boxDestination", boxDestinationRecordBuilder),
        ),
        crud: getTableCrudOperations(gschem, "boxDestination"),
        destNameField: getField(gschem, "destName").string.tableSchemaField,
        boxesField: getField(gschem, "boxes").string.tableSchemaField,
        currentMaximalBoxNumberField: getField(
          gschem,
          "currentMaximalBoxNumber",
        ).int.tableSchemaField,
        destinationPrefixField: getField(gschem, "destinationPrefix").string.tableSchemaField,
        boxOffsetField: getField(gschem, "boxOffset").int.tableSchemaField,
        isSerialBoxField: getField(gschem, "isSerialBox").bool.tableSchemaField,
      },
      box: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "box", boxRecordBuilder)),
        crud: getTableCrudOperations(gschem, "box"),
        boxNameField: getField(gschem, "boxName").string.tableSchemaField,
        boxLinesField: getField(gschem, "boxLines").string.tableSchemaField,
        boxDestField: getField(gschem, "boxDest").string.tableSchemaField,
        boxNumberOnlyField: getField(gschem, "boxNumberOnly").int.tableSchemaField,
        isMaxBoxField: getField(gschem, "isMaxBox").intBool.tableSchemaField,
        isToggledForPackingField: getField(gschem, "isToggledForPacking").bool.tableSchemaField,
        isPenultimateBoxField: getField(gschem, "isPenultimateBox").intBool.tableSchemaField,
        isEmptyField: getField(gschem, "isEmpty").intBool.tableSchemaField,
      },
      boxLine: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "boxLine", boxLineRecordBuilder)),
        crud: getTableCrudOperations(gschem, "boxLine"),
        nameField: getField(gschem, "name").string.tableSchemaField,
        boxRecordField: getField(gschem, "boxRecord").string.tableSchemaField,
        boxLineSkuField: getField(gschem, "boxLineSku").string.tableSchemaField,
        boxLineSkuOrderField: getField(gschem, "boxLineSkuOrder").string.tableSchemaField,
        qtyField: getField(gschem, "qty").int.tableSchemaField,
      },
    }
  }
}
