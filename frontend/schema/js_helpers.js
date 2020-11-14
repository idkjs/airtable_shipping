let ui = require('@airtable/blocks/ui')
let mom = require('moment')

let moment = mom.moment
let useRecords = ui.useRecords

function prepBareString (record, field) {
  return record.getCellValueAsString(field)
}

function prepStringOption (record, field) {
  let v = record.getCellValueAsString(field)
  if (v && v.trim().length > 0) {
    return v
  }

  return undefined
}

function prepInt (record, field) {
  let v = parseInt(record.getCellValueAsString(field))
  // we go the long way here because formula fields can return a buncha shit

  if (Number.isNaN(v)) {
    console.error(
      `requested field cannot be parsed as int, returning 0 [fieldname:${field.name},recordname:${record.name},val: ${v}]`
    )
    return 0
  }

  return v
}

function prepBool (record, field) {
  let v = record.getCellValue(field)
  if (typeof v !== 'boolean') {
    console.error(
      `requested field cannot be parsed as bool, returning false [fieldname:${field.name},recordname:${record.name},val: ${v}]`
    )
    return false
  }

  return v
}

function prepIntAsBool (record, field) {
  let v = prepInt(record, field)
  if (v < 0 || v > 1) {
    console.error(
      `requested field is an int bool, but has a value that's neither 0 or 1, returning false [fieldname:${field.name},recordname:${record.name},val: ${v}]`
    )
    return false
  }

  return !!v
}

function prepMomentOption (record, field) {
  let v = record.getCellValueAsString(field)
  let vm = moment(v)

  if (!vm.isValid()) {
    if (v.trim() !== '') {
      // if the cell is blank we don't care... it's just empty
      // this is NOT a type error, it's a None option
      // BUT if the moment is invalid for another reason then...
      // type error
      console.error(
        `requested field is a moment, but moment doesn't think so [fieldname:${field.name},recordname:${record.name},val: ${v}]`
      )
    }
    return undefined
  }
  return vm
}

function prepRelFieldQueryResult (record, field, fetchfields, sortsArr) {
  return record.selectLinkedRecordsFromCell(field, {
    fields: fetchfields,
    sorts: sortsArr
  })
}

function selectRecordsFromTableOrView (tableOrView, fetchfields, sortsArr) {
  return tableOrView.selectRecords({
    fields: fetchfields,
    sorts: sortsArr
  })
}

exports.prepBareString = prepBareString
exports.prepStringOption = prepStringOption
exports.prepInt = prepInt
exports.prepBool = prepBool
exports.prepIntAsBool = prepIntAsBool
exports.prepMomentOption = prepMomentOption
exports.prepRelFieldQueryResult = prepRelFieldQueryResult
exports.selectRecordsFromTableOrView = selectRecordsFromTableOrView