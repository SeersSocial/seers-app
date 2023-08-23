<script>
  import { getContext } from "svelte"
  import inf from "./assets/inf.gif"

  export let title
  export let message
  export let onCancel = () => {}
  export let onOkay = () => {}

  const { close } = getContext("simple-modal")

  let response = null
  let okLabel = "Okay"
  let processing = false

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

{#if !response}
  <h3>{title}</h3>
{:else}
  <h3>Transaction Response</h3>
{/if}

{#if !response}
  <div style="width: 100%; text-align: center">{message}</div>
{/if}
{#if response && response.length == 2}
  <div style="width: 100%; text-align: center">
    {response[0] ? response[0] : "Transaction successful!"}
  </div>
{/if}

<div class="buttons">
  <button class="btn-grad" on:click={_onCancel}> Close</button>
  {#if !response}
    {#if processing}
      <button
        class="btn-grad"
        on:click={() => 0}
        style="width: 100px;overflow:hidden"
      >
        <img
          src={inf}
          alt="inf"
          style="width: 150px; height: 400%; margin: -75%;"
        />
      </button>
    {:else}
      <button class="btn-grad" on:click={_onOkay}>{okLabel}</button>
    {/if}
  {/if}
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
