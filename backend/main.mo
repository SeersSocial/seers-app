import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Int "mo:base/Int";
import Float "mo:base/Float";
import List "mo:base/List";
import Trie "mo:base/Trie";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Deque "mo:base/Deque";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Char "mo:base/Char";

import Prim "mo:⛔";

import Errors "Errors";
import Market "Market";
import SimpleMarket "SimpleMarket";
import State "State";
import Tokens "Tokens";
import User "User";
import Utils "Utils";
import Tx "Tx";
import Post "Post";
import Comment "Comment";
import Like "Like";
import Forecast "Forecast";
import Account "Account";
import FileTypes "./file-upload/types";
import Ledger "Ledger";
import Types "./exchange-rate/Types";
// import LedgerC "LedgerCandid";
// import XDR "XDR";

shared ({ caller = initializer }) actor class Actor() = this {
    private let ledger : Ledger.Interface = actor (Ledger.CANISTER_ID);
    private stable var anon : Text = "2vxsx-fae";

    // Returns the default account identifier of this canister.
    func myAccountId() : Account.AccountIdentifier {
        Account.accountIdentifier(
            Principal.fromActor(this),
            Account.defaultSubaccount(),
        )
    };

    // Returns the default account identifier of this canister.
    func otherAccountId() : Account.AccountIdentifier {
        Account.accountIdentifier(
            Principal.fromActor(this),
            Account.otherSubaccount(),
        )
    };

    // Returns current balance on the default account of this canister.
    public func canisterBalance() : async Ledger.ICP {
        await ledger.account_balance({ account = myAccountId() })
    };

    /* Types */

    // Returns canister's default account identifier as text.
    public query func canisterAccount() : async Text {
        Account.toText(myAccountId())
    };

    // Returns canister's default account identifier as text.
    public query func otherAccount() : async Text {
        Account.toText(otherAccountId())
    };

    // Returns current balance on the default account of this canister.
    public func accountBalance(account : Text) : async ?Ledger.ICP {
        switch (Account.fromText(account)) {
            case null {
                return null
            };
            case (?account) {
                let balance = await ledger.account_balance({ account = account });
                return ?balance
            }
        }
    };

    private func transfer(
        from : Account.Subaccount,
        to : Account.Subaccount,
        amount : Nat64,
    ) : async Result.Result<(), Errors.Error> {
        // assert (msg.caller == initializer);

        let canister = Principal.toText(Principal.fromActor(this));
        let args = {
            memo = Prim.time();
            amount = { e8s = amount };
            fee = { e8s = 10_000 : Nat64 };
            from_subaccount = ?from;
            to = Account.makeAccountIdentifier(to, canister);
            created_at_time = null
        };

        switch (await ledger.transfer(args)) {
            case (#Ok(idx)) {
                return #ok()
            };
            case (#Err(error)) {
                return #err(#failedTransfer(debug_show (error)))
            }
        }
    };

    public shared (msg) func getUserAccount(principal : Text) : async Result.Result<Text, Errors.Error> {
        let account : Text = Account.toText(Account.makeAccountIdentifier(Account.defaultSubaccount(), principal));
        return #ok(account)
    };

    public shared (msg) func setPrincipal(principal : Text, toHandle : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);
        switch (state.users.get(toHandle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?toUser) {
                toUser.id := principal
            }
        };
        state.handles.put(principal, toHandle);
        return #ok()
    };

    public shared (msg) func setHandle(prevHandle : Text, newHandle : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);
        switch (state.users.get(prevHandle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?toUser) {
                toUser.handle := newHandle;
                state.handles.put(toUser.id, newHandle);
                state.users.put(newHandle, toUser)
            }
        };
        return #ok()
    };

    public shared (msg) func transferToIdentifier(to : Text, amount : Nat64) : async Result.Result<(), Errors.Error> {
        // assert (msg.caller == initializer);
        // assert (not updating);
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?fromUser) {
                switch (Account.fromText(to)) {
                    case null {
                        return #err(#userDoesNotExist)
                    };
                    case (?toIdentifier) {
                        if (Account.validateAccountIdentifier(toIdentifier)) {
                            let args = {
                                memo = Prim.time();
                                amount = { e8s = amount };
                                fee = { e8s = 10_000 : Nat64 };
                                from_subaccount = ?fromUser.depositAddrs.icp;
                                to = toIdentifier;
                                created_at_time = null
                            };
                            fromUser.balances := {
                                icp = fromUser.balances.icp - amount - 10_000;
                                seers = fromUser.balances.seers;
                                btc = fromUser.balances.btc;
                                cycles = fromUser.balances.cycles
                            };
                            switch (await ledger.transfer(args)) {
                                case (#Ok(idx)) {
                                    return #ok()
                                };
                                case (#Err(error)) {
                                    return #err(#failedTransfer(debug_show (error)))
                                }
                            }
                        } else {
                            return #err(#invalidIdentifier)
                        }
                    }
                }
            }
        }
    };

    public shared (msg) func unfollowUser(handle : Text) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?fromUser) {
                switch (state.users.get(handle)) {
                    case null {
                        return #err(#userDoesNotExist)
                    };
                    case (?toUser) {
                        toUser.followers := Utils.removeFromBuffer<User.FollowerStable>(
                            toUser.followers,
                            func(x : User.FollowerStable) : Bool {
                                switch x {
                                    case (#v0(x)) {
                                        return x.userdata.principal == fromUser.id
                                    }
                                }
                            },
                        );
                        fromUser.followees := Utils.removeFromBuffer<User.FolloweeStable>(
                            fromUser.followees,
                            func(x : User.FolloweeStable) : Bool {
                                switch x {
                                    case (#v0(x)) {
                                        return x.userdata.principal == toUser.id
                                    }
                                }
                            },
                        )
                    }
                }
            }
        };

        return #ok
    };

    public shared (msg) func followUser(handle : Text) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?fromUser) {
                switch (state.users.get(handle)) {
                    case null {
                        return #err(#userDoesNotExist)
                    };
                    case (?toUser) {
                        let fromData : Utils.UserData = {
                            principal = fromUser.id;
                            handle = fromUser.handle;
                            name = fromUser.name;
                            picture = fromUser.picture
                        };
                        let toData : Utils.UserData = {
                            principal = toUser.id;
                            handle = toUser.handle;
                            name = toUser.name;
                            picture = toUser.picture
                        };
                        let followee : User.FolloweeStable = #v0({
                            userdata = toData;
                            createdAt = Time.now()
                        });
                        let follower : User.FollowerStable = #v0({
                            userdata = fromData;
                            createdAt = Time.now()
                        });

                        fromUser.followees.add(followee);
                        toUser.followers.add(follower)
                    }
                }
            }
        };

        return #ok()
    };

    public shared (msg) func setAvatar(toHandle : Text, avatar : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);
        switch (state.users.get(toHandle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?toUser) {
                toUser.picture := avatar
            }
        };

        return #ok()
    };

    public shared (msg) func setCover(toHandle : Text, cover : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);
        switch (state.users.get(toHandle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?toUser) {
                toUser.cover := cover
            }
        };

        return #ok()
    };

    public shared (msg) func transferToHandle(toHandle : Text, amount : Nat64) : async Result.Result<(), Errors.Error> {
        // assert (msg.caller == initializer);

        // assert (not updating);
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?fromUser) {
                switch (state.users.get(toHandle)) {
                    case null {
                        return #err(#userDoesNotExist)
                    };
                    case (?toUser) {
                        if (fromUser.checkBalance(#icp, amount + 10_000)) {
                            fromUser.balances := {
                                icp = fromUser.balances.icp - amount - 10_000;
                                seers = fromUser.balances.seers;
                                btc = fromUser.balances.btc;
                                cycles = fromUser.balances.cycles
                            };
                            switch (await transfer(fromUser.depositAddrs.icp, toUser.depositAddrs.icp, amount)) {
                                case (#err(e)) {
                                    return #err(e)
                                };
                                case (#ok()) {
                                    return #ok()
                                }
                            }
                        } else {
                            return #err(#notEnoughBalance)
                        }
                    }
                }
            }
        };
        return #err(#userDoesNotExist)
    };

    public shared (msg) func transferToCanister() : async Text {
        // assert(msg.caller == initializer);
        Debug.print(debug_show (initializer));
        Debug.print(debug_show (msg.caller));

        let args = {
            memo = Prim.time();
            amount = { e8s = 80_000 : Nat64 };
            // 0.001 ICP
            fee = { e8s = 10_000 : Nat64 };
            from_subaccount = ?Account.otherSubaccount();
            to = myAccountId();
            created_at_time = null
        };
        switch (await ledger.transfer(args)) {
            case (#Ok(idx)) {
                "transfer successfully on block : " # debug_show (idx)
            };
            case (#Err(error)) { debug_show (error) }
        }
    };

    // Returns canister's default account identifier as a blob.
    public shared (msg) func callerAccount() : async Account.AccountIdentifier {
        let principal = msg.caller;
        return Account.accountIdentifier(principal, Account.defaultSubaccount())
    };

    /* Rate vars */

    // How many data point can be returned as maximum.
    // Given that 2MB is max-allow canister response size, and each <Timestamp, Rate> pair
    // should be less that 20 bytes. Maximum data points could be returned for each
    // call can be as many as 2MB / 20B = 100000.
    let MAX_DATA_PONTS_CANISTER_RESPONSE : Nat = 100000;

    // Remote fetch interval in secs. It is only the canister returned interval
    // that is dynamic according to the data size needs to be returned.
    let REMOTE_FETCH_GRANULARITY : Nat64 = 60;

    // For how many rounds of heartbeat, make a http_request call.
    let RATE_LIMIT_FACTOR : Nat = 5;

    // How many data points in each Coinbase API call. Maximum allowed is 300
    let DATA_POINTS_PER_API : Nat64 = 200;

    // Maximum raw Coinbase API response size. This field is used by IC to calculate circles cost per HTTP call.
    // Here is how this number is derived:
    // Each Coinbase API call return an array of array, and each sub-array look like below:
    // [
    //     1652454000,
    //     9.51,
    //     9.6,
    //     9.55,
    //     9.54,
    //     4857.1892
    // ],
    // Each field of this sub-arry takes less than 10 bytes. Then,
    // 10 (bytes per field) * 6 (fields per timestamp) * 200 (timestamps)
    let MAX_RESPONSE_BYTES : Nat64 = 10 * 6 * DATA_POINTS_PER_API;

    var RATE_COUNTER : Nat = 0;

    /* State */

    private stable var updating : Bool = false;
    private stable var nextMarketId : Nat32 = 1;
    private stable var nextPostId : Nat32 = 8;
    private stable var nextUserId : Nat32 = 15;
    private stable var nextBetId : Nat32 = 1;
    private stable var nextChunkID : Nat = 0;
    private stable var queueError : Text = "Stopped";

    private stable var stableState : State.StableState = #v1 {
        users = [];
        handles = [];
        posts = [];
        postsv = [];
        bets = [];
        markets = [];
        images = [];
        chunks = [];
        assets = [];
        hashtags = [];
        feed = [];
        payments = []
    };
    private var state : State.State = State.State(stableState);

    /* Upgrade */

    system func preupgrade() {
        stableState := state.freeze()
    };

    system func postupgrade() {
        stableState := #v1 {
            users = [];
            handles = [];
            posts = [];
            postsv = [];
            bets = [];
            markets = [];
            images = [];
            feed = [];
            payments = [];
            hashtags = [];
            chunks = [];
            assets = []
        }
    };

    /* Heartbeat */

    var heartbeatCount = 0;
    var heartbeatBusy = false;
    var heartbeatTask = 43;

    // system func heartbeat() : async () {
    //     heartbeatCount += 1;

    //     if (heartbeatCount % 3 == 0) {
    //         queueError := "Busy: " # debug_show (heartbeatBusy) # " task: " # debug_show (heartbeatTask) # " beat: " # debug_show (heartbeatCount)
    //     };

    //     // if (state.payments.size() == heartbeatTask) {
    //     //     state.payments.clear()
    //     // };

    //     if (not heartbeatBusy and heartbeatCount % 100 == 0 and state.payments.size() > heartbeatTask) {
    //         heartbeatBusy := true;

    //         let payments = state.payments.toVarArray();
    //         let i = heartbeatTask;

    //         var payment = payments[i];

    //         if (not payment.processed) {

    //             let fromUser = switch (getUser(payment.from)) {
    //                 case null {
    //                     queueError := "From user not found";
    //                     return ()
    //                 };
    //                 case (?user) {
    //                     user
    //                 }
    //             };

    //             let toUser = switch (getUser(payment.to)) {
    //                 case null {
    //                     queueError := "To user not found";
    //                     return ()
    //                 };
    //                 case (?user) {
    //                     user
    //                 }
    //             };

    //             if (payment.collateralType == #seers) {
    //                 // Not implemented yet, mocked.
    //                 payments[i] := {
    //                     from = payment.from;
    //                     to = payment.to;
    //                     amount = payment.amount;
    //                     collateralType = payment.collateralType;
    //                     processed = true
    //                 };
    //                 heartbeatTask += 1
    //             } else {
    //                 if (fromUser.balances.icp > payment.amount) {
    //                     payments[i] := {
    //                         from = payment.from;
    //                         to = payment.to;
    //                         amount = payment.amount;
    //                         collateralType = payment.collateralType;
    //                         processed = true
    //                     };
    //                     if (fromUser.handle == "seers") {
    //                         fromUser.balances := {
    //                             icp = fromUser.balances.icp;
    //                             seers = fromUser.balances.seers;
    //                             btc = fromUser.balances.btc;
    //                             cycles = fromUser.balances.cycles
    //                         }
    //                     } else {
    //                         fromUser.balances := {
    //                             icp = fromUser.balances.icp - payment.amount;
    //                             seers = fromUser.balances.seers;
    //                             btc = fromUser.balances.btc;
    //                             cycles = fromUser.balances.cycles
    //                         }
    //                     };

    //                     switch (await transfer(fromUser.depositAddrs.icp, toUser.depositAddrs.icp, payment.amount)) {
    //                         case (#ok()) {
    //                             ignore fromUser.decMinusBalance(
    //                                 payment.collateralType,
    //                                 payment.amount,
    //                             );
    //                             ignore toUser.decPlusBalance(
    //                                 payment.collateralType,
    //                                 payment.amount,
    //                             );

    //                             if (toUser.handle == "seers") {
    //                                 toUser.balances := {
    //                                     icp = toUser.balances.icp + payment.amount;
    //                                     seers = toUser.balances.seers;
    //                                     btc = toUser.balances.btc;
    //                                     cycles = toUser.balances.cycles
    //                                 }
    //                             } else {
    //                                 toUser.balances := {
    //                                     icp = toUser.balances.icp;
    //                                     seers = toUser.balances.seers;
    //                                     btc = toUser.balances.btc;
    //                                     cycles = toUser.balances.cycles
    //                                 }
    //                             };

    //                             heartbeatTask += 1;
    //                             queueError := "Processed: " # debug_show (heartbeatCount) # " " # debug_show (i)
    //                         };
    //                         case (#err(e)) {
    //                             payments[i] := {
    //                                 from = payment.from;
    //                                 to = payment.to;
    //                                 amount = payment.amount;
    //                                 collateralType = payment.collateralType;
    //                                 processed = false
    //                             };
    //                             queueError := "Error: " # debug_show (heartbeatCount) # " " # debug_show (e)
    //                         }
    //                     }
    //                 } else {
    //                     queueError := "User has not enough balance" # debug_show (heartbeatCount)
    //                 };

    //             }
    //         };

    //         state.payments := Utils.bufferFromVarArray<User.Payment>(payments);
    //         heartbeatBusy := false
    //     }
    // };

    /* API */

    public shared ({ caller }) func create_chunk(chunk : FileTypes.Chunk) : async {
        chunk_id : Nat
    } {
        Debug.print("creating chunk");
        // nextChunkID := nextChunkID + 1;
        // state.chunks.put(nextChunkID, chunk);

        return { chunk_id = nextChunkID }
    };

    public shared ({ caller }) func commit_batch(
        { batch_name : Text; chunk_ids : [Nat]; content_type : Text } : {
            batch_name : Text;
            content_type : Text;
            chunk_ids : [Nat]
        }
    ) : async () {
        Debug.print("committing batch");
        var content_chunks : [[Nat8]] = [];

        // for (chunk_id in chunk_ids.vals()) {
        //     let chunk : ?FileTypes.Chunk = state.chunks.get(chunk_id);

        //     switch (chunk) {
        //         case (?{ content }) {
        //             content_chunks := Array.append<[Nat8]>(
        //                 content_chunks,
        //                 [Blob.toArray(content)],
        //             )
        //         };
        //         case null {}
        //     }
        // };

        // if (content_chunks.size() > 0) {
        //     var total_length = 0;
        //     for (chunk in content_chunks.vals()) total_length += chunk.size();
        //     let blobs = Array.map(
        //         content_chunks,
        //         func(a : [Nat8]) : Blob {
        //             Blob.fromArray(a)
        //         },
        //     );
        //     state.assets.put(
        //         Text.concat("/assets/", batch_name),
        //         {
        //             content_type = content_type;
        //             encoding = {
        //                 modified = Time.now();
        //                 content_chunks = blobs;
        //                 certified = false;
        //                 total_length
        //             }
        //         },
        //     )
        // }
    };

    private func create_token(
        key : Text,
        chunk_index : Nat,
        encoding : FileTypes.AssetEncoding,
    ) : ?FileTypes.StreamingCallbackToken {

        // if (chunk_index + 1 >= encoding.content_chunks.size()) {
        null
        // } else {
        //     ?{
        //         key;
        //         index = chunk_index + 1;
        //         content_encoding = "gzip"
        //     }
        // }
    };

    public shared query ({ caller }) func http_request(
        request : FileTypes.HttpRequest
    ) : async FileTypes.HttpResponse {
        Debug.print("calling htttp_request");
        if (request.method == "GET") {
            let split : Iter.Iter<Text> = Text.split(request.url, #char '?');
            let key : Text = Iter.toArray(split)[0];

            let asset : ?FileTypes.Asset = state.assets.get(key);

            switch (asset) {
                case (?{ content_type : Text; encoding : FileTypes.AssetEncoding }) {
                    return {
                        body = Blob.toArray(encoding.content_chunks[0]);
                        headers = [
                            ("Content-Type", content_type),
                            ("accept-ranges", "bytes"),
                            ("cache-control", "private, max-age=0"),
                        ];
                        status_code = 200;
                        streaming_strategy = create_strategy(
                            key,
                            0,
                            { content_type; encoding },
                            encoding,
                        )
                    }
                };
                case null {}
            }
        };

        return {
            body = Blob.toArray(Text.encodeUtf8("Permission denied. Could not perform this operation"));
            headers = [];
            status_code = 403;
            streaming_strategy = null
        }
    };

    private func create_strategy(
        key : Text,
        index : Nat,
        asset : FileTypes.Asset,
        encoding : FileTypes.AssetEncoding,
    ) : ?FileTypes.StreamingStrategy {
        switch (create_token(key, index, encoding)) {
            case (null) { null };
            case (?token) {
                let self : Principal = Principal.fromActor(this);
                let canisterId : Text = Principal.toText(self);
                let canister = actor (canisterId) : actor {
                    http_request_streaming_callback : shared () -> async ()
                };

                return ? #Callback({
                    token;
                    callback = canister.http_request_streaming_callback
                })
            }
        }
    };

    public shared query ({ caller }) func http_request_streaming_callback(
        st : FileTypes.StreamingCallbackToken
    ) : async FileTypes.StreamingCallbackHttpResponse {

        switch (state.assets.get(st.key)) {
            case (null) throw Error.reject("key not found: " # st.key);
            case (?asset) {
                return {
                    token = create_token(
                        st.key,
                        st.index,
                        asset.encoding,
                    );
                    body = asset.encoding.content_chunks[st.index]
                }
            }
        }
    };

    // Read payments queue.
    public query func getPayments() : async [User.Payment] {
        return state.payments.toArray()
    };

    // Read payments error.
    public query func getPaymentsError() : async Text {
        return queueError
    };

    // Read users with karma.
    public query func readUsersKarma() : async [(Text, Text, Text, Nat)] {
        return []
        // let usersWithKarma = Array.filter<User.User>(
        //     Iter.toArray(state.users.vals()),
        //     func(u : User.User) : Bool {
        //         return (u.posts.size() > 0 or u.replies.size() > 0 or u.markets.size() > 0)
        //     },
        // );

        // Array.map<User.User, (Text, Text, Text, Nat)>(
        //     usersWithKarma,
        //     func(u : User.User) : (Text, Text, Text, Nat) {
        //         var total : Nat64 = 0;
        //         for (market in u.markets.vals()) {
        //             total += market.spent
        //         };
        //         total := total / 100_000_000;
        //         if (total > 1000) {
        //             return (u.picture, u.handle, u.name, Nat64.toNat(0))
        //         } else {
        //             return (u.picture, u.handle, u.name, Nat64.toNat(total) * 5 + u.posts.size() + u.replies.size())
        //         }
        //     },
        // )
    };

    // Read users with karma and claim.
    public query func readUsersKarmaClaim() : async [(Text, Text, Text, Nat, Text)] {
        let usersWithKarma = Array.filter<User.User>(
            Iter.toArray(state.users.vals()),
            func(u : User.User) : Bool {
                return (u.posts.size() > 0 or u.replies.size() > 0 or u.markets.size() > 0)
            },
        );

        Array.map<User.User, (Text, Text, Text, Nat, Text)>(
            usersWithKarma,
            func(u : User.User) : (Text, Text, Text, Nat, Text) {
                var total : Nat64 = 0;
                for (market in u.markets.vals()) {
                    if (market.createdAt > 1_672_608_253_000_000_000) {
                        var subTotal : Nat64 = 0;
                        for (balance in market.balances.vals()) {
                            if (market.spent > balance and subTotal < market.spent - balance) {
                                subTotal := market.spent - balance
                            }
                        };
                        total += subTotal
                    }
                };
                total := total / 100_000_000;
                if (total > 1000) {
                    return (u.picture, u.handle, u.name, Nat64.toNat(0), "")
                } else {
                    return (u.picture, u.handle, u.name, Nat64.toNat(total) * 3 + u.posts.size() + u.replies.size(), u.discord)
                }
            },
        )
    };

    // Set users rewards.
    public query func setUsersRewards() : async () {

        // let usersWithKarma = Array.filter<User.User>(
        //     Iter.toArray(state.users.vals()),
        //     func(u : User.User) : Bool {
        //         return (u.posts.size() > 0 or u.replies.size() > 0 or u.markets.size() > 0)
        //     },
        // );

        // var totalRewards = 0;
        // for (u in usersWithKarma.vals()) {
        //     var totalSpent : Nat64 = 0;

        //     for (market in u.markets.vals()) {
        //         totalSpent += market.spent
        //     };

        //     // totalSpent := totalSpent / 100_000_000;

        //     if (totalSpent <= 100_000_000_000) {
        //         u.age := Nat64.toNat(totalSpent) * 5 + u.posts.size() + u.replies.size();
        //         totalRewards += u.age
        //     }
        // };
        // for (u in usersWithKarma.vals()) {
        //     u.age := (100 * 100 * u.age / totalRewards) / 100
        // }
    };

    // Set users rewards.
    public shared (msg) func setRewards() : async () {
        assert (msg.caller == initializer);

        let usersWithKarma = Array.filter<User.User>(
            Iter.toArray(state.users.vals()),
            func(u : User.User) : Bool {
                return (u.posts.size() > 0 or u.replies.size() > 0 or u.markets.size() > 0)
            },
        );

        var totalRewards = 0;
        for (u in usersWithKarma.vals()) {
            var totalSpent : Nat64 = 0;

            for (market in u.markets.vals()) {
                if (market.createdAt > 1_672_608_253_000_000_000) {
                    var subTotal : Nat64 = 0;
                    for (balance in market.balances.vals()) {
                        if (market.spent > balance and subTotal < market.spent - balance) {
                            subTotal := market.spent - balance
                        }
                    };
                    totalSpent += subTotal
                }
            };

            totalSpent := totalSpent / 100_000_000;

            if (totalSpent <= 1_000) {
                u.age := Nat64.toNat(totalSpent) * 3 + u.posts.size() + u.replies.size();
                totalRewards += u.age
            }
        };
        for (u in usersWithKarma.vals()) {
            u.age := (4_700_000_000 * u.age) / totalRewards;
            u.discord := "Pending"
        }
    };

    // Read total ICP.
    public query func readTotalICP() : async Nat64 {
        let realUsers = Array.filter<User.User>(
            Iter.toArray(state.users.vals()),
            func(u : User.User) : Bool {
                return u.balances.icp < 200_000_000_000
            },
        );

        var totalICP : Nat64 = 0;

        for (u in realUsers.vals()) {
            totalICP += u.balances.icp
        };

        return totalICP
    };

    // Read all users.
    public query (msg) func readAllUsers() : async [User.UserStable] {
        // assert (msg.caller == initializer);

        Array.map<(Text, User.User), User.UserStable>(
            Iter.toArray(state.users.entries()),
            func(e : (Text, User.User)) : User.UserStable {
                e.1. freeze()
            },
        )
    };

    // Find user .
    public query (msg) func findUser(addr : Text) : async [User.UserStable] {
        assert (msg.caller == initializer);
        var users = Buffer.Buffer<User.UserStable>(1);

        for (user in state.users.vals()) {
            if (user.depositICPaddr == addr) {
                users.add(user.freeze())
            }
        };

        return users.toArray()
    };

    // Backup balances.
    public query (msg) func backupBalances() : async [(Text, Text, Text, Text)] {
        Array.map<(Text, User.User), (Text, Text, Text, Text)>(
            Iter.toArray(state.users.entries()),
            func(e : (Text, User.User)) : (Text, Text, Text, Text) {
                (e.1.id, e.1.handle, e.1.twitter, e.1.depositICPaddr)
            },
        )
    };

    // Backup balances.
    public query (msg) func backupBalances2() : async [(Text, Text, Nat32, Text, Text)] {
        Array.map<(Text, User.User), (Text, Text, Nat32, Text, Text)>(
            Iter.toArray(state.users.entries()),
            func(e : (Text, User.User)) : (Text, Text, Nat32, Text, Text) {
                (e.1.id, e.1.handle, e.1.number, e.1.twitter, e.1.depositICPaddr)
            },
        )
    };

    // Backup IDs.
    public query (msg) func backupIds() : async [Text] {
        Array.map<(Text, User.User), Text>(
            Iter.toArray(state.users.entries()),
            func(e : (Text, User.User)) : Text {
                e.1.id
            },
        )
    };

    // Backup posts.
    public query (msg) func backupPosts() : async [Post.StablePost] {
        assert (msg.caller == initializer);

        Array.map<Post.Post, Post.StablePost>(
            Iter.toArray(state.posts.vals()),
            func(p : Post.Post) : Post.StablePost {
                p.freeze()
            },
        )
    };

    // Backup posts range.
    public query (msg) func backupPostsRange(from : Nat32, to : Nat32) : async [Post.StablePost] {
        assert (from <= to);

        var posts = Buffer.Buffer<Post.StablePost>(Nat32.toNat(to - from));

        for (p in state.posts.vals()) {
            if (p.id >= from and p.id < to) {
                posts.add(p.freeze())
            }
        };

        return posts.toArray()
    };

    public query (msg) func readNextPostId() : async Nat32 {
        return nextPostId
    };

    public query (msg) func readUserByPrincipal(id : Text) : async ?User.UserStable {
        let user = switch (getUser(id)) {
            case null {
                return null
            };
            case (?user) {
                user
            }
        };

        return ?user.freeze()
    };

    public query (msg) func readUserHandle(id : Text) : async ?Text {
        let user = switch (getUser(id)) {
            case null {
                return null
            };
            case (?user) {
                user
            }
        };

        return ?user.handle
    };

    public query (msg) func readUserByHandle(handle : Text) : async ?User.UserStable {
        let user = switch (state.users.get(handle)) {
            case null {
                return null
            };
            case (?user) {
                user
            }
        };
        return ?user.freeze()
    };

    public query (msg) func readUserPrincipal(handle : Text) : async ?Text {
        let user = switch (state.users.get(handle)) {
            case null {
                return null
            };
            case (?user) {
                user
            }
        };
        return ?user.id
    };

    public query (msg) func readStableState() : async State.StableState {
        assert (msg.caller == initializer);

        return stableState
    };

    public query (msg) func readState() : async State.StableState {
        assert (msg.caller == initializer);

        return state.freeze()
    };

    public shared (msg) func setUpdating(status : Bool) : () {
        assert (msg.caller == initializer);
        // Root call.
        updating := status
    };

    // Delete all users.
    public shared (msg) func deleteAllUsers() : async Bool {
        assert (msg.caller == initializer);
        // Root call.

        // state.users := Map.fromIter<Text, User.User>(
        //     ([]).vals(),
        //     0,
        //     Text.equal,
        //     Text.hash,
        // );

        // state.handles := Map.fromIter<Text, Text>(
        //     ([]).vals(),
        //     0,
        //     Text.equal,
        //     Text.hash,
        // );

        return true
    };

    // Set balance.
    public shared (msg) func setIcpBalance(principal : Text, value : Nat64) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (getUser(principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        user.lockedBalances := {
            seers = user.lockedBalances.seers;
            icp = value;
            cycles = user.lockedBalances.cycles;
            btc = user.lockedBalances.btc
        };

        return #ok
    };

    // Reset plus and minus balances.
    public shared (msg) func resetPlusAndMinusBalances(handle : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (state.users.get(handle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        user.minusBalances := {
            seers = user.minusBalances.seers;
            icp = 0;
            cycles = user.minusBalances.cycles;
            btc = user.minusBalances.btc
        };

        user.plusBalances := {
            seers = user.plusBalances.seers;
            icp = 0;
            cycles = user.plusBalances.cycles;
            btc = user.plusBalances.btc
        };

        return #ok
    };

    // Set balance.
    public shared (msg) func setIcpPlusBalance(principal : Text, value : Nat64) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (getUser(principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        user.plusBalances := {
            seers = user.balances.seers;
            icp = value;
            cycles = user.balances.cycles;
            btc = user.balances.btc
        };

        return #ok
    };

    // Set balance.
    public shared (msg) func setSeersBalance(principal : Text, value : Nat64) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (getUser(principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        user.balances := {
            seers = value;
            icp = user.balances.icp;
            cycles = user.balances.cycles;
            btc = user.balances.btc
        };

        return #ok
    };

    // Set Twitter.
    public shared (msg) func setTwitter(principal : Text, twitter : Text) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (getUser(principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        user.twitter := twitter;

        return #ok
    };

    // Set market state.
    public shared (msg) func setMarketState(
        marketId : Nat32,
        marketState : Market.MarketState,
    ) : async Bool {
        assert (msg.caller == initializer);

        switch (state.markets.get(marketId)) {
            case (null) {
                return false
            };
            case (?market) {
                market.state := marketState;
                return true
            }
        }
    };

    // Set market image.
    public shared (msg) func setMarketImage(marketId : Nat32, image : Text) : async Bool {
        assert (msg.caller == initializer);

        switch (state.markets.get(marketId)) {
            case (null) {
                return false
            };
            case (?market) {
                market.imageUrl := image;
                return true
            }
        }
    };

    // Set market end
    public shared (msg) func setMarketEnd(marketId : Nat32, end : Time.Time) : async Bool {
        assert (msg.caller == initializer);

        switch (state.markets.get(marketId)) {
            case (null) {
                return false
            };
            case (?market) {
                market.endDate := end;
                return true
            }
        }
    };

    // Set market image.
    public shared (msg) func setMarketTitle(marketId : Nat32, title : Text) : async Bool {
        assert (msg.caller == initializer);

        switch (state.markets.get(marketId)) {
            case (null) {
                return false
            };
            case (?market) {
                market.title := title;
                return true
            }
        }
    };

    public shared (msg) func resolveMarket(marketId : Nat32, option : Nat) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let marketOpt = state.markets.get(marketId);

        switch (marketOpt) {
            case null {
                return #err(#marketMissing)
            };
            case (?market) {
                assert (market.state == #closed);

                market.state := #resolved(option);

                var bettorsMap : Map.HashMap<Text, Nat64> = Map.fromIter<Text, Nat64>(
                    ([]).vals(),
                    0,
                    Text.equal,
                    Text.hash,
                );

                // Iterate over all market bettors, constructing the map.
                for (bettor in market.bettors.vals()) {
                    switch (bettorsMap.get(bettor.id)) {
                        case null {
                            bettorsMap.put(bettor.id, bettor.spent)
                        };
                        case (?spent) {
                            bettorsMap.put(bettor.id, spent + bettor.spent)
                        }
                    }
                };

                let seers = switch (state.users.get("seers")) {
                    case null {
                        return #err(#userDoesNotExist)
                    };
                    case (?seers) {
                        seers
                    }
                };

                for ((id, spent) in bettorsMap.entries()) {
                    let user = switch (getUser(id)) {
                        case null {
                            return #err(#userDoesNotExist)
                        };
                        case (?user) {
                            user
                        }
                    };

                    // Unlock balance.
                    ignore user.unlockBalance(market.collateralType, spent);

                    var reward : Nat64 = 0;

                    for (um in user.markets.vals()) {
                        if (um.marketId == market.id and um.balances[option] > 0) {
                            reward += um.balances[option]
                        }
                    };

                    if (spent > reward) {
                        let toDeduct = spent - reward;

                        ignore user.incMinusBalance(
                            market.collateralType,
                            toDeduct,
                        );
                        ignore seers.incPlusBalance(
                            market.collateralType,
                            toDeduct,
                        );

                        let payment = {
                            from = user.id;
                            to = seers.id;
                            amount = toDeduct;
                            collateralType = market.collateralType;
                            processed = false
                        };

                        state.payments.add(payment)
                    } else {
                        let toReward = reward - spent;

                        ignore seers.unlockBalance(
                            market.collateralType,
                            toReward,
                        );
                        ignore seers.incMinusBalance(
                            market.collateralType,
                            toReward,
                        );
                        ignore user.incPlusBalance(
                            market.collateralType,
                            toReward,
                        );

                        let payment = {
                            from = seers.id;
                            to = user.id;
                            amount = toReward;
                            collateralType = market.collateralType;
                            processed = false
                        };

                        state.payments.add(payment)
                    }
                };

                return #ok()
            }
        }
    };

    private func checkMarketInitData(marketInitData : Market.MarketInitData) : Result.Result<(), Errors.Error> {
        if (marketInitData.liquidity < 10) {
            return #err(#notEnoughLiquidity)
        };

        if (marketInitData.title == "") {
            return #err(#titleMissing)
        };

        if (marketInitData.description == "") {
            return #err(#descriptionMissing)
        };

        if (marketInitData.labels.size() == 0) {
            return #err(#optionsMissing)
        };

        if (marketInitData.endDate < marketInitData.startDate) {
            return #err(#endDateOld)
        };

        if (marketInitData.endDate < Time.now()) {
            return #err(#endDateOld)
        };

        return #ok(())
    };

    private func _createMarket(author : Text, initData : Market.MarketInitData, postId : Nat32) : Result.Result<Market.MarketStable, Errors.Error> {
        assert (false);

        switch (checkMarketInitData(initData)) {
            case (#err(e)) {
                return #err(e)
            };
            case (#ok(_)) { /* all good; continue */ }
        };

        let optionsLength = initData.labels.size();
        let marketId = nextMarketId;
        nextMarketId += 1;

        var newMarket = Market.Market(initData);
        newMarket.id := marketId;
        newMarket.author := author;

        // Set original post.
        let dummyData : Utils.UserData = {
            principal = "";
            handle = "";
            name = "";
            picture = ""
        };
        let initComment = {
            id = postId;
            author = dummyData;
            content = ""
        };
        let comment = Comment.Comment(initComment);

        newMarket.comments.add(comment);

        // Get provider of liquidity.
        var caller = switch (getUser(author)) {
            case (null) {
                return #err(#profileNotCreated)
            };
            case (?user) {
                user
            }
        };

        if (not caller.checkBalance(initData.collateralType, Nat64.fromNat(initData.liquidity) + 10_000)) {
            return #err(#insufficientBalance)
        };

        let seers = switch (state.users.get("seers")) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?seers) {
                seers
            }
        };

        let liquidity = Nat64.fromNat(initData.liquidity);

        ignore caller.incMinusBalance(initData.collateralType, liquidity);
        ignore seers.incPlusBalance(initData.collateralType, liquidity);

        let payment = {
            from = caller.id;
            to = seers.id;
            amount = liquidity;
            collateralType = initData.collateralType;
            processed = false
        };

        state.payments.add(payment);

        let userMarket : User.UserMarket = {
            marketId = marketId;
            title = initData.title;
            labels = initData.labels;
            balances = Array.freeze(Array.init<Nat64>(optionsLength, 0));
            collateralType = initData.collateralType;
            brierScores = [];
            shares = 0;
            spent = Nat64.fromNat(initData.liquidity);
            redeemed = false;
            author = true;
            createdAt = Time.now();
            modifiedAt = Time.now()
        };

        caller.markets.add(userMarket);
        state.markets.put(marketId, newMarket);

        return #ok(newMarket.freeze())
    };

    // Create a new AMM market.
    // public shared (msg) func createMarket(marketInitData : Market.MarketInitData) : async Result.Result<Market.MarketStable, Errors.Error> {
    //     assert (not updating);
    //     let author = Principal.toText(msg.caller);

    //     if (author == anon) {
    //         return #err(#callerIsAnon)
    //     };

    //     return _createMarket(author, marketInitData)
    // };

    // Create a new 1 to 1 bet using SimpleMarket.
    public shared (msg) func createBet(initData : SimpleMarket.InitData) : async Result.Result<SimpleMarket.SimpleMarketStable, Errors.Error> {
        assert (false);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                switch (SimpleMarket.create(user, initData)) {
                    case (#err(e)) {
                        return #err(e)
                    };
                    case (#ok(sm)) {
                        sm.id := nextBetId;
                        nextBetId += 1;
                        state.bets.put(sm.id, sm);

                        return #ok(sm.freeze())
                    }
                }
            }
        }
    };

    // Match a 1 to 1 bet.
    public shared (msg) func matchBet(betId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                switch (state.bets.get(betId)) {
                    case null {
                        return #err(#betDoesNotExist)
                    };
                    case (?bet) {
                        return bet.match(user)
                    }
                }
            }
        }
    };

    // Resolve the bet to the specified outcome.
    public shared (msg) func resolveBet(betId : Nat32, outcome : Nat) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                switch (state.bets.get(betId)) {
                    case null {
                        return #err(#betDoesNotExist)
                    };
                    case (?bet) {
                        return bet.resolve(user, outcome)
                    }
                }
            }
        }
    };

    /// Send betted amount to winner.
    public shared (msg) func redeemBet(betId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let bet = switch (state.bets.get(betId)) {
            case null {
                return #err(#betDoesNotExist)
            };
            case (?bet) {
                bet
            }
        };

        let a = switch (bet.author) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        let m = switch (bet.matcher) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        let author = switch (getUser(a.principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        let matcher = switch (getUser(m.principal)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        switch (bet.redeem(author, matcher)) {
            case (#ok(?payment)) {
                state.payments.add(payment);
                return #ok()
            };
            case (#ok(null)) {
                return #ok()
            };
            case (#err(e)) {
                return #err(e)
            }
        }
    };

    // Delete a bet.
    public shared (msg) func deleteBet(betId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                switch (state.bets.get(betId)) {
                    case null {
                        return #err(#betDoesNotExist)
                    };
                    case (?bet) {
                        switch (bet.author) {
                            case null {
                                return #err(#authorDoesNotExist)
                            };
                            case (?authorData) {
                                if (authorData.principal == caller and bet.state == #open) {
                                    ignore user.unlockBalance(
                                        bet.collateralType,
                                        bet.authorAmount,
                                    );
                                    ignore state.bets.remove(betId);
                                    return #ok()
                                } else {
                                    return #err(#canNotDelete)
                                }
                            }
                        }
                    }
                }
            }
        }
    };

    // Set a post as market comment.
    public shared (msg) func setMarketPost(marketId : Nat32, postId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);
        assert (msg.caller == initializer);

        let result = state.markets.get(marketId);
        switch (result) {
            case (?market) {
                let dummyData : Utils.UserData = {
                    principal = "";
                    handle = "";
                    name = "";
                    picture = ""
                };
                let initComment = {
                    id = postId;
                    author = dummyData;
                    content = ""
                };
                let comment = Comment.Comment(initComment);
                market.comments.add(comment)
            };
            case (null) {
                return #err(#marketMissing)
            }
        };
        return #ok
    };

    // Submit a retweet.
    public shared (msg) func submitRetweet(postId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?author) {
                switch (state.posts.get(postId)) {
                    case null {
                        #err(#postDoesNotExist)
                    };
                    case (?post) {
                        var newRetweeters = Buffer.Buffer<Utils.UserData>(post.retweeters.size());
                        var exist : Bool = false;

                        for (r in post.retweeters.vals()) {
                            if (r.principal == caller) {
                                exist := true
                            } else {
                                newRetweeters.add(r)
                            }
                        };

                        let authorData : Utils.UserData = {
                            principal = author.id;
                            handle = author.handle;
                            name = author.name;
                            picture = author.picture
                        };

                        // Remove it from user if it exist (un-retweet).
                        if (exist) {
                            var newRetweets = Buffer.Buffer<Nat32>(author.retweets.size());

                            for (r in author.retweets.vals()) {
                                if (r != postId) {
                                    newRetweets.add(r)
                                }
                            };

                            author.retweets := newRetweets
                        } else {
                            // We add it to the post and the user if it doesn't exist (retweet).
                            newRetweeters.add(authorData);
                            author.retweets.add(post.id)
                        };

                        post.retweeters := newRetweeters;
                        var retweet = post.clone();
                        retweet.isRetweet := ?authorData;

                        state.feed.add(post.id);

                        return #ok()
                    }
                }
            }
        }
    };

    private func deletePost(postId : Nat32, caller : Text) : Result.Result<(), Errors.Error> {

        switch (state.posts.get(postId)) {
            case null {
                return #err(#postDoesNotExist)
            };
            case (?post) {
                if (post.author.principal == caller) {
                    ignore state.posts.remove(postId);

                    switch (post.parent) {
                        case null {};
                        case (?parentData) {
                            switch (state.posts.get(parentData.id)) {
                                case null {};
                                case (?parent) {
                                    var newReplies = Buffer.Buffer<Nat32>(parent.replies.size());

                                    for (replyId in parent.replies.vals()) {
                                        if (replyId != postId) {
                                            newReplies.add(replyId)
                                        }
                                    };

                                    parent.replies := newReplies
                                }
                            }
                        }
                    };

                    return #ok()
                } else {
                    return #err(#onlyAuthorCanDelete)
                };

            }
        }
    };

    // Delete a post.
    public shared (msg) func submitDelete(postId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        return deletePost(postId, caller)
    };

    // Edit a post of any type.
    public shared (msg) func editPost(
        initData : Post.PostInitData,
        marketInitData : ?Market.MarketInitData,
    ) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        if (initData.content == "") {
            return #err(#postIsEmpty)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?author) {
                switch (state.posts.get(initData.id)) {
                    case null {
                        return #err(#postDoesNotExist)
                    };
                    case (?post) {
                        if (post.author.principal != caller) {
                            return #err(#onlyAuthorCanEdit)
                        };

                        post.content := initData.content;

                        return #ok()
                    }
                }
            }
        }
    };

    // Submit a post of any type.
    public shared (msg) func submitPost(
        initData : Post.PostInitData,
        marketInitData : ?Market.MarketInitData,
        betInitData : ?SimpleMarket.InitData,
    ) : async Result.Result<(), Errors.Error> {
        assert (not updating);
        assert (nextPostId < 13_000);

        assert (initData.content.size() < 600);
        assert (initData.images.size() < 2);
        assert (initData.pdfs.size() == 0);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        if (initData.content == "" and initData.image == null and initData.images.size() == 0) {
            return #err(#postIsEmpty)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?author) {
                if (author.balances.icp < 100_000_000 and author.twitter.size() == 0 and (author.posts.size() > 10 or author.replies.size() > 10)) {
                    return #err(#notEnoughBalance)
                };

                let id = nextPostId;
                nextPostId += 1;
                var isReply = false;

                let authorData : Utils.UserData = {
                    principal = author.id;
                    name = author.name;
                    handle = author.handle;
                    picture = author.picture
                };

                switch (initData.parent) {
                    case null {
                        // do nothing
                    };
                    case (?parentData) {
                        switch (state.posts.get(parentData.id)) {
                            case null {
                                return #err(#parentDoesNotExist)
                            };
                            case (?parentPost) {
                                isReply := true;
                                parentPost.replies.add(id);

                                if (parentPost.author.principal != author.id) {
                                    // Add notification to author of parent post.
                                    switch (getUser(parentPost.author.principal)) {
                                        case null {
                                            // should not happen
                                        };
                                        case (?parentAuthor) {
                                            let notificationPost : User.NotificationPost = {
                                                id;
                                                author = authorData;
                                                content = initData.content;
                                                parent = initData.parent;
                                                image = initData.image;
                                                images = initData.images;
                                                market = initData.market;
                                                simpleMarket = initData.simpleMarket;
                                                isRetweet = initData.isRetweet;
                                                createdAt = Time.now()
                                            };
                                            let newNoti : User.Notification = #v0(
                                                #reply(notificationPost)
                                            );
                                            parentAuthor.notifications.add(newNoti)
                                        }
                                    }
                                }
                            }
                        }
                    }
                };

                var newInitData : Post.PostInitData = {
                    id = id;
                    author = authorData;
                    content = initData.content;
                    parent = initData.parent;
                    image = initData.image;
                    images = initData.images;
                    pdfs = initData.pdfs;
                    verified = author.twitter.size() > 0;
                    hashtags = initData.hashtags;
                    mentions = initData.mentions;
                    market = initData.market;
                    simpleMarket = initData.simpleMarket;
                    retweet = initData.retweet;
                    isRetweet = initData.isRetweet
                };

                var post : Post.Post = Post.Post(newInitData);
                var isRetweet = false;

                // Retweet.
                switch (initData.retweet) {
                    case null {
                        // do nothing
                    };
                    case (?other) {
                        switch (state.posts.get(other.id)) {
                            case null {
                                return #err(#postDoesNotExist)
                            };
                            case (?realOther) {
                                var exist = false;
                                var newRetweeters = Buffer.Buffer<Utils.UserData>(realOther.retweeters.size());

                                for (r in realOther.retweeters.vals()) {
                                    if (r.principal == caller) {
                                        exist := true
                                    } else {
                                        newRetweeters.add(r)
                                    }
                                };
                                if (not exist) {
                                    let retweeter : Utils.UserData = authorData;
                                    newRetweeters.add(retweeter)
                                };
                                realOther.retweeters := newRetweeters
                            }
                        }
                    }
                };

                // Image.
                switch (post.image) {
                    case null {
                        // do nothing
                    };
                    case (?image) {
                        state.images.put(
                            Nat32.fromNat(state.images.size()),
                            image,
                        )
                    }
                };

                // Market.
                switch (marketInitData) {
                    case null {
                        // do nothing
                    };
                    case (?marketInitData) {
                        switch (_createMarket(caller, marketInitData, post.id)) {
                            case (#err(e)) {
                                return #err(e)
                            };
                            case (#ok(marketStable)) {
                                post.market := marketStable.id
                            }
                        }
                    }
                };

                // Bet.
                switch (betInitData) {
                    case null {
                        // do nothing
                    };
                    case (?initData) {
                        switch (SimpleMarket.create(author, initData)) {
                            case (#err(e)) {
                                return #err(e)
                            };
                            case (#ok(sm)) {
                                sm.id := nextBetId;
                                nextBetId += 1;
                                state.bets.put(sm.id, sm);
                                post.simpleMarket := sm.id
                            }
                        }
                    }
                };

                for (hashtag in post.hashtags.vals()) {
                    switch (state.hashtags.get(hashtag)) {
                        case null {
                            state.hashtags.put(hashtag, Utils.bufferFromArray([post.id]))
                        };
                        case (?postTagged) {
                            postTagged.add(post.id)
                        }
                    }
                };

                if (isReply) {
                    author.replies.add(id)
                } else {
                    author.posts.add(id)
                };

                author.lastSeenAt := Time.now();
                state.posts.put(id, post);

                // Market.
                switch (marketInitData) {
                    case null {
                        state.feed.add(id)
                    };
                    case (?marketInitData) {
                        // do nothing, skip markets from feed
                    }
                };

                return #ok()
            }
        }
    };

    public shared (msg) func fixUser() : async () {
        assert (msg.caller == initializer);

    };

    public shared (msg) func fixAvatars() : async () {
        assert (msg.caller == initializer);

        // for (user in state.users.vals()) {
        //     if (user.picture == "https://pbs.twimg.com/profile_images/1550382038569590789/OKPeY69z_400x400.jpg") {
        //         user.picture := ""
        //     }
        // };

        // for (postId in state.feed.vals()) {
        //     switch (state.posts.get(postId)) {
        //         case null {};
        //         case (?p) {
        //             if (p.author.picture == "https://pbs.twimg.com/profile_images/1550382038569590789/OKPeY69z_400x400.jpg") {
        //                 let author : Utils.UserData = {
        //                     principal = p.author.principal;
        //                     handle = p.author.handle;
        //                     name = p.author.name;
        //                     picture = ""
        //                 };
        //                 p.author := author
        //             }
        //         }
        //     }
        // }
    };

    // Submit text post with content.
    public shared (msg) func submitTextPost(initData : Post.PostInitData, content : Text) : async Result.Result<(), Errors.Error> {
        assert (false);

        for (author in state.users.vals()) {
            if (initData.author.handle == author.twitter) {
                let id = nextPostId;
                nextPostId += 1;

                let authorData : Utils.UserData = {
                    principal = author.id;
                    name = author.name;
                    handle = author.handle;
                    picture = author.picture
                };
                var newInitData : Post.PostInitData = {
                    id = id;
                    author = authorData;
                    content = initData.content;
                    parent = null;
                    image = initData.image;
                    images = [];
                    pdfs = [];
                    verified = author.twitter.size() > 0;
                    hashtags = initData.hashtags;
                    mentions = initData.mentions;
                    market = 0;
                    simpleMarket = 0;
                    retweet = null;
                    isRetweet = null
                };
                var post : Post.Post = Post.Post(newInitData);
                state.posts.put(id, post);
                author.posts.add(id);
                state.feed.add(id);

                for (hashtag in post.hashtags.vals()) {
                    switch (state.hashtags.get(hashtag)) {
                        case null {
                            state.hashtags.put(hashtag, Utils.bufferFromArray([post.id]))
                        };
                        case (?postTagged) {
                            postTagged.add(post.id)
                        }
                    }
                };

                return #ok()
            }
        };

        return #err(#userDoesNotExist)
    };

    // Submit text post with content.
    public shared (msg) func submitTextPost2(initData : Post.PostInitData, content : Text) : async Result.Result<Nat32, Errors.Error> {
        assert (false);

        for (author in state.users.vals()) {
            if (initData.author.handle == author.twitter) {
                let id = nextPostId;
                nextPostId += 1;

                let authorData : Utils.UserData = {
                    principal = author.id;
                    name = author.name;
                    handle = author.handle;
                    picture = author.picture
                };
                let parentData : ?Post.ParentData = if (initData.market != 0) {
                    ?{
                        id = initData.market;
                        author = authorData
                    }
                } else { null };
                var newInitData : Post.PostInitData = {
                    id = id;
                    author = authorData;
                    content = initData.content;
                    parent = parentData;
                    image = initData.image;
                    images = [];
                    pdfs = [];
                    verified = author.twitter.size() > 0;
                    hashtags = initData.hashtags;
                    mentions = initData.mentions;
                    market = 0;
                    simpleMarket = 0;
                    retweet = null;
                    isRetweet = null
                };
                var post : Post.Post = Post.Post(newInitData);
                state.posts.put(id, post);
                author.posts.add(id);
                state.feed.add(id);

                for (hashtag in post.hashtags.vals()) {
                    switch (state.hashtags.get(hashtag)) {
                        case null {
                            state.hashtags.put(hashtag, Utils.bufferFromArray([post.id]))
                        };
                        case (?postTagged) {
                            postTagged.add(post.id)
                        }
                    }
                };

                return #ok(post.id)
            }
        };

        return #err(#userDoesNotExist)
    };

    // Verify user with content.
    public shared (msg) func setTwitterWithContent(seersHandle : Text, twitterHandle : Text, code : Text, content : Text) : async Result.Result<(), Errors.Error> {
        assert (false);
        assert (seersHandle.size() > 0 and twitterHandle.size() > 0 and code.size() >= 5);
        let user = switch (state.users.get(seersHandle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };

        if (Text.startsWith(user.id, #text(code)) and user.twitter == "") {
            user.twitter := twitterHandle
        };

        return #ok
    };

    // Process hashtags.
    public shared (msg) func makeHashTags() : async Result.Result<(), Errors.Error> {
        // for ((postId, post) in state.posts.entries()) {
        //     for (hashtag in post.hashtags.vals()) {
        //         switch (state.hashtags.get(hashtag)) {
        //             case null {
        //                 state.hashtags.put(hashtag, Utils.bufferFromArray([postId]))
        //             };
        //             case (?postTagged) {
        //                 postTagged.add(postId)
        //             }
        //         }
        //     }
        // };

        return #ok()
    };

    // Get hashtags.
    public query (msg) func getHashTags() : async Result.Result<[(Text, [Nat32])], Errors.Error> {
        let hashtags = Array.map<(Text, Buffer.Buffer<Nat32>), (Text, [Nat32])>(
            Iter.toArray(state.hashtags.entries()),
            func(e : (Text, Buffer.Buffer<Nat32>)) : (Text, [Nat32]) {
                (e.0, e.1. toArray())
            },
        );
        return #ok(hashtags)
    };

    // Get queue revenue.
    public query (msg) func getRevenue() : async Result.Result<Nat64, Errors.Error> {
        var total : Nat64 = 100_000_000_000;

        let idToSkip = "dy6u5-nzakf-jbqi5-q4ewu-aupx7-hiiln-azodf-7icqt-d5hd3-6qnyr-fae";
        let seersId = "5pp4x-rpcih-2ts3h-hg77o-3tvnj-bzmqf-ezuac-327uw-fl63x-y72qg-vae";

        for (payment in state.payments.vals()) {
            if (payment.from != idToSkip and payment.to != idToSkip) {
                if (payment.from == seersId) {
                    total -= payment.amount
                } else {
                    total += payment.amount
                }
            }
        };

        return #ok(total)
    };

    // Get posts by hashtag.
    public query (msg) func getPostsByTag(hashtag : Text) : async Result.Result<[Nat32], Errors.Error> {
        switch (state.hashtags.get(hashtag)) {
            case null {
                return #ok([])
            };
            case (?postIds) {
                return #ok(postIds.toArray())
            }
        }
    };

    // Get full posts by hashtag.
    public query (msg) func getFullPostsByTag(hashtag : Text) : async Result.Result<[Post.StablePost], Errors.Error> {
        switch (state.hashtags.get(hashtag)) {
            case null {
                return #ok([])
            };
            case (?postIds) {
                let posts = Utils.bufferFromArray<Post.StablePost>([]);

                for (postId in postIds.vals()) {
                    switch (state.posts.get(postId)) {
                        case null {};
                        case (?post) {
                            posts.add(post.freeze())
                        }
                    }
                };

                return #ok(posts.toArray())
            }
        }
    };

    // Check if the user have notifications.
    public query (msg) func haveNotifications() : async Bool {
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return false
        };

        let user = switch (getUser(caller)) {
            case null { return false };
            case (?user) { user }
        };

        return user.notifications.size() != user.notificationsSeen
    };

    // Update notifications index.
    public shared (msg) func updateNotifications() : async Result.Result<(), Errors.Error> {
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        let user = switch (getUser(caller)) {
            case null { return #err(#userDoesNotExist) };
            case (?user) { user }
        };

        user.notificationsSeen := user.notifications.size();

        return #ok()
    };

    // Read notifications of an user with this principal.
    public query (msg) func readNotifications() : async Result.Result<[User.Notification], Errors.Error> {
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        let user = switch (getUser(caller)) {
            case null { return #err(#userDoesNotExist) };
            case (?user) { user }
        };

        return #ok(user.notifications.toArray())
    };

    // Submit a like.
    public shared (msg) func submitLike(postId : Nat32) : async Result.Result<(), Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#notLoggedIn)
        };

        switch (getUser(caller)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                switch (state.posts.get(postId)) {
                    case null {
                        return #err(#postDoesNotExist)
                    };
                    case (?post) {
                        var newLikes = Buffer.Buffer<Like.Like>(post.likes.size());
                        var found : Bool = false;

                        for (like in post.likes.vals()) {
                            if (like.author.principal != caller) {
                                newLikes.add(like)
                            } else {
                                // Unlike case, we remove.
                                found := true
                            }
                        };

                        if (not found) {
                            let userData : Utils.UserData = {
                                principal = user.id;
                                name = user.name;
                                handle = user.handle;
                                picture = user.picture
                            };
                            let newLike : Like.Like = {
                                author = userData;
                                createdAt = Time.now()
                            };
                            newLikes.add(newLike)
                        };

                        post.likes := newLikes;
                        user.lastSeenAt := Time.now();

                        return #ok()
                    }
                }
            }
        }
    };

    // Read a market.
    public query func readMarket(marketId : Nat32) : async ?Market.MarketStable {
        let result = state.markets.get(marketId);
        return Option.map(
            result,
            func(m : Market.Market) : Market.MarketStable {
                return m.freeze()
            },
        )
    };

    // Read a post.
    public query func getPost(postId : Nat32) : async Result.Result<Post.StablePost, Errors.Error> {
        switch (state.posts.get(postId)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?post) {
                return #ok(post.freeze())
            }
        }
    };

    // Read the thread.
    public query func getThread(postId : Nat32) : async Result.Result<Post.ThreadStable, Errors.Error> {
        switch (_getFullPost(postId)) {
            case (null, _, _) {
                return #err(#postDoesNotExist)
            };
            case (?post, market, simpleMarket) {
                let postReplies = Post.getReplies(post);
                var replies = Buffer.Buffer<Post.FullPost>(postReplies.size());

                for (replyId in postReplies.vals()) {
                    switch (_getFullPost(replyId)) {
                        case (null, _, _) {
                            // Reply missing, continue.
                        };
                        case (?p, m, sm) {
                            replies.add((p, m, sm))
                        }
                    }
                };

                var exit = false;
                var ancestors = Buffer.Buffer<Post.FullPost>(0);
                var current = post;

                while (not exit) {
                    switch (Post.getParent(current)) {
                        case null {
                            exit := true
                        };
                        case (?parent) {
                            switch (_getFullPost(parent.id)) {
                                case (null, _, _) {
                                    // This case shouldn't happen, on delete we leave a dummy.
                                    exit := true
                                };
                                case (?p, m, sm) {
                                    ancestors.add((p, m, sm));
                                    current := p
                                }
                            }
                        }
                    }
                };

                let t : Post.ThreadStable = {
                    ancestors = ancestors.toArray();
                    main = (post, market, simpleMarket);
                    replies = replies.toArray()
                };

                return #ok(t)
            }
        }
    };

    // Read all markets.
    public query func readAllMarkets(
        category : Market.MarketCategory,
        marketState : Market.MarketState,
    ) : async [Market.MarketStable] {
        return Array.mapFilter<(Nat32, Market.Market), Market.MarketStable>(
            Iter.toArray(state.markets.entries()),
            func(e : (Nat32, Market.Market)) : ?Market.MarketStable {
                if (
                    (category == #any or e.1. category == category) and (marketState == #any or e.1. state == marketState or e.1. state == #closed)
                ) {
                    return ?e.1. freeze()
                };
                return null
            },
        )
    };

    // Read all markets states.
    public query func readMarketsState() : async [(Nat32, Text, Market.MarketState, [Nat])] {
        var response = Buffer.Buffer<(Nat32, Text, Market.MarketState, [Nat])>(state.markets.size());

        for (m in state.markets.vals()) {
            response.add((m.id, m.title, m.state, m.probabilities))
        };

        return response.toArray()
    };

    // Read FIFA markets.
    public query func readFIFAMarkets() : async [Market.MarketStable] {
        return Array.mapFilter<(Nat32, Market.Market), Market.MarketStable>(
            Iter.toArray(state.markets.entries()),
            func(e : (Nat32, Market.Market)) : ?Market.MarketStable {
                if (e.1.id == 49 or e.1.id == 50) {
                    return ?e.1.freeze()
                };
                return null
            },
        )
    };

    // Read all bets.
    public query func readAllBets() : async [SimpleMarket.SimpleMarketStable] {
        return Array.map<SimpleMarket.SimpleMarket, SimpleMarket.SimpleMarketStable>(
            Iter.toArray(state.bets.vals()),
            func(m : SimpleMarket.SimpleMarket) : SimpleMarket.SimpleMarketStable {
                return m.freeze()
            },
        )
    };

    public shared (msg) func refreshUser() : async Result.Result<User.UserStable, Errors.Error> {
        assert (not updating);
        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        switch (getUser(caller)) {
            case (null) {
                return #err(#profileNotCreated)
            };
            case (?user) {
                user.expBalances := {
                    seers = user.balances.seers;
                    icp = user.balances.icp;
                    cycles = user.balances.cycles;
                    btc = user.balances.btc
                };

                // Query the ledger to update ICP balance.
                let canister = Principal.toText(Principal.fromActor(this));
                let a : Text = Account.toText(Account.makeAccountIdentifier(user.depositAddrs.icp, canister));
                switch (await accountBalance(a)) {
                    case null {
                        return #err(#cantGetBalance)
                    };
                    case (?balance) {
                        user.balances := {
                            seers = user.balances.seers;
                            icp = balance.e8s;
                            cycles = user.balances.cycles;
                            btc = user.balances.btc
                        }
                    }
                };
                return #ok(user.freeze())
            }
        }
    };

    // Delete a market.
    public shared (msg) func deleteMarket(marketId : Nat32) : async () {
        assert (msg.caller == initializer);
        // Unlock liquidity.
        ignore state.markets.remove(marketId)
    };

    // Unlock user funds.
    public shared (msg) func unlockFunds(
        handle : Text,
        collateralType : Tokens.CollateralType,
        amount : Nat64,
    ) : async Result.Result<(), Errors.Error> {
        assert (msg.caller == initializer);

        let user = switch (state.users.get(handle)) {
            case null {
                return #err(#userDoesNotExist)
            };
            case (?user) {
                user
            }
        };
        ignore user.unlockBalance(collateralType, amount);
        return #ok()
    };

    // Delete all markets.
    public shared (msg) func deleteAllMarkets() : async () {
        assert (msg.caller == initializer);

        state.markets := Map.HashMap<Nat32, Market.Market>(
            0,
            Nat32.equal,
            func(x : Nat32) : Nat32 { x },
        )
    };

    public shared (msg) func claimReward() : async Result.Result<Nat64, Errors.Error> {
        assert (not updating);

        let caller = Principal.toText(msg.caller);

        var user = switch (getUser(caller)) {
            case (null) {
                return #err(#profileNotCreated)
            };
            case (?user) {
                user
            }
        };

        user.lastSeenAt := Time.now();

        // Limit reward to less than 20 ICP.
        assert (user.age < 2_000_000_000 and user.age > 100_000);

        if (user.discord == "Pending") {
            switch (state.users.get("seers")) {
                case null {
                    return #err(#userDoesNotExist)
                };
                case (?fromUser) {
                    let amount = Nat64.fromNat(user.age);

                    if (fromUser.checkBalance(#icp, amount - 10_000)) {
                        fromUser.balances := {
                            icp = fromUser.balances.icp - amount - 10_000;
                            seers = fromUser.balances.seers;
                            btc = fromUser.balances.btc;
                            cycles = fromUser.balances.cycles
                        };
                        switch (await transfer(fromUser.depositAddrs.icp, user.depositAddrs.icp, amount)) {
                            case (#err(e)) {
                                user.discord := "Error";
                                return #err(e)
                            };
                            case (#ok()) {
                                user.discord := "Claimed";
                                let newTx : Tx.MarketTx = {
                                    id = Nat32.fromNat(user.txs.size());
                                    marketId = 0; // System ID
                                    src = null; // Karma
                                    dest = null; // ICP
                                    sent = 0; // Spent
                                    recv = amount; // ICP received
                                    price = 0; // For free
                                    fee = 0; // No fee
                                    collateralType = #icp;
                                    createdAt = Time.now()
                                };
                                user.txs.add(newTx);

                                return #ok(amount)
                            }
                        }
                    } else {
                        return #err(#notEnoughBalance)
                    }
                }
            }
        };

        return #ok(0)
    };

    public shared (msg) func buyOutcome(
        marketId : Nat32,
        value : Nat64,
        selected : Nat,
        save : Bool,
    ) : async Result.Result<Nat64, Errors.Error> {
        assert (false);

        assert (not updating);

        let caller = Principal.toText(msg.caller);

        if (value == 0) {
            return #err(#lowerThanMinAmount)
        };

        let marketOpt = state.markets.get(marketId);

        switch (marketOpt) {
            case null {
                return #err(#marketMissing)
            };
            case (?market) {
                if (market.state != #open) {
                    return #err(#marketNotOpen)
                };

                if (market.startDate > Time.now()) {
                    return #err(#marketNotOpen)
                };

                if (market.endDate < Time.now()) {
                    market.state := #closed;
                    return #err(#marketNotOpen)
                };

                let optionsSize = market.reserves.size();
                var semiK : Nat = 1;

                for (i in Iter.range(0, optionsSize - 1)) {
                    if (i != selected) {
                        semiK := semiK * (market.reserves[i] + Nat64.toNat(value))
                    }
                };

                let newSelectedReserve : Nat = market.k / semiK;
                // TODO FIX
                let tokensOut = market.reserves[selected] - newSelectedReserve + Nat64.toNat(value);

                if (not save) {
                    // Dry run.
                    return #ok(Nat64.fromNat(tokensOut))
                };

                if (caller == anon) {
                    return #err(#callerIsAnon)
                };

                var user = switch (getUser(caller)) {
                    case (null) {
                        return #err(#profileNotCreated)
                    };
                    case (?user) {
                        user
                    }
                };

                // Check enough balance.
                if (save and not user.checkBalance(market.collateralType, value + 10_000)) {
                    return #err(#notEnoughBalance)
                };

                let zero : Nat = 0;
                var newReserves : [var Nat] = Array.init(optionsSize, zero);
                let newLiquidity = market.liquidity - Nat64.toNat(value);

                for (i in Iter.range(0, optionsSize - 1)) {
                    if (i != selected) {
                        newReserves[i] := market.reserves[i] + Nat64.toNat(value)
                    } else {
                        newReserves[i] := newSelectedReserve
                    }
                };

                market.reserves := Array.freeze(newReserves);
                market.liquidity := newLiquidity;
                market.volume := market.volume + Nat64.toNat(value);

                let one : Nat = 1;
                let weight : [var Nat] = Array.init(optionsSize, one);
                let probabilities : [var Nat] = Array.init(optionsSize, zero);
                var weightSum : Nat = 0;

                for (i in Iter.range(0, optionsSize - 1)) {
                    for (j in Iter.range(0, optionsSize - 1)) {
                        if (i != j) {
                            weight[i] := weight[i] * market.reserves[j]
                        }
                    };
                    weightSum := weightSum + weight[i]
                };

                for (i in Iter.range(0, optionsSize - 1)) {
                    probabilities[i] := (weight[i] * 10_000) / weightSum
                };

                market.probabilities := Array.freeze(probabilities);
                let histPoint : Market.HistPoint = {
                    probabilities = market.probabilities;
                    liquidity = market.liquidity;
                    createdAt = Time.now()
                };
                market.histPrices.add(histPoint);

                var markets = user.markets.toArray();
                let marketTokensOpt = Array.find<User.UserMarket>(
                    markets,
                    func(ut : User.UserMarket) : Bool {
                        ut.marketId == market.id
                    },
                );

                switch (marketTokensOpt) {
                    case null {
                        let zero : Nat64 = 0;
                        let balances : [var Nat64] = Array.init(
                            optionsSize,
                            zero,
                        );
                        balances[selected] := Nat64.fromNat(tokensOut);

                        let newUserMarket : User.UserMarket = {
                            author = (market.author == caller);
                            balances = Array.freeze(balances);
                            brierScores = [];
                            collateralType = market.collateralType;
                            createdAt = Time.now();
                            modifiedAt = Time.now();
                            redeemed = false;
                            marketId = market.id;
                            title = market.title;
                            labels = market.labels;
                            shares = 0;
                            spent = value
                        };
                        user.markets.add(newUserMarket)
                    };
                    case (?marketTokens) {
                        user.markets := Utils.bufferFromArray(Array.mapFilter(markets, func(ut : User.UserMarket) : ?User.UserMarket { if (ut.marketId != market.id) { return ?ut } else { let newBalances = Array.mapEntries(ut.balances, func(b : Nat64, i : Nat) : Nat64 { if (i == selected) { return b + Nat64.fromNat(tokensOut) } else { return b } }); let newUserMarket : User.UserMarket = { author = ut.author; balances = newBalances; brierScores = ut.brierScores; collateralType = ut.collateralType; createdAt = ut.createdAt; labels = market.labels; marketId = market.id; modifiedAt = Time.now(); redeemed = false; shares = ut.shares; spent = ut.spent + value; title = market.title }; return ?newUserMarket } }))
                    }
                };

                ignore user.lockBalance(market.collateralType, value);

                let newTx : Tx.MarketTx = {
                    id = Nat32.fromNat(user.txs.size());
                    marketId = market.id;
                    src = null;
                    dest = ?selected;
                    sent = value;
                    recv = Nat64.fromNat(tokensOut);
                    price = value / Nat64.fromNat(tokensOut);
                    fee = 0;
                    collateralType = market.collateralType;
                    createdAt = Time.now()
                };
                user.txs.add(newTx);
                user.lastSeenAt := Time.now();

                let bettor : Market.Bettor = {
                    id = user.id;
                    spent = value;
                    outcome = selected
                };
                market.bettors.add(bettor);

                return #ok(Nat64.fromNat(tokensOut))
            }
        }
    };

    // Get user data.
    public query func getUserStable(userId : Text) : async ?User.UserStable {
        return Option.map(
            getUser(userId),
            func(u : User.User) : User.UserStable {
                return u.freeze()
            },
        )
    };
    public query func getHandles() : async [(Text, Text)] {
        Iter.toArray(state.handles.entries())
    };

    public query func getUsers() : async [(Text, User.UserStable)] {
        Array.map<(Text, User.User), (Text, User.UserStable)>(
            Iter.toArray(state.users.entries()),
            func(e : (Text, User.User)) : (Text, User.UserStable) {
                return (e.0, e.1. freeze())
            },
        )
    };

    // Get user with posts.
    public query func getUserWithPosts(handle : Text) : async Result.Result<(User.UserStable, [Post.FullPost]), Errors.Error> {
        switch (state.users.get(handle)) {
            case null {
                return #err(#profileNotCreated)
            };
            case (?user) {
                var posts = Buffer.Buffer<Post.FullPost>(user.posts.size());

                for (postId in user.posts.vals()) {
                    switch (_getFullPost(postId)) {
                        case (null, _, _) {
                            // Shouldn't happen, but it doesn't matter.
                        };
                        case (?post, m, sm) {
                            posts.add((post, m, sm))
                        }
                    }
                };

                return #ok((user.freeze(), posts.toArray()))
            }
        }
    };

    // Get users from their principals.
    public query func getUsersFromPrincipals(ids : [Text]) : async Result.Result<[User.UserStable], Errors.Error> {
        var users = Buffer.Buffer<User.UserStable>(ids.size());
        for (id in ids.vals()) {
            switch (getUser(id)) {
                case null {
                    // Skip, shouldn't be too important.
                };
                case (?user) {
                    users.add(user.freeze())
                }
            }
        };
        return #ok(users.toArray())
    };

    // Get user with posts from principal.
    public query func getUserFromPrincipal(principal : Text) : async Result.Result<(User.UserStable, [Post.FullPost]), Errors.Error> {
        switch (state.handles.get(principal)) {
            case null {
                return #err(#profileNotCreated)
            };
            case (?handle) {
                switch (state.users.get(handle)) {
                    case null {
                        return #err(#profileNotCreated)
                    };
                    case (?user) {
                        var posts = Buffer.Buffer<Post.FullPost>(0);

                        for (postId in user.posts.vals()) {
                            switch (_getFullPost(postId)) {
                                case (null, _, _) {
                                    // Shouldn't happen, but it doesn't matter.
                                };
                                case (?post, m, sm) {
                                    posts.add((post, m, sm))
                                }
                            }
                        };

                        return #ok((user.freeze(), posts.toArray()))
                    }
                }
            }
        }
    };

    private func _getFullPost(postId : Nat32) : (
        ?Post.StablePost,
        ?Market.MarketStable,
        ?SimpleMarket.SimpleMarketStable,
    ) {
        var post : ?Post.StablePost = null;
        var market : ?Market.MarketStable = null;
        var bet : ?SimpleMarket.SimpleMarketStable = null;

        switch (state.posts.get(postId)) {
            case null {};
            case (?p) {
                post := ?p.freeze();
                switch (state.markets.get(p.market)) {
                    case null {};
                    case (?m) {
                        market := ?m.freeze()
                    }
                };
                switch (state.bets.get(p.simpleMarket)) {
                    case null {};
                    case (?b) {
                        bet := ?b.freeze()
                    }
                }
            }
        };

        return (post, market, bet)
    };

    // Get feed.
    public query (msg) func getFeed() : async [(Post.StablePost, ?Market.MarketStable, ?SimpleMarket.SimpleMarketStable)] {
        var posts = Buffer.Buffer<(Post.StablePost, ?Market.MarketStable, ?SimpleMarket.SimpleMarketStable)>(state.feed.size());
        let feedSize = state.feed.size();
        var postAdded = 0;
        let maxPosts = 300;

        if (feedSize > maxPosts) {
            let start = feedSize - maxPosts;
            for (i in Iter.range(start, feedSize - 1)) {
                let postId = state.feed.get(i);
                switch (_getFullPost(postId)) {
                    case (null, _, _) {};
                    case (?p, m, sm) {
                        posts.add((p, m, sm))
                    }
                }
            }
        } else {
            for (postId in state.feed.vals()) {
                switch (_getFullPost(postId)) {
                    case (null, _, _) {};
                    case (?p, m, sm) {
                        posts.add((p, m, sm))
                    }
                }
            }
        };

        return posts.toArray()
    };

    // Create anon user.
    public shared (msg) func createAnonUser() : async Result.Result<(User.UserStable, [Post.PostStable]), Errors.Error> {
        assert (not updating);
        assert (nextUserId < 4_000);

        let caller = Principal.toText(msg.caller);

        if (caller == anon) {
            return #err(#callerIsAnon)
        };

        let number = nextUserId;
        nextUserId += 1;
        let anonName = "Anon" # debug_show (number);
        let canister = Principal.toText(Principal.fromActor(this));
        let initData : User.UserInitData = {
            id = caller;
            handle = anonName;
            name = anonName;
            age = 0;
            city = "";
            picture = "";
            cover = "https://cdn.thenewstack.io/media/2022/02/aec396cd-screenshot-2022-02-04-at-2.56.57-pm.png";
            twitter = "";
            discord = "";
            bio = "Anon " # debug_show (number);
            website = "";
            number = number;
            canister = canister
        };
        switch (_createUser(initData)) {
            case (#err(e)) {
                return #err(e)
            };
            case (#ok(user)) {
                return #ok((user.freeze(), []))
            }
        }
    };

    // Edit user.
    public shared (msg) func editUser(initData : User.UserInitData) : async Result.Result<User.UserStable, Errors.Error> {
        assert (not updating);

        assert (initData.picture.size() < 200);
        assert (initData.cover.size() < 200);
        assert (initData.handle.size() < 200);
        assert (initData.name.size() < 200);
        assert (initData.bio.size() < 300);

        let caller = Principal.toText(msg.caller);

        if (caller == anon or caller != initData.id) {
            return #err(#callerIsAnon)
        };

        switch (_editUser(initData)) {
            case (#err(e)) {
                return #err(e)
            };
            case (#ok(user)) {
                return #ok(user.freeze())
            }
        }
    };

    // Add a comment to a market.
    public shared (msg) func addCommentToMarket(
        marketId : Nat32,
        content : Text,
    ) : async Result.Result<Comment.CommentStable, Errors.Error> {
        assert (not updating);

        let userId = Principal.toText(msg.caller);

        if (userId == anon) {
            return #err(#callerIsAnon)
        };

        if (content == "") {
            return #err(#commentIsEmpty)
        };

        let userOpt = getUser(userId);

        switch (userOpt) {
            case null {
                return #err(#profileNotCreated)
            };
            case (?user) {
                let marketOpt = state.markets.get(marketId);

                switch (marketOpt) {
                    case null {
                        return #err(#marketMissing)
                    };
                    case (?market) {
                        let userData : Utils.UserData = {
                            principal = user.id;
                            handle = user.handle;
                            name = user.name;
                            picture = user.picture
                        };
                        let initData : Comment.CommentInitData = {
                            id = Nat32.fromNat(market.comments.size());
                            author = userData;
                            content = content
                        };
                        let comment : Comment.Comment = Comment.Comment(initData);
                        market.comments.add(comment);

                        return #ok(comment.freeze())
                    }
                }
            }
        }
    };

    private func getUser(userId : Text) : ?User.User {
        switch (state.handles.get(userId)) {
            case null {
                return null
            };
            case (?handle) {
                return state.users.get(handle)
            }
        }
    };

    private func _editUser(initData : User.UserInitData) : Result.Result<User.User, Errors.Error> {
        switch (getUser(initData.id)) {
            case null {
                // Inconsistency.
                return #err(#userDoesNotExist)
            };
            case (?oldUser) {

                // Check new handle is ok.
                switch (state.users.get(initData.handle)) {
                    case null {
                        // Great, the handle does not exist, we can continue.
                    };
                    case (_) {
                        if (initData.handle != oldUser.handle) {
                            // Bad, the handle is taken and is not the same as before.
                            return #err(#handleAlreadyTaken)
                        }
                    }
                };

                if (initData.handle != oldUser.handle) {
                    ignore state.users.remove(oldUser.handle)
                };

                oldUser.handle := initData.handle;
                oldUser.name := initData.name;
                oldUser.picture := initData.picture;
                oldUser.cover := initData.cover;
                oldUser.bio := initData.bio;
                oldUser.modifiedAt := Time.now();

                let userData : Utils.UserData = {
                    principal = oldUser.id;
                    name = oldUser.name;
                    handle = oldUser.handle;
                    picture = oldUser.picture
                };

                state.handles.put(oldUser.id, oldUser.handle);
                state.users.put(oldUser.handle, oldUser);

                return #ok(oldUser)
            }
        }
    };

    private func _createUser(initData : User.UserInitData) : Result.Result<User.User, Errors.Error> {
        switch (state.handles.get(initData.id)) {
            case (null) {
                switch (state.users.get(initData.handle)) {
                    case null {
                        var user : User.User = User.User(initData);

                        let userData : Utils.UserData = {
                            principal = user.id;
                            name = user.name;
                            handle = user.handle;
                            picture = user.picture
                        };

                        state.users.put(user.handle, user);
                        state.handles.put(user.id, user.handle);

                        return #ok(user)
                    };
                    case (_) {
                        return #err(#handleAlreadyTaken)
                    }
                }
            };
            case (?userHandle) {
                return #err(#userAlreadyExist)
            }
        }
    }
}
