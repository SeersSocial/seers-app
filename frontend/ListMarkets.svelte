<script lang="ts">
  import { onMount } from "svelte"
  import inf from "./assets/inf.gif"

  export let auth

  const PAGE_SIZE = 20

  let markets = []
  let categorySelected = "any"
  let stateSelected = "any"
  let processing = false
  var countdownStr = ""
  
  function countdown(datetime) {
    // Set the date we're counting down to
    var countDownDate = new Date(datetime).getTime();

    // Update the count down every 1 second
    var x = setInterval(function() {

      // Get today's date and time
      var now = new Date().getTime();
        
      // Find the distance between now and the count down date
      var distance = countDownDate - now;
      
      // Time calculations for days, hours, minutes and seconds
      var days = Math.floor(distance / (1000 * 60 * 60 * 24));
      var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);
      
      // Output the result in an element with id="demo"
      countdownStr = days + "d " + hours + "h "
      + minutes + "m " + seconds + "s ";
      // If the count down is over, write some text 
      if (distance < 0) {
        clearInterval(x);
        countdownStr = "Expired";
      }

    }, 1000);
  }


  const runOnMount = async () => {
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
  }

  const printFloat = (x) => {
    if (x > 10000) {
      return (Number(x) / 1000.0).toFixed(2) + "k"
    } else {
      return Number(x).toFixed(2)
    }
  }

  onMount(runOnMount)
</script>

<div class="outer-container">
  <div class="header">
    <h3>Prediction Markets</h3>
  </div>
  {#if markets.length > 0}
    <!-- <div
      style="width: 100%; display:flex; justify-content:center; align-items:center"
    >
      <div style="margin-right: 30px;">
        <select bind:value={categorySelected} on:change={runOnMount}>
          <option value="any">All</option>
          <option value="crypto">Crypto</option>
          <option value="sports">Sports</option>
          <option value="politics">Politics</option>
          <option value="entertainment">Entertainment</option>
          <option value="science">Science</option>
          <option value="business">Business</option>
          <option value="finance">Finance</option>
          <option value="seers">Seers</option>
          <option value="dfinity">Internet Computer</option>
          <option value="self">Self Referential</option>
        </select>
      </div>
      <div>
        <select bind:value={stateSelected} on:change={runOnMount}>
          <option value="any">All</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="open">Open</option>
          <option value="closed">Closed</option>
          <option value="resolved">Resolved</option>
          <option value="invalid">Invalid</option>
        </select>
      </div>
    </div> -->
    {#each markets as market}
      {#if !("resolved" in market.state)}
        <div class="responsiveItem">
          <a href="market/{market.id}">
            <div class="gallery">
              <div>
                {#if market.imageUrl.length > 10}
                  <img src={market.imageUrl} alt="random" />
                {/if}
              </div>
              <div class="content">
                <h4 style="padding-top: 0;margin-top:0">
                  {market.title}
                </h4>
                <div
                  style="margin-top: 10px; margin-bottom: 10px; max-height: 80px; overflow:hidden;"
                >
                  {#each market.labels as label, i}
                    <div style="width: 100%; display: flex; font-size: 1em;">
                      <div style="width: 50%">{label}</div>
                      <div style="width: 50%">
                        {(Number(market.probabilities[i]) / 10_000).toFixed(2)}
                        {"seers" in market.collateralType ? "Σ" : "ICP"}
                      </div>
                    </div>
                  {/each}
                </div>
                <div
                  style="width: 100%; display: flex; flex-direction: row; font-size: 1em; padding-top: 5px"
                >
                  <div style="width: 50%; ">
                    Vol: {printFloat(Number(market.volume) / 100_000_000)}
                    {"seers" in market.collateralType ? "Σ" : "ICP"}
                  </div>
                  <div style="width: 50%">
                    Liq: {printFloat(Number(market.liquidity) / 100_000_000)}
                    {"seers" in market.collateralType ? "Σ" : "ICP"}
                  </div>
                </div>
                <div
                  style="width: 100%; display: flex; flex-direction: row; font-size: 1em; padding-top: 5px"
                >
                  Ends: {new Date(parseInt(market.endDate) / 1_000_000).toLocaleString()}
                </div>
              </div>
            </div>
          </a>
        </div>
      {:else}
        <div class="responsiveItem">
          <a href="market/{market.id}">
            <div class="gallery">
              <div>
                {#if market.imageUrl.length > 10}
                  <img
                    src={market.imageUrl}
                    alt="random"
                    style="filter: brightness(50%);"
                  />
                {/if}
              </div>
              <div class="content-resolved">
                <h4 style="padding-top: 0;margin-top:0">
                  {market.title}
                  <span style="color: hotpink;">
                    Resolved to {market.labels[market.state["resolved"]].slice(
                      0,
                      20,
                    )}
                  </span>
                </h4>
                <div
                  style="margin-top: 10px; margin-bottom: 10px; max-height: 80px; overflow:hidden;"
                >
                  {#each market.labels as label, i}
                    <div style="width: 100%; display: flex; font-size: 1em;">
                      <div style="width: 50%">{label}</div>
                      <div style="width: 50%">
                        {(Number(market.probabilities[i]) / 10_000).toFixed(2)}
                        {"seers" in market.collateralType ? "Σ" : "ICP"}
                      </div>
                    </div>
                  {/each}
                </div>
                <div
                  style="width: 100%; display: flex; flex-direction: row; font-size: 1em; padding-top: 5px"
                >
                  <div style="width: 50%; ">
                    Vol: {printFloat(Number(market.volume) / 100_000_000)}
                    {"seers" in market.collateralType ? "Σ" : "ICP"}
                  </div>
                  <div style="width: 50%">
                    Liq: {printFloat(Number(market.liquidity) / 100_000_000)}
                    {"seers" in market.collateralType ? "Σ" : "ICP"}
                  </div>
                </div>
              </div>
            </div>
          </a>
        </div>
      {/if}
    {/each}
  {:else if processing}
    <div style="padding: 20px">
      <img src={inf} alt="inf" style="width: 150px; height: 150px;" />
    </div>
  {:else}
    <div class="inner-container">There are no markets.</div>
  {/if}
</div>

<style>
  .content {
    margin-left: 15px;
    width: 100%;
    min-height: 170px;
  }
  .content-resolved {
    margin-left: 15px;
    width: 100%;
    color: grey;
    min-height: 170px;
  }

  .rowList {
    display: flex;
    flex-wrap: wrap;
    padding: 0 4px;
    justify-content: center;
    width: 100%;
  }

  div.gallery {
    display: flex;
    padding: 2em;

    box-shadow: 1px 1px 2px 0.5px rgb(54, 27, 46);
    border: 1px solid rgb(61, 60, 61);
    border-radius: 16px;
  }

  img {
    max-width: 150px;
    height: auto;
  }

  div.desc {
    padding: 15px;
    text-align: center;
  }

  * {
    box-sizing: border-box;
  }

  .responsiveItem {
    float: left;
    width: 80%;
    max-width: 500px;
    margin: 1em;
  }

  @media only screen and (max-width: 1000px) {
    .responsiveItem {
      width: 80%;
    }
    .gallery {
      flex-direction: column;
    }

    .content {
      margin-left: 0;
      margin-top: 15px;
    }

    .content-resolved {
      margin-left: 0;
      margin-top: 15px;
    }
  }

  .clearfix:after {
    content: "";
    display: table;
    clear: both;
  }
</style>
