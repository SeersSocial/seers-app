import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Deque "mo:base/Deque";

import Errors "Errors";
import Utils "Utils";
import Tokens "Tokens";
import User "User";

module {
    public type State = {
        #open;
        #matched;
        #closed;
        #cancelled;
        #resolved : Nat;
        #redeemed : Nat
    };

    public type InitData = {
        id : Nat32;
        description : Text;
        outcomes : [Text];
        authorChoice : Nat;
        collateralType : Tokens.CollateralType;
        authorAmount : Nat64;
        author : ?Utils.UserData
    };

    public type SimpleMarketStable = {
        id : Nat32;
        description : Text;
        outcomes : [Text];
        authorChoice : Nat;
        collateralType : Tokens.CollateralType;
        authorAmount : Nat64;
        author : ?Utils.UserData;

        amount : Nat64;
        matcherAmount : Nat64;
        authorResolution : Nat;
        matcher : ?Utils.UserData;
        matcherChoice : Nat;
        matcherResolution : Nat;
        createdAt : Time.Time;
        modifiedAt : Time.Time;
        state : State
    };

    public func unFreeze(ms : SimpleMarketStable) : SimpleMarket {
        let initData : InitData = {
            id = ms.id;
            description = ms.description;
            outcomes = ms.outcomes;
            authorChoice = ms.authorChoice;
            collateralType = ms.collateralType;
            authorAmount = ms.authorAmount;
            author = ms.author
        };
        var market : SimpleMarket = SimpleMarket(initData);
        market.amount := ms.amount;
        market.matcherAmount := ms.matcherAmount;
        market.authorResolution := ms.authorResolution;
        market.matcher := ms.matcher;
        market.matcherChoice := ms.matcherChoice;
        market.createdAt := ms.createdAt;
        market.modifiedAt := ms.modifiedAt;
        market.state := ms.state;

        return market
    };

    public class SimpleMarket(initData : InitData) = this {
        public var id : Nat32 = initData.id;
        public var description : Text = initData.description;
        public var outcomes : [Text] = initData.outcomes;
        public var collateralType : Tokens.CollateralType = initData.collateralType;
        public var amount : Nat64 = initData.authorAmount;
        public var authorAmount : Nat64 = initData.authorAmount;
        public var matcherAmount : Nat64 = 0;
        public var author : ?Utils.UserData = initData.author;
        public var authorChoice : Nat = initData.authorChoice;
        public var authorResolution : Nat = 2; // Valid outcomes: 0, 1. Unset: 2. Cancel: 3.
        public var matcher : ?Utils.UserData = null;
        public var matcherChoice : Nat = 2;
        public var matcherResolution : Nat = 2;
        public var createdAt : Time.Time = Time.now();
        public var modifiedAt : Time.Time = Time.now();
        public var state : State = #open;

        public func freeze() : SimpleMarketStable {
            let ms : SimpleMarketStable = {
                id = id;
                description = description;
                outcomes = outcomes;
                collateralType = collateralType;
                amount = amount;
                authorAmount = authorAmount;
                matcherAmount = matcherAmount;
                author = author;
                authorChoice = authorChoice;
                authorResolution = authorResolution;
                matcher = matcher;
                matcherChoice = matcherChoice;
                matcherResolution = matcherResolution;
                createdAt = createdAt;
                modifiedAt = modifiedAt;
                state = state
            };
            return ms
        };

        // Another user match author's bet by locking funds.
        public func match(caller : User.User) : Result.Result<(), Errors.Error> {
            assert (state == #open);

            if (not caller.checkBalance(collateralType, authorAmount)) {
                return #err(#insufficientBalance)
            };

            switch (caller.lockBalance(collateralType, authorAmount)) {
                case (#err(e)) {
                    return #err(e)
                };
                case (#ok()) {
                    state := #matched;
                    matcherAmount := authorAmount;

                    let u : Utils.UserData = {
                        name = caller.name;
                        principal = caller.id;
                        handle = caller.handle;
                        picture = caller.picture
                    };

                    matcher := ?u;
                    // Always choose the opposite of author's choice.
                    matcherChoice := 1 - authorChoice;
                    return #ok()
                }
            }
        };

        // Bettors can resolve the outcome of the bet or cancel it.
        public func resolve(caller : User.User, outcome : Nat) : Result.Result<(), Errors.Error> {
            assert (state == #matched);

            switch (author) {
                case null {
                    return #err(#userDoesNotExist)
                };
                case (?authorData) {
                    if (caller.id == authorData.principal) {
                        authorResolution := outcome
                    }
                }
            };

            switch (matcher) {
                case null {
                    return #err(#userDoesNotExist)
                };
                case (?matcherData) {
                    if (caller.id == matcherData.principal) {
                        matcherResolution := outcome
                    }
                }
            };

            if (authorResolution < 2 and authorResolution == matcherResolution) {
                state := #resolved(authorResolution)
            };

            if (authorResolution < 2 and authorResolution == matcherChoice) {
                state := #resolved(authorResolution)
            };

            if (matcherResolution < 2 and matcherResolution == authorChoice) {
                state := #resolved(matcherResolution)
            };

            if (authorResolution == 3 and authorResolution == matcherResolution) {
                state := #cancelled
            };

            return #ok()
        };

        // Redeem funds to bettors.
        public func redeem(author : User.User, matcher : User.User) : Result.Result<?User.Payment, Errors.Error> {

            switch (state) {
                case (#cancelled) {
                    ignore author.unlockBalance(collateralType, authorAmount);
                    ignore matcher.unlockBalance(collateralType, authorAmount);
                    state := #redeemed(2);

                    return #ok(null)
                };
                case (#resolved(outcome)) {
                    let w = if (authorChoice == outcome) { author } else {
                        matcher
                    };
                    let l = if (authorChoice == outcome) { matcher } else {
                        author
                    };

                    ignore w.unlockBalance(collateralType, authorAmount);
                    ignore w.incPlusBalance(collateralType, matcherAmount);

                    ignore l.unlockBalance(collateralType, matcherAmount);
                    ignore l.incMinusBalance(collateralType, matcherAmount);

                    let payment : User.Payment = {
                        from = l.id;
                        to = w.id;
                        amount = amount;
                        processed = false;
                        collateralType = collateralType
                    };
                    state := #redeemed(outcome);
                    return #ok(?payment)
                };
                case (_) {
                    return #err(#cannotBeRedeemed)
                }
            }
        }
    };

    private func checkInitData(initData : InitData) : Result.Result<(), Errors.Error> {
        if (initData.description == "") {
            return #err(#missingDescription)
        };

        if (initData.outcomes.size() != 2) {
            return #err(#wrongNumberOfOutcomes)
        };

        if (initData.authorAmount < 1_000) {
            return #err(#notEnoughBetAmount)
        };

        if (initData.authorChoice >= initData.outcomes.size()) {
            return #err(#authorOutcomeMissing)
        };

        return #ok()
    };

    // Creates a simple bet market by locking funds from the caller.
    public func create(caller : User.User, initData : InitData) : Result.Result<SimpleMarket, Errors.Error> {
        switch (checkInitData(initData)) {
            case (#err(e)) {
                return #err(e)
            };
            case (#ok()) { /* continue */ }
        };

        switch (initData.author) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?authorData) {
                if (caller.id != authorData.principal) {
                    return #err(#callerIsNotAuthor)
                }
            }
        };

        if (caller.checkBalance(initData.collateralType, initData.authorAmount)) {
            ignore caller.lockBalance(initData.collateralType, initData.authorAmount);

            var m : SimpleMarket = SimpleMarket(initData);

            m.author := ?{
                principal = caller.id;
                handle = caller.handle;
                name = caller.name;
                picture = caller.picture
            };

            return #ok(m)
        } else {
            return #err(#notEnoughBalance)
        }
    }
}
