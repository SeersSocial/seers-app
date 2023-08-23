import Time "mo:base/Time";

import Tokens "Tokens"

module {
    public type MarketTx = {
        id : Nat32;
        marketId : Nat32;
        src : ?Nat; // Outcome
        dest : ?Nat; // Outcome
        sent : Nat64;
        recv : Nat64;
        fee : Nat64;
        price : Nat64;
        collateralType : Tokens.CollateralType;
        createdAt : Time.Time
    }
}
