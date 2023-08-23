<script lang="ts">
  import Content from "./Content.svelte"
  import Modal from "./Modal.svelte"
  import { modal } from "./store/stores.js"

  export let auth
  export let readMarket
  export let market
  export let principal
  export let selectedLabel
  export let signIn

  let tokensEstimate = 0.0
  let seerAmount = 0.0
  let response
  let errorResponse = ""
  let processing = false
  let buyOptClass = "BuyOptSelected"
  let sellOptClass = "SellOpt"

  let buttonLabel = "Buy"
  let selected = 0

  let buyTokens = true

  let typingTimer //timer identifier

  const debounce = (id, a, ms) => {
    tokensEstimate = 0
    clearTimeout(typingTimer)
    if (seerAmount) {
      typingTimer = setTimeout(() => dryRun(id, a), ms)
    }
  }

  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  const dryRun = async (marketId, amount) => {
    amount = parseInt(amount)
    processing = true
    if (buyTokens) {
      response = await $auth.actor.buyOutcome(marketId, amount, selected, false)
    } else {
      response = await $auth.actor.sellOutcome(
        marketId,
        amount,
        selected,
        false,
      )
    }
    processing = false

    if (response["err"]) {
      errorResponse =
        "Error: " +
        splitCamelCaseToString(Object.keys(response["err"]).toString())
    } else {
      errorResponse = ""
      tokensEstimate = response["ok"]
    }

    selectedLabel = market ? market.labels[selected].label : ""
  }

  const doIt = async (marketId, amount) => {
    errorResponse = ""
    buttonLabel = "Processing..."
    amount = parseInt(amount)

    if (buyTokens) {
      response = await $auth.actor.buyOutcome(marketId, amount, selected, true)
    } else {
      response = await $auth.actor.sellOutcome(marketId, amount, selected, true)
    }
    if (response["err"]) {
      errorResponse =
        "Error: " +
        splitCamelCaseToString(Object.keys(response["err"]).toString())
      tokensEstimate = 0.0
    } else {
      errorResponse = ""
      tokensEstimate = 0.0
    }
    if (buyTokens) buttonLabel = "Buy " + selectedLabel
    else buttonLabel = "Sell " + selectedLabel

    readMarket()

    return [errorResponse, tokensEstimate]
  }
</script>

<div
  style="margin: 0em 1em;display:flex; justify-content:start; flex-direction:column"
>
  {#if market}
    <div class="market-controls">
      <div
        style="display:flex; justify-content:start; text-align:center; align-items:center;flex-direction:column;padding: 10px; width: 200px"
      >
        <h4>Trade</h4>
        <div class="YesNoOptions">
          <div style="width: 70%">
            <button
              class={buyOptClass}
              on:click={() => {
                buyOptClass = "BuyOptSelected"
                sellOptClass = "SellOpt"
                buyTokens = true
                buttonLabel = "Buy " + selectedLabel
              }}>Buy</button
            >
            <button
              class={sellOptClass}
              on:click={() => {
                buyOptClass = "BuyOpt"
                sellOptClass = "SellOptSelected"
                buyTokens = false
                buttonLabel = "Sell " + selectedLabel
              }}>Sell</button
            >
          </div>
        </div>
        <div class="OutcomeTitle">Outcome:</div>
        <div class="ContentTab">
          <div style="width: 70%">
            <select
              bind:value={selected}
              style="width: 100%; height: 1.7em"
              on:change={() => {
                selectedLabel = market.labels[selected].label
                if (buyTokens) buttonLabel = "Buy " + selectedLabel
                else buttonLabel = "Sell " + selectedLabel
              }}
            >
              {#each market.labels as label, i}
                <option value={i}>
                  {label.label.slice(0, 20)}
                  ({Number(market.probabilities[i]).toFixed(2)} &Sigma;)
                </option>
              {/each}
            </select>
            <div class="OutcomeTitle">Amount:</div>
            <div class="OutcomeTitle">
              <input
                bind:value={seerAmount}
                on:keyup={() => debounce(market.id, seerAmount, 500)}
                placeholder="0"
                style="color: rgb(255, 255, 255); background-color: rgb(33, 36, 41); font-size: 1.2em; font-family: 'Roboto Mono', monospace; border: 0px; width: 100px"
              />
            </div>
            <div class="ControlData">
              <div>LP fee 0.00%</div>
              <div>
                {#if buyTokens}
                  Avg. price {tokensEstimate
                    ? (seerAmount / tokensEstimate).toFixed(2)
                    : 0} &Sigma;
                {:else}
                  Avg. price {tokensEstimate
                    ? (seerAmount / tokensEstimate).toFixed(2)
                    : 0} tokens
                {/if}
              </div>
              <div>
                {#if buyTokens}
                  Winnings {tokensEstimate
                    ? Number(tokensEstimate).toFixed(2)
                    : Number(0).toFixed(2)}
                  &Sigma;
                {:else}
                  Get back {tokensEstimate
                    ? Number(tokensEstimate).toFixed(2)
                    : Number(0).toFixed(2)} &Sigma;
                {/if}
              </div>
            </div>
            <div
              style="width: 100%; text-align: center; display: flex; flex-direction: column; justify-content: center"
            >
              {#if principal !== ""}
                <Modal show={$modal}>
                  <Content
                    onOk={async () => {
                      let res = await doIt(market.id, seerAmount)
                      seerAmount = 0.0
                      tokensEstimate = 0.0
                      return res
                    }}
                    {tokensEstimate}
                    {seerAmount}
                    outcome={selectedLabel}
                    {buttonLabel}
                    {buyTokens}
                    {processing}
                  />
                </Modal>
                <div
                  style="width: 100%;text-align:center;color:red;overflow:visible"
                >
                  {errorResponse}
                </div>
              {:else}
                <div
                  style="width: 100%; justify-content: center; text-align: center; display: flex"
                >
                  <button class="btn-grad" on:click={() => signIn()}>
                    Login
                  </button>
                </div>
              {/if}
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .OutcomeTitle {
    width: 100%;
    margin-top: 0.5em;
  }
  .YesNoOptions {
    width: 200px;
    display: flex;
    height: fit-content;
    justify-content: center;
  }
  .TabOptions {
    width: 200px;
    display: flex;
    margin-top: 0.5em;
    height: fit-content;
  }
  .ContentTab {
    width: 200px;
    display: flex;
    justify-content: center;
  }
  .BuyOpt {
    width: 50%;
    height: 30px;
    color: white;
    border-radius: 5px 0 0 5px;
    background: rgb(220 218 224 / 25%);
  }
  .SellOpt {
    width: 50%;
    height: 30px;
    color: white;
    border-radius: 0 5px 5px 0;
    background: rgb(220 218 224 / 25%);
  }
  .BuyOptSelected {
    width: 50%;
    height: 30px;
    color: black;
    background-color: white;
    border-radius: 5px 0 0 5px;
  }
  .SellOptSelected {
    width: 50%;
    height: 30px;
    background-color: white;
    border-radius: 0 5px 5px 0;
    color: black;
  }
  .YesTabSelected {
    width: 50%;
    height: fit-content;
    color: white;
    background-color: green;
  }
  .NoTabSelected {
    width: 50%;
    height: fit-content;
    color: white;
    background-color: crimson;
  }
  .YesTab {
    width: 50%;
    height: fit-content;
    color: black;
  }
  .NoTab {
    width: 50%;
    height: fit-content;
    color: black;
  }
</style>
