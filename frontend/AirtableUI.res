/**
UI INTEGRATION
UI INTEGRATION
UI INTEGRATION
*/
module Input = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (
    ~value: string,
    ~onChange: ReactEvent.Form.t => 'a,
    ~style: ReactDOM.Style.t,
  ) => React.element = "Input"
}

module Dialog = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~onClose: unit => 'a) => React.element = "Dialog"
}

module Heading = {
  @bs.module("@airtable/blocks/ui") @react.component
  external make: (~children: React.element) => React.element = "Heading"
}
