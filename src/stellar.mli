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

module Encoding : Resto.ENCODING
module RPC : module type of Resto_cohttp.Client.Make(Encoding)
(* open RPC *)

val value_encoding : string Json_encoding.encoding
(** Encoder for { value: "<base-64 encoded string>" } *)

module Links : sig
  type t = {
    self : Uri.t ;
    next : Uri.t option ;
    prev : Uri.t option ;
    succeeds : Uri.t option ;
    preceeds : Uri.t option ;
    effects : Uri.t option ;
    transaction : Uri.t option ;
  }

  val encoding : t Json_encoding.encoding
end

val hal_encoding :
  'a Json_encoding.encoding ->
  (Links.t * 'a) Json_encoding.encoding

module Threshold : sig
  type t = {
    low : int;
    med : int;
    high : int;
  }

  val encoding : t Json_encoding.encoding
end

module Balance : sig
  type t = {
    asset_type : string ;
    balance : float ;
  }

  val encoding : t Json_encoding.encoding
end

module Asset : sig
  type kind = Credit_alphanum4 | Credit_alphanum12
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

  val encoding : t Json_encoding.encoding

  (* val all_assets :
   *   ([ `GET ],
   *    unit,
   *    unit,
   *    unit,
   *    unit,
   *    t list,
   *    unit) Service.service *)
end

module Account : sig
  type t = {
    id : string ;
    account_id : string ;
    sequence : int ;
    subentry_count : int ;
    balances: Balance.t list ;
    thresholds : Threshold.t ;
  }
end

module Operation : sig
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

  val create_account_encoding : t Json_encoding.encoding
end
