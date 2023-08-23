<script>
  import { getContext } from "svelte"
  import inf from "./assets/inf.gif"
  import Fa from "svelte-fa"
  import { faXmarkCircle } from "@fortawesome/free-regular-svg-icons"

  import DisplayPost from "./DisplayPost.svelte"
  import InputForm from "./InputForm.svelte"
  import { identity } from "svelte/internal"
  import anon from "./assets/anon.png"

  export let post
  export let auth
  export let signIn
  export let principal
  export let user
  export let getFeed
  export let setPreview

  export let title
  export let message
  export let onCancel = () => {}
  export let onOkay = () => {}

  const { close } = getContext("simple-modal")

  let response = null
  let okLabel = "Okay"
  let processing = false
  let reply = ""

  let onChange = () => {}

  function _onCancel() {
    onCancel()
    close()
  }

  async function _onOkay() {
    processing = true
    response = await onOkay()
    processing = false
  }

  $: onChange()
</script>

<div style="">
  <button on:click={_onCancel}><Fa icon={faXmarkCircle} size="lg" /></button>
  <div class="inner-container" style="border: 0px">
    <DisplayPost
      {user}
      {auth}
      {principal}
      {signIn}
      {post}
      {setPreview}
      isThread={true}
      refresh={getFeed}
    />
    <InputForm
      {auth}
      {principal}
      {signIn}
      {user}
      {getFeed}
      isReply={true}
      parent={{ id: Number(post.id), author: post.author }}
      setPreview={(p) => {
        setPreview(p)
        close()
      }}
    />
  </div>
</div>

<style>
  h3 {
    text-align: center;
  }

  input {
    width: 100%;
  }

  .buttons {
    display: flex;
    width: 100%;
    justify-content: space-around;
  }
</style>
