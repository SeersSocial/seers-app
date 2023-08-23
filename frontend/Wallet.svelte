<script lang="ts">
  import { onMount } from "svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import Fa from "svelte-fa"
  import inf from "./assets/inf.gif"

  import { faClipboard } from "@fortawesome/free-regular-svg-icons"
  import {
    faArrowUpFromBracket,
  } from "@fortawesome/free-solid-svg-icons"
  
  export let auth
  export let principal
  export let signIn

  let user = null
  let createLabel = "Create User"
  let handle = ""
  let response = null
  let errorResponse = ""
  let errorRefresh = ""
  let refreshLabel = "Refresh"
  let isGetting = false
  let processing = false
  let processingReward = false
  var markets = {}
          
  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  const getMarketLabel = (id, idx) => {
    let market = user.markets.find((m) => m.marketId == id)
    if (market) {
      return market.labels[idx]
    } else {
      return "Null"
    }
  }

  // let getAccount = async () => {
  //   const userAccount = await $auth.actor.getUserAccount(principal)
  // }

  let getUserData = async () => {
    if (principal === "") {
      setTimeout(getUserData, 500)
    } else {
      const response = await $auth.actor.readMarketsState()
          
      for (let m of response) {
        markets[m[0]] = m
      }
      
      // await getAccount()
      isGetting = true
      user = await $auth.actor.getUserStable(principal)
      isGetting = false
      if (user) {
        user = user[0]["v4"]
        if (user) {
          user.markets = user.markets.sort(function (a, b) {
            var keyA = Number(a.marketId),
              keyB = Number(b.marketId)
            if (keyA < keyB) return -1
            if (keyA > keyB) return 1
            return 0
          })


          // user.ownMarkets = user.markets.filter((m) => m.author)
          // user.otherMarkets = user.markets.filter((m) => !m.author)
          user.txs = user.txs.reverse()

          
          for (let i = 0; i < user.markets.length; i++) {
            const idx = Number(user.markets[i].marketId)
            if (idx in markets)
              markets[idx].labels = user.markets[i].labels
          }
        }
      }
    }
  }

  let refreshUser = async () => {
    refreshLabel = "Processing..."
    response = await $auth.actor.refreshUser()
    if (response["err"]) {
      errorRefresh =
        "Error: " +
        splitCamelCaseToString(Object.keys(response["err"]).toString())
    } else {
      errorRefresh = ""
      user = response["ok"]["v4"]
      if (user) {
        user.markets = user.markets.sort(function (a, b) {
          var keyA = Number(a.marketId),
            keyB = Number(b.marketId)
          if (keyA < keyB) return -1
          if (keyA > keyB) return 1
          return 0
        })
        // user.ownMarkets = user.markets.filter((m) => m.author)
        // user.otherMarkets = user.markets.filter((m) => !m.author)
        user.txs = user.txs.reverse()
      }
    }
    refreshLabel = "Refresh"
  }
  function myFunction() {
    var copyText = document.getElementById("myInput")
    navigator.clipboard.writeText(user.depositICPaddr.toLowerCase())

    var tooltip = document.getElementById("myTooltip")
    tooltip.innerHTML = "Copied!"
  }

  function outFunc() {
    var tooltip = document.getElementById("myTooltip")
    tooltip.innerHTML = "Click to copy to clipboard"
  }

  onMount(getUserData)
  // afterUpdate(getUserData)
</script>

<div style="justify-content: center; display: flex;width: 100%">
  <div
    class="inner-container"
    style="flex-direction:row; justify-content:center"
  >
    <div class="header">
      <h3>Wallet</h3>
    </div>

    {#if user}
      <div style="border-bottom: 1px solid grey; padding: 20px">
        <div style="margin-bottom: 10px; width: 100%; text-align:center">
          Principal: (do NOT send ICP here)<br />{user.id}
        </div>
        <div style="margin-bottom: 10px; width: 100%; text-align:center">
          Balance: {(Number(user.balances.seers) / 100_000_000).toFixed(2)} $SEER
        </div>

        <div style="margin-bottom: 10px; width: 100%; text-align:center">
          Reward: {(Number(user.age) / 100_000_000).toFixed(4)} ICP ({user.discord})
        </div>

        <div
        style="margin-bottom: 10px; width: 100%; text-align:center; "
      >
        <DisplayButton
          {principal}
          label="Claim"
          {signIn}
          execute={async () => {
            processingReward = true
            const resp = await $auth.actor.claimReward()
            if ("ok" in resp) {
              user.discord = "Claimed"
            } else {
              user.discord = "Error"
            }
            processingReward = false
          }}
          processing={processingReward}
        />
      </div>
        <!-- <div style="margin-bottom: 10px; width: 100%; text-align:center">
          Expected Balance: {Number(user.expBalances.seers).toFixed(2)} Seers
        </div> -->
      </div>
      <div style="border: 0px solid grey; padding: 20px; width: 100%">
        <div style="margin-bottom: 10px; width: 100%; text-align:center">
          ICP deposit account: <br/> <span style="font-size:smaller">(do NOT send NFTs or other tokens here)</span><br />
          <!-- <div style="word-break: break-all">{user.depositICPaddr}</div> -->

          <div class="tooltip">
            <button
              on:click={myFunction}
              on:mouseout={outFunc}
              on:blur={null}
              style="font-size: 14px"
            >
              <input
                type="text"
                readonly
                value={user.depositICPaddr.slice(0, 6) +
                  "..." +
                  user.depositICPaddr.slice(
                    user.depositICPaddr.length - 6,
                    user.depositICPaddr.length,
                  )}
                id="myInput"
                style="width: 15ch; color: white: font-size: 14px;"
              />
              <span class="tooltiptext" id="myTooltip"
                >Click to copy to clipboard</span
              >
              <Fa
                icon={faClipboard}
                style="width: 15px; height: 15px; margin: 5px; color: rgb(29, 155, 240)"
              />
            </button>
          </div>
        </div>
        <div style="margin-bottom: 10px; width: 100%; text-align:center">
          Balance: {(
            Number(
              user.balances.icp +
                user.plusBalances.icp -
                user.minusBalances.icp -
                user.lockedBalances.icp,
            ) / 100_000_000
          ).toFixed(4)} ICP
        </div>
      </div>
      <div
        style="margin-bottom: 10px; text-align:center; display: flex; justify-content: center"
      >
        <DisplayButton
          {principal}
          label="Refresh"
          {signIn}
          execute={async () => {
            processing = true
            await refreshUser()
            processing = false
          }}
          {processing}
        />

        <div style="text-align:center;color:red">
          {errorRefresh}
        </div>
      </div>
      <!-- {#if user.ownMarkets?.length > 0}
        <div
          style="display:flex; flex-direction: column;width: 100%; padding: 5px;"
        >
          My markets
          {#each user.ownMarkets as market}
            <a href="/market/{market.marketId}">
              <div
                style="border-radius: 5px; display:flex; align-items: center; align-content: center; flex-direction: column; gap: 10px; margin-top: 10px; padding: 10px; background-color: rgb(220 218 224 / 10%); "
              >
                <div style="width: 100%; display: flex">
                  <div style="width:fit-content; margin-right: 10px">
                    #{market.marketId}:
                  </div>
                  <div style="width: auto">
                    {market.title}
                  </div>
                </div>
                <div style="width: 100%">
                  {#each market.labels as label, i}
                    {#if market.balances[i] > 0.0}
                      {label +
                        ": " +
                        (Number(market.balances[i]) / 100_000_000).toFixed(2) +
                        "  "}
                    {/if}
                  {/each}
                </div>
              </div>
            </a>
          {/each}
        </div>
        <div
          style="display:flex; flex-direction: column;width: 100%; padding: 5px"
        >
          {#if user.otherMarkets?.length > 0}
            Portfolio
            {#each user.otherMarkets as market}
              <a href="/market/{market.marketId}">
                <div
                  style="border-radius: 5px; display:flex; align-items: center; align-content: center; flex-direction: column; gap: 10px; margin-top: 10px; padding: 10px; background-color: rgb(220 218 224 / 10%); "
                >
                  <div style="width: 100%; display: flex">
                    <div style="width:fit-content; margin-right: 10px">
                      #{market.marketId}:
                    </div>
                    <div style="width: auto">
                      {market.title}
                    </div>
                  </div>
                  <div style="width: 100%">
                    {#each market.labels as label, i}
                      {#if market.balances[i] > 0.0}
                        {label +
                          ": " +
                          (Number(market.balances[i]) / 100_000_000).toFixed(
                            2,
                          ) +
                          "  "}
                      {/if}
                    {/each}
                  </div>
                </div>
              </a>
            {/each}
          {/if}
        </div>
      {/if} -->
      {#if user.txs.length}
        <div
          style="display:flex; flex-direction: column;width: 100%; margin-top: 20px; padding: 5px;"
        >
          Transactions
          {#each user.txs.slice(0, 20) as tx, i}
            {#if tx.marketId == 0}
            <div
            style="border-radius: 5px; display:flex; align-items: center; align-content: center; flex-direction: column; gap: 10px; margin-top: 10px; padding: 10px; background-color: rgb(220 218 224 / 10%); "
          > <a href="/market/{tx.marketId}" style="background:transparent">
            <div style="width: 100%; display: flex; flex-wrap: wrap">
              <div style="width: auto; margin-right: 10px">
                #{user.txs.length - i}: Thanks for your valuable contributions! We are pleased to inform that you received a reward of <span style="color: rgb(0, 186, 124)">{(Number(tx.recv) / 100_000_000).toFixed(2)} ICP</span>. You did a great job, keep up the good work!
                <br/><a
                style="color:rgb(0, 186, 124); background: transparent: padding: 5px"
                href={"https://twitter.com/intent/tweet?text=" +
                  encodeURIComponent(`Happy to share that I received a reward of ${(Number(tx.recv) / 100_000_000).toFixed(2)} $ICP for my contributions to #Seers \n\nThis serves as a testament to the incredible opportunities that the web3 revolution can offer.\n\nJoin us at https://seers.social\n\n`) +
                  "&via=seers_app"}
                target="_blank">Share to Twitter</a
              >
              </div>
              
            </div>
            </a>
          </div>
            {:else}
            <div
            style="border-radius: 5px; display:flex; align-items: center; align-content: center; flex-direction: column; gap: 10px; margin-top: 10px; padding: 10px; background-color: rgb(220 218 224 / 10%); "
          > <a href="/market/{tx.marketId}" style="background:transparent">
            <div style="width: 100%; display: flex; flex-wrap: wrap">
              <div style="width:fit-content; margin-right: 10px">
                #{user.txs.length - i}:
              </div>
              <div style="width: auto; margin-right: 10px;">
                {markets[tx.marketId][1]}
              </div>
              <div
                style="width: auto;margin-right: 10px; text-transform:capitalize"
              >
                From {tx.src.length > 0
                  ? getMarketLabel(tx.marketId, tx.src).slice(0, 30)
                  : "seers" in tx.collateralType
                  ? "TEST"
                  : "ICP"}
              </div>
              <div
                style="width: auto;margin-right: 10px;text-transform:capitalize"
              >
                To {tx.dest.length > 0
                  ? getMarketLabel(tx.marketId, tx.dest).slice(0, 30)
                  : "seers" in tx.collateralType
                  ? "TEST"
                  : "ICP"}
              </div>
              <div style="width: auto;margin-right: 10px;">
                Price {(Number(tx.sent) / Number(tx.recv)).toFixed(2)}
              </div>
              <div style="width: auto;margin-right: 10px;">
                Received {(Number(tx.recv) / 100_000_000).toFixed(2)}
              </div>
              <div style="width: auto;margin-right: 10px;">
                Spent {(Number(tx.sent) / 100_000_000).toFixed(2)}
              </div>
              <div style="width: auto;margin-right: 10px;">
                Fee {Number(tx.fee).toFixed(2)}
              </div>
              <div style="width: auto;margin-right: 10px;">
                Date {new Date(
                  parseInt(tx.createdAt) / 1_000_000,
                ).toLocaleDateString()}
              </div>
              {#if 'resolved' in markets[tx.marketId][2]}
                {#if markets[tx.marketId][2]['resolved'] == tx.dest}
                  <div style="width: auto;margin-right: 10px; color: rgb(0, 186, 124)">
                    {markets[tx.marketId].labels[markets[tx.marketId][2]['resolved']]}
                    +{(Number(tx.recv - tx.sent) / 100_000_000).toFixed(2)}
                  </div>
                  <br/>
                  <a
                    style="color:rgb(0, 186, 124); background: transparent: padding: 5px"
                    href={"https://twitter.com/intent/tweet?text=" +
                      encodeURIComponent(`Happy to share that I predicted correctly the outcome ${markets[tx.marketId].labels[markets[tx.marketId][2]['resolved']]} in the ${markets[tx.marketId][1]} prediction market, and as a result, I won ${(Number(tx.recv - tx.sent) / 100_000_000).toFixed(2)} $ICP in #Seers\n\nJoin us at https://seers.social\n\n`) +
                      "&via=seers_app"}
                    target="_blank">Share to Twitter</a
                  >
                {:else}
                  <div style="width: auto;margin-right: 10px; color: red">
                    {markets[tx.marketId].labels[markets[tx.marketId][2]['resolved']]}
                    -{(Number(tx.sent) / 100_000_000).toFixed(2)}
                  </div>    
                {/if}
              {:else if 'closed' in markets[tx.marketId][2]}
              <div style="width: auto;margin-right: 10px; color:peru">
                Closed
              </div>
              {:else if 'open' in  markets[tx.marketId][2]}
              <div style="width: auto;margin-right: 10px; color:lightskyblue">
                Open
                </div>
              {/if}
              
            </a>
          </div>
            {/if}
           {/each}
        </div>
      {/if}
    {:else}
      <div style="padding: 20px">
        <img src={inf} alt="inf" style="width: 150px; height: 150px;" />
      </div>
    {/if}
  </div>
</div>

<style>
  input[type="text"][disabled] {
    color: white;
  }

  .tooltip {
    position: relative;
    display: inline-block;
  }

  .tooltip .tooltiptext {
    visibility: hidden;
    width: 140px;
    background-color: #555;
    color: white;
    text-align: center;
    border-radius: 6px;
    padding: 5px;
    position: absolute;
    z-index: 1;
    bottom: 150%;
    left: 50%;
    margin-left: -75px;
    opacity: 0;
    transition: opacity 0.3s;
  }

  .tooltip .tooltiptext::after {
    content: "";
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: #555 transparent transparent transparent;
  }

  .tooltip:hover .tooltiptext {
    visibility: visible;
    opacity: 1;
  }
</style>
