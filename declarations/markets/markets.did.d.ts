import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AccountIdentifier = Uint8Array;
export interface Actor {
  'accountBalance' : ActorMethod<[string], [] | [ICP]>,
  'addCommentToMarket' : ActorMethod<[number, string], Result_15>,
  'backupBalances' : ActorMethod<[], Array<[string, string, string, string]>>,
  'backupBalances2' : ActorMethod<
    [],
    Array<[string, string, number, string, string]>
  >,
  'backupIds' : ActorMethod<[], Array<string>>,
  'backupPosts' : ActorMethod<[], Array<StablePost>>,
  'backupPostsRange' : ActorMethod<[number, number], Array<StablePost>>,
  'buyOutcome' : ActorMethod<[number, bigint, bigint, boolean], Result_8>,
  'callerAccount' : ActorMethod<[], AccountIdentifier>,
  'canisterAccount' : ActorMethod<[], string>,
  'canisterBalance' : ActorMethod<[], ICP>,
  'claimReward' : ActorMethod<[], Result_8>,
  'commit_batch' : ActorMethod<
    [
      {
        'batch_name' : string,
        'content_type' : string,
        'chunk_ids' : Array<bigint>,
      },
    ],
    undefined
  >,
  'createAnonUser' : ActorMethod<[], Result_14>,
  'createBet' : ActorMethod<[InitData], Result_13>,
  'create_chunk' : ActorMethod<[Chunk], { 'chunk_id' : bigint }>,
  'deleteAllMarkets' : ActorMethod<[], undefined>,
  'deleteAllUsers' : ActorMethod<[], boolean>,
  'deleteBet' : ActorMethod<[number], Result>,
  'deleteMarket' : ActorMethod<[number], undefined>,
  'editPost' : ActorMethod<[PostInitData, [] | [MarketInitData]], Result>,
  'editUser' : ActorMethod<[UserInitData], Result_2>,
  'findUser' : ActorMethod<[string], Array<UserStable>>,
  'fixAvatars' : ActorMethod<[], undefined>,
  'fixUser' : ActorMethod<[], undefined>,
  'followUser' : ActorMethod<[string], Result>,
  'getFeed' : ActorMethod<
    [],
    Array<[StablePost, [] | [MarketStable], [] | [SimpleMarketStable]]>
  >,
  'getFullPostsByTag' : ActorMethod<[string], Result_12>,
  'getHandles' : ActorMethod<[], Array<[string, string]>>,
  'getHashTags' : ActorMethod<[], Result_11>,
  'getPayments' : ActorMethod<[], Array<Payment>>,
  'getPaymentsError' : ActorMethod<[], string>,
  'getPost' : ActorMethod<[number], Result_10>,
  'getPostsByTag' : ActorMethod<[string], Result_9>,
  'getRevenue' : ActorMethod<[], Result_8>,
  'getThread' : ActorMethod<[number], Result_7>,
  'getUserAccount' : ActorMethod<[string], Result_6>,
  'getUserFromPrincipal' : ActorMethod<[string], Result_5>,
  'getUserStable' : ActorMethod<[string], [] | [UserStable]>,
  'getUserWithPosts' : ActorMethod<[string], Result_5>,
  'getUsers' : ActorMethod<[], Array<[string, UserStable]>>,
  'getUsersFromPrincipals' : ActorMethod<[Array<string>], Result_4>,
  'haveNotifications' : ActorMethod<[], boolean>,
  'http_request' : ActorMethod<[HttpRequest], HttpResponse>,
  'http_request_streaming_callback' : ActorMethod<
    [StreamingCallbackToken],
    StreamingCallbackHttpResponse
  >,
  'makeHashTags' : ActorMethod<[], Result>,
  'matchBet' : ActorMethod<[number], Result>,
  'otherAccount' : ActorMethod<[], string>,
  'readAllBets' : ActorMethod<[], Array<SimpleMarketStable>>,
  'readAllMarkets' : ActorMethod<
    [MarketCategory, MarketState],
    Array<MarketStable>
  >,
  'readAllUsers' : ActorMethod<[], Array<UserStable>>,
  'readFIFAMarkets' : ActorMethod<[], Array<MarketStable>>,
  'readMarket' : ActorMethod<[number], [] | [MarketStable]>,
  'readMarketsState' : ActorMethod<
    [],
    Array<[number, string, MarketState, Array<bigint>]>
  >,
  'readNextPostId' : ActorMethod<[], number>,
  'readNotifications' : ActorMethod<[], Result_3>,
  'readStableState' : ActorMethod<[], StableState>,
  'readState' : ActorMethod<[], StableState>,
  'readTotalICP' : ActorMethod<[], bigint>,
  'readUserByHandle' : ActorMethod<[string], [] | [UserStable]>,
  'readUserByPrincipal' : ActorMethod<[string], [] | [UserStable]>,
  'readUserHandle' : ActorMethod<[string], [] | [string]>,
  'readUserPrincipal' : ActorMethod<[string], [] | [string]>,
  'readUsersKarma' : ActorMethod<[], Array<[string, string, string, bigint]>>,
  'readUsersKarmaClaim' : ActorMethod<
    [],
    Array<[string, string, string, bigint, string]>
  >,
  'redeemBet' : ActorMethod<[number], Result>,
  'refreshUser' : ActorMethod<[], Result_2>,
  'resetPlusAndMinusBalances' : ActorMethod<[string], Result>,
  'resolveBet' : ActorMethod<[number, bigint], Result>,
  'resolveMarket' : ActorMethod<[number, bigint], Result>,
  'setAvatar' : ActorMethod<[string, string], Result>,
  'setCover' : ActorMethod<[string, string], Result>,
  'setHandle' : ActorMethod<[string, string], Result>,
  'setIcpBalance' : ActorMethod<[string, bigint], Result>,
  'setIcpPlusBalance' : ActorMethod<[string, bigint], Result>,
  'setMarketEnd' : ActorMethod<[number, Time], boolean>,
  'setMarketImage' : ActorMethod<[number, string], boolean>,
  'setMarketPost' : ActorMethod<[number, number], Result>,
  'setMarketState' : ActorMethod<[number, MarketState], boolean>,
  'setMarketTitle' : ActorMethod<[number, string], boolean>,
  'setPrincipal' : ActorMethod<[string, string], Result>,
  'setRewards' : ActorMethod<[], undefined>,
  'setSeersBalance' : ActorMethod<[string, bigint], Result>,
  'setTwitter' : ActorMethod<[string, string], Result>,
  'setTwitterWithContent' : ActorMethod<
    [string, string, string, string],
    Result
  >,
  'setUpdating' : ActorMethod<[boolean], undefined>,
  'setUsersRewards' : ActorMethod<[], undefined>,
  'submitDelete' : ActorMethod<[number], Result>,
  'submitLike' : ActorMethod<[number], Result>,
  'submitPost' : ActorMethod<
    [PostInitData, [] | [MarketInitData], [] | [InitData]],
    Result
  >,
  'submitRetweet' : ActorMethod<[number], Result>,
  'submitTextPost' : ActorMethod<[PostInitData, string], Result>,
  'submitTextPost2' : ActorMethod<[PostInitData, string], Result_1>,
  'transferToCanister' : ActorMethod<[], string>,
  'transferToHandle' : ActorMethod<[string, bigint], Result>,
  'transferToIdentifier' : ActorMethod<[string, bigint], Result>,
  'unfollowUser' : ActorMethod<[string], Result>,
  'unlockFunds' : ActorMethod<[string, CollateralType, bigint], Result>,
  'updateNotifications' : ActorMethod<[], Result>,
}
export interface Asset { 'encoding' : AssetEncoding, 'content_type' : string }
export interface AssetEncoding {
  'modified' : bigint,
  'certified' : boolean,
  'content_chunks' : Array<Uint8Array>,
  'total_length' : bigint,
}
export interface Balance {
  'btc' : bigint,
  'icp' : bigint,
  'seers' : bigint,
  'cycles' : bigint,
}
export interface Bettor { 'id' : string, 'spent' : bigint, 'outcome' : bigint }
export interface BrierScore { 'createdAt' : Time, 'score' : number }
export interface Chunk { 'content' : Uint8Array, 'batch_name' : string }
export type CollateralType = { 'btc' : null } |
  { 'icp' : null } |
  { 'seers' : null } |
  { 'cycles' : null };
export interface CommentStable {
  'id' : number,
  'content' : string,
  'modifiedAt' : Time,
  'createdAt' : Time,
  'author' : UserData,
  'likes' : Array<Like>,
}
export interface DepositAddrs {
  'btc' : string,
  'icp' : Subaccount,
  'cycles' : string,
}
export type Error = { 'insufficientBalance' : null } |
  { 'callerIsAnon' : null } |
  { 'missingICPaddress' : null } |
  { 'userAlreadyExist' : null } |
  { 'nothingToRedeem' : null } |
  { 'notLoggedIn' : null } |
  { 'imageMissing' : null } |
  { 'profileNotCreated' : null } |
  { 'invalidIdentifier' : null } |
  { 'parentDoesNotExist' : null } |
  { 'notEnoughBalance' : null } |
  { 'postIsEmpty' : null } |
  { 'optionsMissing' : null } |
  { 'betDoesNotExist' : null } |
  { 'failedTransfer' : string } |
  { 'descriptionMissing' : null } |
  { 'marketNotFound' : null } |
  { 'titleMissing' : null } |
  { 'handleAlreadyTaken' : null } |
  { 'canNotDelete' : null } |
  { 'imageNotFound' : null } |
  { 'alreadyLiked' : null } |
  { 'lowerThanMinAmount' : null } |
  { 'onlyAuthorCanDelete' : null } |
  { 'missingDescription' : null } |
  { 'marketMissing' : null } |
  { 'startDateOld' : null } |
  { 'marketNotOpen' : null } |
  { 'callerIsNotAuthor' : null } |
  { 'onlyAuthorCanEdit' : null } |
  { 'postDoesNotExist' : null } |
  { 'alreadyRetweeted' : null } |
  { 'commentIsEmpty' : null } |
  { 'userDoesNotExist' : null } |
  { 'outcomeMissing' : null } |
  { 'authorOutcomeMissing' : null } |
  { 'endDateOld' : null } |
  { 'cantGetBalance' : null } |
  { 'notEnoughBetAmount' : null } |
  { 'newtonFailed' : null } |
  { 'notEnoughAmount' : null } |
  { 'endDateOlderThanStartDate' : null } |
  { 'wrongNumberOfOutcomes' : null } |
  { 'authorDoesNotExist' : null } |
  { 'cannotBeRedeemed' : null } |
  { 'notEnoughLiquidity' : null };
export interface Followee { 'createdAt' : Time, 'user' : string }
export interface Followee0 { 'userdata' : UserData, 'createdAt' : Time }
export type FolloweeStable = { 'v0' : Followee0 };
export interface Follower { 'createdAt' : Time, 'user' : string }
export interface Follower0 { 'userdata' : UserData, 'createdAt' : Time }
export type FollowerStable = { 'v0' : Follower0 };
export type Forecast = Array<number>;
export type FullPost = [
  StablePost,
  [] | [MarketStable],
  [] | [SimpleMarketStable],
];
export type HeaderField = [string, string];
export interface HistPoint {
  'probabilities' : Array<bigint>,
  'createdAt' : Time,
  'liquidity' : bigint,
}
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Uint8Array,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Uint8Array,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export interface ICP { 'e8s' : bigint }
export interface InitData {
  'id' : number,
  'collateralType' : CollateralType,
  'description' : string,
  'author' : [] | [UserData],
  'outcomes' : Array<string>,
  'authorChoice' : bigint,
  'authorAmount' : bigint,
}
export interface Like { 'createdAt' : Time, 'author' : UserData }
export type MarketCategory = { 'any' : null } |
  { 'entertainment' : null } |
  { 'self' : null } |
  { 'seers' : null } |
  { 'crypto' : null } |
  { 'business' : null } |
  { 'financial' : null } |
  { 'sports' : null } |
  { 'dfinity' : null } |
  { 'science' : null } |
  { 'politics' : null };
export interface MarketInitData {
  'id' : number,
  'title' : string,
  'probabilities' : Array<bigint>,
  'endDate' : Time,
  'labels' : Array<string>,
  'liquidity' : bigint,
  'collateralType' : CollateralType,
  'description' : string,
  'author' : string,
  'imageUrl' : string,
  'category' : MarketCategory,
  'startDate' : Time,
  'images' : Array<string>,
}
export interface MarketStable {
  'k' : bigint,
  'id' : number,
  'forecasts' : Array<Forecast>,
  'title' : string,
  'histPrices' : Array<HistPoint>,
  'probabilities' : Array<bigint>,
  'endDate' : Time,
  'modifiedAt' : Time,
  'labels' : Array<string>,
  'createdAt' : Time,
  'liquidity' : bigint,
  'reserves' : Array<bigint>,
  'collateralType' : CollateralType,
  'description' : string,
  'volume' : bigint,
  'bettors' : Array<Bettor>,
  'author' : string,
  'state' : MarketState,
  'imageUrl' : string,
  'category' : MarketCategory,
  'providers' : Array<string>,
  'comments' : Array<CommentStable>,
  'totalShares' : bigint,
  'startDate' : Time,
  'images' : Array<string>,
}
export type MarketState = { 'any' : null } |
  { 'resolved' : bigint } |
  { 'closed' : null } |
  { 'pending' : null } |
  { 'invalid' : null } |
  { 'open' : null } |
  { 'approved' : null };
export interface MarketTx {
  'id' : number,
  'fee' : bigint,
  'src' : [] | [bigint],
  'dest' : [] | [bigint],
  'createdAt' : Time,
  'recv' : bigint,
  'sent' : bigint,
  'collateralType' : CollateralType,
  'marketId' : number,
  'price' : bigint,
}
export type Notification = { 'v0' : NotificationType0 };
export interface NotificationPost {
  'id' : number,
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'content' : string,
  'createdAt' : Time,
  'author' : UserData,
  'market' : number,
  'image' : [] | [string],
  'parent' : [] | [ParentData__1],
  'images' : Array<string>,
}
export type NotificationType0 = { 'reply' : NotificationPost };
export interface ParentData { 'id' : number, 'author' : UserData }
export interface ParentData__1 { 'id' : number, 'author' : UserData }
export interface Payment {
  'to' : string,
  'from' : string,
  'collateralType' : CollateralType,
  'processed' : boolean,
  'amount' : bigint,
}
export interface PostInitData {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'verified' : boolean,
  'content' : string,
  'hashtags' : Array<string>,
  'pdfs' : Array<string>,
  'author' : UserData,
  'market' : number,
  'image' : [] | [string],
  'mentions' : Array<string>,
  'parent' : [] | [ParentData],
  'images' : Array<string>,
}
export interface PostStable {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'deleted' : boolean,
  'content' : string,
  'createdAt' : Time,
  'author' : UserData,
  'likes' : Array<Like>,
  'replies' : Uint32Array,
  'market' : number,
  'image' : [] | [string],
  'parent' : [] | [ParentData],
  'retweeters' : Array<UserData>,
}
export interface PostStable0 {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'deleted' : boolean,
  'content' : string,
  'createdAt' : Time,
  'author' : UserData,
  'likes' : Array<Like>,
  'replies' : Uint32Array,
  'market' : number,
  'image' : [] | [string],
  'parent' : [] | [ParentData],
  'retweeters' : Array<UserData>,
}
export interface PostStable1 {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'deleted' : boolean,
  'content' : string,
  'createdAt' : Time,
  'author' : UserData,
  'likes' : Array<Like>,
  'replies' : Uint32Array,
  'market' : number,
  'image' : [] | [string],
  'parent' : [] | [ParentData],
  'retweeters' : Array<UserData>,
  'images' : Array<string>,
}
export interface PostStable2 {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'deleted' : boolean,
  'content' : string,
  'hashtags' : Array<string>,
  'createdAt' : Time,
  'author' : UserData,
  'likes' : Array<Like>,
  'replies' : Uint32Array,
  'market' : number,
  'image' : [] | [string],
  'mentions' : Array<string>,
  'parent' : [] | [ParentData],
  'retweeters' : Array<UserData>,
  'images' : Array<string>,
}
export interface PostStable3 {
  'id' : number,
  'retweet' : [] | [Retweet],
  'isRetweet' : [] | [UserData],
  'simpleMarket' : number,
  'verified' : boolean,
  'deleted' : boolean,
  'content' : string,
  'hashtags' : Array<string>,
  'createdAt' : Time,
  'pdfs' : Array<string>,
  'author' : UserData,
  'likes' : Array<Like>,
  'replies' : Uint32Array,
  'market' : number,
  'image' : [] | [string],
  'mentions' : Array<string>,
  'parent' : [] | [ParentData],
  'retweeters' : Array<UserData>,
  'images' : Array<string>,
}
export type Result = { 'ok' : null } |
  { 'err' : Error };
export type Result_1 = { 'ok' : number } |
  { 'err' : Error };
export type Result_10 = { 'ok' : StablePost } |
  { 'err' : Error };
export type Result_11 = { 'ok' : Array<[string, Uint32Array]> } |
  { 'err' : Error };
export type Result_12 = { 'ok' : Array<StablePost> } |
  { 'err' : Error };
export type Result_13 = { 'ok' : SimpleMarketStable } |
  { 'err' : Error };
export type Result_14 = { 'ok' : [UserStable, Array<PostStable>] } |
  { 'err' : Error };
export type Result_15 = { 'ok' : CommentStable } |
  { 'err' : Error };
export type Result_2 = { 'ok' : UserStable } |
  { 'err' : Error };
export type Result_3 = { 'ok' : Array<Notification> } |
  { 'err' : Error };
export type Result_4 = { 'ok' : Array<UserStable> } |
  { 'err' : Error };
export type Result_5 = { 'ok' : [UserStable, Array<FullPost>] } |
  { 'err' : Error };
export type Result_6 = { 'ok' : string } |
  { 'err' : Error };
export type Result_7 = { 'ok' : ThreadStable } |
  { 'err' : Error };
export type Result_8 = { 'ok' : bigint } |
  { 'err' : Error };
export type Result_9 = { 'ok' : Uint32Array } |
  { 'err' : Error };
export interface Retweet {
  'id' : number,
  'content' : string,
  'createdAt' : Time,
  'author' : UserData,
  'parent' : [] | [ParentData],
}
export interface SimpleMarketStable {
  'id' : number,
  'matcherResolution' : bigint,
  'matcherChoice' : bigint,
  'matcherAmount' : bigint,
  'modifiedAt' : Time,
  'createdAt' : Time,
  'collateralType' : CollateralType,
  'description' : string,
  'authorResolution' : bigint,
  'author' : [] | [UserData],
  'outcomes' : Array<string>,
  'state' : State,
  'matcher' : [] | [UserData],
  'amount' : bigint,
  'authorChoice' : bigint,
  'authorAmount' : bigint,
}
export type StablePost = { 'v0' : PostStable0 } |
  { 'v1' : PostStable1 } |
  { 'v2' : PostStable2 } |
  { 'v3' : PostStable3 };
export type StableState = { 'v0' : StableState0 } |
  { 'v1' : StableState1 };
export interface StableState0 {
  'payments' : Array<Payment>,
  'bets' : Array<[number, SimpleMarketStable]>,
  'feed' : Uint32Array,
  'handles' : Array<[string, string]>,
  'markets' : Array<[number, MarketStable]>,
  'users' : Array<[string, UserStable]>,
  'posts' : Array<[number, PostStable]>,
  'images' : Array<[number, string]>,
}
export interface StableState1 {
  'hashtags' : Array<[string, Uint32Array]>,
  'payments' : Array<Payment>,
  'bets' : Array<[number, SimpleMarketStable]>,
  'feed' : Uint32Array,
  'handles' : Array<[string, string]>,
  'assets' : Array<[string, Asset]>,
  'markets' : Array<[number, MarketStable]>,
  'users' : Array<[string, UserStable]>,
  'chunks' : Array<[bigint, Chunk]>,
  'posts' : Array<[number, PostStable]>,
  'postsv' : Array<[number, StablePost]>,
  'images' : Array<[number, string]>,
}
export type State = { 'resolved' : bigint } |
  { 'closed' : null } |
  { 'cancelled' : null } |
  { 'redeemed' : bigint } |
  { 'open' : null } |
  { 'matched' : null };
export interface StreamingCallbackHttpResponse {
  'token' : [] | [StreamingCallbackToken],
  'body' : Uint8Array,
}
export interface StreamingCallbackToken {
  'key' : string,
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken,
      'callback' : [Principal, string],
    }
  };
export type Subaccount = Uint8Array;
export interface ThreadStable {
  'main' : FullPost,
  'ancestors' : Array<FullPost>,
  'replies' : Array<FullPost>,
}
export type Time = bigint;
export interface UserData {
  'principal' : string,
  'name' : string,
  'picture' : string,
  'handle' : string,
}
export interface UserInitData {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'twitter' : string,
  'city' : string,
  'name' : string,
  'cover' : string,
  'website' : string,
  'picture' : string,
  'canister' : string,
  'number' : number,
  'discord' : string,
  'handle' : string,
}
export interface UserMarket {
  'brierScores' : Array<BrierScore>,
  'title' : string,
  'shares' : bigint,
  'modifiedAt' : Time,
  'redeemed' : boolean,
  'labels' : Array<string>,
  'createdAt' : Time,
  'collateralType' : CollateralType,
  'author' : boolean,
  'spent' : bigint,
  'marketId' : number,
  'balances' : BigUint64Array,
}
export type UserStable = { 'v0' : UserStable0 } |
  { 'v1' : UserStable1 } |
  { 'v2' : UserStable2 } |
  { 'v3' : UserStable3 } |
  { 'v4' : UserStable4 };
export interface UserStable0 {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'txs' : Array<MarketTx>,
  'retweets' : Uint32Array,
  'expBalances' : Balance,
  'twitter' : string,
  'lastSeenAt' : Time,
  'modifiedAt' : Time,
  'city' : string,
  'name' : string,
  'createdAt' : Time,
  'cover' : string,
  'markets' : Array<UserMarket>,
  'website' : string,
  'likes' : Uint32Array,
  'picture' : string,
  'minusBalances' : Balance,
  'plusBalances' : Balance,
  'canister' : string,
  'number' : number,
  'replies' : Uint32Array,
  'discord' : string,
  'handle' : string,
  'comments' : Array<CommentStable>,
  'posts' : Uint32Array,
  'followees' : Array<Followee>,
  'followers' : Array<Follower>,
  'depositAddrs' : DepositAddrs,
  'balances' : Balance,
  'depositICPaddr' : string,
}
export interface UserStable1 {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'txs' : Array<MarketTx>,
  'retweets' : Uint32Array,
  'expBalances' : Balance,
  'twitter' : string,
  'lastSeenAt' : Time,
  'modifiedAt' : Time,
  'city' : string,
  'name' : string,
  'createdAt' : Time,
  'cover' : string,
  'markets' : Array<UserMarket>,
  'website' : string,
  'likes' : Uint32Array,
  'picture' : string,
  'minusBalances' : Balance,
  'plusBalances' : Balance,
  'canister' : string,
  'number' : number,
  'replies' : Uint32Array,
  'discord' : string,
  'handle' : string,
  'comments' : Array<CommentStable>,
  'posts' : Uint32Array,
  'followees' : Array<Followee>,
  'followers' : Array<Follower>,
  'depositAddrs' : DepositAddrs,
  'balances' : Balance,
  'depositICPaddr' : string,
}
export interface UserStable2 {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'txs' : Array<MarketTx>,
  'retweets' : Uint32Array,
  'expBalances' : Balance,
  'twitter' : string,
  'lastSeenAt' : Time,
  'modifiedAt' : Time,
  'city' : string,
  'name' : string,
  'createdAt' : Time,
  'cover' : string,
  'markets' : Array<UserMarket>,
  'website' : string,
  'likes' : Uint32Array,
  'picture' : string,
  'minusBalances' : Balance,
  'plusBalances' : Balance,
  'canister' : string,
  'number' : number,
  'replies' : Uint32Array,
  'discord' : string,
  'handle' : string,
  'lockedBalances' : Balance,
  'comments' : Array<CommentStable>,
  'posts' : Uint32Array,
  'followees' : Array<Followee>,
  'followers' : Array<Follower>,
  'depositAddrs' : DepositAddrs,
  'balances' : Balance,
  'depositICPaddr' : string,
}
export interface UserStable3 {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'txs' : Array<MarketTx>,
  'retweets' : Uint32Array,
  'expBalances' : Balance,
  'notifications' : Array<Notification>,
  'twitter' : string,
  'lastSeenAt' : Time,
  'modifiedAt' : Time,
  'city' : string,
  'name' : string,
  'createdAt' : Time,
  'cover' : string,
  'markets' : Array<UserMarket>,
  'website' : string,
  'likes' : Uint32Array,
  'picture' : string,
  'minusBalances' : Balance,
  'plusBalances' : Balance,
  'canister' : string,
  'number' : number,
  'replies' : Uint32Array,
  'discord' : string,
  'handle' : string,
  'lockedBalances' : Balance,
  'comments' : Array<CommentStable>,
  'posts' : Uint32Array,
  'followees' : Array<Followee>,
  'followers' : Array<Follower>,
  'notificationsSeen' : bigint,
  'depositAddrs' : DepositAddrs,
  'balances' : Balance,
  'depositICPaddr' : string,
}
export interface UserStable4 {
  'id' : string,
  'age' : bigint,
  'bio' : string,
  'txs' : Array<MarketTx>,
  'retweets' : Uint32Array,
  'expBalances' : Balance,
  'notifications' : Array<Notification>,
  'twitter' : string,
  'lastSeenAt' : Time,
  'modifiedAt' : Time,
  'city' : string,
  'name' : string,
  'createdAt' : Time,
  'cover' : string,
  'markets' : Array<UserMarket>,
  'website' : string,
  'likes' : Uint32Array,
  'picture' : string,
  'minusBalances' : Balance,
  'plusBalances' : Balance,
  'canister' : string,
  'number' : number,
  'replies' : Uint32Array,
  'discord' : string,
  'handle' : string,
  'lockedBalances' : Balance,
  'comments' : Array<CommentStable>,
  'posts' : Uint32Array,
  'followees' : Array<FolloweeStable>,
  'followers' : Array<FollowerStable>,
  'notificationsSeen' : bigint,
  'depositAddrs' : DepositAddrs,
  'balances' : Balance,
  'depositICPaddr' : string,
}
export interface _SERVICE extends Actor {}
