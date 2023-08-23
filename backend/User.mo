import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Map "mo:base/HashMap";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";

import Errors "Errors";
import Utils "Utils";
import Forecast "Forecast";
import Tx "Tx";
import Tokens "Tokens";
import Comment "Comment";
import Account "Account";
import Like "Like";

module {
    public type ParentData = {
        id : Nat32;
        author : Utils.UserData
    };

    public type NotificationPost = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        images : [Text];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time
    };

    public type NotificationType0 = {
        #reply : NotificationPost;

        // #like : (Nat32, Text, Text, Text, Text);
        // #mention : (Nat32, Text, Text, Text, Text, Text);
        // #repost : (Nat32, Text, Text, Text, Text);
        // #newFollower : (Text, Text, Text, Text);

        // #likedMention : (Nat32, Text, Text, Text, Text);
        // #repostedMention : (Nat32, Text, Text, Text, Text)
    };

    public type Notification = {
        #v0 : NotificationType0
    };
    public type Follower = {
        user : Text;
        createdAt : Time.Time
    };

    public type Followee = {
        user : Text;
        createdAt : Time.Time
    };

    public type Follower0 = {
        userdata : Utils.UserData;
        createdAt : Time.Time
    };

    public type Followee0 = {
        userdata : Utils.UserData;
        createdAt : Time.Time
    };

    public type FollowerStable = {
        #v0 : Follower0
    };

    public type FolloweeStable = {
        #v0 : Followee0
    };

    public type Payment = {
        from : Text;
        to : Text;
        amount : Nat64;
        processed : Bool;
        collateralType : Tokens.CollateralType
    };

    public type UserInitData = {
        id : Text;
        handle : Text;
        name : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        number : Nat32;
        canister : Text
    };

    public type Balance = {
        seers : Nat64;
        icp : Nat64;
        cycles : Nat64;
        btc : Nat64
    };

    public type DepositAddrs = {
        icp : Account.Subaccount;
        cycles : Text;
        btc : Text
    };

    public type UserMarket = {
        marketId : Nat32;
        title : Text;
        labels : [Text];
        balances : [Nat64];
        collateralType : Tokens.CollateralType;
        brierScores : [Forecast.BrierScore];
        shares : Nat64;
        spent : Nat64;
        redeemed : Bool;
        author : Bool;
        createdAt : Time.Time;
        modifiedAt : Time.Time
    };

    public class User(initData : UserInitData) = this {
        public var id : Text = initData.id;
        public var handle : Text = initData.handle;
        public var name : Text = initData.name;
        public var picture : Text = initData.picture;
        public var cover : Text = initData.cover;
        public var website : Text = initData.website;
        public var city : Text = initData.city;
        public var age : Nat = initData.age;
        public var twitter : Text = initData.twitter;
        public var discord : Text = initData.discord;
        public var bio : Text = initData.bio;
        public var number : Nat32 = initData.number;
        public var canister : Text = initData.canister;

        public var balances : Balance = {
            // Mirror of real balance.
            seers = 0;
            icp = 0;
            cycles = 0;
            btc = 0
        };
        public var plusBalances : Balance = {
            // To pay from treasury.
            seers = 0;
            icp = 0;
            cycles = 0;
            btc = 0
        };
        public var lockedBalances : Balance = {
            // Locked.
            seers = 0;
            icp = 0;
            cycles = 0;
            btc = 0
        };
        public var minusBalances : Balance = {
            // To send to treasury.
            seers = 0;
            icp = 0;
            cycles = 0;
            btc = 0
        };
        public var expBalances : Balance = {
            // Balances multiplied by probabilities.
            seers = 100_000_000_000;
            icp = 0;
            cycles = 0;
            btc = 0
        };
        public var depositAddrs : DepositAddrs = {
            icp = Account.makeSubAccount(initData.number);
            cycles = "";
            btc = "";
            seers = ""
        };
        public var depositICPaddr : Text = Account.toText(Account.makeAccountIdentifier(depositAddrs.icp, initData.canister));
        public var markets : Buffer.Buffer<UserMarket> = Buffer.Buffer<UserMarket>(5);
        public var txs : Buffer.Buffer<Tx.MarketTx> = Buffer.Buffer<Tx.MarketTx>(5);
        public var forecasts : Buffer.Buffer<Forecast.Forecast> = Buffer.Buffer<Forecast.Forecast>(5);
        public var comments : Buffer.Buffer<Comment.Comment> = Buffer.Buffer<Comment.Comment>(5);

        public var posts : Buffer.Buffer<Nat32> = Buffer.Buffer<Nat32>(0);
        public var replies : Buffer.Buffer<Nat32> = Buffer.Buffer<Nat32>(0);
        public var likes : Buffer.Buffer<Nat32> = Buffer.Buffer<Nat32>(0);
        public var retweets : Buffer.Buffer<Nat32> = Buffer.Buffer<Nat32>(0);

        public var followers : Buffer.Buffer<FollowerStable> = Buffer.Buffer<FollowerStable>(5);
        public var followees : Buffer.Buffer<FolloweeStable> = Buffer.Buffer<FolloweeStable>(5);

        public var notifications = Buffer.Buffer<Notification>(0);
        public var notificationsSeen : Nat = 0;

        public var createdAt : Time.Time = Time.now();
        public var lastSeenAt : Time.Time = Time.now();
        public var modifiedAt : Time.Time = Time.now();

        public func checkBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Bool {
            switch (collateralType) {
                case (#seers) {
                    return (balances.seers >= amount + minusBalances.seers + lockedBalances.seers)
                };
                case (#icp) {
                    return (balances.icp >= amount + minusBalances.icp + lockedBalances.icp)
                };
                case (#cycles) {
                    return (balances.cycles >= amount + minusBalances.cycles + lockedBalances.cycles)
                };
                case (#btc) {
                    return (balances.btc >= amount + minusBalances.btc + lockedBalances.btc)
                }
            }
        };

        public func getFinalBalances() : Balance {
            let finalBalances : Balance = {
                seers = balances.seers + plusBalances.seers - minusBalances.seers - lockedBalances.seers;
                icp = balances.icp + plusBalances.icp - minusBalances.icp - lockedBalances.icp;
                cycles = balances.cycles + plusBalances.cycles - minusBalances.cycles - lockedBalances.cycles;
                btc = balances.btc + plusBalances.btc - minusBalances.btc - lockedBalances.btc
            };
            return finalBalances
        };

        public func incPlusBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    let newBalance : Balance = {
                        icp = plusBalances.icp;
                        seers = plusBalances.seers + amount;
                        cycles = plusBalances.cycles;
                        btc = plusBalances.btc
                    };
                    plusBalances := newBalance;
                    return #ok()
                };
                case (#icp) {
                    let newBalance : Balance = {
                        icp = plusBalances.icp + amount;
                        seers = plusBalances.seers;
                        cycles = plusBalances.cycles;
                        btc = plusBalances.btc
                    };
                    plusBalances := newBalance;
                    return #ok()
                };
                case (#cycles) {
                    let newBalance : Balance = {
                        icp = plusBalances.icp;
                        seers = plusBalances.seers;
                        cycles = plusBalances.cycles + amount;
                        btc = plusBalances.btc
                    };
                    plusBalances := newBalance;
                    return #ok()
                };
                case (#btc) {
                    let newBalance : Balance = {
                        icp = plusBalances.icp;
                        seers = plusBalances.seers;
                        cycles = plusBalances.cycles;
                        btc = plusBalances.btc + amount
                    };
                    plusBalances := newBalance;
                    return #ok()
                }
            };

        };

        public func decPlusBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    if (plusBalances.seers >= amount) {
                        let newBalance : Balance = {
                            icp = plusBalances.icp;
                            seers = plusBalances.seers - amount;
                            cycles = plusBalances.cycles;
                            btc = plusBalances.btc
                        };
                        plusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#icp) {
                    if (plusBalances.icp >= amount) {
                        let newBalance : Balance = {
                            icp = plusBalances.icp - amount;
                            seers = plusBalances.seers;
                            cycles = plusBalances.cycles;
                            btc = plusBalances.btc
                        };
                        plusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#cycles) {
                    if (plusBalances.cycles >= amount) {
                        let newBalance : Balance = {
                            icp = plusBalances.icp;
                            seers = plusBalances.seers;
                            cycles = plusBalances.cycles - amount;
                            btc = plusBalances.btc
                        };
                        plusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#btc) {
                    if (plusBalances.btc >= amount) {
                        let newBalance : Balance = {
                            icp = plusBalances.icp;
                            seers = plusBalances.seers;
                            cycles = plusBalances.cycles;
                            btc = plusBalances.btc - amount
                        };
                        plusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                }
            }
        };

        public func incMinusBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    let newBalance : Balance = {
                        icp = minusBalances.icp;
                        seers = minusBalances.seers + amount;
                        cycles = minusBalances.cycles;
                        btc = minusBalances.btc
                    };
                    minusBalances := newBalance;
                    return #ok()
                };
                case (#icp) {
                    let newBalance : Balance = {
                        icp = minusBalances.icp + amount;
                        seers = minusBalances.seers;
                        cycles = minusBalances.cycles;
                        btc = minusBalances.btc
                    };
                    minusBalances := newBalance;
                    return #ok()
                };
                case (#cycles) {
                    let newBalance : Balance = {
                        icp = minusBalances.icp;
                        seers = minusBalances.seers;
                        cycles = minusBalances.cycles + amount;
                        btc = minusBalances.btc
                    };
                    minusBalances := newBalance;
                    return #ok()
                };
                case (#btc) {
                    let newBalance : Balance = {
                        icp = minusBalances.icp;
                        seers = minusBalances.seers;
                        cycles = minusBalances.cycles;
                        btc = minusBalances.btc + amount
                    };
                    minusBalances := newBalance;
                    return #ok()
                }
            }
        };

        public func decMinusBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    if (minusBalances.seers >= amount) {
                        let newBalance : Balance = {
                            icp = minusBalances.icp;
                            seers = minusBalances.seers - amount;
                            cycles = minusBalances.cycles;
                            btc = minusBalances.btc
                        };
                        minusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#icp) {
                    if (minusBalances.icp >= amount) {
                        let newBalance : Balance = {
                            icp = minusBalances.icp - amount;
                            seers = minusBalances.seers;
                            cycles = minusBalances.cycles;
                            btc = minusBalances.btc
                        };
                        minusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#cycles) {
                    if (minusBalances.cycles >= amount) {
                        let newBalance : Balance = {
                            icp = minusBalances.icp;
                            seers = minusBalances.seers;
                            cycles = minusBalances.cycles - amount;
                            btc = minusBalances.btc
                        };
                        minusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#btc) {
                    if (minusBalances.btc >= amount) {
                        let newBalance : Balance = {
                            icp = minusBalances.icp;
                            seers = minusBalances.seers;
                            cycles = minusBalances.cycles;
                            btc = minusBalances.btc - amount
                        };
                        minusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                }
            }
        };

        public func lockBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    let newBalance : Balance = {
                        icp = lockedBalances.icp;
                        seers = lockedBalances.seers + amount;
                        cycles = lockedBalances.cycles;
                        btc = lockedBalances.btc
                    };
                    lockedBalances := newBalance;
                    return #ok()
                };
                case (#icp) {
                    let newBalance : Balance = {
                        icp = lockedBalances.icp + amount;
                        seers = lockedBalances.seers;
                        cycles = lockedBalances.cycles;
                        btc = lockedBalances.btc
                    };
                    lockedBalances := newBalance;
                    return #ok()
                };
                case (#cycles) {
                    let newBalance : Balance = {
                        icp = lockedBalances.icp;
                        seers = lockedBalances.seers;
                        cycles = lockedBalances.cycles + amount;
                        btc = lockedBalances.btc
                    };
                    lockedBalances := newBalance;
                    return #ok()
                };
                case (#btc) {
                    let newBalance : Balance = {
                        icp = lockedBalances.icp;
                        seers = lockedBalances.seers;
                        cycles = lockedBalances.cycles;
                        btc = lockedBalances.btc + amount
                    };
                    lockedBalances := newBalance;
                    return #ok()
                }
            }
        };

        public func unlockBalance(
            collateralType : Tokens.CollateralType,
            amount : Nat64,
        ) : Result.Result<(), Errors.Error> {
            switch (collateralType) {
                case (#seers) {
                    if (lockedBalances.seers >= amount) {
                        let newBalance : Balance = {
                            icp = lockedBalances.icp;
                            seers = lockedBalances.seers - amount;
                            cycles = lockedBalances.cycles;
                            btc = lockedBalances.btc
                        };
                        lockedBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#icp) {
                    if (lockedBalances.icp >= amount) {
                        let newBalance : Balance = {
                            icp = lockedBalances.icp - amount;
                            seers = lockedBalances.seers;
                            cycles = lockedBalances.cycles;
                            btc = lockedBalances.btc
                        };
                        lockedBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#cycles) {
                    if (lockedBalances.cycles >= amount) {
                        let newBalance : Balance = {
                            icp = lockedBalances.icp;
                            seers = lockedBalances.seers;
                            cycles = lockedBalances.cycles - amount;
                            btc = lockedBalances.btc
                        };
                        minusBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                };
                case (#btc) {
                    if (lockedBalances.btc >= amount) {
                        let newBalance : Balance = {
                            icp = lockedBalances.icp;
                            seers = lockedBalances.seers;
                            cycles = lockedBalances.cycles;
                            btc = lockedBalances.btc - amount
                        };
                        lockedBalances := newBalance;
                        return #ok()
                    };
                    return #err(#notEnoughBalance)
                }
            }
        };

        public func freeze() : UserStable {
            let stableComments = Array.map(
                comments.toArray(),
                func(c : Comment.Comment) : Comment.CommentStable {
                    c.freeze()
                },
            );
            let us : UserStable4 = {
                id = id;
                name = name;
                handle = handle;
                city = city;
                age = age;
                picture = picture;
                cover = cover;
                website = website;
                twitter = twitter;
                discord = discord;
                bio = bio;
                number = number;
                canister = canister;
                balances = balances;
                lockedBalances = lockedBalances;
                plusBalances = plusBalances;
                minusBalances = minusBalances;
                expBalances = expBalances;
                depositICPaddr = depositICPaddr;
                depositAddrs = depositAddrs;
                markets = markets.toArray();
                txs = txs.toArray();
                comments = stableComments;

                posts = posts.toArray();
                replies = replies.toArray();
                retweets = retweets.toArray();
                likes = likes.toArray();

                followers = followers.toArray();
                followees = followees.toArray();

                notifications = notifications.toArray();
                notificationsSeen = notificationsSeen;

                createdAt = createdAt;
                lastSeenAt = lastSeenAt;
                modifiedAt = modifiedAt
            };
            return #v4(us)
        };

        public func privateFreeze() : UserStable {
            let stableComments = Array.map(
                comments.toArray(),
                func(c : Comment.Comment) : Comment.CommentStable {
                    c.freeze()
                },
            );
            let us : UserStable4 = {
                id = "";
                name = name;
                handle = handle;
                city = "";
                age = posts.size() + replies.size();
                picture = picture;
                cover = cover;
                website = website;
                twitter = twitter;
                discord = discord;
                bio = bio;
                number = number;
                canister = canister;
                balances = {
                    seers = 0;
                    icp = 0;
                    btc = 0;
                    cycles = 0
                };
                lockedBalances = {
                    seers = 0;
                    icp = 0;
                    btc = 0;
                    cycles = 0
                };
                plusBalances = {
                    seers = 0;
                    icp = 0;
                    btc = 0;
                    cycles = 0
                };
                minusBalances = {
                    seers = 0;
                    icp = 0;
                    btc = 0;
                    cycles = 0
                };
                expBalances = {
                    seers = 0;
                    icp = 0;
                    btc = 0;
                    cycles = 0
                };
                depositICPaddr = "";
                depositAddrs = {
                    btc = "";
                    cycles = "";
                    icp = ""
                };
                markets = [];
                txs = [];
                comments = stableComments;

                posts = [];
                replies = [];
                retweets = [];
                likes = [];

                followers = [];
                followees = [];

                notifications = [];
                notificationsSeen = notificationsSeen;

                createdAt = createdAt;
                lastSeenAt = lastSeenAt;
                modifiedAt = modifiedAt
            };
            return #v4(us)
        }
    };

    private type UserStable0 = {
        id : Text;
        name : Text;
        handle : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        balances : Balance;
        plusBalances : Balance;
        minusBalances : Balance;
        expBalances : Balance;
        depositICPaddr : Text;
        depositAddrs : DepositAddrs;
        markets : [UserMarket];
        txs : [Tx.MarketTx];
        comments : [Comment.CommentStable];
        posts : [Nat32];
        replies : [Nat32];
        retweets : [Nat32];
        likes : [Nat32];
        followers : [Follower];
        followees : [Followee];
        createdAt : Time.Time;
        lastSeenAt : Time.Time;
        modifiedAt : Time.Time;
        number : Nat32;
        canister : Text
    };

    private type UserStable1 = {
        id : Text;
        name : Text;
        handle : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        number : Nat32;
        canister : Text;
        balances : Balance;
        plusBalances : Balance;
        minusBalances : Balance;
        expBalances : Balance;
        depositICPaddr : Text;
        depositAddrs : DepositAddrs;
        markets : [UserMarket];
        txs : [Tx.MarketTx];
        comments : [Comment.CommentStable];
        posts : [Nat32];
        replies : [Nat32];
        retweets : [Nat32];
        likes : [Nat32];
        followers : [Follower];
        followees : [Followee];
        createdAt : Time.Time;
        lastSeenAt : Time.Time;
        modifiedAt : Time.Time
    };

    private type UserStable2 = {
        id : Text;
        name : Text;
        handle : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        number : Nat32;
        canister : Text;
        balances : Balance;
        lockedBalances : Balance;
        plusBalances : Balance;
        minusBalances : Balance;
        expBalances : Balance;
        depositICPaddr : Text;
        depositAddrs : DepositAddrs;
        markets : [UserMarket];
        txs : [Tx.MarketTx];
        comments : [Comment.CommentStable];
        posts : [Nat32];
        replies : [Nat32];
        retweets : [Nat32];
        likes : [Nat32];
        followers : [Follower];
        followees : [Followee];
        createdAt : Time.Time;
        lastSeenAt : Time.Time;
        modifiedAt : Time.Time
    };

    private type UserStable3 = {
        id : Text;
        name : Text;
        handle : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        number : Nat32;
        canister : Text;
        balances : Balance;
        lockedBalances : Balance;
        plusBalances : Balance;
        minusBalances : Balance;
        expBalances : Balance;
        depositICPaddr : Text;
        depositAddrs : DepositAddrs;
        markets : [UserMarket];
        txs : [Tx.MarketTx];
        comments : [Comment.CommentStable];
        posts : [Nat32];
        replies : [Nat32];
        retweets : [Nat32];
        likes : [Nat32];
        followers : [Follower];
        followees : [Followee];
        notifications : [Notification];
        notificationsSeen : Nat;
        createdAt : Time.Time;
        lastSeenAt : Time.Time;
        modifiedAt : Time.Time
    };

    private type UserStable4 = {
        id : Text;
        name : Text;
        handle : Text;
        age : Nat;
        city : Text;
        picture : Text;
        cover : Text;
        twitter : Text;
        discord : Text;
        bio : Text;
        website : Text;
        number : Nat32;
        canister : Text;
        balances : Balance;
        lockedBalances : Balance;
        plusBalances : Balance;
        minusBalances : Balance;
        expBalances : Balance;
        depositICPaddr : Text;
        depositAddrs : DepositAddrs;
        markets : [UserMarket];
        txs : [Tx.MarketTx];
        comments : [Comment.CommentStable];
        posts : [Nat32];
        replies : [Nat32];
        retweets : [Nat32];
        likes : [Nat32];
        followers : [FollowerStable];
        followees : [FolloweeStable];
        notifications : [Notification];
        notificationsSeen : Nat;
        createdAt : Time.Time;
        lastSeenAt : Time.Time;
        modifiedAt : Time.Time
    };

    public type UserStable = {
        #v0 : UserStable0;
        #v1 : UserStable1;
        #v2 : UserStable2;
        #v3 : UserStable3;
        #v4 : UserStable4
    };

    public func unFreeze(u : UserStable) : User {
        switch (u) {
            case (#v0(u)) {
                let initData : UserInitData = {
                    id = u.id;
                    name = u.name;
                    handle = u.handle;
                    age = u.age;
                    city = u.city;
                    picture = u.picture;
                    cover = u.cover;
                    twitter = u.twitter;
                    discord = u.discord;
                    bio = u.bio;
                    website = u.website;
                    canister = u.canister;
                    number = u.number
                };
                let comments = Array.map(
                    u.comments,
                    func(c : Comment.CommentStable) : Comment.Comment {
                        Comment.unFreeze(c)
                    },
                );
                var user : User = User(initData);

                user.posts := Utils.bufferFromArray(u.posts);
                user.replies := Utils.bufferFromArray(u.replies);
                user.retweets := Utils.bufferFromArray(u.retweets);
                user.likes := Utils.bufferFromArray(u.likes);

                user.balances := u.balances;
                user.lockedBalances := u.minusBalances;
                user.plusBalances := u.plusBalances;
                user.minusBalances := u.minusBalances;
                user.expBalances := u.expBalances;
                user.depositICPaddr := u.depositICPaddr;
                user.depositAddrs := u.depositAddrs;
                user.markets := Utils.bufferFromArray(u.markets);
                user.txs := Utils.bufferFromArray(u.txs);
                user.comments := Utils.bufferFromArray(comments);
                user.followers := Utils.bufferFromArray([]);
                user.followees := Utils.bufferFromArray([]);

                user.notifications := Utils.bufferFromArray([]);
                user.notificationsSeen := 0;

                user.createdAt := u.createdAt;
                user.lastSeenAt := u.lastSeenAt;
                user.modifiedAt := u.modifiedAt;

                return user
            };
            case (#v1(u)) {
                let initData : UserInitData = {
                    id = u.id;
                    name = u.name;
                    handle = u.handle;
                    age = u.age;
                    city = u.city;
                    picture = u.picture;
                    cover = u.cover;
                    twitter = u.twitter;
                    discord = u.discord;
                    bio = u.bio;
                    website = u.website;
                    number = u.number;
                    canister = u.canister
                };
                let comments = Array.map(
                    u.comments,
                    func(c : Comment.CommentStable) : Comment.Comment {
                        Comment.unFreeze(c)
                    },
                );
                var user : User = User(initData);

                user.posts := Utils.bufferFromArray(u.posts);
                user.replies := Utils.bufferFromArray(u.replies);
                user.retweets := Utils.bufferFromArray(u.retweets);
                user.likes := Utils.bufferFromArray(u.likes);

                user.balances := u.balances;
                user.lockedBalances := u.minusBalances;
                user.plusBalances := u.plusBalances;
                user.minusBalances := u.minusBalances;
                user.expBalances := u.expBalances;
                user.depositICPaddr := u.depositICPaddr;
                user.depositAddrs := u.depositAddrs;
                user.markets := Utils.bufferFromArray(u.markets);
                user.txs := Utils.bufferFromArray(u.txs);
                user.comments := Utils.bufferFromArray(comments);
                user.followers := Utils.bufferFromArray([]);
                user.followees := Utils.bufferFromArray([]);

                user.notifications := Utils.bufferFromArray([]);
                user.notificationsSeen := 0;

                user.createdAt := u.createdAt;
                user.lastSeenAt := u.lastSeenAt;
                user.modifiedAt := u.modifiedAt;

                return user
            };
            case (#v2(u)) {
                let initData : UserInitData = {
                    id = u.id;
                    name = u.name;
                    handle = u.handle;
                    age = u.age;
                    city = u.city;
                    picture = u.picture;
                    cover = u.cover;
                    twitter = u.twitter;
                    discord = u.discord;
                    bio = u.bio;
                    website = u.website;
                    number = u.number;
                    canister = u.canister
                };
                let comments = Array.map(
                    u.comments,
                    func(c : Comment.CommentStable) : Comment.Comment {
                        Comment.unFreeze(c)
                    },
                );
                var user : User = User(initData);

                user.posts := Utils.bufferFromArray(u.posts);
                user.replies := Utils.bufferFromArray(u.replies);
                user.retweets := Utils.bufferFromArray(u.retweets);
                user.likes := Utils.bufferFromArray(u.likes);

                user.balances := u.balances;
                user.lockedBalances := u.lockedBalances;
                user.plusBalances := u.plusBalances;
                user.minusBalances := u.minusBalances;
                user.expBalances := u.expBalances;
                user.depositICPaddr := u.depositICPaddr;
                user.depositAddrs := u.depositAddrs;
                user.markets := Utils.bufferFromArray(u.markets);
                user.txs := Utils.bufferFromArray(u.txs);
                user.comments := Utils.bufferFromArray(comments);
                user.followers := Utils.bufferFromArray([]);
                user.followees := Utils.bufferFromArray([]);

                user.notifications := Utils.bufferFromArray([]);
                user.notificationsSeen := 0;

                user.createdAt := u.createdAt;
                user.lastSeenAt := u.lastSeenAt;
                user.modifiedAt := u.modifiedAt;

                return user
            };
            case (#v3(u)) {
                let initData : UserInitData = {
                    id = u.id;
                    name = u.name;
                    handle = u.handle;
                    age = u.age;
                    city = u.city;
                    picture = u.picture;
                    cover = u.cover;
                    twitter = u.twitter;
                    discord = u.discord;
                    bio = u.bio;
                    website = u.website;
                    number = u.number;
                    canister = u.canister
                };
                let comments = Array.map(
                    u.comments,
                    func(c : Comment.CommentStable) : Comment.Comment {
                        Comment.unFreeze(c)
                    },
                );
                var user : User = User(initData);

                user.posts := Utils.bufferFromArray(u.posts);
                user.replies := Utils.bufferFromArray(u.replies);
                user.retweets := Utils.bufferFromArray(u.retweets);
                user.likes := Utils.bufferFromArray(u.likes);

                user.balances := u.balances;
                user.lockedBalances := u.lockedBalances;
                user.plusBalances := u.plusBalances;
                user.minusBalances := u.minusBalances;
                user.expBalances := u.expBalances;
                user.depositICPaddr := u.depositICPaddr;
                user.depositAddrs := u.depositAddrs;
                user.markets := Utils.bufferFromArray(u.markets);
                user.txs := Utils.bufferFromArray(u.txs);
                user.comments := Utils.bufferFromArray(comments);
                user.followers := Utils.bufferFromArray([]);
                user.followees := Utils.bufferFromArray([]);

                user.notifications := Utils.bufferFromArray(u.notifications);
                user.notificationsSeen := u.notificationsSeen;

                user.createdAt := u.createdAt;
                user.lastSeenAt := u.lastSeenAt;
                user.modifiedAt := u.modifiedAt;

                return user
            };
            case (#v4(u)) {
                let initData : UserInitData = {
                    id = u.id;
                    name = u.name;
                    handle = u.handle;
                    age = u.age;
                    city = u.city;
                    picture = u.picture;
                    cover = u.cover;
                    twitter = u.twitter;
                    discord = u.discord;
                    bio = u.bio;
                    website = u.website;
                    number = u.number;
                    canister = u.canister
                };
                let comments = Array.map(
                    u.comments,
                    func(c : Comment.CommentStable) : Comment.Comment {
                        Comment.unFreeze(c)
                    },
                );
                var user : User = User(initData);

                user.posts := Utils.bufferFromArray(u.posts);
                user.replies := Utils.bufferFromArray(u.replies);
                user.retweets := Utils.bufferFromArray(u.retweets);
                user.likes := Utils.bufferFromArray(u.likes);

                user.balances := u.balances;
                user.lockedBalances := u.lockedBalances;
                user.plusBalances := u.plusBalances;
                user.minusBalances := u.minusBalances;
                user.expBalances := u.expBalances;
                user.depositICPaddr := u.depositICPaddr;
                user.depositAddrs := u.depositAddrs;
                user.markets := Utils.bufferFromArray(u.markets);
                user.txs := Utils.bufferFromArray(u.txs);
                user.comments := Utils.bufferFromArray(comments);
                user.followers := Utils.bufferFromArray(u.followers);
                user.followees := Utils.bufferFromArray(u.followees);

                user.notifications := Utils.bufferFromArray(u.notifications);
                user.notificationsSeen := u.notificationsSeen;

                user.createdAt := u.createdAt;
                user.lastSeenAt := u.lastSeenAt;
                user.modifiedAt := u.modifiedAt;

                return user
            }
        }
    }
}
