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

let trimLower: string => string = str => {
  str->Js.String.toLowerCase->Js.String.trim
}

let resultAndThen: (result<'err, 'a>, 'a => result<'err, 'b>) => result<'err, 'b> = (res, map) => {
  switch res {
  | Ok(a) => map(a)
  | Err(err) => Err(err)
  }
}

let isError: result<'err, 'succ> => bool = res => {
  switch res {
  | Ok(_) => false
  | _ => true
  }
}

let unzipFour: array<(('a, 'b), ('c, 'd), ('e, 'f), ('g, 'h))> => (
  array<('a, 'b)>,
  array<('c, 'd)>,
  array<('e, 'f)>,
  array<('g, 'h)>,
) = arr => {
  (
    arr->Array.map(((a, _, _, _)) => a),
    arr->Array.map(((_, b, _, _)) => b),
    arr->Array.map(((_, _, c, _)) => c),
    arr->Array.map(((_, _, _, d)) => d),
  )
}
