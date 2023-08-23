import Float "mo:base/Float";
import Time "mo:base/Time";

module {
    public type Forecast = [Float];
    public type BrierScore = {
        score : Float;
        createdAt : Time.Time
    }
}
