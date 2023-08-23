<script lang="ts">
  import { faBreadSlice } from "@fortawesome/free-solid-svg-icons"

  import { onMount } from "svelte"
  export let auth

  let payments = []
  let queueError = ""
  let processing = false

  let getPayments = async () => {
    processing = true
    payments = await $auth.actor.getPayments()
    queueError = await $auth.actor.getPaymentsError()
    processing = false
  }

  onMount(getPayments)
</script>

<div class="header">
  <h3>Payments Queue ({queueError})</h3>
</div>

<div style="justify-content: center; display: flex;width: 100%">
  {#if payments.length > 0}
    <div class="ranking">
      <div class="row">
        <div
          style="width: 10%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          #
        </div>
        <div
          style="width: 20%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          From
        </div>
        <div
          style="width: 20%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          To
        </div>
        <div
          style="width: 20%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          Amount
        </div>
        <div
          style="width: 20%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          Token
        </div>
        <div
          style="width: 10%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          Status
        </div>
      </div>
      {#each payments as p, i}
        <div class="row">
          <div style="width: 10%;margin: 3px">{i}</div>
          <div style="width: 20%;margin: 3px">
            {p.from}
          </div>
          <div style="width: 20%;margin: 3px">
            {p.to}
          </div>
          <div style="width: 20%;margin: 3px">
            {(Number(p.amount) / 100_000_000).toFixed(4)}
          </div>
          <div style="width: 20%;margin: 3px">
            {"seers" in p.collateralType ? "Seers" : "ICP"}
          </div>
          <div style="width: 10%;margin: 3px">
            {p.processed}
          </div>
        </div>
      {/each}
    </div>
  {:else if processing}
    <div class="ranking">Loading</div>
  {:else}
    <div class="ranking">There are no tasks</div>
  {/if}
</div>

<style>
  .row {
    display: flex;
    width: 100%;
  }
  .row:hover {
    background-color: hotpink;
  }
  .ranking {
    display: flex;
    flex-wrap: wrap;
    padding: 1em;
    justify-content: start;
    min-width: 50%;
    max-width: 800px;
    border: 1px solid rgb(61, 60, 61);
    border-radius: 16px;
    justify-content: center;
  }
</style>
