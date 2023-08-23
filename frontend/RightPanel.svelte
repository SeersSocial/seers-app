<script lang="ts">
  import { faBreadSlice } from "@fortawesome/free-solid-svg-icons"
  import { onMount } from "svelte"
  import inf from "./assets/inf.gif"

  export let auth

  let markets = []
  let categorySelected = "any"
  let stateSelected = "open"
  let processing = false
  let tvl = "0"
  let revenue = "0"

  const getMarkets = async () => {
    let category = {}
    let state = {}
    category[categorySelected] = null
    state[stateSelected] = null
    processing = true
    markets = await $auth.actor.readAllMarkets(category, state)
    markets = markets.sort((a, b) => {
      return Number(a.endDate - b.endDate)
    })
    processing = false

    tvl = await $auth.actor.readTotalICP()
    tvl = (Number(tvl) / 100_000_000.0).toFixed(2)

    revenue =  await $auth.actor.getRevenue()
    revenue = ((Number(revenue["ok"]) - 100_000_000_000.0) / 100_000_000.0).toFixed(2)

  }

  onMount(getMarkets)
</script>

<div
  style=" min-width:200px; max-width: 250px; display:flex;  margin-top: 15px;  border-radius:15px; flex-direction:column"
>
<h3>Stats</h3>
  <div style="padding-top: 5px">
    TVL: {tvl} ICP <br/>
  </div>
  <!-- <div style="padding-top: 5px">
    Revenue: 0 ICP
  </div>   -->
<h3>Prediction Markets</h3>
<div style="padding-top: 5px">
  No markets currently open.
</div>

  {#each markets as m}
    <div style="padding-top: 5px">
      <a href={`https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/market/` + m.id}
        >{m.title.slice(0, 30)}</a
      >
    </div>
  {/each}  
<h3>Note</h3>
<div style="padding-top: 5px">
  You need to have 1 ICP deposited in your account to be able to post content.

  Any misbehaviour (e.g. spamming) will be punished by slashing the ICP deposited.
</div>
</div>
