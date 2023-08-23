<script lang="ts">
  import { useNavigate } from "svelte-navigator"
  import Fa from "svelte-fa"
  import { faBars } from "@fortawesome/free-solid-svg-icons"
  import logo from "./assets/logo.jpeg"
  import { onMount } from "svelte"
  import anon from "./assets/anon.png"
  import { loggedUser, userMap, setUserMapStore } from "./store/stores"

  export let principal
  export let signOut
  export let signIn
  export let auth
  export let changeTheme = () => {}

  const navigate = useNavigate()

  let user = null
  let innerWidth = window.innerWidth
  let navStyle = "display: flex; flex-direction: row;  justify-content:center"
  let common =
    ";text-decoration: none; background-color: transparent; font-size: 18px; padding: 5px; \
    height: 37px;margin-top: 15px; border: 0;"
  let menuItemStyle = ""
  let menuOpen = false

  $: if (innerWidth < 1100) {
    window.ontouchend = function (event) {
      if (
        !event.target.matches(".dropbtn") &&
        !event.target.matches(".dropdown") &&
        !event.target.matches(".menu-button-elli") &&
        !event.target.matches(".dropdown-content") &&
        !event.target.matches(".link")
      ) {
        var dropdowns = document.getElementsByClassName("dropdown-content")

        var i
        for (i = 0; i < dropdowns.length; i++) {
          var openDropdown = dropdowns[i]
          if (openDropdown.classList.contains("show")) {
            openDropdown.classList.remove("show")
          }
        }
      }
    }

    menuItemStyle = "display: none; text-align: center" + common
  } else {
    navStyle = "display: flex; flex-direction: row; justify-content:center"
    menuItemStyle = "display: block; text-align: center" + common
  }

  function clickMenu() {
    if (window.innerWidth >= 1100) {
      return
    }
    if (menuOpen) {
      menuOpen = false
      menuItemStyle =
        "display: none; text-align: right; margin-right: 15px" + common
      navStyle = "display: flex; flex-direction: row;  justify-content:center"
    } else {
      menuOpen = true
      navStyle = "display: flex; flex-direction: column; justify-content:center"
      menuItemStyle =
        "display: block; text-align: right; margin-right: 15px" + common
    }
  }

  const redirectToCreateProfile = async () => {
    if (principal !== "") {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("err" in resp) {
        navigate("/new")
      }
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
        $loggedUser = user
      }
    } else {
      setTimeout(redirectToCreateProfile, 500)
    }
  }

  onMount(redirectToCreateProfile)
</script>

<svelte:window bind:innerWidth />

<div style={navStyle}>
  {#if innerWidth < 1100}
    {#if user}
      <div style="display: flex; width: 100%">
        <button
          style="all:unset;margin: 0; padding: 0; text-align: left;"
          on:click={() => {
            navigate("/profile")
          }}
        >
          <img
            src={user.picture}
            onError="this.src='{anon}';"
            alt=""
            style="width: 40px; height: 40px; align-content: left; text-align: left;object-fit: cover; border-radius: 50%;object-fit:cover"
          />
        </button>
        <button
          style="all:unset; margin-right: 40px; padding: 0; text-align: center; flex-grow: 1; justify-content:center; display:flex; align-items:center"
          on:click={() => {
            navigate("/feed")
          }}
        >
          <img
            src={logo}
            alt="logo"
            style="width: 40px; height: 40px; align-content: left; text-align: left;object-fit: cover; border-radius: 50%"
          />
        </button>
      </div>
    {:else}
      <div style="display: flex; width: 100%">
        <button
          on:click={() => {
            menuOpen = false
            signIn()
          }}
          style="background-color: rgba(0, 0, 0, 0); display:flex; "
        >
          <img
            src={anon}
            onError="this.src='{anon}';"
            alt=""
            style="width: 40px; height: 40px; align-content: left; justify-content:center; text-align: left;object-fit: cover; border-radius: 50%;object-fit:cover"
          />
        </button>
        <button
          on:click={() => {
            menuOpen = false
            navigate("feed")
          }}
          style="background-color: rgba(0, 0, 0, 0);margin-right: 40px; padding: 0; text-align: center; flex-grow: 1; justify-content:center; display:flex; align-items:center"
          ><img
            src={logo}
            alt="logo"
            style="width: 40px; height: 40px; align-content: left; text-align: left;object-fit: cover; border-radius: 50%"
          /></button
        >
      </div>
    {/if}

    <button
      on:click={() => {
        clickMenu()
        navigate("/feed")
      }}
      style={menuItemStyle}>Home</button
    >
    <button
      on:click={() => {
        clickMenu()
        navigate("/markets")
      }}
      style={menuItemStyle}>Markets</button
    >

    <!-- <button
      on:click={() => {
        clickMenu()
        navigate("/fifa-world-cup-2022")
      }}
      style={menuItemStyle}>World Cup</button
    > -->

    {#if principal !== ""}
      <button
        on:click={() => {
          clickMenu()
          navigate("/notifications")
        }}
        style={menuItemStyle}
      >Notifications</button>
      <button
        on:click={() => {
          clickMenu()
          navigate("/profile")
        }}
        style={menuItemStyle}>Profile</button
      >
      <button
        on:click={() => {
          clickMenu()
          navigate("/wallet")
        }}
        style={menuItemStyle}>Wallet</button
      >
      <button
        on:click={() => {
          clickMenu()
          navigate("/leaderboard")
        }}
        style={menuItemStyle}>Leaderboard</button
      >

      <button
        on:click={() => {
          changeTheme()
        }}
        style={menuItemStyle}>Display</button
      >

      <!-- <a href="https://forms.gle/fYmc9iTc9P46upm47" style={menuItemStyle}>Bugs</a> -->
      <button
        on:click={() => {
          clickMenu()
          signOut()
        }}
        style={menuItemStyle}>Logout</button
      >
    {/if}

    <!-- <button
      on:click={() => {
        clickMenu()
        navigate("/bets")
      }}
      style={menuItemStyle}>Bets</button
    > -->
    <!-- <button
      on:click={() => {
        clickMenu()
        navigate("/ranking")
      }}
      style={menuItemStyle}>Leaderboard</button
    >
    <button
      on:click={() => {
        clickMenu()
        navigate("/queue")
      }}
      style={menuItemStyle}>Payments</button
    > -->

    {#if principal === ""}
      <!-- <a href="https://forms.gle/fYmc9iTc9P46upm47" style={menuItemStyle}>Bugs</a> -->
      <button on:click={signIn} style={menuItemStyle}>Login</button>
    {/if}

    <!-- <button on:click={changeTheme} style={menuItemStyle}>Theme</button> -->
  {/if}

  <a href="javascript:void(0);" class="icon" on:click={clickMenu}>
    <Fa icon={faBars} />
  </a>
</div>

<style>
  button:hover {
    cursor: pointer;
  }

  .icon {
    display: none;
    font-size: 1.2em;
  }

  @media screen and (max-width: 1100px) {
    .icon {
      position: absolute;
      display: block;
      padding: 10px;
      right: 0;
      top: 0;
    }
    .topnav.responsive a.left {
      float: none;
      display: block;
      text-align: left;
    }
    .topnav.responsive button {
      float: right;
      display: block;
      text-align: right;
    }
  }
</style>
