open Belt

let s = React.string

let joinWith = Js.Array.joinWith

let map2Tuple: ('a => 'b, ('a, 'a)) => ('b, 'b) = (op, tup) => {
  let (l, r) = tup
  (op(l), op(r))
}

let first: (('a, 'b)) => 'a = ((l, _)) => l
let second: (('a, 'b)) => 'b = ((_, r)) => r

let identity: 'a => 'a = v => v

type result<'err, 'succ> = Ok('succ) | Err('err)

let optionToError: (option<'succ>, 'err) => result<'err, 'succ> = (opt, err) => {
  opt->Option.mapWithDefault(Err(err), rawSucc => Ok(rawSucc))
}

let partitionErrors: array<result<'err, 'succ>> => (array<'err>, array<'succ>) = arr => {
  Array.reduce(arr, ([], []), (accum, res) => {
    let (errs, succs) = accum
    switch res {
    | Err(err) => (Array.concat(errs, [err]), succs)
    | Ok(succ) => (errs, Array.concat(succs, [succ]))
    }
  })
}

let isError: result<'err, 'succ> => bool = res => {
  switch res {
  | Ok(_) => false
  | _ => true
  }
}
