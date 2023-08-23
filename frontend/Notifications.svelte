<script>
  import { onMount } from "svelte"
  import DisplayPost from "./DisplayPost.svelte"
  import inf from "./assets/inf.gif"

  export let auth
  export let principal
  export let signIn

  let user = null
  let processing = false
  let notifications = []

  const getUser = async () => {
    if (principal !== "") {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
      }
    }
  }

  const readNotifications = async () => {
    if (principal === "") {
      setTimeout(readNotifications, 500)
    } else {
      processing = true
      notifications = await $auth.actor.readNotifications()
      processing = false
      if ("ok" in notifications) {
        notifications = notifications["ok"].reverse()
        notifications = notifications.map((noti) => {
          let post = noti["v0"]["reply"]
          post.retweet = []
          post.replies = []
          post.retweeters = []
          post.likes = []
          return post
        })
      }
      await $auth.actor.updateNotifications()
      setTimeout(getUser, 500)
    }
  }

  onMount(readNotifications)
</script>

<div class="outer-container">
  <div class="inner-container" style="justify-content: left;">
    <h3 class="headline" style="padding-left: 10px">Notifications</h3>
  </div>
</div>

<div class="outer-container">
  <div class="inner-container">
    {#if notifications.length > 0}
      {#each notifications as post, i}
        <DisplayPost
          {auth}
          {principal}
          {user}
          {signIn}
          {post}
          refresh={readNotifications}
          setPreview={(preview) => {}}
        />
      {/each}
    {:else if !processing}
      There are no new notifications
    {:else}
      <img src={inf} alt="inf" style="width: 150px; height: 400%;" />
    {/if}
  </div>
</div>
