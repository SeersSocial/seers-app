import Comment "Comment";
import Tx "Tx";

module {
    public type Bet = {
        tx : Tx.UserTx;
        comment : Comment.CommentStable
    }
}
