<script lang="ts">
  import { onMount } from "svelte"
  import SvelteMarkdown from "svelte-markdown"
  import Chart from "chart.js/auto"
  import DisplayPost from "./DisplayPost.svelte"
  import Trade from "./Trade.svelte"
  import Forecast from "./Forecast.svelte"
  import Comments from "./Comments.svelte"

  export let auth
  export let id
  export let principal
  export let signIn

  let market
  let marketId
  let selectedLabel
  let comments
  let myChart
  let post
  let user

  const createChart = () => {
    if (myChart) myChart.destroy()
    const ctx = document.getElementById("myChart") as HTMLCanvasElement
    const backgrounds = [
      "rgba(54, 162, 235, 0.2)",
      "rgba(255, 99, 132, 0.2)",
      "rgba(255, 206, 86, 0.2)",
      "rgba(75, 192, 192, 0.2)",
      "rgba(153, 102, 255, 0.2)",
      "rgba(255, 159, 64, 0.2)",
    ]
    const borders = [
      "rgba(54, 162, 235, 1)",
      "rgba(255, 99, 132, 1)",
      "rgba(255, 206, 86, 1)",
      "rgba(75, 192, 192, 1)",
      "rgba(153, 102, 255, 1)",
      "rgba(255, 159, 64, 1)",
    ]

    if (market) {
      if (market.histPrices.length == 1) {
        market.histPrices.push(market.histPrices[0])
      }
      const datasets = market.labels.map((label, idx) => {
        return {
          label: label.label,
          data: market.histPrices.map(
            (point) => Number(point.probabilities[idx]) / 100.0,
          ),
          backgroundColor: [backgrounds[idx]],
          borderColor: [borders[idx]],
          borderWidth: 1,
        }
      })

      const dates = market.histPrices.map((point) =>
        new Date(Number(point.createdAt) / 1_000_000).toLocaleDateString(),
      )

      myChart = new Chart(ctx, {
        type: "line",
        data: {
          labels: dates,
          datasets: datasets,
        },
        options: {
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      })
    }
  }

  const readMarket = async () => {
    market = await $auth.actor.readMarket(parseInt(id))
    if (market) {
      market = market[0]
      if (market) {
        market.labels = market.labels.map((label) => {
          return { label, value: 0.0 }
        })
        createChart()
      }
    }
    let postId = Number(market.comments[0].id)

    const resp = await $auth.actor.getThread(postId)
    if ("ok" in resp) {
      post = resp["ok"].main[0]["v3"]
      post.market = resp["ok"].main[1]
      post.simpleMarket = resp["ok"].main[2]
    }

    if (principal !== "") {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
      }
    }
  }

  const printFloat = (x) => {
    if (x > 10000) {
      return (Number(x) / 1000.0).toFixed(2) + "k"
    } else {
      return Number(x).toFixed(2)
    }
  }

  onMount(readMarket)
</script>

<div class="outer-container">
  <div class="inner-container">
    <div
      style="display:flex; flex-direction: row; justify-content:start; text-align:center; width: 100%"
    >
      <div style="width: 100%">
        <h3>{market ? market.title : ""}</h3>

        <div style="width: 100%">
          <div
            style="display:flex; margin: 0; padding: 10px; width: 100%; line-height: 1.5em; gap: 10px; color:gray"
          >
            <div style="width: 20%">
              <div>Status</div>
              <div>{market ? Object.keys(market?.state).toString() : ""}</div>
            </div>
            <div style="width: 20%">
              <div>Starts</div>
              <div>
                {new Date(
                  parseInt(market?.startDate) / 1_000_000,
                ).toLocaleString()}
              </div>
            </div>
            <div style="width: 20%">
              <div>Ends</div>
              <div>
                {new Date(parseInt(market?.endDate) / 1_000_000).toLocaleString()}
              </div>
            </div>
            <div style="width: 20%">
              <div>Volume</div>
              <div>
                {printFloat(Number(market?.volume) / 100_000_000)}
                {market && "seers" in market.collateralType ? "Σ" : "ICP"}
              </div>
            </div>
            <div style="width: 20%">
              <div>Liquidity</div>
              <div>
                {printFloat(Number(market?.liquidity) / 100_000_000)}
                {market && "seers" in market.collateralType ? "Σ" : "ICP"}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div style="display:flex;margin-top: 50px; width: 100%">
      <div style="width: 100%">
        <canvas id="myChart" />
      </div>
    </div>
  </div>
  <div class="inner-container">
    <DisplayPost
      {user}
      {auth}
      {principal}
      {signIn}
      {post}
      setPreview={null}
      refresh={readMarket}
    />
  </div>
</div>

<style global>
  .comment-container {
    margin: 25px 0px 5px 0px;
    width: 100%;
    align-items: center;
  }
  .comment-input {
    width: 100%;
    height: 30px;
    padding: 15px;
    border: hidden;
    border-radius: 20px;
    min-width: 200px;
  }

  select:focus,
  textarea:focus,
  input:focus {
    outline: none;
  }
  select {
    border: 1px solid rgb(61, 60, 61);
    height: 30px;
    font-size: 1.2em;
    text-align: center;
    width: fit-content;
    padding: 5px;
  }
  .header {
    display: flex;
    text-align: center;
    justify-content: center;
    width: 100%;
    outline: none;
  }

  h3 {
    outline: none;
  }

  .rowView {
    display: flex;
    flex-wrap: wrap;
    /* padding-top: 40px; */
    justify-content: center;
    width: 100%;
  }

  .menu-button {
    background: rgb(220 218 224 / 25%);
    padding: 5px;
    margin: 3px 0px;
    border-radius: 5px;
    font-size: 1em;
    height: 33px;
    border: 0;
    align-items: center;
    text-align: center;
    border-color: white;
    cursor: pointer;
    text-decoration: none;
  }

  .menu-button-selected {
    color: white;
    background: rgba(12, 3, 43, 0.9);
    padding: 5px;
    margin: 3px 0px;
    border-radius: 5px;
    font-size: 1em;
    height: 33px;
    border: 0;
    align-items: center;
    text-align: center;
    border-color: white;
    cursor: pointer;
    text-decoration: none;
  }

  button {
    color: white;
    border: none;
    padding: 3px;
  }

  body.light-mode button {
    color: black;
    border: none;
    padding: 3px;
  }

  .Image {
    border-radius: 8px;
    width: 150px;
    float: left;
    padding: 0px 10px 10px 0px;
  }

  .ControlData {
    margin-top: 0.5em;
  }

  .container {
    display: flex;
    justify-content: center;
  }
  .v-container {
    display: flex;
    flex-direction: column;
    justify-content: start;
    margin: 0em 1em;
  }
  .market-comments {
    display: flex;
    flex-direction: column;
    max-width: 40%;
    min-width: 400px;
    margin-bottom: 1em;
    overflow: auto;
    flex-direction: column;
    height: fit-content;
    margin: 0em 1em;
    /* padding: 2em; */
    word-wrap: break-word;
    justify-content: space-between;
  }

  .market {
    padding: 2em;

    box-shadow: 2px 2px 20px 0.5px rgb(54, 27, 46);
    background-color: rgb(25, 27, 31);
    border: 1px solid rgb(61, 60, 61);

    /* border: 2px solid rgb(25, 27, 31); */
    border-radius: 16px;
    color: rgb(255, 255, 255);
    justify-content: space-between;
    font-family: "Inter", sans-serif;
    margin: 0em 1em;
    word-wrap: break-word;
    /* overflow: auto; */
    flex-direction: column;
    height: fit-content;
    /* width: max-content; */
    /* min-width: 400px;
    max-width: 100%;*/
    margin-bottom: 1em;
  }

  @media only screen and (max-width: 1100px) {
    .market {
      margin: 1em;
      display: flex;
      flex-direction: column;
      justify-content: center;
      /* width: 300px;
      min-width: 0px;
      max-width: 80%; */
    }

    .market-comments {
      width: 330px;
      max-width: 80%;
      min-width: 0px;
    }

    .comment-container {
      flex-direction: column;
      display: flex;
    }
  }

  .market-controls {
    box-shadow: 2px 2px 20px 0.5px rgb(54, 27, 46);
    margin: 1em;
    padding: 10px 30px;
    background-color: rgb(25, 27, 31);
    border: 1px solid rgb(61, 60, 61);
    border-radius: 16px;
    justify-content: space-between;
    font-family: "Inter", sans-serif;
    font-size: 1rem;
    font-weight: 500;
    word-break: break-word;
    overflow: hidden;
    white-space: nowrap;
    height: fit-content;
    border-radius: 1em;
    word-wrap: break-word;
    overflow: auto;
    display: flex;
    justify-content: center;
  }
  .MarketDetails {
    display: flex;
    justify-content: center;
    align-items: flex-start;
  }

  .MarketHeader {
    display: flex;
    align-items: flex-start;
    justify-content: flex-start;
    text-align: start;
  }

  .App-logo {
    height: 15vmin;
    pointer-events: none;
  }

  .App-header {
    margin-top: 150px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    font-size: calc(10px + 2vmin);
  }

  .App-link {
    color: rgb(26, 117, 255);
  }
</style>
