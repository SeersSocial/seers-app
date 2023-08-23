import Text "mo:base/Text";

module {
    public type Error = {
        #callerIsAnon;
        #profileNotCreated;
        #notEnoughLiquidity;
        #titleMissing;
        #descriptionMissing;
        #optionsMissing;
        #imageMissing;
        #startDateOld;
        #endDateOld;
        #endDateOlderThanStartDate;
        #notEnoughBalance;
        #marketMissing;
        #marketNotOpen;
        #newtonFailed;
        #lowerThanMinAmount;
        #commentIsEmpty;
        #userAlreadyExist;
        #userDoesNotExist;
        #handleAlreadyTaken;
        #cantGetBalance;

        #notLoggedIn;
        #postDoesNotExist;
        #alreadyLiked;
        #marketNotFound;
        #imageNotFound;
        #parentDoesNotExist;
        #alreadyRetweeted;
        #postIsEmpty;

        #onlyAuthorCanEdit;
        #outcomeMissing;
        #authorOutcomeMissing;
        #notEnoughAmount;
        #callerIsNotAuthor;

        #insufficientBalance;
        #cannotBeRedeemed;
        #nothingToRedeem;

        #missingDescription;
        #wrongNumberOfOutcomes;
        #notEnoughBetAmount;

        #betDoesNotExist;
        #missingICPaddress;

        #failedTransfer: Text;
        #invalidIdentifier;

        #authorDoesNotExist;
        #canNotDelete;
        #onlyAuthorCanDelete;
    };
}