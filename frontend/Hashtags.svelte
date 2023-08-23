<script lang="ts">
  import { onMount } from "svelte"
  import DisplayPost from "./DisplayPost.svelte"

  export let auth
  export let hashtag = ""
  export let principal
  export let signIn
  export let feed = []
  export let user = null

  const getPostsByTag = async () => {
    feed = await $auth.actor.getFullPostsByTag(hashtag)
    if ("ok" in feed) {
      feed = feed["ok"].map((p) => p["v3"])
      feed = feed.reverse()
    }
  }

  onMount(getPostsByTag)
</script>

<div class="outer-container">
  <div class="inner-container" style="justify-content: left;">
    <h3 class="headline" style="padding-left: 10px">Hashtag #{hashtag}</h3>
  </div>
</div>

<div class="outer-container">
  {#each feed as post, i}
    {#if post}
      <div class="inner-container">
        <DisplayPost
          {auth}
          {principal}
          {user}
          {signIn}
          {post}
          refresh={null}
          setPreview={null}
        />
      </div>
    {/if}
  {/each}
</div>
