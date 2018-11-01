(*
 * Copyright (c) 2018 Vincent Bernardoff <vb@luminar.eu.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

module Encoding = struct
  type 'a t = 'a Json_encoding.encoding
  type schema = Json_schema.schema
  let unit = Json_encoding.empty
  let untyped = Json_encoding.(obj1 (req "untyped" string))
  let conv f g t = Json_encoding.(conv ~schema:(schema t) f g t)
  let schema t = Json_encoding.schema t
  let description_request_encoding = failwith "unimplemented"
  let description_answer_encoding = failwith "unimplemented"
end
module RPC = Resto_cohttp.Client.Make(Encoding)
(* open RPC *)

let b64_encoding =
  Json_encoding.(conv B64.encode B64.decode string)

let value_encoding =
  let open Json_encoding in
  conv (fun s -> s) (fun s -> s) (obj1 (req "value" b64_encoding))

module Links = struct
  type t = {
    self : Uri.t ;
    next : Uri.t option ;
    prev : Uri.t option ;
    succeeds : Uri.t option ;
    preceeds : Uri.t option ;
    effects : Uri.t option ;
    transaction : Uri.t option ;
  }

  let uri_encoding =
    let open Json_encoding in
    conv Uri.to_string Uri.of_string (obj1 (req "href" string))

  let encoding =
    let open Json_encoding in
    conv
      (fun { self ; next ; prev ; succeeds ; preceeds ; effects ; transaction } ->
         ((), (self, next, prev, succeeds, preceeds, effects, transaction)))
      (fun ((), (self, next, prev, succeeds, preceeds, effects, transaction)) ->
         { self ; next ; prev ; succeeds ; preceeds ; effects ; transaction })
      (merge_objs
         unit
         (obj7
            (req "self" uri_encoding)
            (opt "next" uri_encoding)
            (opt "prev" uri_encoding)
            (opt "succeeds" uri_encoding)
            (opt "preceeds" uri_encoding)
            (opt "effects" uri_encoding)
            (opt "transaction" uri_encoding)))
end

let embedded_encoding encoding =
  let open Json_encoding in
  obj1 (req "records" encoding)

let hal_encoding encoding =
  let open Json_encoding in
  (obj2
     (req "_links" Links.encoding)
     (req "_embedded" (embedded_encoding encoding)))

let float_str_encoding =
  let open Json_encoding in
  conv string_of_float float_of_string string

module Operation = struct
  type kind =
    | Create_account
    | Payment
    | Path_payment
    | Manage_offer
    | Create_passive_offer
    | Set_options
    | Change_trust
    | Allow_trust
    | Account_merge
    | Inflation
    | Manage_data
    | Bump_sequence

  let kind_of_int = function
    | 0 -> Create_account
    | 1 -> Payment
    | 2 -> Path_payment
    | 3 -> Manage_offer
    | 4 -> Create_passive_offer
    | 5 -> Set_options
    | 6 -> Change_trust
    | 7 -> Allow_trust
    | 8 -> Account_merge
    | 9 -> Inflation
    | 10 -> Manage_data
    | 11 -> Bump_sequence
    | _ -> invalid_arg "kind_of_int"

  let kind_encoding =
    let open Json_encoding in
    conv (fun _ -> invalid_arg "kind_encoding") kind_of_int int

  type t =
    | Create_account of {
        account: string ;
        funder : string ;
        starting_balance : float ;
      }
    | Payment
    | Path_payment
    | Manage_offer
    | Create_passive_offer
    | Set_options
    | Change_trust
    | Allow_trust
    | Account_merge
    | Inflation
    | Manage_data
    | Bump_sequence

  let create_account ~account ~funder ~starting_balance =
    Create_account { account ; funder ; starting_balance }

  type common_attrs = {
    id: int64 ;
    paging_token : int64 ;
    kind : kind ;
  }
  let common_attrs_encoding =
    let open Json_encoding in
    conv
      (fun _ -> invalid_arg "not implemented")
      (fun (id, paging_token, _, kind) ->
         { id ; paging_token ; kind })
      (obj4
         (req "id" int53)
         (req "paging_token" int53)
         (req "type" string)
         (req "type_i" kind_encoding))

  let create_account_encoding =
    let open Json_encoding in
    conv
      (fun _ -> invalid_arg "not implemented")
      (fun (_, (account, funder, starting_balance)) ->
            create_account ~account ~funder ~starting_balance)
      (merge_objs
         common_attrs_encoding
         (obj3
            (req "account" string)
            (req "funder" string)
            (req "starting_balance" float_str_encoding)))
end

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
  type kind = Credit_alphanum4 | Credit_alphanum12
  let kind_encoding =
    let open Json_encoding in
    string_enum [
      "credit_alphanum4", Credit_alphanum4 ;
      "credit_alphanum12", Credit_alphanum12 ;
    ]

  type t = {
    typ : kind ;
    code : string ;
    issuer : string ;
    amount : int64 ;
    num_accounts : int ;
    auth_immutable : bool ;
    auth_required : bool ;
    auth_revocable : bool ;
    paging_token : string ;
  }

  let flag_encoding =
    let open Json_encoding in
    obj3
      (req "auth_immutable" bool)
      (req "auth_required" bool)
      (req "auth_revocable" bool)

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> invalid_arg "unsupported")
      (fun (typ, code, issuer, paging_token, amount,
            num_accounts, (auth_immutable, auth_required, auth_revocable)) ->
        { typ ; code ; issuer ; paging_token ; amount ; num_accounts ;
          auth_immutable ; auth_required ; auth_revocable })
      (obj7
         (req "asset_type" kind_encoding)
         (req "asset_code" string)
         (req "asset_issuer" string)
         (req "paging_token" string)
         (req "amount" int53)
         (req "num_accounts" int)
         (req "flags" flag_encoding))

  (* let all_assets =
   *   Service.get_service
   *     ~description:"This endpoint represents all assets. It will give \
   *                   you all the assets in the system along with \
   *                   various statistics about each." *)
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
