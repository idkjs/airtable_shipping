// needed or a pulled in airtable lib crashes
global.window = 'beep'

/*
// this was originally output by the below in a .res file, added the console.log

export default = Airtable.outputEntireSchemaAsString(SchemaDef.allTables)
*/

var Airtable$JocoReceiving = require('./Airtable.bs.js')
var SchemaDef$JocoReceiving = require('./SchemaDef.bs.js')

var $$default = console.log(
  Airtable$JocoReceiving.outputEntireSchemaAsString(
    SchemaDef$JocoReceiving.allTables
  )
)

exports.$$default = $$default
exports.default = $$default
exports.__esModule = true
/*  Not a pure module */
