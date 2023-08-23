import Time "mo:base/Time";
import Utils "Utils";

module {
    public type Like = {
        author : Utils.UserData;
        createdAt : Time.Time
    }
}
