<script lang="ts">
  import { onMount } from "svelte"

  import { useNavigate } from "svelte-navigator"
  import Fa from "svelte-fa"
  import {
    faMagnifyingGlass,
    faHouse,
    faUser,
    faWallet,
    faMoneyCheckDollar,
    faPeopleLine,
    faChartSimple,
    faCoins,
    faUserAstronaut,
    faSignOut,
    faSignIn,
    faBell,
    faDisplay,
    faFootball,
    faSoccerBall,
  } from "@fortawesome/free-solid-svg-icons"

  import logo from "./assets/logo.jpeg"

  export let signIn
  export let signOut
  export let principal
  export let auth
  export let changeTheme = () => {}

  let doHave = false
  let selected = "home"

  const navigate = useNavigate()

  const haveNotifications = async () => {
    if (principal === "") {
      setTimeout(haveNotifications, 500000)
    } else {
      doHave = await $auth.actor.haveNotifications()
      setTimeout(haveNotifications, 500000)
    }
  }

  onMount(haveNotifications)
</script>

<div
  style="margin-top: 15px; padding-left:30px; min-width: 200px; justify-content: center; align-items: start;display:flex; flex-direction:column;gap:5px;"
>
  <div style="text-align:center; display:flex; align-items:center;">
    <a href="/">
      <div style="display:flex">
        <img
          src={logo}
          alt="logo"
          style="width: 40px; height: 40px; align-content: left; text-align: left;object-fit: cover; border-radius: 50%"
        />
        <!-- <div style="padding: 10px">Demo</div> -->
      </div>
    </a>
  </div>
  <button
    class="navbar-button"
    on:click={() => {
      if (selected == "home" && window.location.href.includes("feed")) {
        window.scrollTo(0, 0)
      } else {
        selected = "home"
        navigate("/feed")
      }
    }}
  >
    <Fa icon={faHouse} style="margin-right: 10px" />
    Home</button
  >

  <button
    class="navbar-button"
    on:click={() => {
      selected = "markets"
      navigate("/markets")
    }}
  >
    <Fa icon={faChartSimple} style="margin-right: 10px" />
    Markets</button
  >
  <!-- <button
    class="navbar-button"
    on:click={() => {
      selected = "fifa"
      navigate("/fifa-world-cup-2022")
    }}
  >

    <Fa icon={faSoccerBall} style="margin-right: 10px" />
    World Cup</button
  > -->
  <button
    class="navbar-button"
    on:click={() => {
      selected = "notifications"
      navigate("/notifications")
    }}
  >
    <div
      style={`height: 0; width: 0; overflow: ${doHave ? "visible" : "hidden"};`}
    >
      <div class="notification-dot" />
    </div>
    <Fa icon={faBell} style="margin-right: 10px" />
    Notifications
  </button>

  <button
    class="navbar-button"
    on:click={() => {
      selected = "profile"
      navigate("/profile")
    }}
  >
    <Fa icon={faUser} style="margin-right: 10px" />
    Profile
  </button>
  <button
    class="navbar-button"
    on:click={() => {
      selected = "wallet"
      navigate("/wallet")
    }}
  >
    <Fa icon={faWallet} style="margin-right: 10px" />
    Wallet
  </button>

  <button
    class="navbar-button"
    on:click={() => {
      navigate("/leaderboard")
    }}
  >
    <Fa icon={faUserAstronaut} style="margin-right: 10px" />
    Leaderboard
  </button>

  <button
    class="navbar-button"
    on:click={() => {
      changeTheme()
    }}
  >
    <Fa icon={faDisplay} style="margin-right: 10px" />
    Display
  </button>

  <!-- <button
    style="cursor:pointer; color:white; background:black; width:fit-content;font-size: 20px; line-height:24px;"
    on:click={() => {
      navigate("/bets")
    }}
  >
    <Fa icon={faCoins} style="margin-right: 10px" />
    Bets</button
  > -->

  {#if principal !== ""}
    <button
      class="navbar-button"
      on:click={() => {
        signOut()
      }}
    >
      <Fa icon={faSignOut} style="margin-right: 10px" />
      Logout</button
    >
  {:else}
    <button
      class="navbar-button"
      on:click={() => {
        signIn()
      }}
    >
      <Fa icon={faSignIn} style="margin-right: 10px" />
      Login</button
    >
  {/if}
  <!--
  <button
    style="cursor:pointer; color:white; background:black; width:fit-content;font-size: 20px; line-height:24px;"
    on:click={() => {
      navigate("/queue")
    }}
  >
    <Fa icon={faMoneyCheckDollar} style="margin-right: 10px" />
    Payments
  </button> -->
</div>

<style global>
  .notification-dot {
    height: 7px;
    width: 7px;
    background-color: var(--link-color-blue);
    border-radius: 50%;
    border: 1px solid var(--link-color-blue);
    display: flex;
    position: relative;
    top: -5px;
    left: 12px;
  }

  body button.navbar-button {
    cursor: pointer;
    width: fit-content;
    font-size: 20px;
    line-height: 24px;
    padding: 13px 13px 13px 13px;
    margin: 0px;
  }

  .navbar-button:hover {
    border-radius: 25px;
  }
</style>
