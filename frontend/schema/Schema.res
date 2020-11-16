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
  skuOrders: multipleRelRecordField<skuOrderRecord>,
  isReceived: readOnlyScalarRecordField<bool>,
  receivedTime: readWriteScalarRecordField<option<airtableMoment>>,
  jocoNotes: readWriteScalarRecordField<string>,
  warehouseNotes: readWriteScalarRecordField<string>,
}
and skuOrderRecord = {
  id: string,
  orderName: readOnlyScalarRecordField<string>,
  trackingRecord: singleRelRecordField<skuOrderTrackingRecord>,
  skuOrderSku: singleRelRecordField<skuRecord>,
  skuOrderBoxDest: singleRelRecordField<boxDestinationRecord>,
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
  boxes: multipleRelRecordField<boxRecord>,
  currentMaximalBoxNumber: readOnlyScalarRecordField<int>,
  destinationPrefix: readWriteScalarRecordField<string>,
  boxOffset: readWriteScalarRecordField<int>,
  isSerialBox: readWriteScalarRecordField<bool>,
}
and boxRecord = {
  id: string,
  boxNumber: readOnlyScalarRecordField<string>,
  boxLines: multipleRelRecordField<boxLineRecord>,
  boxDest: singleRelRecordField<boxDestinationRecord>,
  boxNumberOnly: readWriteScalarRecordField<int>,
  isMaxBox: readOnlyScalarRecordField<bool>,
  isToggledForPacking: readWriteScalarRecordField<bool>,
  isPenultimateBox: readOnlyScalarRecordField<bool>,
  isEmpty: readOnlyScalarRecordField<bool>,
}
and boxLineRecord = {
  id: string,
  name: readOnlyScalarRecordField<string>,
  boxRecord: singleRelRecordField<boxRecord>,
  boxLineSku: singleRelRecordField<skuRecord>,
  boxLineSkuOrder: singleRelRecordField<skuOrderRecord>,
  qty: readWriteScalarRecordField<int>,
}
and skuOrderTrackingTable = {
  getRecords: array<recordSortParam<skuOrderTrackingRecord>> => array<skuOrderTrackingRecord>,
  useRecords: array<recordSortParam<skuOrderTrackingRecord>> => array<skuOrderTrackingRecord>,
  hasTrackingNumbersView: multipleRelRecordField<skuOrderTrackingRecord>,
  trackingNumberField: tableSchemaField<skuOrderTrackingRecord>,
  skuOrdersField: tableSchemaField<skuOrderTrackingRecord>,
  isReceivedField: tableSchemaField<skuOrderTrackingRecord>,
  receivedTimeField: tableSchemaField<skuOrderTrackingRecord>,
  jocoNotesField: tableSchemaField<skuOrderTrackingRecord>,
  warehouseNotesField: tableSchemaField<skuOrderTrackingRecord>,
}
and skuOrderTable = {
  getRecords: array<recordSortParam<skuOrderRecord>> => array<skuOrderRecord>,
  useRecords: array<recordSortParam<skuOrderRecord>> => array<skuOrderRecord>,
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
  getRecords: array<recordSortParam<skuRecord>> => array<skuRecord>,
  useRecords: array<recordSortParam<skuRecord>> => array<skuRecord>,
  skuNameField: tableSchemaField<skuRecord>,
  serialNumberField: tableSchemaField<skuRecord>,
  isSerialRequiredField: tableSchemaField<skuRecord>,
  lifetimeOrderQtyField: tableSchemaField<skuRecord>,
}
and boxDestinationTable = {
  getRecords: array<recordSortParam<boxDestinationRecord>> => array<boxDestinationRecord>,
  useRecords: array<recordSortParam<boxDestinationRecord>> => array<boxDestinationRecord>,
  destNameField: tableSchemaField<boxDestinationRecord>,
  boxesField: tableSchemaField<boxDestinationRecord>,
  currentMaximalBoxNumberField: tableSchemaField<boxDestinationRecord>,
  destinationPrefixField: tableSchemaField<boxDestinationRecord>,
  boxOffsetField: tableSchemaField<boxDestinationRecord>,
  isSerialBoxField: tableSchemaField<boxDestinationRecord>,
}
and boxTable = {
  getRecords: array<recordSortParam<boxRecord>> => array<boxRecord>,
  useRecords: array<recordSortParam<boxRecord>> => array<boxRecord>,
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
  getRecords: array<recordSortParam<boxLineRecord>> => array<boxLineRecord>,
  useRecords: array<recordSortParam<boxLineRecord>> => array<boxLineRecord>,
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
    getRecords: getQueryableRelField(gschem, "skuOrders", skuOrderRecordBuilder, rawRec).getRecords,
    useRecords: getQueryableRelField(gschem, "skuOrders", skuOrderRecordBuilder, rawRec).useRecords,
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
    getRecord: getQueryableRelField(
      gschem,
      "trackingRecord",
      skuOrderTrackingRecordBuilder,
      rawRec,
    ).getRecord,
    useRecord: getQueryableRelField(
      gschem,
      "trackingRecord",
      skuOrderTrackingRecordBuilder,
      rawRec,
    ).useRecord,
  },
  skuOrderSku: {
    getRecord: getQueryableRelField(gschem, "skuOrderSku", skuRecordBuilder, rawRec).getRecord,
    useRecord: getQueryableRelField(gschem, "skuOrderSku", skuRecordBuilder, rawRec).useRecord,
  },
  skuOrderBoxDest: {
    getRecord: getQueryableRelField(
      gschem,
      "skuOrderBoxDest",
      boxDestinationRecordBuilder,
      rawRec,
    ).getRecord,
    useRecord: getQueryableRelField(
      gschem,
      "skuOrderBoxDest",
      boxDestinationRecordBuilder,
      rawRec,
    ).useRecord,
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
    getRecords: getQueryableRelField(gschem, "boxes", boxRecordBuilder, rawRec).getRecords,
    useRecords: getQueryableRelField(gschem, "boxes", boxRecordBuilder, rawRec).useRecords,
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
    getRecords: getQueryableRelField(gschem, "boxLines", boxLineRecordBuilder, rawRec).getRecords,
    useRecords: getQueryableRelField(gschem, "boxLines", boxLineRecordBuilder, rawRec).useRecords,
  },
  boxDest: {
    getRecord: getQueryableRelField(
      gschem,
      "boxDest",
      boxDestinationRecordBuilder,
      rawRec,
    ).getRecord,
    useRecord: getQueryableRelField(
      gschem,
      "boxDest",
      boxDestinationRecordBuilder,
      rawRec,
    ).useRecord,
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
    getRecord: getQueryableRelField(gschem, "boxRecord", boxRecordBuilder, rawRec).getRecord,
    useRecord: getQueryableRelField(gschem, "boxRecord", boxRecordBuilder, rawRec).useRecord,
  },
  boxLineSku: {
    getRecord: getQueryableRelField(gschem, "boxLineSku", skuRecordBuilder, rawRec).getRecord,
    useRecord: getQueryableRelField(gschem, "boxLineSku", skuRecordBuilder, rawRec).useRecord,
  },
  boxLineSkuOrder: {
    getRecord: getQueryableRelField(
      gschem,
      "boxLineSkuOrder",
      skuOrderRecordBuilder,
      rawRec,
    ).getRecord,
    useRecord: getQueryableRelField(
      gschem,
      "boxLineSkuOrder",
      skuOrderRecordBuilder,
      rawRec,
    ).useRecord,
  },
  qty: getField(gschem, "qty").int.buildReadWrite(rawRec),
}

let buildSchema: array<airtableTableDef> => schema = tdefs => {
  let base = useBase()
  switch dereferenceGenericSchema(base, tdefs) {
  | Error(errstr) => Js.Exn.raiseError(errstr)
  | Ok(gschem) => {
      skuOrderTracking: {
        getRecords: getQueryableTableOrView(
          gschem,
          "skuOrderTracking",
          skuOrderTrackingRecordBuilder,
        ).getRecords,
        useRecords: getQueryableTableOrView(
          gschem,
          "skuOrderTracking",
          skuOrderTrackingRecordBuilder,
        ).useRecords,
        hasTrackingNumbersView: {
          getRecords: getQueryableTableOrView(
            gschem,
            "hasTrackingNumbersView",
            skuOrderTrackingRecordBuilder,
          ).getRecords,
          useRecords: getQueryableTableOrView(
            gschem,
            "hasTrackingNumbersView",
            skuOrderTrackingRecordBuilder,
          ).useRecords,
        },
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
        getRecords: getQueryableTableOrView(gschem, "skuOrder", skuOrderRecordBuilder).getRecords,
        useRecords: getQueryableTableOrView(gschem, "skuOrder", skuOrderRecordBuilder).useRecords,
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
        getRecords: getQueryableTableOrView(gschem, "sku", skuRecordBuilder).getRecords,
        useRecords: getQueryableTableOrView(gschem, "sku", skuRecordBuilder).useRecords,
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
        getRecords: getQueryableTableOrView(
          gschem,
          "boxDestination",
          boxDestinationRecordBuilder,
        ).getRecords,
        useRecords: getQueryableTableOrView(
          gschem,
          "boxDestination",
          boxDestinationRecordBuilder,
        ).useRecords,
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
        getRecords: getQueryableTableOrView(gschem, "box", boxRecordBuilder).getRecords,
        useRecords: getQueryableTableOrView(gschem, "box", boxRecordBuilder).useRecords,
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
        getRecords: getQueryableTableOrView(gschem, "boxLine", boxLineRecordBuilder).getRecords,
        useRecords: getQueryableTableOrView(gschem, "boxLine", boxLineRecordBuilder).useRecords,
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
