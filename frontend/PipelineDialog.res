open AirtableUI

@react.component
let make = (
  ~header: string,
  ~children: React.element,
  ~actionButtons: array<React.element>,
  ~closeCancel: unit => _,
) => {
  <Dialog
    onClose=closeCancel
    width=800
    paddingTop=`28px`
    paddingLeft=`33px`
    paddingRight=`33px`
    paddingBottom=`55px`>
    <DialogCloseButton />
    <Heading> {React.string(header)} {children} {React.array(actionButtons)} </Heading>
  </Dialog>
}

module EditButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="edit" size="large" variant="default"> {children} </Button>
}

module CancelWarningButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="trash" size="large" variant="danger"> {children} </Button>
}

module PrimaryActionButton = {
  @react.component
  let make = (~onClick: unit => _, ~children: React.element) =>
    <Button onClick icon="bolt" size="large" variant="primary"> {children} </Button>
}
