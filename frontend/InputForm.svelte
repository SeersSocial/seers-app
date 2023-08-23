<script lang="ts">
  import Fa from "svelte-fa"
  import { faChartBar, faImage } from "@fortawesome/free-regular-svg-icons"
  import {
    faPlus,
    faMoneyBillTransfer,
    faCoins,
    faCirclePlus,
    faPlusCircle,
    faHardOfHearing,
    faFilePdf,
  } from "@fortawesome/free-solid-svg-icons"

  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import { splitCamelCaseToString } from "./utils/utils"
  import { loggedUser } from "./store/stores"

  import PostForm from "./PostForm.svelte"
  import MarketForm from "./MarketForm.svelte"
  // import BetForm from "./bets/BetForm.svelte"
  import TransferForm from "./TransferForm.svelte"
  import ImageForm from "./ImageForm.svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import PdfForm from "./PdfForm.svelte"

  export let auth
  export let principal
  export let signIn
  export let getFeed
  export let user = $loggedUser
  export let setPreview
  export let parent
  export let isReply = false

  let state = "post"
  let description = ""
  let imageInput = ""

  let processing = false
  let errorResponse = ""

  let postform
  let imageform
  let pdfform
  let marketform
  let betform
  let transferform
</script>

<div style="width: 100%;">
  {#if state == "post"}
    <PostForm bind:this={postform} {auth} {principal} {user} {isReply} />
  {:else if state == "market"}
    <MarketForm bind:this={marketform} {auth} {principal} {user} />
  {:else if state == "transfer"}
    <TransferForm bind:this={transferform} {auth} {user} {principal} />
  {:else if state == "image"}
    <ImageForm bind:this={imageform} {auth} {principal} {user} />
    <!-- {:else if state == "pdf"}
    <PdfForm bind:this={pdfform} {auth} {principal} {user} /> -->
  {/if}
  <div
    style="display:flex; height: 80px; align-items:center; margin-left: 60px;"
  >
    <div
      class="feed-icon"
      on:click|stopPropagation={() => {
        if (state == "image") {
          state = "post"
        } else {
          state = "image"
        }
      }}
    >
      <!-- <label for="file-input-{parent?.id}"> -->
      <Fa icon={faImage} scale={1} />
      <!-- </label> -->
    </div>
    <!-- <input
      id="file-input-{parent?.id}"
      class="file-input"
      alt=""
      type="file"
      bind:value={imageInput}
      on:change={async (event) => {
        await imageform.uploadFiles(event.target.files)
      }}
      multiple
      accept="image/x-png,image/jpeg,image/gif,image/svg+xml,image/webp"
    /> -->

    <!-- <div
      class="feed-icon"
      on:click|stopPropagation={() => {
        if (state == "market") {
          state = "post"
        } else {
          state = "market"
        }
      }}
    >
      <Fa icon={faChartBar} scale={1} />
    </div> -->
    <!-- <div
      class="feed-icon"
      on:click={() => {
        state = "bet"
      }}
    >
      <Fa icon={faCoins} scale={1} />
    </div> -->
    <div
      class="feed-icon"
      on:click|stopPropagation={() => {
        if (state == "transfer") {
          state = "post"
        } else {
          state = "transfer"
        }
      }}
    >
      <Fa icon={faMoneyBillTransfer} scale={1} />
    </div>
    <!-- <div
      class="feed-icon"
      on:click|stopPropagation={() => {
        if (state == "pdf") {
          state = "post"
        } else {
          state = "pdf"
        }
      }}
    >
      <Fa icon={faFilePdf} scale={1} />
    </div> -->
    <div
      style="display:flex; margin: 10px; padding: 5px; flex-grow:1; justify-content: flex-end"
    >
      <DisplayButton
        label={isReply ? "Reply" : "Post"}
        {principal}
        {signIn}
        execute={async () => {
          if (state == "market") {
            let [preview, promise] = await marketform.submitMarket(parent)
            state = "post"
            setPreview(preview)
            const resp = await promise
            if (resp["err"]) {
              errorResponse =
                "Error: " +
                splitCamelCaseToString(Object.keys(resp["err"]).toString())
            }
          } else if (state == "image") {
            let [preview, promise] = await imageform.submitImage(parent)
            state = "post"
            setPreview(preview)
            await promise
          } else if (state == "pdf") {
            let [preview, promise] = await pdfform.submitPdf(parent)
            state = "post"
            setPreview(preview)
            await promise
          } else if (state == "transfer") {
            let [preview, transPromise, postPromise] =
              await transferform.submitTransfer(parent)
            state = "post"
            setPreview(preview)
            let tresp = await transPromise
            console.log(tresp)
            if ("ok" in tresp) {
              await postPromise()
            }
          } else if (state == "bet") {
            await betform.submitBet()
          } else {
            let [preview, promise] = await postform.submitPost(parent)
            setPreview(preview)
            await promise
          }
          await getFeed()
        }}
        {processing}
      />
    </div>
  </div>
  <div style="color:red">
    {errorResponse}
  </div>
</div>
