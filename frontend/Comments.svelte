<script lang="ts">
  import SvelteMarkdown from "svelte-markdown"
  import inf from "./assets/inf.gif"

  export let auth
  export let marketId
  export let readMarket
  export let comments = []
  export let signIn
  export let principal

  let processing = false
  let comment = ""
  let commentLabel = "Comment"
  let commentErrorResponse = ""

  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  const postComment = async () => {
    processing = true
    let response = await $auth.actor.addCommentToMarket(marketId, comment)

    if (response["err"]) {
      commentErrorResponse =
        "Error: " +
        splitCamelCaseToString(Object.keys(response["err"]).toString())
    } else {
      commentErrorResponse = ""
      readMarket()
      comment = ""
    }
    processing = false
  }
</script>

<div style="width: 100%">
  <h3 style="text-align:start">Comments</h3>
  <div style="text-align:start">
    <div class="comment-container">
      <textarea
        bind:value={comment}
        rows="5"
        style="height: auto; width: 95%; font-size: 1.3em;border: 0px solid rgb(61, 60, 61); padding: 10px"
        placeholder="Please share your thoughts."
      />
      <div style="display:flex; justify-content: right; width: 95%">
        {#if principal === ""}
          <button class="btn-grad" on:click={() => signIn()}> Login </button>
        {:else if processing}
          <button
            class="btn-grad"
            on:click={() => 0}
            style="width: 100px; overflow:hidden"
          >
            <img
              src={inf}
              alt="inf"
              style="width: 150px; height: 400%; margin: -75%;"
            />
          </button>
        {:else}
          <button class="btn-grad" on:click={postComment}>
            {commentLabel}
          </button>
        {/if}
      </div>
      <div style="width: 100%;text-align:center;color:red">
        {commentErrorResponse}
      </div>
    </div>
    {#each comments as comment}
      <div style="margin: 5px 0px">
        <div
          style="display:flex; gap: 20px; margin: 15px 0px; min-height: 100px"
        >
          <img
            src={comment.picture}
            alt="pic"
            style="width: 70px; height: 70px; border-radius: 50%"
          />
          <div>
            <div style="display:flex; gap: 10px">
              <div style="color:pink; padding: 0px 0px; font-weight:bold">
                {comment.handle}
              </div>
              <div style="color:grey; padding: 0px 0px">
                {new Date(
                  Number(comment.createdAt) / 1_000_000,
                ).toLocaleString()}
              </div>
            </div>
            <SvelteMarkdown source={comment.content} />
          </div>
        </div>
      </div>
    {/each}
  </div>
</div>
