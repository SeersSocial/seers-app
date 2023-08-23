import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

import Like "Like";
import Utils "Utils";

module {
    public type CommentInitData = {
        id : Nat32;
        author : Utils.UserData;
        content : Text
    };

    public type CommentStable = {
        id : Nat32;
        author : Utils.UserData;
        content : Text;
        likes : [Like.Like];
        createdAt : Time.Time;
        modifiedAt : Time.Time
    };

    public func unFreeze(cs : CommentStable) : Comment {
        let initData : CommentInitData = {
            id = cs.id;
            author = cs.author;
            content = cs.content
        };
        var c : Comment = Comment(initData);
        c.likes := Utils.bufferFromArray(cs.likes);
        c.createdAt := cs.createdAt;
        c.modifiedAt := c.modifiedAt;

        return c
    };

    public class Comment(initData : CommentInitData) = {
        public var id : Nat32 = initData.id;
        public var author : Utils.UserData = initData.author;
        public var content : Text = initData.content;
        public var likes : Buffer.Buffer<Like.Like> = Buffer.Buffer<Like.Like>(0);
        public var createdAt : Time.Time = Time.now();
        public var modifiedAt : Time.Time = Time.now();

        public func freeze() : CommentStable {
            let cs : CommentStable = {
                id = id;
                author = author;
                content = content;
                likes = likes.toArray();
                createdAt = createdAt;
                modifiedAt = modifiedAt
            };
            return cs
        }
    }
}
