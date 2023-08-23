import Map "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Hash "mo:base/Hash";

import Utils "Utils";
import User "User";
import Post "Post";
import Market "Market";
import SimpleMarket "SimpleMarket";
import FileTypes "./file-upload/types";
import Types "./exchange-rate/Types";

module {
    private type StableState0 = {
        users : [(Text, User.UserStable)];
        handles : [(Text, Text)];
        posts : [(Nat32, Post.PostStable)];
        bets : [(Nat32, SimpleMarket.SimpleMarketStable)];
        markets : [(Nat32, Market.MarketStable)];
        images : [(Nat32, Text)];
        feed : [Nat32];
        payments : [User.Payment]
    };

    private type StableState1 = {
        users : [(Text, User.UserStable)];
        handles : [(Text, Text)];
        posts : [(Nat32, Post.PostStable)];
        postsv : [(Nat32, Post.StablePost)];
        bets : [(Nat32, SimpleMarket.SimpleMarketStable)];
        markets : [(Nat32, Market.MarketStable)];
        images : [(Nat32, Text)];
        feed : [Nat32];
        payments : [User.Payment];
        chunks : [(Nat, FileTypes.Chunk)];
        assets : [(Text, FileTypes.Asset)];
        hashtags : [(Text, [Nat32])]
    };

    public type StableState = {
        #v0 : StableState0;
        #v1 : StableState1
    };

    public func migrate(stableState : StableState) : StableState {
        return stableState
    };

    public class State(stableState : StableState) = this {
        public var fetched = Map.HashMap<Types.Timestamp, Types.Rate>(
            10,
            func(t1 : Types.Timestamp, t2 : Types.Timestamp) : Bool {
                t1 == t2
            },
            func(t : Types.Timestamp) : Hash.Hash {
                Text.hash(Nat64.toText(t))
            },
        );

        public var chunks : Map.HashMap<Nat, FileTypes.Chunk> = do {
            let chunksIter = getChunks(stableState).vals();

            Map.fromIter<Nat, FileTypes.Chunk>(
                chunksIter,
                50,
                Nat.equal,
                func(x : Nat) : Nat32 { Nat32.fromNat(x) },
            )
        };
        public var assets : Map.HashMap<Text, FileTypes.Asset> = do {
            let assetsIter = getAssets(stableState).vals();

            Map.fromIter<Text, FileTypes.Asset>(
                assetsIter,
                50,
                Text.equal,
                Text.hash,
            )
        };
        public var users : Map.HashMap<Text, User.User> = do {
            let usersIter = Iter.map<(Text, User.UserStable), (Text, User.User)>(
                getUsers(stableState).vals(),
                func(e : (Text, User.UserStable)) : (Text, User.User) {
                    let v = User.unFreeze(e.1);
                    return (e.0, v)
                },
            );

            Map.fromIter<Text, User.User>(
                usersIter,
                50,
                Text.equal,
                Text.hash,
            )
        };
        public var handles : Map.HashMap<Text, Text> = do {
            Map.fromIter<Text, Text>(
                getHandles(stableState).vals(),
                10,
                Text.equal,
                Text.hash,
            )
        };
        public var posts : Map.HashMap<Nat32, Post.Post> = do {
            let postIter = Iter.map<(Nat32, Post.StablePost), (Nat32, Post.Post)>(
                getPosts(stableState).vals(),
                func(e : (Nat32, Post.StablePost)) : (Nat32, Post.Post) {
                    let v = Post.unFreeze(e.1);
                    return (e.0, v)
                },
            );

            Map.fromIter<Nat32, Post.Post>(
                postIter,
                10,
                Nat32.equal,
                func(x : Nat32) : Nat32 { x },
            )
        };
        public var bets : Map.HashMap<Nat32, SimpleMarket.SimpleMarket> = do {
            let marketIter = Iter.map<(Nat32, SimpleMarket.SimpleMarketStable), (Nat32, SimpleMarket.SimpleMarket)>(
                getBets(stableState).vals(),
                func(e : (Nat32, SimpleMarket.SimpleMarketStable)) : (
                    Nat32,
                    SimpleMarket.SimpleMarket,
                ) {
                    let v = SimpleMarket.unFreeze(e.1);
                    return (e.0, v)
                },
            );

            Map.fromIter<Nat32, SimpleMarket.SimpleMarket>(
                marketIter,
                10,
                Nat32.equal,
                func(x : Nat32) : Nat32 { x },
            )
        };
        public var markets : Map.HashMap<Nat32, Market.Market> = do {
            let marketIter = Iter.map<(Nat32, Market.MarketStable), (Nat32, Market.Market)>(
                getMarkets(stableState).vals(),
                func(e : (Nat32, Market.MarketStable)) : (Nat32, Market.Market) {
                    let v = Market.unFreeze(e.1);
                    return (e.0, v)
                },
            );

            Map.fromIter<Nat32, Market.Market>(
                marketIter,
                10,
                Nat32.equal,
                func(x : Nat32) : Nat32 { x },
            )
        };
        public var images : Map.HashMap<Nat32, Text> = do {
            let imageIter = Iter.map<(Nat32, Text), (Nat32, Text)>(
                getImages(stableState).vals(),
                func(e : (Nat32, Text)) : (Nat32, Text) {
                    return e
                },
            );

            Map.fromIter<Nat32, Text>(
                imageIter,
                10,
                Nat32.equal,
                func(x : Nat32) : Nat32 { x },
            )
        };
        public var feed : Buffer.Buffer<Nat32> = Utils.bufferFromArray(getFeed(stableState));
        public var payments : Buffer.Buffer<User.Payment> = Utils.bufferFromArray(getPayments(stableState));

        public var hashtags : Map.HashMap<Text, Buffer.Buffer<Nat32>> = do {
            let tagsIter = Iter.map<(Text, [Nat32]), (Text, Buffer.Buffer<Nat32>)>(
                getHashTags(stableState).vals(),
                func(e : (Text, [Nat32])) : (Text, Buffer.Buffer<Nat32>) {
                    return (e.0, Utils.bufferFromArray(e.1))
                },
            );

            Map.fromIter<Text, Buffer.Buffer<Nat32>>(
                tagsIter,
                10,
                Text.equal,
                Text.hash,
            )
        };

        public func freeze() : StableState {
            let s : StableState1 = {
                chunks = Iter.toArray(chunks.entries());
                assets = Iter.toArray(assets.entries());
                users = Array.map<(Text, User.User), (Text, User.UserStable)>(
                    Iter.toArray(users.entries()),
                    func(e : (Text, User.User)) : (Text, User.UserStable) {
                        (e.0, e.1. freeze())
                    },
                );
                hashtags = Array.map<(Text, Buffer.Buffer<Nat32>), (Text, [Nat32])>(
                    Iter.toArray(hashtags.entries()),
                    func(e : (Text, Buffer.Buffer<Nat32>)) : (Text, [Nat32]) {
                        (e.0, e.1. toArray())
                    },
                );
                handles = Iter.toArray(handles.entries());
                posts = [];
                postsv = Array.map<(Nat32, Post.Post), (Nat32, Post.StablePost)>(
                    Iter.toArray(posts.entries()),
                    func(e : (Nat32, Post.Post)) : (Nat32, Post.StablePost) {
                        (e.0, e.1. freeze())
                    },
                );
                bets = Array.map<(Nat32, SimpleMarket.SimpleMarket), (Nat32, SimpleMarket.SimpleMarketStable)>(
                    Iter.toArray(bets.entries()),
                    func(e : (Nat32, SimpleMarket.SimpleMarket)) : (
                        Nat32,
                        SimpleMarket.SimpleMarketStable,
                    ) { (e.0, e.1. freeze()) },
                );
                markets = Array.map<(Nat32, Market.Market), (Nat32, Market.MarketStable)>(
                    Iter.toArray(markets.entries()),
                    func(e : (Nat32, Market.Market)) : (
                        Nat32,
                        Market.MarketStable,
                    ) { (e.0, e.1. freeze()) },
                );
                images = Iter.toArray(images.entries());
                feed = feed.toArray();
                payments = payments.toArray()
            };

            let stableState : StableState = #v1(s);

            return stableState
        }
    };

    public func getUsers(state : StableState) : [(Text, User.UserStable)] {
        switch (state) {
            case (#v0(s)) {
                return s.users
            };
            case (#v1(s)) {
                return s.users
            }
        }
    };

    public func getFeed(state : StableState) : [Nat32] {
        switch (state) {
            case (#v0(s)) {
                return s.feed
            };
            case (#v1(s)) {
                return s.feed
            }
        }
    };

    public func getMarkets(state : StableState) : [(Nat32, Market.MarketStable)] {
        switch (state) {
            case (#v0(s)) {
                return s.markets
            };
            case (#v1(s)) {
                return s.markets
            }
        }
    };

    public func getBets(state : StableState) : [(Nat32, SimpleMarket.SimpleMarketStable)] {
        switch (state) {
            case (#v0(s)) {
                return s.bets
            };
            case (#v1(s)) {
                return s.bets
            }
        }
    };

    public func getPosts(state : StableState) : [(Nat32, Post.StablePost)] {
        switch (state) {
            case (#v0(s)) {
                let postsIter = Iter.map<(Nat32, Post.PostStable), (Nat32, Post.StablePost)>(
                    s.posts.vals(),
                    func(p : (Nat32, Post.PostStable)) : (
                        Nat32,
                        Post.StablePost,
                    ) {
                        let postStable0 : Post.PostStable0 = p.1;
                        return (p.0, #v0(postStable0))
                    },
                );
                return Iter.toArray(postsIter)
            };
            case (#v1(s)) {
                return s.postsv
            }
        }
    };

    public func getImages(state : StableState) : [(Nat32, Text)] {
        switch (state) {
            case (#v0(s)) {
                return s.images
            };
            case (#v1(s)) {
                return s.images
            }
        }
    };

    public func getHandles(state : StableState) : [(Text, Text)] {
        switch (state) {
            case (#v0(s)) {
                return s.handles
            };
            case (#v1(s)) {
                return s.handles
            }
        }
    };

    public func getPayments(state : StableState) : [User.Payment] {
        switch (state) {
            case (#v0(s)) {
                return s.payments
            };
            case (#v1(s)) {
                return s.payments
            }
        }
    };

    public func getChunks(state : StableState) : [(Nat, FileTypes.Chunk)] {
        switch (state) {
            case (#v0(_)) {
                return []
            };
            case (#v1(s)) {
                return s.chunks
            }
        }
    };

    public func getAssets(state : StableState) : [(Text, FileTypes.Asset)] {
        switch (state) {
            case (#v0(_)) {
                return []
            };
            case (#v1(s)) {
                return s.assets
            }
        }
    };

    public func getHashTags(state : StableState) : [(Text, [Nat32])] {
        switch (state) {
            case (#v0(s)) {
                return []
            };
            case (#v1(s)) {
                return s.hashtags
            }
        }
    };

}
