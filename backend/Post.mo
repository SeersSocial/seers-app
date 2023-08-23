import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Option "mo:base/Option";

import Like "Like";
import Utils "Utils";
import Market "Market";
import SimpleMarket "SimpleMarket";

module {

    public type ParentData = {
        id : Nat32;
        author : Utils.UserData
    };

    public type PostInitData = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        images : [Text];
        pdfs : [Text];
        hashtags : [Text];
        mentions : [Text];
        isRetweet : ?Utils.UserData;
        verified : Bool
    };

    public type FullPost = (
        StablePost,
        ?Market.MarketStable,
        ?SimpleMarket.SimpleMarketStable,
    );

    public type ThreadStable = {
        ancestors : [FullPost];
        main : FullPost;
        replies : [FullPost]
    };

    public class Post(initData : PostInitData) = this {
        public var id : Nat32 = initData.id;
        public var author : Utils.UserData = initData.author;
        public var content : Text = initData.content;

        public var parent : ?ParentData = initData.parent;
        public var retweet : ?Retweet = initData.retweet;
        public var market : Nat32 = 0;
        public var simpleMarket : Nat32 = 0;
        public var image : ?Text = initData.image;
        public var images : [Text] = initData.images;
        public var pdfs : [Text] = initData.pdfs;
        public var verified : Bool = initData.verified;
        public var hashtags : [Text] = initData.hashtags;
        public var mentions : [Text] = initData.mentions;

        public var likes : Buffer.Buffer<Like.Like> = Buffer.Buffer<Like.Like>(0);
        public var replies : Buffer.Buffer<Nat32> = Buffer.Buffer<Nat32>(0);
        public var retweeters : Buffer.Buffer<Utils.UserData> = Buffer.Buffer<Utils.UserData>(0);

        public var isRetweet : ?Utils.UserData = initData.isRetweet;

        public var createdAt : Time.Time = Time.now();
        public var deleted : Bool = false;

        public func freeze() : StablePost {
            let ps : PostStable3 = {
                id = id;
                author = author;
                content = content;
                parent = parent;
                replies = replies.toArray();
                retweeters = retweeters.toArray();
                retweet = retweet;
                simpleMarket = simpleMarket;
                market = market;
                image = image;
                images = images;
                pdfs = pdfs;
                verified = verified;
                mentions = mentions;
                hashtags = hashtags;
                likes = likes.toArray();
                isRetweet = isRetweet;
                createdAt = createdAt;
                deleted = deleted
            };

            return #v3(ps)
        };

        public func privateFreeze() : StablePost {
            let ps : PostStable3 = {
                id = id;
                author = {
                    principal = "";
                    handle = author.handle;
                    name = author.name;
                    picture = author.picture
                };
                content = content;
                parent = Option.map<ParentData, ParentData>(
                    parent,
                    func(pd : ParentData) : ParentData {
                        {
                            id = pd.id;
                            author = {
                                principal = "";
                                handle = pd.author.handle;
                                name = pd.author.name;
                                picture = pd.author.picture
                            }
                        }
                    },
                );
                replies = replies.toArray();
                retweeters = [];
                retweet = retweet;
                simpleMarket = simpleMarket;
                market = market;
                image = image;
                images = images;
                pdfs = pdfs;
                verified = verified;
                mentions = Array.map<Like.Like, Text>(
                    likes.toArray(),
                    func(like : Like.Like) : Text {
                        return like.author.handle
                    },
                );
                hashtags = [];
                likes = [];
                isRetweet = isRetweet;
                createdAt = createdAt;
                deleted = deleted
            };

            return #v3(ps)
        };

        public func clone() : Post {
            let c : PostInitData = {
                id = id;
                author = author;
                content = content;
                parent = parent;
                retweet = retweet;
                market = market;
                simpleMarket = simpleMarket;
                image = image;
                images = images;
                pdfs = pdfs;
                verified = verified;
                hashtags = hashtags;
                mentions = mentions;
                isRetweet = null
            };

            var p : Post = Post(initData);
            p.replies := replies;
            p.retweeters := retweeters;
            p.likes := likes;
            p.createdAt := createdAt;
            p.deleted := deleted;

            return p
        }
    };

    public type Retweet = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        createdAt : Time.Time
    };

    public type PostStable = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        replies : [Nat32];
        retweeters : [Utils.UserData];
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        likes : [Like.Like];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time;
        deleted : Bool
    };

    public type PostStable0 = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        replies : [Nat32];
        retweeters : [Utils.UserData];
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        likes : [Like.Like];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time;
        deleted : Bool
    };

    public type PostStable1 = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        replies : [Nat32];
        retweeters : [Utils.UserData];
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        images : [Text];
        likes : [Like.Like];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time;
        deleted : Bool
    };

    public type PostStable2 = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        replies : [Nat32];
        retweeters : [Utils.UserData];
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        images : [Text];
        mentions : [Text];
        hashtags : [Text];
        likes : [Like.Like];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time;
        deleted : Bool
    };

    public type PostStable3 = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        parent : ?ParentData;
        replies : [Nat32];
        retweeters : [Utils.UserData];
        retweet : ?Retweet;
        market : Nat32;
        simpleMarket : Nat32;
        image : ?Text;
        images : [Text];
        pdfs : [Text];
        verified : Bool;
        mentions : [Text];
        hashtags : [Text];
        likes : [Like.Like];
        isRetweet : ?Utils.UserData;
        createdAt : Time.Time;
        deleted : Bool
    };

    public type StablePost = {
        #v0 : PostStable0;
        #v1 : PostStable1;
        #v2 : PostStable2;
        #v3 : PostStable3
    };

    public func getParent(sp : StablePost) : ?ParentData {
        switch (sp) {
            case (#v0(ps)) {
                return ps.parent
            };
            case (#v1(ps)) {
                return ps.parent
            };
            case (#v2(ps)) {
                return ps.parent
            };
            case (#v3(ps)) {
                return ps.parent
            }
        }
    };

    public func getReplies(sp : StablePost) : [Nat32] {
        switch (sp) {
            case (#v0(ps)) {
                return ps.replies
            };
            case (#v1(ps)) {
                return ps.replies
            };
            case (#v2(ps)) {
                return ps.replies
            };
            case (#v3(ps)) {
                return ps.replies
            }
        }
    };

    public func unFreeze(sp : StablePost) : Post {
        switch (sp) {
            case (#v0(ps)) {
                let initData : PostInitData = {
                    id = ps.id;
                    author = ps.author;
                    content = ps.content;
                    parent = ps.parent;
                    retweet = ps.retweet;
                    image = ps.image;
                    images = [];
                    pdfs = [];
                    verified = false;
                    hashtags = [];
                    mentions = [];
                    market = ps.market;
                    simpleMarket = ps.simpleMarket;
                    isRetweet = ps.isRetweet
                };
                var p : Post = Post(initData);

                p.market := ps.market;
                p.simpleMarket := ps.simpleMarket;
                p.replies := Utils.bufferFromArray(ps.replies);
                p.retweeters := Utils.bufferFromArray(ps.retweeters);
                p.likes := Utils.bufferFromArray(ps.likes);
                p.createdAt := ps.createdAt;
                p.deleted := ps.deleted;

                return p
            };
            case (#v1(ps)) {
                let initData : PostInitData = {
                    id = ps.id;
                    author = ps.author;
                    content = ps.content;
                    parent = ps.parent;
                    retweet = ps.retweet;
                    image = ps.image;
                    images = ps.images;
                    pdfs = [];
                    verified = false;
                    hashtags = [];
                    mentions = [];
                    market = ps.market;
                    simpleMarket = ps.simpleMarket;
                    isRetweet = ps.isRetweet
                };
                var p : Post = Post(initData);

                p.market := ps.market;
                p.simpleMarket := ps.simpleMarket;
                p.replies := Utils.bufferFromArray(ps.replies);
                p.retweeters := Utils.bufferFromArray(ps.retweeters);
                p.likes := Utils.bufferFromArray(ps.likes);
                p.createdAt := ps.createdAt;
                p.deleted := ps.deleted;

                return p
            };
            case (#v2(ps)) {
                let initData : PostInitData = {
                    id = ps.id;
                    author = ps.author;
                    content = ps.content;
                    parent = ps.parent;
                    retweet = ps.retweet;
                    image = ps.image;
                    images = ps.images;
                    pdfs = [];
                    verified = false;
                    hashtags = ps.hashtags;
                    mentions = ps.mentions;
                    market = ps.market;
                    simpleMarket = ps.simpleMarket;
                    isRetweet = ps.isRetweet
                };
                var p : Post = Post(initData);

                p.market := ps.market;
                p.simpleMarket := ps.simpleMarket;
                p.replies := Utils.bufferFromArray(ps.replies);
                p.retweeters := Utils.bufferFromArray(ps.retweeters);
                p.likes := Utils.bufferFromArray(ps.likes);
                p.createdAt := ps.createdAt;
                p.deleted := ps.deleted;

                return p
            };
            case (#v3(ps)) {
                let initData : PostInitData = {
                    id = ps.id;
                    author = ps.author;
                    content = ps.content;
                    parent = ps.parent;
                    retweet = ps.retweet;
                    image = ps.image;
                    images = ps.images;
                    pdfs = ps.pdfs;
                    verified = ps.verified;
                    hashtags = ps.hashtags;
                    mentions = ps.mentions;
                    market = ps.market;
                    simpleMarket = ps.simpleMarket;
                    isRetweet = ps.isRetweet
                };
                var p : Post = Post(initData);

                p.market := ps.market;
                p.simpleMarket := ps.simpleMarket;
                p.replies := Utils.bufferFromArray(ps.replies);
                p.retweeters := Utils.bufferFromArray(ps.retweeters);
                p.likes := Utils.bufferFromArray(ps.likes);
                p.createdAt := ps.createdAt;
                p.deleted := ps.deleted;

                return p
            }
        }
    }
}
