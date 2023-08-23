
<script lang="ts">
  import { Router, Route } from "svelte-navigator"
  import { AuthClient } from "@dfinity/auth-client"
  import { onMount } from "svelte"
  import icLogo from "./assets/ic.svg"
  import { auth, createActor } from "./store/auth"
  import ListMarkets from "./ListMarkets.svelte"
  import Auth from "./Auth.svelte"
  import ViewMarket from "./ViewMarket.svelte"
  import Wallet from "./Wallet.svelte"
  import Ranking from "./Ranking.svelte"
  import Feed from "./Feed.svelte"
  import Profile from "./Profile.svelte"
  import ViewPost from "./ViewPost.svelte"
  import EditPost from "./EditPost.svelte"
  import Bets from "./bets/Bets.svelte"
  import Queue from "./Queue.svelte"
  import Fifa from "./Fifa.svelte"
  import VerifiedFeed from "./VerifiedFeed.svelte"

  import twitterIcon from "./assets/twitter-light.png"
  import githubIcon from "./assets/github-light.png"
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
  } from "@fortawesome/free-solid-svg-icons"

  import NavBar from "./NavBar.svelte"
  import Notifications from "./Notifications.svelte"
  import RightPanel from "./RightPanel.svelte"
  import ViewFeed from "./ViewFeed.svelte"
  import Display from "./Display.svelte"
  import Hashtags from "./Hashtags.svelte"

  let innerWidth = window.innerWidth
  let principal = ""
  let viewfeed

  /** @type {AuthClient} */
  let client

  function handleAuth() {
    auth.update(() => ({
      loggedIn: true,
      actor: createActor({
        agentOptions: {
          identity: client.getIdentity(),
        },
        actorOptions: {
          identity: client.getIdentity(),
        },
      }),
    }))
    principal = client.getIdentity().getPrincipal().toText()
  }

  const initAuth = async () => {
    client = await AuthClient.create({
      idleOptions: {
        disableIdle: true,
        disableDefaultIdleCallback: true, // disable the default reload behavior
      },
    })
    if (await client.isAuthenticated()) {
      handleAuth()
    }
  }

  const signIn = () => {
    if (client)
      client.login({
        // 14 days in nanoseconds
        maxTimeToLive: BigInt(14 * 24 * 60 * 60 * 1000 * 1000 * 1000),
        // identityProvider: "http://rkp4c-7iaaa-aaaaa-aaaca-cai.localhost:8000/",
        identityProvider: "https://identity.ic0.app/",
        onSuccess: handleAuth,
      })
  }

  const signOut = async () => {
    principal = ""
    await client.logout()
    auth.update(() => ({
      loggedIn: false,
      actor: createActor({
        agentOptions: {
          identity: client.getIdentity(),
        },
        actorOptions: {
          identity: client.getIdentity(),
        },
      }),
    }))
  }

  $: theme = Number(localStorage.getItem("theme"))

  $: bodyStyle = [
    `
<style>
  body {
    color: white;
    background-color: rgba(21, 32, 43, 1);
  }

  button.navbar-button {
    color: white;
    background: rgba(21, 32, 43, 1);
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: rgba(21, 32, 43, 1);
  }


  .btn-grad {
    background-color: rgb(249, 24, 128); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(249, 24, 128);  
  }
</style>
`,

    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(29, 155, 240); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(29, 155, 240);
  }

</style>
`,
    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(255, 212, 0); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(255, 212, 0);
  }

</style>
`,
    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(120, 86, 255); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(120, 86, 255);
  }

</style>
`,
    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(255, 122, 0); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(255, 122, 0);
  }

</style>
`,
    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(0, 186, 124); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(0, 186, 124);
  }

</style>
`,
    `
<style>
  body {
    color: white;
    background-color: black;
  }

  button.navbar-button {
    color: white;
    background: black;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: black;
  }

  .btn-grad {
    background-color: rgb(249, 24, 128); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(249, 24, 128);
  }

</style>
`,

    `
<style>
  body {
    color: black;
    background-color: white;
  }

  button.navbar-button {
    color: black;
    background: white;
  }

  textarea, input, select, a, button, .window {
    color: black;
    background-color: white;
  }


  .btn-grad {
    background-color: rgb(29, 155, 240); 
  }

  .feed-icon, .post-url, .plus-circle {
    color: rgb(29, 155, 240);
  }
</style>
`,
    `
<style>
  body {
    color: white;
    background-color: #333333;
  }

  button.navbar-button {
    color: white;
    background: #333333;
  }

  textarea, input, select, a, button, .window {
    color: white;
    background-color: #333333;
  }


  .btn-grad {
    background-color: #97d700; 
  }

  .feed-icon, .post-url, .plus-circle {
    color: #97d700;
  }
</style>
`,
  ]

  const changeTheme = () => {
    theme = (theme + 1) % bodyStyle.length
    localStorage.setItem("theme", theme.toString())
  }

  onMount(initAuth)
</script>

<svelte:window bind:innerWidth />

<svelte:head>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link
    href="https://fonts.googleapis.com/css2?family=Manrope&family=Noto+Sans&family=Roboto&family=Roboto+Mono&family=Poppins&family=Rubik&display=swap"
    rel="stylesheet"
  />
  {@html bodyStyle[Number(theme)]}
</svelte:head>
  <Router>
  <div style="min-height: 80vh;width: 100%; display:flex;">
    {#if innerWidth > 1100}
      <div
        style="position: fixed; width: {(innerWidth - 650 - 60) /
          2}px; padding-right: 30px; display: flex; justify-content: flex-end;"
      >
        <NavBar {auth} {principal} {signIn} {signOut} {changeTheme} />
      </div>
    {/if}
    {#if innerWidth > 1100}
      <div
        style="margin-left: {(innerWidth - 650 - 30) /
          2}px; width: 650px; min-width: 200px;"
      >
        <Auth {auth} {principal} {signIn} {signOut} {changeTheme} />
        <Route path="market/:id" let:params>
          <ViewMarket {auth} {principal} {signIn} id={params.id} />
        </Route>
        <Route path="wallet">
          <Wallet {auth} {principal} {signIn} />
        </Route>

        <Route path="feed" primary={false}>
          <ViewFeed bind:this={viewfeed} {auth} {principal} {signIn} />
        </Route>
        <Route path="feed" primary={false}>
          <Feed {auth} {principal} {signIn} />
        </Route>
        <Route path="new" let:params>
          <Profile {auth} {principal} {signIn} create={true} />
        </Route>
        <Route path="profile" let:params>
          <Profile {auth} {principal} {signIn} />
        </Route>
        <Route path="fifa-world-cup-2022">
          <Fifa {auth} {principal} {signIn} />
        </Route>

        <Route path="hashtag/:hashtag" let:params>
          <Hashtags {auth} hashtag={params.hashtag} {principal} {signIn} />
        </Route>

        <Route path="profile/:handle" let:params>
          <Profile {auth} handle={params.handle} {principal} {signIn} />
        </Route>
        <Route path="post/:id" let:params primary={false}>
          <ViewPost {auth} id={params.id} {principal} {signIn} />
        </Route>
        <Route path="post/:id/edit" let:params primary={false}>
          <EditPost {auth} id={params.id} {principal} {signIn} />
        </Route>
        <Route path="leaderboard">
          <Ranking {auth} />
        </Route>
        <Route path="notifications">
          <Notifications {auth} {principal} {signIn} />
        </Route>
        <Route path="queue">
          <Queue {auth} />
        </Route>
        <Route path="markets">
          <ListMarkets {auth} />
        </Route>
        <Route path="bets">
          <Bets {auth} {principal} {signIn} />
        </Route>
        <Route path="/" primary={false}>
          <ViewFeed bind:this={viewfeed} {auth} {principal} {signIn} />
        </Route>
        <footer
          style="width: 100%; text-align: center; padding: 20px 0px; align-items:center; display: flex; flex-direction: column;justify-content: center; gap: 15px"
        >
          <div style="width: 50%;display:flex; justify-content:center">
            <img src={icLogo} alt="ic logo" style="max-width: 400px;" />
          </div>
          <div
            style="max-width: 300px; width: 100%;display:flex; justify-content:center;align-items:center; flex-direction:column"
          >
            <div style="width: 100%;justify-content:center">
              © Seers 2023 <br />
            </div>

            <div style="width: 100%;justify-content:center">
             <a target="_blank" href="https://docs.google.com/document/d/15iAz0gxVEj1ZKvlxiRaT2QlR0ITm8AGVGsvAj15uyFk/edit?usp=sharing">Terms of Use</a> -
              <a target="_blank" href="https://docs.google.com/document/d/1NkaGXvzFCLV5ep9jQQU3WaY5Gcxqh0ihekymImckhAo/edit?usp=sharing">Privacy Policy</a>
             </div>
          </div>
        </footer>
      </div>
    {:else}
      <div style="width: 100%; ">
        <Auth {auth} {principal} {signIn} {signOut} {changeTheme} />
        <Route path="market/:id" let:params>
          <ViewMarket {auth} {principal} {signIn} id={params.id} />
        </Route>
        <Route path="wallet">
          <Wallet {auth} {principal} {signIn} />
        </Route>
        <Route path="fifa-world-cup-2022">
          <Fifa {auth} {principal} {signIn} />
        </Route>
        <Route path="new" let:params>
          <Profile {auth} {principal} {signIn} create={true} />
        </Route>
        <Route path="notifications">
          <Notifications {auth} {principal} {signIn} />
        </Route>
        <Route path="hashtag/:hashtag" let:params>
          <Hashtags {auth} hashtag={params.hashtag} {principal} {signIn} />
        </Route>

        <Route path="profile" let:params>
          <Profile {auth} {principal} {signIn} />
        </Route>
        <Route path="profile/:handle" let:params>
          <Profile {auth} handle={params.handle} {principal} {signIn} />
        </Route>
        <Route path="post/:id" let:params primary={false}>
          <ViewPost {auth} id={params.id} {principal} {signIn} />
        </Route>
        <Route path="post/:id/edit" let:params primary={false}>
          <EditPost {auth} id={params.id} {principal} {signIn} />
        </Route>
        <Route path="leaderboard">
          <Ranking {auth} />
        </Route>
        <Route path="queue">
          <Queue {auth} />
        </Route>
        <Route path="markets">
          <ListMarkets {auth} />
        </Route>
        <Route path="bets">
          <Bets {auth} {principal} {signIn} />
        </Route>
        <Route path="feed" primary={false}>
          <ViewFeed bind:this={viewfeed} {auth} {principal} {signIn} />
        </Route>
        <Route path="/" primary={false}>
          <ViewFeed bind:this={viewfeed} {auth} {principal} {signIn} />
        </Route>

        <Route path="feed" primary={false}>
          <Feed {auth} {principal} {signIn} />
        </Route>
        <Route path="/" primary={false}>
          <Feed {auth} {principal} {signIn} />
        </Route>
        <footer
          style="width: 100%; text-align: center; padding: 20px 0px; align-items:center; display: flex; flex-direction: column;justify-content: center; gap: 15px"
        >
          <div style="width: 50%;display:flex; justify-content:center">
            <img src={icLogo} alt="ic logo" style="max-width: 400px;" />
          </div>
          <div
            style="max-width: 300px; width: 100%;display:flex; justify-content:center;align-items:center; flex-direction:column"
          >
            <div style="width: 100%;justify-content:center">
              © Seers 2023 <br />
            </div>
            <div style="width: 100%;justify-content:center">
              <a target="_blank" href="https://docs.google.com/document/d/15iAz0gxVEj1ZKvlxiRaT2QlR0ITm8AGVGsvAj15uyFk/edit?usp=sharing">Terms of Use</a> - 
              <a target="_blank" href="https://docs.google.com/document/d/1NkaGXvzFCLV5ep9jQQU3WaY5Gcxqh0ihekymImckhAo/edit?usp=sharing">Privacy Policy</a>
             </div>
          </div>
        </footer>
      </div>
    {/if}

    {#if innerWidth > 1100}
      <div
        style="position: fixed; margin-left: {(innerWidth - 650 - 30) / 2 +
          650}px; width: {(innerWidth - 650 - 60) / 2}px; padding-left: 30px"
      >
        <RightPanel {auth} />
      </div>
    {/if}
  </div></Router
> 

<style global>
  :root {
    --link-color-blue: rgb(29, 155, 240);
    --link-color-yellow: rgb(255, 212, 0);
    --link-color-pink: rgb(249, 24, 128);
    --link-color-purple: rgb(120, 86, 255);
    --link-color-orange: rgb(255, 122, 0);
    --link-color-green: rgb(0, 186, 124);

    --dim-bg-color: rgba(21, 32, 43, 1);
    --dark-bg-color: rgb(0, 0, 0);
    --light-bg-color: rgba(255, 255, 255, 1);

    --dark-font-color: white;
    --light-font-color: black;
    --dim-font-color: white;

    --dim-hover-color: rgba(21, 32, 43, 0.03);
    --dark-hover-color: rgb(49, 48, 48);
    --light-hover-color: rgba(255, 255, 255, 0.03);

    --light-custom-grey: rgb(83, 100, 113);
    --dim-custom-grey: rgb(113, 118, 123);
    --dark-custom-grey: rgb(113, 118, 123);
  }

  .feed-icon {
    display: flex;
    text-align: center;
    justify-content: center;
    align-items: center;
    width: 30px;
    height: 30px;
    margin: 5px;
    border-radius: 30px;
  }
  .post-url {
    color: rgb(29, 155, 240);
  }
  .select {
    border: 0px;
    font-size: 1.1em;
  }
  .centered {
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
  }
  input {
    border: 0px;
    font-size: 1.2em;
    width: 100%;
    text-align: start;
    padding-left: 20px;
    font-family: "Noto Sans", monospace;
  }

  input:disabled {
    color: white;
  }

  input:focus {
    background-color: black;
  }

  .input-container {
    display: flex;
    align-items: center;
    width: 90%;
    height: 50px;
    border: 1px solid rgb(51, 54, 57);
    border-radius: 10px;
  }
  .action-textarea {
    width: 95%;
    font-size: 1.3em;
    border: 0px;
    padding: 5px;
    border-radius: 15px;
  }
  .error-container {
    color: red;
  }
  .right-container {
    display: flex;
    width: 100%;
    justify-content: end;
  }
  .outer-container {
    justify-content: center;
    display: flex;
    width: 100%;
    margin-top: 0px 0px 0px 0px;
    flex-direction: column;
    align-items: center;
  }
  .inner-container {
    flex-direction: column;
    display: flex;
    flex-wrap: wrap;
    padding: 0px;
    justify-content: start;
    max-width: 650px;
    /* margin-top: 15px; */
    width: 100%;
    border: 1px solid rgb(61, 60, 61);
    border-top: 0px;
    /* border-radius: 16px; */
    justify-content: flex-end;
  }

  @media screen and (max-width: 1100px) {
    .inner-container {
      padding: 0px;
      margin: 0px;
      border-left: 0px;
      border-right: 0px;
      border-bottom: 1px solid rgb(61, 60, 61);
      border-top: 0px;
      border-radius: 0px;
    }
  }

  .grey {
    color: rgb(167, 165, 165);
  }
  body a {
    text-decoration: none;
  }

  html {
    scroll-behavior: smooth;
    height: 100%;
    overflow-x: hidden;
  }

  body {
    position: relative;
    color: var(--dark-font-color);
    background-color: var(--dark-bg-color);
    overflow-x: hidden;
    font-family: "Roboto", sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  .light-mode {
    color: var(--light-font-color);
    background-color: var(--light-bg-color);
  }

  .App {
    text-align: center;
    align-items: center;
    align-content: center;
    justify-content: center;
  }
</style>
