<script lang="ts">
  import { onMount } from "svelte"
  import { useNavigate } from "svelte-navigator"
  import inf from "./assets/inf.gif"

  import DisplayButton from "./DisplayButton.svelte"
  import DisplayPost from "./DisplayPost.svelte"

  export let id
  export let auth
  export let principal
  export let signIn

  const navigate = useNavigate()

  let content = ""
  let amount = 0.5
  let post
  let errorResponse = ""
  let processing = false
  let processingPost = false
  let picture = ""
  let handle = ""
  let name = ""

  const getPost = async () => {
    processingPost = true
    const resp = await $auth.actor.getThread(Number(id))
    if ("ok" in resp) {
      post = resp["ok"]["main"][0]["v3"]
      post.market = resp["ok"]["main"][1]
      post.simpleMarket = resp["ok"]["main"][2]
    }
    processingPost = false
  }

  onMount(getPost)
</script>

<div class="outer-container">
  <div class="inner-container">
    <div
      style="justify-content: center; display: flex;width: 100%; flex-direction:column; align-items:center;"
    >
      <div
        id="main"
        style="padding: 0px 0px 0px 0px; width: 100%; border: 0px solid grey; "
      >
        {#if processingPost}
          <img src={inf} alt="inf" style="width: 150px; height: 150px;" />
        {:else}
          <DisplayPost
            {auth}
            {principal}
            {signIn}
            {post}
            isMain={true}
            isEditing={true}
            refresh={getPost}
          />
        {/if}
      </div>
    </div>
  </div>
</div>

<style>
  .menu-button-elli {
    width: 10px;
    justify-content: start;
    text-align: start;
    padding: 0px 0px;
    cursor: pointer;
  }

  .menu-button-elli:hover {
    color: #1da1f2;
  }

  .like-bt {
    all: unset;
    cursor: pointer;
  }
  .like-bt:hover {
    color: rgb(249, 24, 128);
  }

  .retweet-bt {
    all: unset;
    cursor: pointer;
  }
  .retweet-bt:hover {
    color: #19cf86;
  }

  .reply-bt {
    all: unset;
    cursor: pointer;
  }
  .reply-bt:hover {
    color: #1da1f2;
  }
</style>
