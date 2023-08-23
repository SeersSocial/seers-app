
<script>
  import { getContext } from "svelte"
  import ReplyDialog from "./ReplyDialog.svelte"
  import inf from "./assets/inf.gif"

  import Fa from "svelte-fa"
  import { faComment } from "@fortawesome/free-regular-svg-icons"

  export let post
  export let auth
  export let signIn
  export let principal
  export let user
  export let getFeed
  export let setPreview

  const { open } = getContext("simple-modal")

  const onCancel = () => {}

  const onOkay = () => {
    // return onOk()
  }

  const getMessage = () => {}

  const showDialog = () => {
    open(
      ReplyDialog,
      {
        title: "Confirm Transaction",
        message: getMessage(),
        hasForm: true,
        post,
        auth,
        signIn,
        principal,
        user,
        getFeed,
        setPreview,
        onCancel,
        onOkay,
      },
      {
        closeButton: false,
        closeOnEsc: false,
        closeOnOuterClick: false,
      },
    )
  }
</script>

<button class="reply-bt" on:click|stopPropagation={showDialog}
  ><Fa icon={faComment} /></button
>
