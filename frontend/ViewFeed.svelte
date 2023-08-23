<script lang="ts">
  import { onMount } from "svelte"
  import {
    userMap,
    setUserMapStore,
    pageType,
    userToView,
    postToView,
    loggedUser,
  } from "./store/stores"

  import Feed from "./Feed.svelte"

  export let auth
  export let principal
  export let signIn

  let feedcomp
  let feed = []
  $: user = $loggedUser

  export const showFeed = () => {
    $postToView = null
    $userToView = null
    $pageType = 0
  }

  const getFeed = async () => {
    ;[feed, user] = await feedcomp.getFeed()
    if ($userMap == null) await setUserMapStore($auth)
  }

  onMount(getFeed)
</script>

<Feed
  bind:this={feedcomp}
  {auth}
  {principal}
  {signIn}
  viewpost={(post) => {
    $postToView = post
    $pageType = 1
  }}
  viewuser={(handle) => {
    $userToView = $userMap[handle]
    $pageType = 2
  }}
  {feed}
  {user}
/>
