<script lang="ts">
  import { faBreadSlice } from "@fortawesome/free-solid-svg-icons"

  import { onMount } from "svelte"

  import inf from "./assets/inf.gif"
  export let auth

  import anon from "./assets/anon.png"

  let response = []
  let totalKarma = 0

  let getKarma = async () => {
    let users = await $auth.actor.readUsersKarmaClaim()
    response = users.sort(function (a, b) {
      var keyA = a[3],
        keyB = b[3]
      if (keyA < keyB) return 1
      if (keyA > keyB) return -1
      return 0
    })
    totalKarma = response.reduce((acc, curr) => acc + Number(curr[3]), 0)
  }

  onMount(getKarma)
</script>

<div class="outer-container">
  <div class="inner-container" style="justify-content: left;">
    <h3 class="headline" style="padding-left: 10px">Leaderboard</h3>
  </div>
</div>

<div class="outer-container">
  <div
    class="inner-container"
    style="flex-direction: row; justify-content:center"
  >
    {#if response.length > 0}
      <div class="row">
        <div
          style="width: 10%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          #
        </div>
        <div
          style="width: 40%;margin: 3px; font-size: 1.2em;margin-bottom: 1em"
        >
          User
        </div>
        <div
          style="width: 20%;margin: 3px; font-size: 1.2em;margin-bottom: 1em; text-align:right"
        >
          Karma (%)
        </div>
        <div
          style="width: 30%;margin: 3px; font-size: 1.2em;margin-bottom: 1em; text-align:right"
        >
          Weekly Reward (ICP)
        </div>
      </div>
      {#each response as user, i}
        <div class="row">
          <div style="width: 10%;margin: 3px; display:flex; align-items:center">
            {i}
          </div>
          <div style="width: 40%;margin: 3px;display:flex; align-items:center">
            <img
              src={user[0]}
              style="width: 25px; height: 25px;object-fit:cover; border-radius: 50%; padding: 0px 5px"
              alt=""
              onError="this.src='{anon}';"
            />
            <a href="/profile/{user[1]}">
              {user[2]}
            </a>
          </div>
          <div
            style="width: 20%;margin: 3px; display:flex; align-items:center;justify-content:right"
          >
            {user[3]} ({(100 * Number(user[3])/totalKarma).toFixed(0)})
          </div>
          {#if user[4] == "Pending"}
          <div
            style="color: green; width: 30%;margin: 3px; display:flex; align-items:center;justify-content:right"
          >
            +{(1.16 * Number(user[3])/totalKarma).toFixed(4)}
          </div>
          {:else if user[4] == "Claimed"}
          <div
          style="color: grey; width: 30%;margin: 3px; display:flex; align-items:center;justify-content:right"
        >
          +{(1.16 * Number(user[3])/totalKarma).toFixed(4)}
        </div>
        {:else}
        <div
        style="color: green; width: 30%;margin: 3px; display:flex; align-items:center;justify-content:right"
      >
        0
    </div>
      
        
          {/if}
        </div>
      {/each}
    {:else}
      <img src={inf} alt="inf" style="width: 150px; height: 150px;" />
    {/if}
  </div>
</div>

<style>
  .row a {
    background-color: transparent;
  }
  .row {
    display: flex;
    width: 100%;
    padding: 0px 10px 0px 10px;
  }
  .row:hover {
    background-color: hotpink;
  }
</style>
