import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";

import Utils "Utils";
import Forecast "Forecast";
import Tokens "Tokens";
import Comment "Comment";

module {
    public type MarketState = {
        #any;
        #pending;
        #approved;
        #open;
        #closed;
        #invalid;
        #resolved : Nat
    };

    public type MarketCategory = {
        #any;
        #crypto;
        #science;
        #politics;
        #sports;
        #entertainment;
        #business;
        #financial;
        #seers;
        #dfinity;
        #self
    };

    public type MarketInitData = {
        id : Nat32;
        title : Text;
        description : Text;
        labels : [Text];
        images : [Text];
        probabilities : [Nat];
        category : MarketCategory;
        collateralType : Tokens.CollateralType;
        liquidity : Nat;
        startDate : Time.Time;
        endDate : Time.Time;
        imageUrl : Text;
        author : Text
    };

    public type HistPoint = {
        probabilities : [Nat];
        liquidity : Nat;
        createdAt : Time.Time
    };

    public type Bettor = {
        id : Text;
        spent : Nat64;
        outcome : Nat
    };

    public class Market(initData : MarketInitData) = this {
        public var id : Nat32 = initData.id;
        public var title : Text = initData.title;
        public var description : Text = initData.description;
        public var startDate : Time.Time = initData.startDate;
        public var endDate : Time.Time = initData.endDate;
        public var author : Text = initData.author;
        public var labels : [Text] = initData.labels;
        public var images : [Text] = initData.images;
        public var category : MarketCategory = initData.category;
        public var collateralType : Tokens.CollateralType = initData.collateralType;
        public var probabilities : [Nat] = initData.probabilities;
        public var liquidity : Nat = initData.liquidity;
        public var reserves : [Nat] = do {
            let size = initData.labels.size();
            var reserves : [Nat] = [];
            for (i in Iter.range(0, size - 1)) {
                reserves := Array.append(reserves, [initData.liquidity])
            };
            reserves
        };
        public var k : Nat = do {
            let size = initData.labels.size();
            var k : Nat = 1;
            for (i in Iter.range(0, size - 1)) {
                k := k * reserves[i]
            };
            k
        };
        public var providers : Buffer.Buffer<Text> = do {
            var providers = Buffer.Buffer<Text>(1);
            providers.add(initData.author);
            providers
        };
        public var bettors : Buffer.Buffer<Bettor> = Buffer.Buffer<Bettor>(0);
        public var totalShares : Nat = 0; // TODO: FIX dummy to sqrt(k)
        public var imageUrl : Text = initData.imageUrl;
        public var state : MarketState = #open;
        public var volume : Nat = 0;
        public var comments : Buffer.Buffer<Comment.Comment> = Buffer.Buffer<Comment.Comment>(0);
        public var histPrices : Buffer.Buffer<HistPoint> = do {
            var histPrices = Buffer.Buffer<HistPoint>(1);
            let histPoint : HistPoint = {
                probabilities = initData.probabilities;
                liquidity = initData.liquidity;
                createdAt = Time.now()
            };
            histPrices.add(histPoint);
            histPrices
        };
        public var forecasts : Buffer.Buffer<Forecast.Forecast> = Buffer.Buffer<Forecast.Forecast>(0);
        public var createdAt : Time.Time = Time.now();
        public var modifiedAt : Time.Time = Time.now();

        public func freeze() : MarketStable {
            let stableComments = Array.map(
                comments.toArray(),
                func(c : Comment.Comment) : Comment.CommentStable {
                    c.freeze()
                },
            );
            let ms : MarketStable = {
                id = id;
                title = title;
                description = description;
                startDate = startDate;
                endDate = endDate;
                author = author;
                labels = labels;
                images = images;
                probabilities = probabilities;
                liquidity = liquidity;
                reserves = reserves;
                category = category;
                collateralType = collateralType;
                k = k;
                providers = providers.toArray();
                bettors = bettors.toArray();
                totalShares = totalShares;
                imageUrl = imageUrl;
                state = state;
                volume = volume;
                comments = stableComments;
                histPrices = histPrices.toArray();
                forecasts = forecasts.toArray();
                createdAt = createdAt;
                modifiedAt = modifiedAt
            };
            return ms
        }
    };
    public type MarketStable = {
        id : Nat32;
        title : Text;
        description : Text;
        startDate : Time.Time;
        endDate : Time.Time;
        author : Text;
        labels : [Text];
        images : [Text];
        probabilities : [Nat];
        liquidity : Nat;
        reserves : [Nat];
        category : MarketCategory;
        collateralType : Tokens.CollateralType;
        k : Nat;
        providers : [Text];
        bettors : [Bettor];
        totalShares : Nat;
        imageUrl : Text;
        state : MarketState;
        volume : Nat;
        comments : [Comment.CommentStable];
        histPrices : [HistPoint];
        forecasts : [Forecast.Forecast];
        createdAt : Time.Time;
        modifiedAt : Time.Time
    };

    public func unFreeze(m : MarketStable) : Market {
        let initData : MarketInitData = {
            id = m.id;
            title = m.title;
            description = m.description;
            startDate = m.startDate;
            endDate = m.endDate;
            author = m.author;
            labels = m.labels;
            images = m.images;
            probabilities = m.probabilities;
            liquidity = m.liquidity;
            imageUrl = m.imageUrl;
            category = m.category;
            collateralType = m.collateralType
        };
        let comments = Array.map(
            m.comments,
            func(c : Comment.CommentStable) : Comment.Comment {
                Comment.unFreeze(c)
            },
        );
        var market : Market = Market(initData);
        market.reserves := m.reserves;
        market.k := m.k;
        market.providers := Utils.bufferFromArray(m.providers);
        market.bettors := Utils.bufferFromArray(m.bettors);
        market.totalShares := m.totalShares;
        market.state := m.state;
        market.volume := m.volume;
        market.comments := Utils.bufferFromArray(comments);
        market.histPrices := Utils.bufferFromArray(m.histPrices);
        market.forecasts := Utils.bufferFromArray(m.forecasts);
        market.createdAt := m.createdAt;
        market.modifiedAt := m.modifiedAt;

        return market
    }
}
