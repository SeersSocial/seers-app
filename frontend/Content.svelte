<script>
  import { getContext } from "svelte"
  import Dialog from "./Dialog.svelte"
  import inf from "./assets/inf.gif"

  export let onOk
  export let tokensEstimate
  export let outcome
  export let seerAmount
  export let buttonLabel
  export let buyTokens
  export let processing

  const { open } = getContext("simple-modal")

  const onCancel = () => {}

  const onOkay = () => {
    return onOk()
  }

  const getMessage = () => {
    if (buyTokens) {
      return `Buying ${tokensEstimate.toFixed(
        2,
      )} shares of "${outcome}". Total cost is ${Number(seerAmount).toFixed(
        2,
      )} tokens`
    } else {
      return `Selling ${Number(seerAmount).toFixed(
        2,
      )} shares of "${outcome}". Receiving ${Number(tokensEstimate).toFixed(
        2,
      )} Σ`
    }
  }

  const showDialog = () => {
    open(
      Dialog,
      {
        title: "Confirm Transaction",
        message: getMessage(),
        hasForm: true,
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

<div
  style="width: 100%; justify-content: center; text-align: center; display: flex"
>
  {#if processing}
    <button
      class="btn-grad"
      on:click={() => 0}
      style="width: 150px; overflow:hidden"
    >
      <img
        src={inf}
        alt="inf"
        style="width: 150%; height: 400%; margin: -75%;"
      />
    </button>
  {:else}
    <button class="btn-grad" on:click={showDialog}>{buttonLabel}</button>
  {/if}
</div>

<style>
</style>
