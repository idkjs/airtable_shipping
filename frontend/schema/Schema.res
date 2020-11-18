open Airtable
open SchemaDefinition
open GenericSchema

// warnings that complain about matching fields in mut recursive types
// and overlapping labels
// and we dgaf in this case... it's p much of intentional
@@warning("-30")
@@warning("-45")

type rec skuOrderTrackingRecord = {
  id: string,
  trackingNumber: readWriteScalarRecordField<string>,
  skuOrders: relRecordField<multipleRelField<skuOrderRecord>, readOnlyScalarRecordField<string>>,
  isReceived: readOnlyScalarRecordField<bool>,
  receivedTime: readWriteScalarRecordField<option<airtableMoment>>,
  jocoNotes: readWriteScalarRecordField<string>,
  warehouseNotes: readWriteScalarRecordField<string>,
}
and skuOrderRecord = {
  id: string,
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
  skuIsReceived: readWriteScalarRecordField<bool>,
  skuOrderDestinationPrefix: readOnlyScalarRecordField<string>,
  receivingNotes: readWriteScalarRecordField<string>,
}
and skuRecord = {
  id: string,
  skuName: readWriteScalarRecordField<string>,
  serialNumber: readWriteScalarRecordField<string>,
  isSerialRequired: readOnlyScalarRecordField<bool>,
  lifetimeOrderQty: readOnlyScalarRecordField<int>,
}
and boxDestinationRecord = {
  id: string,
  destName: readOnlyScalarRecordField<string>,
  boxes: relRecordField<multipleRelField<boxRecord>, readOnlyScalarRecordField<string>>,
  currentMaximalBoxNumber: readOnlyScalarRecordField<int>,
  destinationPrefix: readWriteScalarRecordField<string>,
  boxOffset: readWriteScalarRecordField<int>,
  isSerialBox: readWriteScalarRecordField<bool>,
}
and boxRecord = {
  id: string,
  boxNumber: readOnlyScalarRecordField<string>,
  boxLines: relRecordField<multipleRelField<boxLineRecord>, readOnlyScalarRecordField<string>>,
  boxDest: relRecordField<singleRelField<boxDestinationRecord>, readOnlyScalarRecordField<string>>,
  boxNumberOnly: readWriteScalarRecordField<int>,
  isMaxBox: readOnlyScalarRecordField<bool>,
  isToggledForPacking: readWriteScalarRecordField<bool>,
  isPenultimateBox: readOnlyScalarRecordField<bool>,
  isEmpty: readOnlyScalarRecordField<bool>,
}
and boxLineRecord = {
  id: string,
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
  hasTrackingNumbersView: multipleRelField<skuOrderTrackingRecord>,
  trackingNumberField: tableSchemaField<skuOrderTrackingRecord>,
  skuOrdersField: tableSchemaField<skuOrderTrackingRecord>,
  isReceivedField: tableSchemaField<skuOrderTrackingRecord>,
  receivedTimeField: tableSchemaField<skuOrderTrackingRecord>,
  jocoNotesField: tableSchemaField<skuOrderTrackingRecord>,
  warehouseNotesField: tableSchemaField<skuOrderTrackingRecord>,
}
and skuOrderTable = {
  rel: multipleRelField<skuOrderRecord>,
  orderNameField: tableSchemaField<skuOrderRecord>,
  trackingRecordField: tableSchemaField<skuOrderRecord>,
  skuOrderSkuField: tableSchemaField<skuOrderRecord>,
  skuOrderBoxDestField: tableSchemaField<skuOrderRecord>,
  quantityExpectedField: tableSchemaField<skuOrderRecord>,
  quantityReceivedField: tableSchemaField<skuOrderRecord>,
  quantityPackedField: tableSchemaField<skuOrderRecord>,
  boxedCheckboxField: tableSchemaField<skuOrderRecord>,
  externalProductNameField: tableSchemaField<skuOrderRecord>,
  skuIsReceivedField: tableSchemaField<skuOrderRecord>,
  skuOrderDestinationPrefixField: tableSchemaField<skuOrderRecord>,
  receivingNotesField: tableSchemaField<skuOrderRecord>,
}
and skuTable = {
  rel: multipleRelField<skuRecord>,
  skuNameField: tableSchemaField<skuRecord>,
  serialNumberField: tableSchemaField<skuRecord>,
  isSerialRequiredField: tableSchemaField<skuRecord>,
  lifetimeOrderQtyField: tableSchemaField<skuRecord>,
}
and boxDestinationTable = {
  rel: multipleRelField<boxDestinationRecord>,
  destNameField: tableSchemaField<boxDestinationRecord>,
  boxesField: tableSchemaField<boxDestinationRecord>,
  currentMaximalBoxNumberField: tableSchemaField<boxDestinationRecord>,
  destinationPrefixField: tableSchemaField<boxDestinationRecord>,
  boxOffsetField: tableSchemaField<boxDestinationRecord>,
  isSerialBoxField: tableSchemaField<boxDestinationRecord>,
}
and boxTable = {
  rel: multipleRelField<boxRecord>,
  boxNumberField: tableSchemaField<boxRecord>,
  boxLinesField: tableSchemaField<boxRecord>,
  boxDestField: tableSchemaField<boxRecord>,
  boxNumberOnlyField: tableSchemaField<boxRecord>,
  isMaxBoxField: tableSchemaField<boxRecord>,
  isToggledForPackingField: tableSchemaField<boxRecord>,
  isPenultimateBoxField: tableSchemaField<boxRecord>,
  isEmptyField: tableSchemaField<boxRecord>,
}
and boxLineTable = {
  rel: multipleRelField<boxLineRecord>,
  nameField: tableSchemaField<boxLineRecord>,
  boxRecordField: tableSchemaField<boxLineRecord>,
  boxLineSkuField: tableSchemaField<boxLineRecord>,
  boxLineSkuOrderField: tableSchemaField<boxLineRecord>,
  qtyField: tableSchemaField<boxLineRecord>,
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
  skuIsReceived: getField(gschem, "skuIsReceived").bool.buildReadWrite(rawRec),
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
  boxNumber: getField(gschem, "boxNumber").string.buildReadOnly(rawRec),
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
        hasTrackingNumbersView: asMultipleRelField(
          getQueryableTableOrView(gschem, "hasTrackingNumbersView", skuOrderTrackingRecordBuilder),
        ),
        trackingNumberField: {
          sortAsc: getField(gschem, "trackingNumber").sortAsc,
          sortDesc: getField(gschem, "trackingNumber").sortDesc,
        },
        skuOrdersField: {
          sortAsc: getField(gschem, "skuOrders").sortAsc,
          sortDesc: getField(gschem, "skuOrders").sortDesc,
        },
        isReceivedField: {
          sortAsc: getField(gschem, "isReceived").sortAsc,
          sortDesc: getField(gschem, "isReceived").sortDesc,
        },
        receivedTimeField: {
          sortAsc: getField(gschem, "receivedTime").sortAsc,
          sortDesc: getField(gschem, "receivedTime").sortDesc,
        },
        jocoNotesField: {
          sortAsc: getField(gschem, "jocoNotes").sortAsc,
          sortDesc: getField(gschem, "jocoNotes").sortDesc,
        },
        warehouseNotesField: {
          sortAsc: getField(gschem, "warehouseNotes").sortAsc,
          sortDesc: getField(gschem, "warehouseNotes").sortDesc,
        },
      },
      skuOrder: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "skuOrder", skuOrderRecordBuilder)),
        orderNameField: {
          sortAsc: getField(gschem, "orderName").sortAsc,
          sortDesc: getField(gschem, "orderName").sortDesc,
        },
        trackingRecordField: {
          sortAsc: getField(gschem, "trackingRecord").sortAsc,
          sortDesc: getField(gschem, "trackingRecord").sortDesc,
        },
        skuOrderSkuField: {
          sortAsc: getField(gschem, "skuOrderSku").sortAsc,
          sortDesc: getField(gschem, "skuOrderSku").sortDesc,
        },
        skuOrderBoxDestField: {
          sortAsc: getField(gschem, "skuOrderBoxDest").sortAsc,
          sortDesc: getField(gschem, "skuOrderBoxDest").sortDesc,
        },
        quantityExpectedField: {
          sortAsc: getField(gschem, "quantityExpected").sortAsc,
          sortDesc: getField(gschem, "quantityExpected").sortDesc,
        },
        quantityReceivedField: {
          sortAsc: getField(gschem, "quantityReceived").sortAsc,
          sortDesc: getField(gschem, "quantityReceived").sortDesc,
        },
        quantityPackedField: {
          sortAsc: getField(gschem, "quantityPacked").sortAsc,
          sortDesc: getField(gschem, "quantityPacked").sortDesc,
        },
        boxedCheckboxField: {
          sortAsc: getField(gschem, "boxedCheckbox").sortAsc,
          sortDesc: getField(gschem, "boxedCheckbox").sortDesc,
        },
        externalProductNameField: {
          sortAsc: getField(gschem, "externalProductName").sortAsc,
          sortDesc: getField(gschem, "externalProductName").sortDesc,
        },
        skuIsReceivedField: {
          sortAsc: getField(gschem, "skuIsReceived").sortAsc,
          sortDesc: getField(gschem, "skuIsReceived").sortDesc,
        },
        skuOrderDestinationPrefixField: {
          sortAsc: getField(gschem, "skuOrderDestinationPrefix").sortAsc,
          sortDesc: getField(gschem, "skuOrderDestinationPrefix").sortDesc,
        },
        receivingNotesField: {
          sortAsc: getField(gschem, "receivingNotes").sortAsc,
          sortDesc: getField(gschem, "receivingNotes").sortDesc,
        },
      },
      sku: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "sku", skuRecordBuilder)),
        skuNameField: {
          sortAsc: getField(gschem, "skuName").sortAsc,
          sortDesc: getField(gschem, "skuName").sortDesc,
        },
        serialNumberField: {
          sortAsc: getField(gschem, "serialNumber").sortAsc,
          sortDesc: getField(gschem, "serialNumber").sortDesc,
        },
        isSerialRequiredField: {
          sortAsc: getField(gschem, "isSerialRequired").sortAsc,
          sortDesc: getField(gschem, "isSerialRequired").sortDesc,
        },
        lifetimeOrderQtyField: {
          sortAsc: getField(gschem, "lifetimeOrderQty").sortAsc,
          sortDesc: getField(gschem, "lifetimeOrderQty").sortDesc,
        },
      },
      boxDestination: {
        rel: asMultipleRelField(
          getQueryableTableOrView(gschem, "boxDestination", boxDestinationRecordBuilder),
        ),
        destNameField: {
          sortAsc: getField(gschem, "destName").sortAsc,
          sortDesc: getField(gschem, "destName").sortDesc,
        },
        boxesField: {
          sortAsc: getField(gschem, "boxes").sortAsc,
          sortDesc: getField(gschem, "boxes").sortDesc,
        },
        currentMaximalBoxNumberField: {
          sortAsc: getField(gschem, "currentMaximalBoxNumber").sortAsc,
          sortDesc: getField(gschem, "currentMaximalBoxNumber").sortDesc,
        },
        destinationPrefixField: {
          sortAsc: getField(gschem, "destinationPrefix").sortAsc,
          sortDesc: getField(gschem, "destinationPrefix").sortDesc,
        },
        boxOffsetField: {
          sortAsc: getField(gschem, "boxOffset").sortAsc,
          sortDesc: getField(gschem, "boxOffset").sortDesc,
        },
        isSerialBoxField: {
          sortAsc: getField(gschem, "isSerialBox").sortAsc,
          sortDesc: getField(gschem, "isSerialBox").sortDesc,
        },
      },
      box: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "box", boxRecordBuilder)),
        boxNumberField: {
          sortAsc: getField(gschem, "boxNumber").sortAsc,
          sortDesc: getField(gschem, "boxNumber").sortDesc,
        },
        boxLinesField: {
          sortAsc: getField(gschem, "boxLines").sortAsc,
          sortDesc: getField(gschem, "boxLines").sortDesc,
        },
        boxDestField: {
          sortAsc: getField(gschem, "boxDest").sortAsc,
          sortDesc: getField(gschem, "boxDest").sortDesc,
        },
        boxNumberOnlyField: {
          sortAsc: getField(gschem, "boxNumberOnly").sortAsc,
          sortDesc: getField(gschem, "boxNumberOnly").sortDesc,
        },
        isMaxBoxField: {
          sortAsc: getField(gschem, "isMaxBox").sortAsc,
          sortDesc: getField(gschem, "isMaxBox").sortDesc,
        },
        isToggledForPackingField: {
          sortAsc: getField(gschem, "isToggledForPacking").sortAsc,
          sortDesc: getField(gschem, "isToggledForPacking").sortDesc,
        },
        isPenultimateBoxField: {
          sortAsc: getField(gschem, "isPenultimateBox").sortAsc,
          sortDesc: getField(gschem, "isPenultimateBox").sortDesc,
        },
        isEmptyField: {
          sortAsc: getField(gschem, "isEmpty").sortAsc,
          sortDesc: getField(gschem, "isEmpty").sortDesc,
        },
      },
      boxLine: {
        rel: asMultipleRelField(getQueryableTableOrView(gschem, "boxLine", boxLineRecordBuilder)),
        nameField: {
          sortAsc: getField(gschem, "name").sortAsc,
          sortDesc: getField(gschem, "name").sortDesc,
        },
        boxRecordField: {
          sortAsc: getField(gschem, "boxRecord").sortAsc,
          sortDesc: getField(gschem, "boxRecord").sortDesc,
        },
        boxLineSkuField: {
          sortAsc: getField(gschem, "boxLineSku").sortAsc,
          sortDesc: getField(gschem, "boxLineSku").sortDesc,
        },
        boxLineSkuOrderField: {
          sortAsc: getField(gschem, "boxLineSkuOrder").sortAsc,
          sortDesc: getField(gschem, "boxLineSkuOrder").sortDesc,
        },
        qtyField: {
          sortAsc: getField(gschem, "qty").sortAsc,
          sortDesc: getField(gschem, "qty").sortDesc,
        },
      },
    }
  }
}
