open AirtableUI
open Airtable
open Schema
open Util
open Reducer
open Belt
open PipelineDialog
open SkuOrderDialogs
open SkuOrderBox

type stage =
  | DataCorruption(string)
  | ReceiveQtyOfSku(skuOrderDialogVars)
  | CollectSerialNumberAndReceive1(skuOrderDialogVars)
  | PutInBox(skuOrderDialogVars, potentialBoxes)

let recordStatus: (schema, skuOrderRecord, state, action => unit) => stage = (
  schema,
  skuOrder,
  state,
  dispatch,
) => {
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

  switch (skuOpt, destOpt, parentOpt, skuOrder.quantityExpected.read()) {
  | (Some(sku), Some(dest), Some(parent), expectQty) when expectQty > 0 => {
      // welp we've deref'd some important core stuff
      let sovars = {
        skuOrder: skuOrder,
        sku: sku,
        dest: dest,
        tracking: parent,
        dispatch: dispatch,
        closeCancel: () => UnfocusOrderRecord->dispatch,
        updateQtyReceivedFromState: BlindFieldUpdate(
          () => skuOrder.quantityReceived.updateAsync(state.skuQuantityReceived),
        ),
        updateReceivingNotesFromState: BlindFieldUpdate(
          () => skuOrder.receivingNotes.updateAsync(state.skuReceivingNotes),
        ),
        updateSerialNumberFromState: BlindFieldUpdate(
          () => sku.serialNumber.updateAsync(state.skuSerial),
        ),
        markReceivedCheckbox: BlindFieldUpdate(() => skuOrder.skuOrderIsReceived.updateAsync(true)),
        serializeSkuName: BlindFieldUpdate(
          () =>
            if sku->serialIsEntered {
              sku.skuName.updateAsync(
                // take out the templatized part
                // put in the end of the serial as entered
                sku.skuName.read()->slice(~from=0, ~to_=-4) ++
                  sku.serialNumber.read()->sliceToEnd(~from=-4),
              )
            } else {
              Js.Exn.raiseError(
                `You can't serialize the sku name of something that is missing its sku, my friend`,
              )
            },
        ),
        dialogClose: UnfocusOrderRecord,
        qtyToReceive: state.skuQuantityReceived->Option.getWithDefault(
          skuOrder.quantityExpected.read(),
        ),
        qtyToReceiveOnChange: dispatch->onChangeHandler(v => UpdateSKUReceivedQty(
          v->Int.fromString,
        )),
        receivingNotes: state.skuReceivingNotes,
        receivingNotesOnChange: dispatch->onChangeHandler(v => UpdateReceivingNotes(v)),
      }

      switch (
        skuOrder.quantityReceived.read(),
        sku.isSerialRequired.read(),
        sku->serialIsEntered && sku->nameIsSerialized,
        schema->findPotentialBoxes(dest),
      ) {
      // a serial number is not required--so let's receive this thing
      | (None, false, _, _) => ReceiveQtyOfSku(sovars)
      | (None, true, _, _) =>
        // we need a serial it's not entered yet
        switch (sku->nameIsSerialTemplate, sku.lifetimeOrderQty.read() == 1) {
        | (true, true) => CollectSerialNumberAndReceive1(sovars)
        | (false, _) =>
          // name is not a template
          DataCorruption(
            `A serial number is required for this SKU but the SKU name is not a "template."
SKUs with template names end with -XXXX or -XXXY or similar. The key thing is that the 
end of the SKU is a DASH and then FOUR characters. The first after the dash is an uppercase X.

So, -XDZD is valid but -YXXX is NOT.`,
          )
        | (true, false) =>
          // more than one ever ordered of this sku
          DataCorruption(
            `This SKU requires a serial number, but more than one of this SKU has been 
ordered in the lifetime of the SKU.

I.e. 
  - there are multiple SKU orders for this specific SKU  - OR - 
  - the quantity listed on this ONE sku order is greater than 1
  - this sku doesn't actually need a serial number

These issues need to be fixed before the serial numbered item can be received.`,
          )
        }

      // 0 entered as qty received (leave blank instead)
      | (Some(number), _, _, _) when number <= 0 =>
        DataCorruption(
          `The number 0 was entered as the number of this item which was 
received. In order to proceed, some number > 0 must be indicated as the
received quantity. I.e. you have to receive some of something in order to 
have received it.

Instead of marking anything as received for this SKU, it should just not
have a quantity received entered at all, since we are still waiting for it.
`,
        )
      //

      | (Some(_), true, true, Ok(potentialBoxes))
      | (Some(_), false, false, Ok(potentialBoxes)) =>
        PutInBox(sovars, potentialBoxes)
      | (Some(_), _, _, Error(boxDataError)) => DataCorruption(boxDataError)
      | (Some(_), _, _, _) =>
        DataCorruption(
          `A quantity has been marked as received, 
but the sku itself has some messed up attributes and it looks like it's both a serial item
and not a serial item at the same time and I'm not sure what in tarnation I'm supposed to
do about it.`,
        )
      }
    }
  | (skuopt, destop, parent, qty) => {
      let stat = opt => opt->Option.isNone ? "SET" : "NOT SET"
      DataCorruption(
        `In order to be received, the following things must be true: 
  - SKU must be set (status: ${skuopt->stat})
  - A SkuOrderTrackingRecord must be connected (status: ${parent->stat})
  - SKU serial must be 6 characters in length or MORE (pad with spaces in front if needed)
      (len: ${skuOpt
        ->Option.mapWithDefault(0, sku => sku.skuName.read()->length)
        ->Int.toString})
  - SKU serial must not end in X### where '#' is anything and 'X' is a capital X
  - Box destination must be set (status: ${destop->stat})
  - Expected Qty must be > 0 (qty: ${qty->Int.toString})`,
      )
    }
  }
}

type skuOrderState = {activationButton: React.element, dialog: React.element}

let parseRecordState: (schema, skuOrderRecord, state, action => _) => skuOrderState = (
  schema,
  sor,
  state,
  dispatch,
) => {
  let recordStatus = recordStatus(schema, sor, state, dispatch)

  let dumbOpen = () => dispatch(FocusOnOrderRecord(sor))
  let closeCancel = () => dispatch(UnfocusOrderRecord)

  let realOpen = ({skuOrder, sku}, unit) => {
    let _ =
      dispatch->multi([
        UpdateSKUReceivedQty(Some(skuOrder.quantityExpected.read())),
        UpdateReceivingNotes(skuOrder.receivingNotes.read()),
        UpdateSKUSerial(sku.serialNumber.read()),
      ])
    dumbOpen()
  }

  {
    activationButton: switch recordStatus {
    | DataCorruption(_) => <WarningButton onClick=dumbOpen> {"Data Corruption"->s} </WarningButton>
    | ReceiveQtyOfSku(sov) =>
      <PrimaryActionButton onClick={realOpen(sov)}> {"Receive Item(s)"->s} </PrimaryActionButton>
    | CollectSerialNumberAndReceive1(sov) =>
      <PrimaryActionButton onClick={realOpen(sov)}>
        {"Enter Serial Number"->s}
      </PrimaryActionButton>
    | PutInBox(sov, _) =>
      <PrimaryActionButton onClick={realOpen(sov)}> {"Box Item"->s} </PrimaryActionButton>
    },
    dialog: switch recordStatus {
    | DataCorruption(msg) => <DataCorruption closeCancel formattedErrorText=msg />
    | ReceiveQtyOfSku(skuOrderDialogVars) => <ReceiveUnserialedSku dialogVars=skuOrderDialogVars />
    | _ => <Temp closeCancel />
    },
  }
}
