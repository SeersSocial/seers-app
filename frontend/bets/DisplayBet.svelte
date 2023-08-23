<!-- 
// Copyright 2022 Pense Technologies.
// This file is part of Seers.

// Seers is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Seers is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Seers.  If not, see <http://www.gnu.org/licenses/>.
 -->
<script lang="ts">
  import { parseTwitterDate } from "../utils/utils"
  import Fa from "svelte-fa"
  import { faEllipsis } from "@fortawesome/free-solid-svg-icons"
  import inf from "../assets/inf.gif"

  export let auth
  export let principal
  export let signIn
  export let bet
  export let isThread = false
  export let doNotShowBorder = false
  export let managed = false
  export let refresh

  let displayDropdown = "none"
  let processing = false
  let errorResponse = ""
  let amount = Number(bet.amount) / 100_000_000

  const submitMatch = async (betId) => {
    processing = true
    const resp = await $auth.actor.matchBet(betId)
    processing = false
    refresh()
  }

  const submitResolve = async (betId, outcome) => {
    const resp = await $auth.actor.resolveBet(betId, outcome)
    refresh()
  }

  const submitRedeem = async (betId) => {
    const resp = await $auth.actor.redeemBet(betId)
    refresh()
  }

  const submitDelete = async (betId) => {
    const resp = await $auth.actor.deleteBet(betId)
    refresh()
  }
</script>

<div
  style={`display:flex; justify-content:start; text-align:start; width: 100%; padding: 0px 5px 0px 0px; flex-direction:column; align-items:center; border-bottom: ${
    isThread || doNotShowBorder ? 0 : 1
  }px solid rgb(47, 51, 54);`}
>
  <div style="display:flex; width: 100%;">
    {#if !managed}
      <div
        style="display:flex; flex-direction:column; padding: 0px; margin: 5px; height: 100%"
      >
        <a href={`/profile/${bet.author[0].handle}`}>
          <img
            src={bet.author[0].picture}
            alt="avatar"
            style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; padding: 0px 0px 0px 0px;margin: 10px 0px 0px 0px;"
          />
        </a>
      </div>
    {/if}
    <div
      style="flex-grow: 1; justify-content: start; text-align:start; padding: 15px 0px;"
    >
      {#if !managed}
        <div style="display:flex; gap: 5px;">
          <div>
            <a href={`/profile/${bet.author[0].handle}`}>{bet.author[0].name}</a
            >
          </div>
          <div style="color:grey">
            <a href={`/profile/${bet.author[0].handle}`} style="color:grey">
              @{bet.author[0].handle}
            </a>
          </div>
          <div style="color:grey">
            - {parseTwitterDate(parseInt(bet.createdAt) / 1_000_000)}
          </div>
        </div>
        <div style="width: 100%; text-align:start; padding: 15px 0px">
          {bet.description}
        </div>
      {/if}
      {#if bet && bet.outcomes.length > 0}
        <div>
          {#each bet.outcomes as label, i}
            <div
              style="width: 100%; display:flex; cursor:pointer; margin: 0; padding: 0;align-items:center; position:relative"
            >
              {#if "resolved" in bet.state || "redeemed" in bet.state}
                <div
                  style={`${
                    bet.state["resolved"] == i || bet.state["redeemed"] == i
                      ? "background: rgb(56 55 55);"
                      : "background: rgb(56 55 55);"
                  }; 
            ${
              bet.authorChoice == i || bet.matcher.length > 0
                ? "width: 75%;"
                : "width: 2%;"
            }; display:flex; z-index: -100; position:absolute; height: 24px; justify-content:start; align-items:center; text-align:left; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; color:white;overflow:visible`}
                />
              {:else}
                <div
                  style={`${
                    bet.authorChoice != i
                      ? "background: rgb(56 55 55);"
                      : "background: rgb(56 55 55);"
                  }; 
                ${
                  bet.authorChoice == i || bet.matcher.length > 0
                    ? "width: 75%;"
                    : "width: 2%;"
                }; display:flex; z-index: -100; position:absolute; height: 24px; justify-content:start; align-items:center; text-align:left; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; color:white;overflow:visible`}
                />
              {/if}

              <button
                style="all:unset; width: 200px;display:flex; margin-left: 5px"
                on:click={() => {
                  bet.selected = i
                }}
              >
                {label.slice(0, 20)}
              </button>
              <div
                style="flex-grow: 1; justify-content:flex-end; text-align:end;padding: 5px"
              >
                {bet.authorChoice == i ||
                bet.matcher.length > 0 ||
                "redeemed" in bet.state
                  ? amount
                  : 0}
                {"seers" in bet.collateralType ? "Σ" : "ICP"}
              </div>
            </div>
          {/each}
          <div
            style="display:flex; text-align:end; justify-content:start; flex-grow: 1"
          >
            {#if processing}
              <button
                class="btn-grad"
                style="width: 100px; margin: 15px 0px; color:white;overflow:hidden;"
                on:click={() => {}}
              >
                <img
                  src={inf}
                  alt="inf"
                  style="width: 150px; height: 400%; margin: -75%;"
                />
              </button>
              <input
                style=" font-size: 1em; font-family: 'Roboto Mono', monospace; border: 0px; padding: 0px 5px; margin: 0px 15px; width: 30px"
                bind:value={amount}
                disabled
              />
              <div
                style="display:flex; text-align:center; align-items:center; padding: 0px 5px"
              >
                {"seers" in bet.collateralType ? "Σ" : "ICP"}
              </div>
            {:else if "open" in bet.state}
              <button
                class="btn-grad"
                style="padding: 0px 15px; margin: 15px 0px;"
                on:click={() => {
                  if (principal === "") {
                    signIn()
                  } else {
                    submitMatch(bet.id)
                  }
                }}
              >
                Bet
              </button>
              <div
                style="display:flex; text-align:center; align-items:center; padding: 0px 5px; margin-left:5px;font-family: 'Roboto Mono', monospace;"
              >
                {amount}
              </div>
              <div
                style="display:flex; text-align:center; align-items:center; padding: 0px 5px"
              >
                {"seers" in bet.collateralType ? "Σ" : "ICP"}
              </div>
            {:else if "resolved" in bet.state}
              <div
                style="text-align:start;align-items:center; justify-content:center; width: 100%"
              >
                Resolved to {bet.outcomes[bet.state["resolved"]]}.
                {#if bet.state["resolved"] == bet.authorChoice}
                  <img
                    src={bet.author[0].picture}
                    alt="author"
                    style="width: 20px; height: 20px; border-radius: 50%;object-fit: cover;"
                  />
                  <a href="/profile/{bet.author[0].handle}">
                    @{bet.author[0].handle}
                  </a>
                {:else}
                  <img
                    src={bet.matcher[0].picture}
                    alt="matcher"
                    style="width: 20px; height: 20px; border-radius: 50%;object-fit: cover;"
                  />
                  <a href="/profile/{bet.author[0].handle}">
                    @{bet.matcher[0].handle}
                  </a>
                {/if}&nbsp;won {amount}
                {"seers" in bet.collateralType ? "Σ" : "ICP"}.
              </div>
            {:else if "redeemed" in bet.state}
              <div
                style="text-align:start;align-items:center; justify-content:center"
              >
                Resolved to {bet.outcomes[bet.state["redeemed"]]}.
                {#if bet.state["redeemed"] == bet.authorChoice}
                  <img
                    src={bet.author[0].picture}
                    alt="author"
                    style="width: 20px; height: 20px; border-radius: 50%; object-fit: cover;"
                  />
                  <a href="/profile/{bet.author[0].handle}">
                    @{bet.author[0].handle}
                  </a>
                {:else}
                  <img
                    src={bet.matcher[0].picture}
                    alt="matcher"
                    style="width: 20px; height: 20px; border-radius: 50%; object-fit: cover;"
                  />
                  <a href="/profile/{bet.author[0].handle}">
                    @{bet.matcher[0].handle}
                  </a>
                {/if}&nbsp;won {amount}
                {"seers" in bet.collateralType ? "Σ" : "ICP"} (paid).
              </div>
            {:else if "matched" in bet.state}
              <div
                style="text-align:start;align-items:center; justify-content:center"
              >
                Matched by <img
                  src={bet.matcher[0].picture}
                  alt="matcher"
                  style="width: 20px; height: 20px; border-radius: 50%; object-fit: cover;"
                />
                <a href="/profile/{bet.matcher[0].handle}">
                  @{bet.matcher[0].handle}
                </a>
              </div>
            {/if}
            <div style="text-align: center;color:red">
              {errorResponse}
            </div>
          </div>
        </div>
      {/if}
    </div>
    {#if !managed}
      <div class="menu-button-elli">
        <div class="dropdown">
          <button
            class="dropbtn"
            on:click={() => {
              if (
                !document
                  .getElementById(`Dropdown-${bet?.id}`)
                  .classList.contains("show") &&
                displayDropdown == "none"
              ) {
                displayDropdown = "block"
                document
                  .getElementById(`Dropdown-${bet?.id}`)
                  .classList.toggle("show")
              } else {
                displayDropdown = "none"
              }
            }}><Fa icon={faEllipsis} /></button
          >
          {#if bet.author[0]?.principal == principal || bet?.matcher[0]?.principal == principal}
            <div id="Dropdown-{bet.id}" class="dropdown-content">
              {#if "matched" in bet.state}
                <button on:click={() => submitResolve(bet.id, 0)}
                  >Resolve to {bet.outcomes[0]}</button
                >
                <button on:click={() => submitResolve(bet.id, 1)}
                  >Resolve to {bet.outcomes[1]}</button
                >
                <button on:click={() => submitResolve(bet.id, 3)}>Cancel</button
                >
              {:else if "open" in bet.state}
                <a href={`/bet/${bet.id}/edit`}>Edit</a>
                <button on:click={() => submitDelete(bet.id)}>Delete</button>
              {:else if "resolved" in bet.state}
                <button on:click={() => submitRedeem(bet.id)}>Redeem</button>
              {:else}
                <button on:click={null}>Share (todo)</button>
              {/if}
            </div>
          {:else}
            <div id="Dropdown-{bet?.id}" class="dropdown-content">
              <a href="#">Share (todo)</a>
            </div>
          {/if}
        </div>
      </div>
    {/if}
  </div>
</div>
