open Belt
open Schema
open Util

type userSelectableBox = BoxThatExists(string) | BoxToMake(string)

type potentialBoxes = {
  maxBox: option<boxRecord>,
  penultimateBox: option<boxRecord>,
  otherEmptyBoxes: array<boxRecord>,
  newBox: string,
}

let formatBoxNameWithNumber: (boxDestinationRecord, int) => string = (bdr, i) => {
  open Js.String2
  let paddedNumber = // box numbers are 0 padded 2 or 3 digit numbers
  (bdr.boxOffset.read() + i + 1000)
  ->// we add the 1000 to get enough zeroes in there
  Int.toString
  // if it's a serial box it's 2 long, otherwise 3
  ->sliceToEnd(~from=bdr.isSerialBox.read() ? -2 : -3)
  `${bdr.destinationPrefix.read()}-${paddedNumber}`
}

let findPotentialBoxes: (schema, boxDestinationRecord) => result<potentialBoxes, string> = (
  schema,
  bdr,
) => {
  let boxes = bdr.boxes.rel.getRecords([schema.box.boxNumberOnlyField.sortDesc])
  let boxOffset = bdr.boxOffset.read()

  // almost all this function is dedicated to parsing out the potential errors and
  // describing them in close detail
  let errorMessage = switch boxes {
  // if there are no boxes, then there aren't sequence errors
  | [] => ""
  | _ => {
      let presentBoxNumbers = Set.Int.fromArray(boxes->Array.map(box => box.boxNumberOnly.read()))
      let expectedBoxNumbers = Set.Int.fromArray(
        // note that we need to have length for this inclusive range to be valid here
        Array.range(boxOffset + 1, boxOffset + boxes->Array.length),
      )

      // i want the symmetric difference -- everything that's not
      // present in both lists... the opposite of the intersection
      // https://en.wikipedia.org/wiki/Symmetric_difference
      let expectedButNotPresent = Set.Int.diff(expectedBoxNumbers, presentBoxNumbers)
      let presentButNotExpected = Set.Int.diff(presentBoxNumbers, expectedBoxNumbers)

      switch (expectedButNotPresent->Set.Int.isEmpty, presentButNotExpected->Set.Int.isEmpty) {
      // seems good if there is nothing in these sets
      | (true, true) => ""
      | _ => {
          let minMaxNum = set => (
            // we know the set has length
            set->Set.Int.minimum->Option.getExn |> formatBoxNameWithNumber(bdr),
            set->Set.Int.maximum->Option.getExn |> formatBoxNameWithNumber(bdr),
          )

          let toNumberList = set =>
            set->Set.Int.toArray->Array.map(formatBoxNameWithNumber(bdr)) |> joinWith(", ")
          let expectedSize = expectedBoxNumbers->Set.Int.size->Int.toString
          let actualSize = presentBoxNumbers->Set.Int.size->Int.toString
          let expectMinMax = minMaxNum(expectedBoxNumbers)
          let presentMinMax = minMaxNum(presentBoxNumbers)

          `There is a potential data integrity issue with the list of boxes
      that are currently in the airtable for this destination. Our expectation for this
      destination is there will be ${expectedSize} boxes. There are, in fact, ${actualSize}
      boxes listed. 

      It seems like we SHOULD have boxes [${expectMinMax->first}] to [${expectMinMax->second}].
      It seems like we DO have boxes [${presentMinMax->first}] to [${presentMinMax->second}].
      
      We expected to see the following box numbers but they were missing: [${expectedButNotPresent->toNumberList}]
      We didn't expect to see the following box numbers: [${presentButNotExpected->toNumberList}] 
      `
        }
      }
    }
  }

  switch errorMessage {
  | "" =>
    Ok({
      // it's sorted and this returns an option
      maxBox: boxes->Array.get(0),
      penultimateBox: boxes->Array.get(1),
      otherEmptyBoxes: boxes->Array.keep(box => box.isEmpty.read()),
      // either the next box number or the first box
      newBox: boxes->Array.get(0)->Option.mapWithDefault(1, box => box.boxNumberOnly.read() + 1)
        |> formatBoxNameWithNumber(bdr),
    })
  | err => Error(err)
  }
}
