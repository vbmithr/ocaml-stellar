let b64_encoding =
  Json_encoding.(conv B64.encode B64.decode string)

let value_encoding =
  let open Json_encoding in
  conv (fun s -> s) (fun s -> s) (obj1 (req "value" b64_encoding))

module Threshold = struct
  type t = {
    low : int;
    med : int;
    high : int;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun { low ; med ; high } -> (low, med, high))
      (fun (low, med, high) -> { low ; med ; high })
      (obj3
        (req "low_threshold" int)
        (req "med_threshold" int)
        (req "high_threshold" int))
end

module Balance = struct
  type t = {
    asset_type : string ;
    balance : float ;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun { asset_type ; balance } -> (asset_type, balance))
      (fun (asset_type, balance) -> { asset_type ; balance })
      (obj2
         (req "asset_type" string)
         (req "balance" float))
end

module Asset = struct
  type t = {
    typ : string ;
    code : string ;
    issuer : string ;
    amount : int ;
    num_accounts : int ;
    auth_required : bool ;
    auth_revocable : bool ;
    paging_token : string ;
  }

  let flag_encoding =
    let open Json_encoding in
    obj2
      (req "auth_required" bool)
      (req "auth_revocable" bool)

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> invalid_arg "unsupported")
      (fun (typ, code, issuer, paging_token, amount,
            num_accounts, (auth_required, auth_revocable)) ->
        { typ ; code ; issuer ; paging_token ; amount ; num_accounts ;
          auth_required ; auth_revocable })
      (obj7
         (req "asset_type" string)
         (req "asset_code" string)
         (req "asset_issuer" string)
         (req "paging_token" string)
         (req "amount" int)
         (req "num_accounts" int)
         (req "flags" flag_encoding))
end

module Account = struct
  type t = {
    id : string ;
    account_id : string ;
    sequence : int ;
    subentry_count : int ;
    balances: Balance.t list ;
    thresholds : Threshold.t ;
  }
end