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

  val encoding : t Json_encoding.encoding
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
