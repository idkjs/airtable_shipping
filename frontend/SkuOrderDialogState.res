open AirtableUI
open Airtable
open Schema
open Util
open Reducer
open Belt
open PipelineDialog
open SkuOrderDialogs
open SkuOrderBox

type sovars = {
  skuOrder: skuOrderRecord,
  sku: skuRecord,
  dest: boxDestinationRecord,
  tracking: skuOrderTrackingRecord,
  updateReceivingNotes: string => unit,
}

type stage =
  | DataCorruption(string)
  | ReceiveQtyOfSku(
      sovars,
      // dispatch number to receive
      int => unit,
    )
  | CollectSerialNumber(
      sovars,
      // update the serial number on the record
      string => unit,
    )
  // w function to update the skuname and mark it received
  | SerializeSkuNameAndReceive1(sovars, unit => unit) // update the sku name and enter a qty of 1 received
  | PutInBox(sovars, potentialBoxes)

let getState: (schema, skuOrderRecord, action => unit) => stage = (schema, skuOrder, dispatch) => {
  let skuOpt = skuOrder.skuOrderSku.rel.getRecord()
  let destOpt = skuOrder.skuOrderBoxDest.rel.getRecord()
  let parentOpt = skuOrder.trackingRecord.rel.getRecord()
  open Js.String2
  let nameIsSerialTemplate: skuRecord => bool = sku =>
    // they look like SKUNAME-XXXX or XXXY or somethign
    sku.skuName.read()->sliceToEnd(~from=-5)->startsWith("-X")

  let serialIsEntered: skuRecord => bool = sku => sku.serialNumber.read()->length > 6

  let nameIsSerialized: skuRecord => bool = sku =>
    // if the last 4 match
    sku.skuName.read()->sliceToEnd(~from=-4) == sku.serialNumber.read()->sliceToEnd(~from=-4) &&
      // and the sku name prior to that has a dash in it
      "-" == sku.skuName.read()->slice(~from=-5, ~to_=-4)

  let dispatchMarkReceived = () =>
    dispatch(BlindFieldUpdate(skuOrder.skuOrderIsReceived.updateAsync(true)))

  let dispatchReceiveQty = i =>
    dispatch(BlindFieldUpdate(skuOrder.quantityReceived.updateAsync(Some(i))))

  switch (skuOpt, destOpt, parentOpt, skuOrder.quantityExpected.read()) {
  | (Some(sku), Some(dest), Some(parent), expectQty) when expectQty > 0 => {
      // welp we've deref'd some important core stuff
      let sovars = {
        skuOrder: skuOrder,
        sku: sku,
        dest: dest,
        tracking: parent,
        updateReceivingNotes: s =>
          dispatch(BlindFieldUpdate(skuOrder.receivingNotes.updateAsync(s))),
      }

      switch (
        skuOrder.quantityReceived.read(),
        sku.isSerialRequired.read(),
        sku->nameIsSerialTemplate,
        sku.lifetimeOrderQty.read() == 1,
        sku->serialIsEntered,
        sku->nameIsSerialized,
        schema->findPotentialBoxes(dest),
      ) {
      // a serial number is not required--so let's receive this thing
      | (None, false, _, _, _, _, _) => ReceiveQtyOfSku(sovars, dispatchReceiveQty)
      | (None, true, false, _, _, _, _) =>
        // needs a serial but is not a template
        DataCorruption(
          `A serial number is required for this SKU but the SKU name is not a "template."
SKUs with template names end with -XXXX or -XXXY or similar. The key thing is that the 
end of the SKU is a DASH and then FOUR characters. The first after the dash is an uppercase X.

So, -XDZD is valid but -YXXX is NOT.`,
        )
      | (None, true, _, false, _, _, _) =>
        // needs a serial but we've ordered more than one of this sku ever
        DataCorruption(
          `This SKU requires a serial number, but more than one of this SKU has been 
ordered in the lifetime of the SKU.

I.e. 
  - there are multiple SKU orders for this specific SKU  - OR - 
  - the quantity listed on this ONE sku order is greater than 1
  - this sku doesn't actually need a serial number

These issues need to be fixed before the serial numbered item can be received.`,
        )
      // we need a serial, the sku is right, the order qty is right
      // we have NOT entered the serial though
      // it's time to collect the serial number
      | (None, true, true, true, false, _, _) =>
        CollectSerialNumber(
          sovars,
          str => dispatch(BlindFieldUpdate(sku.serialNumber.updateAsync(str))),
        )
      // it's time to mark this received--everything is looking good
      | (None, true, true, true, true, false, _) =>
        SerializeSkuNameAndReceive1(
          sovars,
          () => {
            // dispatch sku name change
            dispatch(
              BlindFieldUpdate(
                sku.skuName.updateAsync(
                  // take out the templatized part
                  // put in the end of the serial as entered
                  sku.skuName.read()->slice(~from=0, ~to_=-4) ++
                    sku.serialNumber.read()->sliceToEnd(~from=-4),
                ),
              ),
            )
            // receive the 1 item
            dispatchReceiveQty(1)
          },
        )
      // the sku is entered and the name has been serialized
      // we ignore whether the name is a template, though it is unlikely
      // time to select a box or display an error about box integrity
      | (Some(_), true, _, true, true, true, Error(boxDataError)) => DataCorruption(boxDataError)
      | (Some(_), true, _, true, true, true, Ok(potentialBoxes)) => PutInBox(sovars, potentialBoxes)
      }
    }
  | (skuopt, destop, _, qty) => {
      let stat = opt => opt->Option.isNone ? "SET" : "NOT SET"
      DataCorruption(
        `In order to be received, the following things must be true: 
  - SKU must be set (status: ${skuopt->stat})
  - SKU serial must be 6 characters in length or MORE (pad with spaces in front if needed)
      (len: ${skuOpt
        ->Option.mapWithDefault(0, sku => sku.skuName.read()->length)
        ->Int.toString})
  - SKU serial must not end in X### where '#' is anything and 'X' is a capital X
  - Box destination must be set (status: ${destop->stat})
  - Qty must be > 0 (qty: ${qty->Int.toString})`,
      )
    }
  }
}

type skuOrderState = {activationButton: React.element, dialog: React.element}
type actionType =
  | CloseOnly
  | OpenDumbly
  | Open(sovars)
  | CloseAndSave(sovars)
  | SaveOnly(sovars)

let parseRecordState: (schema, skuOrderRecord, state, action => _) => skuOrderState = (
  schema,
  sor,
  state,
  dispatch,
) => {
  let recordStatus = getState(schema, sor, dispatch)
  let action: (actionType, unit) => unit = (toggle, _) => {
    let persistFromReducerState: sovars => unit = ({skuOrder, sku}) => {
      dispatch(BlindFieldUpdate(skuOrder.quantityReceived.updateAsync(state.skuQuantityReceived)))
      dispatch(BlindFieldUpdate(skuOrder.receivingNotes.updateAsync(state.skuReceivingNotes)))
      dispatch(BlindFieldUpdate(sku.serialNumber.updateAsync(state.skuSerial)))
    }
    let justOpenTheDialog = () => dispatch(FocusOnOrderRecord(sor))
    let justCloseTheDialog = () => dispatch(UnfocusOrderRecord)

    switch toggle {
    // this is pretty much incoherent
    | CloseOnly => justCloseTheDialog()
    | OpenDumbly => justOpenTheDialog()
    | Open({skuOrder, sku}) => {
        // we set up these variables any time we open one of these
        // they persist after the dialog closes
        dispatch(UpdateSKUReceivedQty(Some(skuOrder.quantityExpected.read())))
        dispatch(UpdateReceivingNotes(skuOrder.receivingNotes.read()))
        dispatch(UpdateSKUSerial(sku.serialNumber.read()))
        justOpenTheDialog()
      }
    | SaveOnly(sovar) // fallthru
    | CloseAndSave(sovar) => {
        persistFromReducerState(sovar)
        justCloseTheDialog()
      }
    }
  }
  let closeCancel = action(CloseOnly)

  let cancelAndDontSaveButton =
    <CancelButton onClick={action(CloseOnly)}> {s(`Cancel & Don't Save`)} </CancelButton>

  let saveAndContinueButton = sovars =>
    <PrimarySaveButton onClick={action(SaveOnly(sovars))}>
      {s(`Save & Continue`)}
    </PrimarySaveButton>

  let saveAndCloseButton = sovars =>
    <SecondarySaveButton onClick={action(CloseAndSave(sovars))}>
      {s(`Save & Close`)}
    </SecondarySaveButton>

  let skuReceivingQtyStr = state.skuQuantityReceived->Option.mapWithDefault("", Int.toString)
  let onSkuReceivingQtyChange = dispatch->mapEvent(v => UpdateSKUReceivedQty(v), Int.fromString)
  let skuReceivingNotes = state.skuReceivingNotes
  let onSkuReceivingNotesChange = dispatch->mapEvent(v => UpdateReceivingNotes(v), identity)

  {
    activationButton: switch recordStatus {
    | DataCorruption(_) =>
      <WarningButton onClick={action(OpenDumbly)}> {"Data Corruption"->s} </WarningButton>
    | ReceiveQtyOfSku(sov, _) =>
      <PrimaryActionButton onClick={action(Open(sov))}>
        {"Receive Item(s)"->s}
      </PrimaryActionButton>
    | CollectSerialNumber(sov, _) =>
      <PrimaryActionButton onClick={action(Open(sov))}>
        {"Enter Serial Number"->s}
      </PrimaryActionButton>
    | SerializeSkuNameAndReceive1(sov, _) =>
      <PrimaryActionButton onClick={action(Open(sov))}>
        {"Receive Serial Item"->s}
      </PrimaryActionButton>
    | PutInBox(sov, _) =>
      <PrimaryActionButton onClick={action(Open(sov))}> {"Box Item"->s} </PrimaryActionButton>
    },
    dialog: switch recordStatus {
    | DataCorruption(msg) => <DataCorruption closeCancel formattedErrorText=msg />
    | ReceiveQtyOfSku(sovar, _) => {
        let {skuOrder, sku, tracking} = sovar
        <ReceiveUnserialedSku
          skuOrder
          sku
          tracking
          skuReceivingQtyStr
          onSkuReceivingQtyChange
          skuReceivingNotes
          onSkuReceivingNotesChange
          closeCancel
          saveClose={action(CloseAndSave(sovar))}
          saveContinue={action(SaveOnly(sovar))}
        />
      }
    | CollectSerialNumber(_, _) => <Temp closeCancel />
    | SerializeSkuNameAndReceive1(_, _) => <Temp closeCancel />
    | PutInBox(_, _) => <Temp closeCancel />
    },
  }
}
