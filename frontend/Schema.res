open Airtable

// warning 30 complains about matching fields in mut recursive types
// and we dgaf in this case... it's p much of intentional
@@warning("-30")

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

and skuOrderTrackingTableSchema = {
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
and skuOrderTableSchema = {
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
and skuTableSchema = {
  getRecords: array<recordSortParam<skuRecord>> => array<skuRecord>,
  useRecords: array<recordSortParam<skuRecord>> => array<skuRecord>,
  skuNameField: tableSchemaField<skuRecord>,
  serialNumberField: tableSchemaField<skuRecord>,
  isSerialRequiredField: tableSchemaField<skuRecord>,
  lifetimeOrderQtyField: tableSchemaField<skuRecord>,
}
and boxDestinationTableSchema = {
  getRecords: array<recordSortParam<boxDestinationRecord>> => array<boxDestinationRecord>,
  useRecords: array<recordSortParam<boxDestinationRecord>> => array<boxDestinationRecord>,
  destNameField: tableSchemaField<boxDestinationRecord>,
  boxesField: tableSchemaField<boxDestinationRecord>,
  currentMaximalBoxNumberField: tableSchemaField<boxDestinationRecord>,
  destinationPrefixField: tableSchemaField<boxDestinationRecord>,
  boxOffsetField: tableSchemaField<boxDestinationRecord>,
  isSerialBoxField: tableSchemaField<boxDestinationRecord>,
}
and boxTableSchema = {
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
and boxLineTableSchema = {
  getRecords: array<recordSortParam<boxLineRecord>> => array<boxLineRecord>,
  useRecords: array<recordSortParam<boxLineRecord>> => array<boxLineRecord>,
  nameField: tableSchemaField<boxLineRecord>,
  boxField: tableSchemaField<boxLineRecord>,
  skuField: tableSchemaField<boxLineRecord>,
  skuOrderField: tableSchemaField<boxLineRecord>,
  qtyField: tableSchemaField<boxLineRecord>,
}

type schema = {
  skuOrderTracking: skuOrderTrackingTableSchema,
  skuOrder: skuOrderTableSchema,
  sku: skuTableSchema,
  boxDestination: boxDestinationTableSchema,
  box: boxTableSchema,
  boxLine: boxLineTableSchema,
}

let rec skuOrderTrackingRecordBuilder: (
  genericSchema,
  airtableRawRecord,
) => skuOrderTrackingRecord = (gschem, rawRec) => {
  id: rawRec.id,
  trackingNumber: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "trackingNumber"),
      getString,
    ),
    render: encloseCellRenderer(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "trackingNumber"),
    ),
  },
  skuOrders: {
    getRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "skuOrders"),
      gsGetAllFieldsForTable(gschem, "skuOrder"),
      false,
      skuOrderRecordBuilder(gschem),
    ),
    useRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "skuOrders"),
      gsGetAllFieldsForTable(gschem, "skuOrder"),
      true,
      skuOrderRecordBuilder(gschem),
    ),
  },
  isReceived: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "isReceived"),
      getIntAsBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrderTracking", "isReceived")),
  },
  receivedTime: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "receivedTime"),
      getMomentOption,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrderTracking", "receivedTime")),
  },
  jocoNotes: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "jocoNotes"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrderTracking", "jocoNotes")),
  },
  warehouseNotes: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "warehouseNotes"),
      getString,
    ),
    render: encloseCellRenderer(
      rawRec,
      gsGetRawField(gschem, "skuOrderTracking", "warehouseNotes"),
    ),
  },
}
and skuOrderRecordBuilder: (genericSchema, airtableRawRecord) => skuOrderRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  orderName: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "orderName"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "orderName")),
  },
  trackingNumber: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "trackingNumber"),
      gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
      false,
      skuOrderTrackingRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "trackingNumber"),
      gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
      true,
      skuOrderTrackingRecordBuilder(gschem),
    ),
  },
  sku: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "sku"),
      gsGetAllFieldsForTable(gschem, "sku"),
      false,
      skuRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "sku"),
      gsGetAllFieldsForTable(gschem, "sku"),
      true,
      skuRecordBuilder(gschem),
    ),
  },
  boxDest: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "boxDest"),
      gsGetAllFieldsForTable(gschem, "boxDestination"),
      false,
      boxDestinationRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "boxDest"),
      gsGetAllFieldsForTable(gschem, "boxDestination"),
      true,
      boxDestinationRecordBuilder(gschem),
    ),
  },
  quantityExpected: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "quantityExpected"),
      getInt,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "quantityExpected")),
  },
  quantityReceived: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "quantityReceived"),
      getInt,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "quantityReceived")),
  },
  quantityPacked: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "quantityPacked"),
      getInt,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "quantityPacked")),
  },
  boxedCheckbox: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "boxedCheckbox"),
      getBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "boxedCheckbox")),
  },
  externalProductName: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "externalProductName"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "externalProductName")),
  },
  skuIsReceived: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "skuIsReceived"),
      getBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "skuIsReceived")),
  },
  destinationPrefix: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "destinationPrefix"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "destinationPrefix")),
  },
  receivingNotes: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "skuOrder", "receivingNotes"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "skuOrder", "receivingNotes")),
  },
}
and skuRecordBuilder: (genericSchema, airtableRawRecord) => skuRecord = (gschem, rawRec) => {
  id: rawRec.id,
  skuName: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "sku", "skuName"), getString),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "sku", "skuName")),
  },
  serialNumber: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "sku", "serialNumber"), getString),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "sku", "serialNumber")),
  },
  isSerialRequired: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "sku", "isSerialRequired"),
      getIntAsBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "sku", "isSerialRequired")),
  },
  lifetimeOrderQty: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "sku", "lifetimeOrderQty"),
      getInt,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "sku", "lifetimeOrderQty")),
  },
}
and boxDestinationRecordBuilder: (genericSchema, airtableRawRecord) => boxDestinationRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  destName: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "destName"),
      getString,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "boxDestination", "destName")),
  },
  boxes: {
    getRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "boxes"),
      gsGetAllFieldsForTable(gschem, "box"),
      false,
      boxRecordBuilder(gschem),
    ),
    useRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "boxes"),
      gsGetAllFieldsForTable(gschem, "box"),
      true,
      boxRecordBuilder(gschem),
    ),
  },
  currentMaximalBoxNumber: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "currentMaximalBoxNumber"),
      getInt,
    ),
    render: encloseCellRenderer(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "currentMaximalBoxNumber"),
    ),
  },
  destinationPrefix: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "destinationPrefix"),
      getString,
    ),
    render: encloseCellRenderer(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "destinationPrefix"),
    ),
  },
  boxOffset: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "boxOffset"),
      getInt,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "boxDestination", "boxOffset")),
  },
  isSerialBox: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "boxDestination", "isSerialBox"),
      getBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "boxDestination", "isSerialBox")),
  },
}
and boxRecordBuilder: (genericSchema, airtableRawRecord) => boxRecord = (gschem, rawRec) => {
  id: rawRec.id,
  boxNumber: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "box", "boxNumber"), getString),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "boxNumber")),
  },
  boxLines: {
    getRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "box", "boxLines"),
      gsGetAllFieldsForTable(gschem, "boxLine"),
      false,
      boxLineRecordBuilder(gschem),
    ),
    useRecords: getMultiRecordAsArray(
      rawRec,
      gsGetRawField(gschem, "box", "boxLines"),
      gsGetAllFieldsForTable(gschem, "boxLine"),
      true,
      boxLineRecordBuilder(gschem),
    ),
  },
  boxDest: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "box", "boxDest"),
      gsGetAllFieldsForTable(gschem, "boxDestination"),
      false,
      boxDestinationRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "box", "boxDest"),
      gsGetAllFieldsForTable(gschem, "boxDestination"),
      true,
      boxDestinationRecordBuilder(gschem),
    ),
  },
  boxNumberOnly: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "box", "boxNumberOnly"), getInt),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "boxNumberOnly")),
  },
  isMaxBox: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "box", "isMaxBox"), getIntAsBool),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "isMaxBox")),
  },
  isToggledForPacking: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "box", "isToggledForPacking"),
      getBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "isToggledForPacking")),
  },
  isPenultimateBox: {
    read: encloseAndTypeScalarRead(
      rawRec,
      gsGetRawField(gschem, "box", "isPenultimateBox"),
      getIntAsBool,
    ),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "isPenultimateBox")),
  },
  isEmpty: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "box", "isEmpty"), getIntAsBool),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "box", "isEmpty")),
  },
}
and boxLineRecordBuilder: (genericSchema, airtableRawRecord) => boxLineRecord = (
  gschem,
  rawRec,
) => {
  id: rawRec.id,
  name: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "boxLine", "name"), getString),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "boxLine", "name")),
  },
  box: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "box"),
      gsGetAllFieldsForTable(gschem, "box"),
      false,
      boxRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "box"),
      gsGetAllFieldsForTable(gschem, "box"),
      true,
      boxRecordBuilder(gschem),
    ),
  },
  sku: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "sku"),
      gsGetAllFieldsForTable(gschem, "sku"),
      false,
      skuRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "sku"),
      gsGetAllFieldsForTable(gschem, "sku"),
      true,
      skuRecordBuilder(gschem),
    ),
  },
  skuOrder: {
    getRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "skuOrder"),
      gsGetAllFieldsForTable(gschem, "skuOrder"),
      false,
      skuOrderRecordBuilder(gschem),
    ),
    useRecord: getSingleRecordAsOption(
      rawRec,
      gsGetRawField(gschem, "boxLine", "skuOrder"),
      gsGetAllFieldsForTable(gschem, "skuOrder"),
      true,
      skuOrderRecordBuilder(gschem),
    ),
  },
  qty: {
    read: encloseAndTypeScalarRead(rawRec, gsGetRawField(gschem, "boxLine", "qty"), getInt),
    render: encloseCellRenderer(rawRec, gsGetRawField(gschem, "boxLine", "qty")),
  },
}

let buildSchema: array<airtableTableDef> => schema = tdefs => {
  switch buildGenericSchema(tdefs) {
  | Err(errstr) => Js.Exn.raiseError(errstr)
  | Ok(gschem) => {
      skuOrderTracking: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "skuOrderTracking"),
            gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
            sortParams,
          )->getOrUseQueryResult(false, skuOrderTrackingRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "skuOrderTracking"),
            gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
            sortParams,
          )->getOrUseQueryResult(true, skuOrderTrackingRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above
        hasTrackingNumbersView: {
          getRecords: sortParams =>
            getViewRecordsQueryResult(
              gsGetRawView(gschem, "skuOrderTracking", "hasTrackingNumbersView"),
              gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
              sortParams,
            )->getOrUseQueryResult(false, skuOrderTrackingRecordBuilder(gschem)),
          useRecords: sortParams =>
            getViewRecordsQueryResult(
              gsGetRawView(gschem, "skuOrderTracking", "hasTrackingNumbersView"),
              gsGetAllFieldsForTable(gschem, "skuOrderTracking"),
              sortParams,
            )->getOrUseQueryResult(true, skuOrderTrackingRecordBuilder(gschem)),
        },
        trackingNumberField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "trackingNumber"),
        ),
        skuOrdersField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "skuOrders"),
        ),
        isReceivedField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "isReceived"),
        ),
        receivedTimeField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "receivedTime"),
        ),
        jocoNotesField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "jocoNotes"),
        ),
        warehouseNotesField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrderTracking", "warehouseNotes"),
        ),
      },
      skuOrder: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "skuOrder"),
            gsGetAllFieldsForTable(gschem, "skuOrder"),
            sortParams,
          )->getOrUseQueryResult(false, skuOrderRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "skuOrder"),
            gsGetAllFieldsForTable(gschem, "skuOrder"),
            sortParams,
          )->getOrUseQueryResult(true, skuOrderRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above

        orderNameField: buildTableSchemaField(gsGetRawField(gschem, "skuOrder", "orderName")),
        trackingNumberField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "trackingNumber"),
        ),
        skuField: buildTableSchemaField(gsGetRawField(gschem, "skuOrder", "sku")),
        boxDestField: buildTableSchemaField(gsGetRawField(gschem, "skuOrder", "boxDest")),
        quantityExpectedField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "quantityExpected"),
        ),
        quantityReceivedField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "quantityReceived"),
        ),
        quantityPackedField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "quantityPacked"),
        ),
        boxedCheckboxField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "boxedCheckbox"),
        ),
        externalProductNameField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "externalProductName"),
        ),
        skuIsReceivedField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "skuIsReceived"),
        ),
        destinationPrefixField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "destinationPrefix"),
        ),
        receivingNotesField: buildTableSchemaField(
          gsGetRawField(gschem, "skuOrder", "receivingNotes"),
        ),
      },
      sku: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "sku"),
            gsGetAllFieldsForTable(gschem, "sku"),
            sortParams,
          )->getOrUseQueryResult(false, skuRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "sku"),
            gsGetAllFieldsForTable(gschem, "sku"),
            sortParams,
          )->getOrUseQueryResult(true, skuRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above

        skuNameField: buildTableSchemaField(gsGetRawField(gschem, "sku", "skuName")),
        serialNumberField: buildTableSchemaField(gsGetRawField(gschem, "sku", "serialNumber")),
        isSerialRequiredField: buildTableSchemaField(
          gsGetRawField(gschem, "sku", "isSerialRequired"),
        ),
        lifetimeOrderQtyField: buildTableSchemaField(
          gsGetRawField(gschem, "sku", "lifetimeOrderQty"),
        ),
      },
      boxDestination: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "boxDestination"),
            gsGetAllFieldsForTable(gschem, "boxDestination"),
            sortParams,
          )->getOrUseQueryResult(false, boxDestinationRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "boxDestination"),
            gsGetAllFieldsForTable(gschem, "boxDestination"),
            sortParams,
          )->getOrUseQueryResult(true, boxDestinationRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above

        destNameField: buildTableSchemaField(gsGetRawField(gschem, "boxDestination", "destName")),
        boxesField: buildTableSchemaField(gsGetRawField(gschem, "boxDestination", "boxes")),
        currentMaximalBoxNumberField: buildTableSchemaField(
          gsGetRawField(gschem, "boxDestination", "currentMaximalBoxNumber"),
        ),
        destinationPrefixField: buildTableSchemaField(
          gsGetRawField(gschem, "boxDestination", "destinationPrefix"),
        ),
        boxOffsetField: buildTableSchemaField(gsGetRawField(gschem, "boxDestination", "boxOffset")),
        isSerialBoxField: buildTableSchemaField(
          gsGetRawField(gschem, "boxDestination", "isSerialBox"),
        ),
      },
      box: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "box"),
            gsGetAllFieldsForTable(gschem, "box"),
            sortParams,
          )->getOrUseQueryResult(false, boxRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "box"),
            gsGetAllFieldsForTable(gschem, "box"),
            sortParams,
          )->getOrUseQueryResult(true, boxRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above

        boxNumberField: buildTableSchemaField(gsGetRawField(gschem, "box", "boxNumber")),
        boxLinesField: buildTableSchemaField(gsGetRawField(gschem, "box", "boxLines")),
        boxDestField: buildTableSchemaField(gsGetRawField(gschem, "box", "boxDest")),
        boxNumberOnlyField: buildTableSchemaField(gsGetRawField(gschem, "box", "boxNumberOnly")),
        isMaxBoxField: buildTableSchemaField(gsGetRawField(gschem, "box", "isMaxBox")),
        isToggledForPackingField: buildTableSchemaField(
          gsGetRawField(gschem, "box", "isToggledForPacking"),
        ),
        isPenultimateBoxField: buildTableSchemaField(
          gsGetRawField(gschem, "box", "isPenultimateBox"),
        ),
        isEmptyField: buildTableSchemaField(gsGetRawField(gschem, "box", "isEmpty")),
      },
      boxLine: {
        getRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "boxLine"),
            gsGetAllFieldsForTable(gschem, "boxLine"),
            sortParams,
          )->getOrUseQueryResult(false, boxLineRecordBuilder(gschem)),
        useRecords: sortParams =>
          getTableRecordsQueryResult(
            gsGetRawTable(gschem, "boxLine"),
            gsGetAllFieldsForTable(gschem, "boxLine"),
            sortParams,
          )->getOrUseQueryResult(true, boxLineRecordBuilder(gschem)),
        // don't put a comma after this, it comes from above

        nameField: buildTableSchemaField(gsGetRawField(gschem, "boxLine", "name")),
        boxField: buildTableSchemaField(gsGetRawField(gschem, "boxLine", "box")),
        skuField: buildTableSchemaField(gsGetRawField(gschem, "boxLine", "sku")),
        skuOrderField: buildTableSchemaField(gsGetRawField(gschem, "boxLine", "skuOrder")),
        qtyField: buildTableSchemaField(gsGetRawField(gschem, "boxLine", "qty")),
      },
    }
  }
}
