<script>
  import { onMount } from "svelte"
  import DisplayPost from "./DisplayPost.svelte"
  import inf from "./assets/inf.gif"

  export let auth
  export let principal
  export let signIn

  let user = null
  let processing = false
  let markets = []
  let posts = []

  const printFloat = (x) => {
    if (x > 10000) {
      return (Number(x) / 1000.0).toFixed(2) + "k"
    } else {
      return Number(x).toFixed(2)
    }
  }

  const getUser = async () => {
    if (principal !== "") {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
      }
    }
  }

  const readMarkets = async () => {
    if (principal === "") {
      setTimeout(readMarkets, 500)
    } else {
      processing = true
      markets = await $auth.actor.readFIFAMarkets()
      for (const market of markets) {
        let postId = Number(market.comments[0].id)
        let post = null
        const resp = await $auth.actor.getThread(postId)
        if ("ok" in resp) {
          post = resp["ok"].main[0]["v3"]
          post.market = resp["ok"].main[1]
          post.simpleMarket = resp["ok"].main[2]

          posts.push(post)
        }
      }

      processing = false
      setTimeout(getUser, 500)
    }
  }

  onMount(readMarkets)
</script>

<div class="outer-container">
  <div class="inner-container" style="justify-content: left;">
    <h3 class="headline" style="padding-left: 10px">FIFA World Cup 2022</h3>
  </div>
  <img
    src="https://assets.khelnow.com/news/uploads/2022/08/fifa-world-cup-22.jpg"
    alt="fifa2022"
    style="width: 100%;"
  />
</div>

<div class="outer-container">
  <div class="inner-container">
    {#if !processing && markets.length > 0}
      {#each posts as post}
        <div class="inner-container">
          <DisplayPost
            {user}
            {auth}
            {principal}
            {signIn}
            {post}
            setPreview={null}
            refresh={readMarkets}
          />
        </div>
      {/each}
    {:else if !processing}
      There are no new markets
    {:else}
      <img src={inf} alt="inf" style="width: 150px; height: 400%;" />
    {/if}
  </div>
</div>
