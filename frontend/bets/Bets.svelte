<script lang="ts">
  import { onMount } from "svelte"

  import DisplayBet from "./DisplayBet.svelte"

  export let auth
  export let principal
  export let signIn

  let bets = []
  let processing = false

  const getBets = async () => {
    processing = true
    bets = await $auth.actor.readAllBets()
    processing = false
    bets = bets.reverse()
  }

  onMount(getBets)
</script>

<div class="outer-container">
  <div class="header">
    <h3>Bets</h3>
  </div>

  <div class="inner-container">
    {#if bets.length > 0}
      {#each bets as bet, i}
        <DisplayBet
          {auth}
          {principal}
          {signIn}
          {bet}
          doNotShowBorder={i < bets.length - 1 ? false : true}
          refresh={getBets}
        />
      {/each}
    {:else if processing}
      Loading
    {:else}
      There are no bets.
    {/if}
  </div>
</div>
