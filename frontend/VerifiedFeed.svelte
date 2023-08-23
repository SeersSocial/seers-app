<script lang="ts">
  import { onMount } from "svelte"
  import Fa from "svelte-fa"
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import { MetaTags } from "svelte-meta-tags"
  import { feedStore, userToView, loggedUser } from "./store/stores"

  import { faChartBar, faImage } from "@fortawesome/free-regular-svg-icons"
  import {
    faPlus,
    faMoneyBillTransfer,
    faCoins,
    faCirclePlus,
    faPlusCircle,
    faMinusCircle,
    faFirstAid,
  } from "@fortawesome/free-solid-svg-icons"
  import { useNavigate } from "svelte-navigator"

  import DisplayPost from "./DisplayPost.svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import BetForm from "./bets/BetForm.svelte"
  import InputForm from "./InputForm.svelte"
  import { Rec } from "@dfinity/candid/lib/cjs/idl"

  import inf from "./assets/inf.gif"
  import { uniqBy } from "./utils/utils"
  import { children } from "svelte/internal"
  import RecursivePost from "./RecursivePost.svelte"

  export let auth
  export let principal
  export let signIn
  export let viewpost = null
  export let viewuser = null
  export let feed = null
  export let user = $loggedUser

  let showInput = false
  let processing = false
  let processingFeed = false
  let collateralSelected = "seers"
  let liquidity = 100.0
  let toHandle = ""
  let toValue = ""
  let newPost = null
  let errorResponse = ""
  let showMoneyForm = false
  let showBetForm = false
  let showImageForm = false
  let showMarketForm = false
  let sendBet = false
  let startDate = ""
  let endDate = ""
  let image = {
    label: "Image URL",
    value:
      "https://cdn.pixabay.com/photo/2015/04/19/08/32/marguerite-729510__340.jpg",
  }

  export const getFeed = async () => {
    feed = await $auth.actor.getFeed()

    feed = feed.reverse()
    feed = feed.map((p) => {
      let post = p[0]["v3"]
      post.market = p[1]
      post.simpleMarket = p[2]
      post.likes = post.mentions

      return post
    })
    feed = uniqBy(feed, (item) => {
      return Number(item.id)
    })

    let postMap = new Map()

    // Create map of id -> post.
    feed.forEach((post) => {
      postMap.set(post.id, post)
    })

    // Filter only verified posts.
    feed = feed.filter((p) => p.verified)

    // Attach children to post in map.
    feed.forEach((post) => {
      if (post.parent && post.parent.length > 0) {
        let parent = postMap.get(post.parent[0].id)
        if (parent && "children" in parent) {
          parent.children.push(post)
        } else if (parent) {
          parent.children = [post]
        }
        postMap.delete(post.id)
      }
    })
    feed = Array.from(postMap.values())
    let feedNoImage = []
    let feedImage = []

    feed.forEach((post) => {
      if ("children" in post) {
        post.children = post.children.reverse()
      }
    })

    $feedStore = feed

    newPost = null
    if (principal !== "" && !$loggedUser) {
      const resp = await $auth.actor.getUserFromPrincipal(principal)
      if ("ok" in resp) {
        user = resp["ok"][0]["v4"]
      }
    }

    return [feed, user]
  }
</script>

<svelte:head>
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@seers_app" />
  <meta name="twitter:creator" content="@seers_app" />
  <meta name="twitter:title" content="Seers" />
  <meta name="twitter:description" content="Decentralised Social Network" />
  <meta
    name="twitter:image"
    content="https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/assets/logo.jpeg"
  />
</svelte:head>

{#if window.innerWidth < 1100}
  <div
    style={`position:fixed;top: ${
      (window.innerHeight * 15) / 16
    }px; right: 40px; z-index:2000;`}
  >
    <button
      style="width: fit-content; margin: 0px; padding: 0px;  background-color: rgba(0, 0, 0, 0);overflow:hidden;"
      on:click={() => {
        if (showInput) {
          showInput = false
        } else {
          showInput = true
        }
      }}
    >
      {#if showInput}
        <Fa
          icon={faMinusCircle}
          class="plus-circle"
          style="font-size: 48px;  border-radius: 50%; background-color:white"
        />
      {:else}
        <Fa
          icon={faPlusCircle}
          class="plus-circle"
          style="font-size: 48px;  border-radius: 50%; background-color:white"
        />
      {/if}
    </button>
  </div>
{:else}
  <div class="outer-container">
    <div
      class="inner-container"
      style="justify-content: left; border-bottom: 0px solid black"
    >
      <h3 class="headline" style="padding: 10px">Home</h3>
    </div>
  </div>
{/if}

<div class="outer-container">
  {#if window.innerWidth >= 1100 || showInput}
    <div class="inner-container">
      <InputForm
        {auth}
        {principal}
        {signIn}
        {getFeed}
        {user}
        parent={null}
        setPreview={(preview) => {
          newPost = preview
          showInput = false
        }}
      />
    </div>
  {/if}
  {#if !showInput}
    <div class="inner-container">
      {#if newPost}
        <DisplayPost
          {user}
          {auth}
          {principal}
          {signIn}
          post={newPost}
          refresh={getFeed}
          setPreview={(preview) => {
            newPost = preview
          }}
        />
      {/if}
      {#if $feedStore.length > 0}
        {#each $feedStore as post, i (post.id)}
          <RecursivePost
            {auth}
            {principal}
            {user}
            {signIn}
            {post}
            {getFeed}
            {viewpost}
            {viewuser}
            doNotShowBorder={false}
            doNotShowParent={true}
            tabNums={0}
            lastChild={i == $feedStore.length - 1}
          />
        {/each}
      {:else if processingFeed}
        <img src={inf} alt="inf" style="width: 150px; height: 400%;" />
      {:else}
        <img src={inf} alt="inf" style="width: 150px; height: 400%;" />
      {/if}
    </div>
  {/if}
</div>
