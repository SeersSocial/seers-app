<script lang="ts">
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import { anon } from "./utils/utils"
  import { loggedUser } from "./store/stores"

  export let auth
  export let user = $loggedUser
  export let principal

  let toHandle = ""
  let toValue = ""
  let post = ""

  export const submitTransfer = async (parent) => {
    let contentPrev = ""
    let content = ""

    if (toHandle.startsWith("@")) {
      contentPrev =
        post +
        `
        🤖: @${user.handle} sending ${toValue} ICP to ${toHandle}`

      content =
        post +
        `
        🤖: @${user.handle} sent ${toValue} ICP to ${toHandle}`
    } else {
      contentPrev =
        post +
        `
        🤖: @${user.handle} sending ${toValue} ICP to the outside world 🌎`

      content =
        post +
        `
        🤖: @${user.handle} sent ${toValue} ICP to the outside world 🌎`
    }

    const newPost = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content: contentPrev,
      parent: parent ? [parent] : [],
      retweet: [],
      market: 0,
      simpleMarket: 0,
      image: [],
      images: [],
      likes: [],
      replies: [],
      retweeters: [],
      isRetweet: [],
      createdAt: Date.now() * 1_000_000,
      deleted: false,
    }
    let initData = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content,
      parent: parent ? [parent] : [],
      image: [],
      images: [],
      pdfs: [],
      verified: user.twitter ? true : false,
      mentions: [],
      hashtags: [],
      market: 0,
      simpleMarket: 0,
      retweet: [],
      isRetweet: [],
    }

    let transferPromise = null

    if (toHandle.startsWith("@")) {
      transferPromise = $auth.actor.transferToHandle(
        toHandle.slice(1),
        Math.floor(Number(toValue) * 100_000_000), // ICP e8s
      )
    } else {
      // Send to identifier.
      transferPromise = $auth.actor.transferToIdentifier(
        toHandle,
        Math.floor(Number(toValue) * 100_000_000), // ICP e8s
      )
    }

    post = ""
    toValue = ""
    toHandle = ""

    return [
      newPost,
      transferPromise,
      async () => {
        return await $auth.actor.submitPost(initData, [], [])
      },
    ]
  }
</script>

<div
  style="width: 100%; display: flex; align-items: center; justify-content: flex-start; padding: 5px;"
>
  {#if user && user.picture.includes("raw.ic0.app/?tokenid=") && !user.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")}
    <img
      src={`${user.picture}&type=thumbnail`}
      alt="avatar"
      onError="this.src='{anon + user?.handle}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {:else}
    <img
      src={user ? user.picture : anon + user?.handle}
      alt="avatar"
      onError="this.src='{anon + user?.handle}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {/if}

  <textarea
    bind:value={post}
    rows="3"
    onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
    onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
    style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
    placeholder={"What's happening?"}
  />
</div>

<div
  style="display:flex; flex-direction: column; width: 90%; margin-left: 30px; height: fit-content; border: 1px solid rgb(47, 51, 54); border-radius: 16px; align-items:flex-end"
>
  <div
    style="display:flex; width: 100%; height: 70px; border-top: 0px solid rgb(47, 51, 54); align-items:flex-end;"
  >
    <div style="display:flex; width: 100%; height: 100%; padding: 0px 5px;">
      <div
        style="width: 50%; height: 100%; border-right: 1px solid rgb(47, 51, 54); display:flex; flex-direction:column; padding: 0px 10px"
      >
        <label for="start" style="width: 100%; color:grey">Send to:</label>
        <div style="display:flex; align-items:center">
          <!-- <div>@</div> -->
          <div>
            <input
              type="text"
              id="toHandle"
              placeholder="@handle or account id"
              bind:value={toHandle}
              style="border: 0px; font-size: 1.1em; width: 90%;"
            />
          </div>
        </div>
      </div>
      <div
        style="width: 50%; height: 100%; border-right: 0px solid rgb(47, 51, 54); display:flex; flex-direction:column;padding: 0px 10px"
      >
        <label for="start" style="width: 100%; color:grey">Amount:</label>
        <div style="display:flex; width: 100%; align-items:center">
          <input
            type="text"
            id="toValue"
            bind:value={toValue}
            placeholder="0.0"
            style="border: 0px; font-size: 1.1em; width: 50%"
          />
          <div style="width:30%">ICP</div>
        </div>
      </div>
    </div>
  </div>
</div>
