<script lang="ts">
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import { loggedUser } from "./store/stores"
  import anon from "./assets/anon.png"

  export let auth
  export let user = $loggedUser
  export let principal
  export let isReply = false

  let post = ""

  $: user = $loggedUser

  export const submitPost = async (parent) => {
    const metadata = linkify.find(post)
    const mentions = metadata
      .filter((t) => t.type == "mention")
      .map((t) => t.value.slice(1))

    let hashtags = metadata
      .filter((t) => t.type == "hashtag")
      .map((t) => t.value.slice(1))

    
    post = post.trim()
    if (post.length < 3 || post.length > 600) return

    const newPost = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content: post,
      parent: [],
      retweet: [],
      market: 0,
      simpleMarket: 0,
      image: [],
      images: [],
      verified: user && user.twitter ? true : false,
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
      content: post,
      parent: parent ? [parent] : [],
      image: [],
      images: [],
      pdfs: [],
      verified: user && user.twitter ? true : false,
      mentions,
      hashtags,
      market: 0,
      simpleMarket: 0,
      retweet: [],
      isRetweet: [],
    }
    post = ""
    return [newPost, $auth.actor.submitPost(initData, [], [])]
  }
</script>

<div style="display:flex;justify-content:flex-start; padding: 0px 5px">
  {#if user && user.picture.includes("raw.ic0.app/?tokenid=") && !user.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")}
    <img
      src={`${user.picture}&type=thumbnail`}
      alt="avatar"
      onError="this.src='{anon + user.handle}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {:else}
    <img
      src={user ? user.picture : anon}
      alt="avatar"
      onError="this.src='{anon}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {/if}
  {#if window.innerWidth >= 1100}
    <textarea
      bind:value={post}
      rows="3"
      onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
      placeholder={isReply ? "Add another post" : "What's happening?"}
    />
  {:else}
    <textarea
      bind:value={post}
      rows="3"
      onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
      placeholder={isReply ? "Add another post" : "What's happening?"}
    />
  {/if}
</div>
