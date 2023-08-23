import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Text "mo:base/Text";

module {
    public type UserData = {
        principal : Text;
        handle : Text;
        name : Text;
        picture : Text
    };

    public func removeFromBuffer<X>(b : Buffer.Buffer<X>, f : X -> Bool) : Buffer.Buffer<X> {
        var buf : Buffer.Buffer<X> = Buffer.Buffer<X>(b.size());
        for (e in b.vals()) {
            if (not f(e)) {
                buf.add(e)
            }
        };
        return buf
    };

    public func bufferFromArray<X>(a : [X]) : Buffer.Buffer<X> {
        var buf : Buffer.Buffer<X> = Buffer.Buffer<X>(a.size());
        for (e in a.vals()) {
            buf.add(e)
        };
        return buf
    };

    public func bufferFromVarArray<X>(a : [var X]) : Buffer.Buffer<X> {
        var buf : Buffer.Buffer<X> = Buffer.Buffer<X>(a.size());
        for (e in a.vals()) {
            buf.add(e)
        };
        return buf
    };

    public func newtonMethod(x0 : Float, f : Float -> Float) : ?Float {
        let tolerance = 1e-7;
        let epsylon = 2.220446049250313e-16;
        let h = 1e-4;
        let hr = 1 / h;
        let maxIter = 100;

        var iter = 0;
        var prev = x0;

        while (iter < maxIter) {
            // Compute the value of the function.
            let y = f(prev);

            // Use numerica derivatives.
            let yph = f(prev + h);
            let ymh = f(prev - h);
            let yp2h = f(prev + 2 * h);
            let ym2h = f(prev - 2 * h);

            let yp = ((ym2h - yp2h) + 8 * (yph - ymh)) * hr / 12;

            if (Float.abs(yp) <= epsylon * Float.abs(y)) {
                return null
            };

            // Update the guess.
            let next = prev - y / yp;

            // Check for convergence:
            if (Float.abs(next - prev) <= tolerance * Float.abs(next)) {
                return ?next
            };

            prev := next;
            iter := iter + 1
        };

        return null
    }
}
