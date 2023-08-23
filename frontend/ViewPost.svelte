<script lang="ts">
  import { onMount } from "svelte"
  import { postToView, loggedUser } from "./store/stores"
  import DisplayPost from "./DisplayPost.svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import InputForm from "./InputForm.svelte"
  import { faTemperature0 } from "@fortawesome/free-solid-svg-icons"
  import SvelteSeo from "svelte-seo"

  export let auth
  export let principal
  export let signIn
  export let post = $postToView
  export let id = 0
  export let user = $loggedUser

  let newReply = null
  let newComment = ""
  let errorResponse = ""
  let processing = false
  let replies = []
  let ancestors = []

  const getPost = async (id) => {
    if (!id) return
    const resp = await $auth.actor.getThread(Number(id))
    if ("ok" in resp) {
      post = resp["ok"]["main"][0]["v3"]
      post.market = resp["ok"]["main"][1]
      post.simpleMarket = resp["ok"]["main"][2]

      replies = resp["ok"]["replies"].reverse()
      replies = replies.map((r) => {
        let p = r[0]["v3"]
        p.market = r[1]
        p.simpleMarket = r[2]

        return p
      })
      ancestors = resp["ok"]["ancestors"].reverse()
      ancestors = ancestors.map((a) => {
        let p = a[0]["v3"]
        p.market = a[1]
        p.simpleMarket = a[2]

        return p
      })
    }
    newReply = null

    if (principal !== "") {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
      }
    }
  }

  onMount(async () => {
    if (!id) {
      id = post.id
    }
    await getPost(id)
  })
</script>

<svelte:head>
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@seers_app" />
  <meta name="twitter:creator" content="@seers_app" />
  <meta
    name="twitter:title"
    content={post ? post.title : "Come to read this amazing post"}
  />
  <meta
    name="twitter:description"
    content={post ? post.content : "You will regret it otherwise"}
  />
  <meta
    name="twitter:image"
    content={post && post.images.length > 0
      ? post.images[0]
      : "https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/assets/logo.jpeg"}
  />
</svelte:head>

<div class="outer-container">
  <div class="inner-container" style="justify-content: left;">
    <h3 class="headline" style="padding-left: 10px">Thread</h3>
  </div>
</div>

{#if post}
  <div
    style="justify-content: center; display: flex;width: 100%; flex-direction:column; align-items:center;"
  >
    <div class="inner-container" style="padding-top: 10px;">
      {#each ancestors as ancestor, i}
        <DisplayPost
          {auth}
          {principal}
          {signIn}
          post={ancestor}
          {user}
          isThread={true}
          doNotShowParent={true}
          refresh={() => getPost(post.id)}
          viewpost={async (ancestor) => await getPost(ancestor.id)}
        />
      {/each}
      <div
        id="main"
        style="padding: 0px 0px 0px 0px; width: 100%; border-top: 0px solid grey; margin-bottom: 5px"
      >
        <DisplayPost
          {auth}
          {principal}
          {user}
          {signIn}
          {post}
          isMain={true}
          refresh={() => getPost(post.id)}
          viewpost={async (post) => await getPost(post.id)}
        />
      </div>
      <div style="width: 100%; border-bottom: 1px solid rgb(61, 60, 61);">
        <InputForm
          {auth}
          {principal}
          {signIn}
          {user}
          getFeed={() => getPost(post.id)}
          parent={{
            id: post ? post.id : Number(id),
            author: post ? post.author : null,
          }}
          setPreview={(preview) => {
            newReply = preview
          }}
        />
      </div>

      {#if newReply}
        <DisplayPost
          {user}
          {auth}
          {principal}
          {signIn}
          post={newReply}
          isThread={false}
          refresh={() => getPost(post.id)}
          setPreview={(preview) => {
            newReply = preview
          }}
        />
      {/if}
      {#each replies as reply, i}
        <DisplayPost
          {user}
          {auth}
          {principal}
          {signIn}
          post={reply}
          setPreview={(preview) => {
            newReply = preview
          }}
          isThread={false}
          doNotShowBorder={i < replies.length - 1 ? false : true}
          refresh={() => getPost(post.id)}
          viewpost={async (post) => await getPost(post.id)}
        />
      {/each}
    </div>
  </div>
{/if}

<style global>
  .icon-comment {
    width: 50px;
    display: flex;
    gap: 15px;
    color: grey;
  }

  .icon-comment:hover {
    color: skyblue;
  }

  .icon-retweet {
    width: 50px;
    display: flex;
    gap: 15px;
  }

  .icon-retweet:hover {
    color: greenyellow;
  }

  .icon-heart {
    width: 50px;
    display: flex;
    gap: 15px;
  }

  .icon-heart:hover {
    color: rgb(249, 24, 128);
  }
</style>
