<script lang="ts">
  import { onMount } from "svelte"
  import { usersStore, userToView } from "./store/stores"
  import DisplayPost from "./DisplayPost.svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import ImageForm from "./ImageForm.svelte"

  import anon from "./assets/anon.png"
  import * as linkify from "linkifyjs"
  import linkifyHtml from "linkify-html"

  import Fa from "svelte-fa"
  import { faCheckCircle, faCalendarDays, faCalendarAlt } from "@fortawesome/free-solid-svg-icons"

  import inf from "./assets/inf.gif"

  let coverImage =
    "https://cdn.thenewstack.io/media/2022/02/aec396cd-screenshot-2022-02-04-at-2.56.57-pm.png"
  export let auth
  export let handle = ""
  export let signIn
  export let principal = ""
  export let create = false
  export let view = 0 // 0 show posts, 1 posts and replies, 2 media, 3 likes, 4 followers/followees
  export let user = null

  const options = {
    formatHref: {
      hashtag: (href) =>
        "https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/hashtag/" + href.substr(1),
      // "http://localhost:3000/hashtag/" + href.substr(1),
      mention: (href) =>
        "https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/profile" + href,
      // "http://localhost:3000/profile" + href,
    },
    defaultProtocol: "https",
    className: "post-url",
  }

  let name = ""
  let age = 42
  let city = ""
  let picture = ""
  let cover = ""
  let twitter = ""
  let discord = ""
  let bio = ""
  let website = ""
  let imageform

  let editMode = false
  let response = null
  let errorResponse = ""
  let errorRefresh = ""
  let isGetting = true
  let posts = []
  let processing = false
  let followerCount = $userToView?.followers.length ?? 0

  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  const processUserData = (user, posts, doReverse = true) => {
    user.markets = user.markets.sort(function (a, b) {
      var keyA = Number(a.marketId),
        keyB = Number(b.marketId)
      if (keyA < keyB) return -1
      if (keyA > keyB) return 1
      return 0
    })
    user.ownMarkets = user.markets.filter((m) => m.author)
    user.otherMarkets = user.markets.filter((m) => !m.author)

    if (doReverse) {
      user.txs = user.txs.reverse()
      user.posts = posts.reverse()
    } else {
      user.posts = posts
    }
    picture = user.picture
    cover = user.cover
    name = user.name
    handle = user.handle
    bio = user.bio
    followerCount = user.followers.length

    isGetting = false
  }

  let processingFollow = false
  let processingUnFollow = false

  const followUser = async () => {
    if (handle != "") {
      processingFollow = true
      processingUnFollow = false
      followerCount += 1
      const resp = await $auth.actor.followUser(handle)
    }
  }

  const unfollowUser = async () => {
    if (handle != "") {
      processingUnFollow = true
      processingFollow = false
      followerCount -= 1
      const resp = await $auth.actor.unfollowUser(handle)
    }
  }

  let getUserData = async () => {
    let resp = {}

    if ($userToView != null) {
      user = $userToView
      user.posts = []
      user.replies = []
    }

    if (principal === "" && handle === "") {
      isGetting = true
      setTimeout(getUserData, 500)
    } else if (handle !== "") {
      isGetting = true
      resp = await $auth.actor.getUserWithPosts(handle)
    } else if (principal !== "") {
      isGetting = true
      resp = await $auth.actor.getUserFromPrincipal(principal)
    }
    if ("ok" in resp) {
      
      const data = resp["ok"]
      user = data[0]["v4"]

      posts = data[1].map((fp) => {
        let p = fp[0]["v3"]
        p.market = fp[1]
        p.simpleMarket = fp[2]
        p.likes = p.mentions
        return p
      })
      if (user) {
        processUserData(user, posts)
      }
    } else {
      resp = await $auth.actor.createAnonUser()
      if ("ok" in resp) {
        const data = resp["ok"]
        user = data[0]["v4"]
        posts = data[1].map((fp) => {
          let p = fp[0]["v3"]
          p.market = fp[1]
          p.simpleMarket = fp[2]
          p.likes = p.mentions

          return p
        })
        if (user) {
          processUserData(user, posts)
        }
      }
    }
  }

  let createUserData = async () => {
    errorResponse = ""
    age = Number(age)
    name = name.trim()
    handle = handle.trim()
    let initData = {
      id: principal,
      handle,
      name,
      age,
      city,
      picture,
      cover,
      twitter,
      discord,
      bio,
      website,
      number: 0,
      canister: "",
    }

    if (editMode) {
      response = await $auth.actor.editUser(initData)
    } else {
      response = await $auth.actor.createUser(initData)
    }
    if ("err" in response) {
      errorResponse =
        "Error: " +
        splitCamelCaseToString(Object.keys(response["err"]).toString())
    } else {
      user = response["ok"]["v4"]
      if (user) {
        processUserData(user, posts, false)
      }
      editMode = false
    }
  }

  const isFollowing = (principal, user) => {
    for (const follower of user.followers) {
      if (follower["v0"].userdata.principal == principal) return true
    }
    return false
  }

  onMount(getUserData)
</script>

<svelte:head>
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="@seers_app" />
  <meta name="twitter:creator" content="@seers_app" />
  <meta
    name="twitter:title"
    content={user ? "Profile: " + user?.name : "Come see my Seers profile"}
  />
  <meta
    name="twitter:description"
    content={user ? user?.bio : "You will regret it otherwise"}
  />
  <meta name="twitter:image" content={user ? user?.picture : anon} />
</svelte:head>

<filter id="round">
  <feGaussianBlur in="SourceGraphic" stdDeviation="5" result="blur" />
  <feColorMatrix
    in="blur"
    mode="matrix"
    values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 19 -9"
    result="goo"
  />
  <feComposite in="SourceGraphic" in2="goo" operator="atop" />
</filter>

{#if editMode}
  <div class="header">
    <h3>Edit Profile</h3>
  </div>
{/if}

<div class="outer-container">
  {#if user && !editMode}
    <div class="inner-container">
      {#if user?.picture.includes("raw.ic0.app/?tokenid=") && !user?.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")}
        <img
          src={user?.cover.concat("&type=thumbnail")}
          alt="cover"
          onError="this.src='{coverImage}';"
          style="width: 100%; object-fit: cover; height: 200px;"
        />
      {:else}
        <img
          src={user?.cover}
          alt="cover"
          onError="this.src='{coverImage}';"
          style="width: 100%; object-fit: cover; height: 200px;"
        />
      {/if}
    </div>
    <div
      class="inner-container"
      style="border-bottom: 0px; justify-content:flex-start; flex-direction: row"
    >
      <div style="text-align:start; width: 100px;  padding: 5px;">
        {#if user?.picture.includes("e4cao-6iaaa-aaaab-qah2q-cai")}
        <img
        src={`${user?.picture}`}
        alt="avatar"
        onError="this.src='{anon}';"
        style="width: 100px; height: 100px; border-radius:50%; object-fit:cover;margin-top: -30px; border: 3px solid black"
      />
        {:else if user?.picture.includes("?tokenid=") && !user?.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai") && !user?.picture.includes("skjpp-haaaa-aaaae-qac7q-cai") && !user.picture.includes("pk6rk-6aaaa-aaaae-qaazq-cai")}
          <img
            src={`${user?.picture}&type=thumbnail`}
            alt="avatar"
            onError="this.src='{anon}';"
            style="width: 100px; height: 100px; border-radius:50%; object-fit:cover;margin-top: -30px; border: 3px solid black"
          />
        {:else if user?.picture.includes("?tokenid=")}
          <iframe
            src={`${user?.picture}&type=thumbnail`}
            title=""
            style="width: 100px; height: 100px; border-radius:50%; object-fit:cover;margin-top: -30px; border: 3px solid black"
          />
        {:else}
          <img
            src={user?.picture ? user?.picture : anon}
            alt="avatar"
            onError="this.src='{anon}';"
            style="width: 100px; height: 100px; border-radius:50%; object-fit:cover;margin-top: -30px; border: 3px solid black"
          />
        {/if}
      </div>

      <div style="margin-left: 5px;  width: 100px; justify-content: flex-start">
        <div style="display:flex; gap: 5px; align-items:center; width: 200px;">
          {user?.name}
          {#if user?.twitter}
            <Fa icon={faCheckCircle} color="rgb(29, 155, 240)" />
          {/if}
        </div>
        <div style="color:gray">@{user?.handle}</div>
        {#if user?.twitter}
          <div>
            <a
              href={`https://twitter.com/${user?.twitter}`}
              class="post-url"
              target="_blank">@{user?.twitter}</a
            >
          </div>
        {/if}
      </div>
      {#if user && principal == user?.id}
        <div
          style="margin-bottom: 10px; width: 150px; text-align:end; display: flex; justify-content:end; flex-grow: 1"
        >
          <button class="btn-grad" on:click={() => (editMode = true)}
            >Edit Profile</button
          >
          <div style="text-align:center;color:red">
            {errorRefresh}
          </div>
        </div>
      {:else if user && principal != user?.id}
        {#if processingUnFollow || (!processingFollow && !isFollowing(principal, user))}
          <div
            style="margin-bottom: 10px; width: 150px; text-align:end; display: flex; justify-content:end; flex-grow: 1"
          >
            <button class="btn-grad" on:click={followUser}>Follow</button>
            <div style="text-align:center;color:red">
              {errorRefresh}
            </div>
          </div>
        {:else}
          <div
            style="margin-bottom: 10px; width: 150px; text-align:end; display: flex; justify-content:end;flex-grow: 1"
          >
            <button class="btn-grad" on:click={unfollowUser}>Unfollow</button>
            <div style="text-align:center;color:red">
              {errorRefresh}
            </div>
          </div>
        {/if}
      {/if}
    </div>
    <div class="inner-container" style="border-top: 0px; border-bottom: 0px;">
      <div style="width: 100%; text-align:start; margin: 5px; padding: 5px">
        {@html user?.bio ? linkifyHtml(user?.bio, options) : ""}
      </div>
    </div>
    <div class="inner-container" style="border-top: 0px;">
      <div style="width: 100%; text-align:start; margin: 5px; padding: 5px">
        <button
          style="all:unset; cursor: pointer"
          on:click={() => {
            if (view != 5) view = 5
            else view = 0
          }}
          >{user?.followees.length}
          <span style="color:grey">Following</span></button
        >
        <button
          style="all:unset; cursor: pointer"
          on:click={() => {
            if (view != 4) view = 4
            else view = 0
          }}>{followerCount} <span style="color:grey">Followers</span></button
        >
      </div>
      <div style="color: grey;width: 100%; text-align:start; margin: 5px; padding: 5px">
        <Fa icon={faCalendarDays}  />
        {new Date(
          parseInt(user?.createdAt) / 1_000_000,
        ).toLocaleDateString()}
        - {new Date(
          parseInt(user?.lastSeenAt) / 1_000_000,
        ).toLocaleDateString()}
      </div>
    </div>
    {#if view == 0}
      <div class="inner-container">
        {#each user?.posts as post, i}
          <DisplayPost
            {user}
            {auth}
            {principal}
            {signIn}
            {post}
            setPreview={null}
            refresh={getUserData}
          />
        {/each}
      </div>
    {:else if view == 5}
      <div class="inner-container">
        {#each user?.followees as followee, i}
          <a
            href={"/profile/" + followee["v0"].userdata.handle}
            style="width: 100%"
          >
            <div
              style="width: 100%; padding: 5px; display:flex; align-items:center"
            >
              <img
                src={followee["v0"].userdata.picture}
                alt=""
                loading="lazy"
                onError="this.src='{anon}';"
                style="width: 30px; height: 30px; border-radius: 50%; background-color:transparent; border-color:transparent; padding: 5px; object-fit:cover"
              />
              {followee["v0"].userdata.name} @{followee["v0"].userdata.handle}
            </div>
          </a>
        {/each}
      </div>
    {:else if view == 4}
      <div class="inner-container">
        {#each user?.followers as follower, i}
          <a
            href={"/profile/" + follower["v0"].userdata.handle}
            style="width: 100%"
          >
            <div
              style="width: 100%; padding: 5px; display:flex; align-items:center"
            >
              <img
                src={follower["v0"].userdata.picture}
                alt=""
                loading="lazy"
                onError="this.src='{anon}';"
                style="width: 30px; height: 30px; border-radius: 50%; background-color:transparent; border-color:transparent; padding: 5px; object-fit:cover"
              />
              {follower["v0"].userdata.name} @{follower["v0"].userdata.handle}
            </div>
          </a>
        {/each}
      </div>
    {/if}
  {:else if editMode && !isGetting}
    <div style="display: flex; align-items: center; flex-direction: column">
      <div style="display:flex; flex-direction:column; align-items:center">
        <div style="padding: 10px; margin: 10px">Handle:</div>
        <input
          bind:value={handle}
          type="text"
          style="align-items: center; width:100%; height: 30px; background:black; color:grey;font-size: 1.2em; border: 1px solid grey; border-radius: 5px"
        />
      </div>
      <div style="display:flex; flex-direction:column;align-items:center">
        <div style="padding: 10px; margin: 10px">Name:</div>
        <input
          bind:value={name}
          style="align-items: center; width:100%; height: 30px; background:black; color:grey;font-size: 1.2em; border: 1px solid grey; border-radius: 5px"
        />
      </div>
      <div style="display:flex; flex-direction:column;align-items:center">
        <div style="padding: 10px; margin: 10px">Avatar:</div>
        <!-- <input
          bind:value={picture}
          style="align-items: center; width:100%; height: 30px; background:black; color:grey;font-size: 1.2em; border: 1px solid grey; border-radius: 5px"
        /> -->
        <div>
          <ImageForm
            bind:this={imageform}
            {auth}
            {principal}
            {user}
            setimage={(src) => {
              picture = src
            }}
            imageSize={200}
          />
        </div>
        <img
          src={picture}
          alt="avatar"
          style="width: 200px; border-radius: 15px; padding: 5px"
        />
      </div>
      <div style="display:flex; flex-direction:column;align-items:center">
        <div style="padding: 10px; margin: 10px">Cover:</div>
        <input
          bind:value={cover}
          style="align-items: center; width:100%; height: 30px; background:black; color:grey;font-size: 1.2em; border: 1px solid grey; border-radius: 5px"
        />
        <img
          src={cover}
          alt="cover"
          style="width: 200px; border-radius: 15px; padding: 5px"
        />
      </div>
      <div
        style="display:flex;flex-direction:column; align-items:center; width: 300px"
      >
        <div style="padding: 10px; margin: 10px">Bio:</div>
        <textarea
          placeholder="Social Network for Crypto Natives"
          rows="5"
          bind:value={bio}
          style="align-items: center; width:100%; height: 100px; font-size: 1.5em; border: 1px solid grey; border-radius: 5px "
        />
      </div>

      <DisplayButton
        {principal}
        label="Submit"
        {signIn}
        execute={async () => {
          processing = true
          await createUserData()
          processing = false
        }}
        {processing}
      />
      <div style="color:red">
        {errorResponse}
      </div>
    </div>
  {:else if !isGetting}
    <div style="display: flex; align-items: center; flex-direction: column">
      <div style="width: 100%;display:flex; justify-content:center">
        <button
          class="btn-grad"
          on:click={() => {
            signIn()
          }}>Login</button
        >
      </div>
    </div>
  {:else if create}
    <div style="padding: 20px; text-align:center">
      <div>Creating Profile</div>
      <img src={inf} alt="inf" style="width: 150px; height: 150px" />
    </div>
  {:else}
    <div style="padding: 20px">
      <img src={inf} alt="inf" style="width: 150px; height: 150px;" />
    </div>
  {/if}
</div>

<style global>
  image {
    width: 100px;
    height: 100px;
    object-fit: cover;
    border: 0px;
  }
  .btn-grad {
    height: 40px;
    margin: 10px 10px 10px 10px;
    padding: 0em 10px;
    text-align: center;
    text-transform: capitalize;
    transition: 0.5s;
    background-size: 200% auto;
    color: white;
    box-shadow: 0 0 1px #eee;
    border-radius: 10px;
    display: block;
    outline: 0;
    border: 0;
    cursor: pointer;
    min-width: 100px;
    max-width: 150px;
    white-space: normal;
    font-weight: bold;
  }
</style>
