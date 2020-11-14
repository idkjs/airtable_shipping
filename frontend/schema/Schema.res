open AirtableRaw
open SchemaDefinition
open GenericSchema2

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
  trackingNumber: singleRelRecordField<skuOrderTrackingRecord>,
  sku: singleRelRecordField<skuRecord>,
  boxDest: singleRelRecordField<boxDestinationRecord>,
  quantityExpected: readWriteScalarRecordField<int>,
  quantityReceived: readWriteScalarRecordField<int>,
  quantityPacked: readOnlyScalarRecordField<int>,
  boxedCheckbox: readWriteScalarRecordField<bool>,
  externalProductName: readWriteScalarRecordField<string>,
  skuIsReceived: readWriteScalarRecordField<bool>,
  destinationPrefix: readOnlyScalarRecordField<string>,
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
  box: singleRelRecordField<boxRecord>,
  sku: singleRelRecordField<skuRecord>,
  skuOrder: singleRelRecordField<skuOrderRecord>,
  qty: readWriteScalarRecordField<int>,
}
and skuOrderTrackingTable = {
  getRecords: array<recordSortParam<skuOrderTrackingRecord>> => array<skuOrderTrackingRecord>,
  useRecords: array<recordSortParam<skuOrderTrackingRecord>> => array<skuOrderTrackingRecord>,
  hasTrackingNumbersView: tableSchemaView<skuOrderTrackingRecord>,
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
  trackingNumberField: tableSchemaField<skuOrderRecord>,
  skuField: tableSchemaField<skuOrderRecord>,
  boxDestField: tableSchemaField<skuOrderRecord>,
  quantityExpectedField: tableSchemaField<skuOrderRecord>,
  quantityReceivedField: tableSchemaField<skuOrderRecord>,
  quantityPackedField: tableSchemaField<skuOrderRecord>,
  boxedCheckboxField: tableSchemaField<skuOrderRecord>,
  externalProductNameField: tableSchemaField<skuOrderRecord>,
  skuIsReceivedField: tableSchemaField<skuOrderRecord>,
  destinationPrefixField: tableSchemaField<skuOrderRecord>,
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
  boxField: tableSchemaField<boxLineRecord>,
  skuField: tableSchemaField<boxLineRecord>,
  skuOrderField: tableSchemaField<boxLineRecord>,
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
  skuOrders: buildMultipleRelRecordField(
    gschem,
    getRelField(gschem, "skuOrders"),
    skuOrderRecordBuilder,
    rawRec,
  ),
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
  trackingNumber: buildSingleRelRecordField(
    gschem,
    getRelField(gschem, "trackingNumber"),
    skuOrderTrackingRecordBuilder,
    rawRec,
  ),
  sku: buildSingleRelRecordField(gschem, getRelField(gschem, "sku"), skuRecordBuilder, rawRec),
  boxDest: buildSingleRelRecordField(
    gschem,
    getRelField(gschem, "boxDest"),
    boxDestinationRecordBuilder,
    rawRec,
  ),
  quantityExpected: getField(gschem, "quantityExpected").int.buildReadWrite(rawRec),
  quantityReceived: getField(gschem, "quantityReceived").int.buildReadWrite(rawRec),
  quantityPacked: getField(gschem, "quantityPacked").int.buildReadOnly(rawRec),
  boxedCheckbox: getField(gschem, "boxedCheckbox").bool.buildReadWrite(rawRec),
  externalProductName: getField(gschem, "externalProductName").string.buildReadWrite(rawRec),
  skuIsReceived: getField(gschem, "skuIsReceived").bool.buildReadWrite(rawRec),
  destinationPrefix: getField(gschem, "destinationPrefix").string.buildReadOnly(rawRec),
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
  boxes: buildMultipleRelRecordField(
    gschem,
    getRelField(gschem, "boxes"),
    boxRecordBuilder,
    rawRec,
  ),
  currentMaximalBoxNumber: getField(gschem, "currentMaximalBoxNumber").int.buildReadOnly(rawRec),
  destinationPrefix: getField(gschem, "destinationPrefix").string.buildReadWrite(rawRec),
  boxOffset: getField(gschem, "boxOffset").int.buildReadWrite(rawRec),
  isSerialBox: getField(gschem, "isSerialBox").bool.buildReadWrite(rawRec),
}
and boxRecordBuilder: (genericSchema, airtableRawRecord) => boxRecord = (gschem, rawRec) => {
  id: rawRec.id,
  boxNumber: getField(gschem, "boxNumber").string.buildReadOnly(rawRec),
  boxLines: buildMultipleRelRecordField(
    gschem,
    getRelField(gschem, "boxLines"),
    boxLineRecordBuilder,
    rawRec,
  ),
  boxDest: buildSingleRelRecordField(
    gschem,
    getRelField(gschem, "boxDest"),
    boxDestinationRecordBuilder,
    rawRec,
  ),
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
  box: buildSingleRelRecordField(gschem, getRelField(gschem, "box"), boxRecordBuilder, rawRec),
  sku: buildSingleRelRecordField(gschem, getRelField(gschem, "sku"), skuRecordBuilder, rawRec),
  skuOrder: buildSingleRelRecordField(
    gschem,
    getRelField(gschem, "skuOrder"),
    skuOrderRecordBuilder,
    rawRec,
  ),
  qty: getField(gschem, "qty").int.buildReadWrite(rawRec),
}

let buildSchema: genericSchema => schema = gschem => {
  skuOrderTracking: {
    getRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "skuOrderTracking"),
      skuOrderTrackingRecordBuilder,
      false,
    ),
    useRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "skuOrderTracking"),
      skuOrderTrackingRecordBuilder,
      true,
    ),
    hasTrackingNumbersView: {
      getRecords: buildGetOrUseRecords(
        gschem,
        getView(gschem, "hasTrackingNumbersView"),
        skuOrderTrackingRecordBuilder,
        false,
      ),
      useRecords: buildGetOrUseRecords(
        gschem,
        getView(gschem, "hasTrackingNumbersView"),
        skuOrderTrackingRecordBuilder,
        true,
      ),
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
    getRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "skuOrder"),
      skuOrderRecordBuilder,
      false,
    ),
    useRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "skuOrder"),
      skuOrderRecordBuilder,
      true,
    ),
    orderNameField: {
      sortAsc: getField(gschem, "orderName").sortAsc,
      sortDesc: getField(gschem, "orderName").sortDesc,
    },
    trackingNumberField: {
      sortAsc: getField(gschem, "trackingNumber").sortAsc,
      sortDesc: getField(gschem, "trackingNumber").sortDesc,
    },
    skuField: {
      sortAsc: getField(gschem, "sku").sortAsc,
      sortDesc: getField(gschem, "sku").sortDesc,
    },
    boxDestField: {
      sortAsc: getField(gschem, "boxDest").sortAsc,
      sortDesc: getField(gschem, "boxDest").sortDesc,
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
    destinationPrefixField: {
      sortAsc: getField(gschem, "destinationPrefix").sortAsc,
      sortDesc: getField(gschem, "destinationPrefix").sortDesc,
    },
    receivingNotesField: {
      sortAsc: getField(gschem, "receivingNotes").sortAsc,
      sortDesc: getField(gschem, "receivingNotes").sortDesc,
    },
  },
  sku: {
    getRecords: buildGetOrUseRecords(gschem, getTable(gschem, "sku"), skuRecordBuilder, false),
    useRecords: buildGetOrUseRecords(gschem, getTable(gschem, "sku"), skuRecordBuilder, true),
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
    getRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "boxDestination"),
      boxDestinationRecordBuilder,
      false,
    ),
    useRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "boxDestination"),
      boxDestinationRecordBuilder,
      true,
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
    getRecords: buildGetOrUseRecords(gschem, getTable(gschem, "box"), boxRecordBuilder, false),
    useRecords: buildGetOrUseRecords(gschem, getTable(gschem, "box"), boxRecordBuilder, true),
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
    getRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "boxLine"),
      boxLineRecordBuilder,
      false,
    ),
    useRecords: buildGetOrUseRecords(
      gschem,
      getTable(gschem, "boxLine"),
      boxLineRecordBuilder,
      true,
    ),
    nameField: {
      sortAsc: getField(gschem, "name").sortAsc,
      sortDesc: getField(gschem, "name").sortDesc,
    },
    boxField: {
      sortAsc: getField(gschem, "box").sortAsc,
      sortDesc: getField(gschem, "box").sortDesc,
    },
    skuField: {
      sortAsc: getField(gschem, "sku").sortAsc,
      sortDesc: getField(gschem, "sku").sortDesc,
    },
    skuOrderField: {
      sortAsc: getField(gschem, "skuOrder").sortAsc,
      sortDesc: getField(gschem, "skuOrder").sortDesc,
    },
    qtyField: {
      sortAsc: getField(gschem, "qty").sortAsc,
      sortDesc: getField(gschem, "qty").sortDesc,
    },
  },
}
