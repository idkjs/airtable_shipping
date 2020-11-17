open AirtableUI
open Belt

@react.component
let make = (
  ~header: string,
  ~children: React.element,
  ~actionButtons: array<React.element>,
  ~closeCancel: unit => _,
) => {
  let wrappedButtons =
    actionButtons
    ->Array.map(btn => <span style={ReactDOM.Style.make(~padding="10px 5px", ())}> btn </span>)
    ->React.array
  <Dialog
    onClose=closeCancel
    width=800
    paddingTop=`28px`
    paddingLeft=`33px`
    paddingRight=`33px`
    paddingBottom=`55px`>
    <DialogCloseButton />
    <Heading style={ReactDOM.Style.make(~marginBottom=`16px`, ~textAlign="center", ())}>
      {React.string(header)}
    </Heading>
    {children}
    {wrappedButtons}
  </Dialog>
}

module Subheading = {
  @react.component
  let make = (~children: React.element) =>
    <Heading
      size="small"
      style={ReactDOM.Style.make(~color="green", ~marginTop="11px", ~marginBottom="7px", ())}>
      children
    </Heading>
}

module EditButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="edit" size="large" variant="default"> {children} </Button>
}

module CancelButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="trash" size="large" variant="default"> {children} </Button>
}

module WarningButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="warning" size="large" variant="danger"> {children} </Button>
}

module PrimaryActionButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="bolt" size="large" variant="primary"> {children} </Button>
}
module PrimarySaveButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="book" size="large" variant="primary"> {children} </Button>
}
