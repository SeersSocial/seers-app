<script lang="ts">
  import { onMount } from "svelte"

  import Fa from "svelte-fa"

  import {
    faComment,
    faHeart,
    faCircleCheck,
  } from "@fortawesome/free-regular-svg-icons"
  import {
    faRetweet,
    faEllipsis,
    faCheckCircle,
    faHeart as faSolidHeart,
    faArrowUpFromBracket,
  } from "@fortawesome/free-solid-svg-icons"
  import inf from "./assets/inf.gif"
  import { Jumper, Moon, Plane } from 'svelte-loading-spinners';
  
  import {
    parseTwitterDate,
    splitCamelCaseToString,
    textAreaAdjust,
    urlify,
  } from "./utils/utils.js"
  import DisplayBet from "./bets/DisplayBet.svelte"
  import Modal from "./Modal.svelte"
  import NewContent from "./NewContent.svelte"
  import DisplayButton from "./DisplayButton.svelte"
  import { useNavigate } from "svelte-navigator"
  import { modal } from "./store/stores.js"
  import * as linkify from "linkifyjs"
  import linkifyHtml from "linkify-html"
  import { LogarithmicScale } from "chart.js"
  import Content from "./Content.svelte"
  import anon from "./assets/anon.png"

  export let auth
  export let principal
  export let signIn
  export let post
  export let user
  export let setPreview
  export let isThread = false
  export let doNotShowBorder = false
  export let isMain = false
  export let doNotShowParent = false
  export let refresh
  export let isEditing = false
  export let viewpost = null
  export let viewuser = null

  const navigate = useNavigate()

  const options = {
    formatHref: {
      hashtag: (href) =>
        "https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/hashtag/" + href.substr(1),
      // "http://localhost:3000/hashtag/" + href.substr(1),
      mention: (href) =>
        "https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/profile" + href,
      // "http://localhost:3000/profile" + href,
    },
    ignoreTags: ["iframe", "blockquote"],
    target: "_blank",
    defaultProtocol: "https",
    className: "post-url",
  }

  let tokens = ""
  let marketId = 0
  let displayDropdown = "none"
  let amount = 1.0
  let errorResponse = ""
  let processing = false
  let fullPageBackground = ""
  let imageFullPage = "none"
  let processingEdit = false
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

  function getId(url) {
    const regExp =
      /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/
    const match = url.match(regExp)

    return match && match[2].length === 11 ? match[2] : null
  }

  const printFloat = (x) => {
    if (x > 10000) {
      return (Number(x) / 1000.0).toFixed(2) + "k"
    } else {
      return Number(x).toFixed(2)
    }
  }

  const getPost = async () => {
    const resp = await $auth.actor.getThread(Number(post.id))
    if ("ok" in resp) {
      post = resp["ok"].main[0]["v3"]
      post.market = resp["ok"].main[1]
      post.simpleMarket = resp["ok"].main[2]
      post.content = post.content.trim()
    }
  }

  const submitEdit = async () => {
    let initData = {
      id: post.id,
      author: post.author,
      content: post.content,
      parent: post.parent,
      retweet: post.retweet,
      image: post.image,
      images: post.images,
      hashtags: post.hashtags,
      mentions: post.mentions,
      verified: post.verified,
      pdfs: post.pdfs,
      market: "id" in post.market ? post.market.id : 0,
      simpleMarket: "id" in post.simpleMarket ? post.simpleMarket.id : 0,
      isRetweet: post.isRetweet,
    }
    const resp = await $auth.actor.editPost(initData, [])
    if ("ok" in resp) {
      navigate(`/post/${post.id}`)
    } else {
      errorResponse = resp["err"]
    }
  }

  const submitDelete = async (postId) => {
    const resp = await $auth.actor.submitDelete(Number(postId))
    if ("err" in resp) {
      errorResponse = Object.keys(resp["err"]).toString()
    } else {
      refresh()
    }
  }

  const submitBuy = async (marketId, selected, amount) => {
    processing = true
    selected = selected === undefined ? 0 : selected
    const resp = await $auth.actor.buyOutcome(
      marketId,
      Number(amount * 100_000_000),
      selected,
      true,
    )
    if ("err" in resp) {
      errorResponse = Object.keys(resp["err"]).toString()
    } else {
      getPost()
      amount = 0.1
    }
    processing = false
  }

  const submitLike = async (postId) => {
    const resp = await $auth.actor.submitLike(Number(postId))
    if ("err" in resp) {
      errorResponse = resp["err"]
    } else {
      getPost()
    }
  }

  const submitRetweet = async () => {
    const resp = await $auth.actor.submitRetweet(Number(post.id))
    if ("err" in resp) {
      errorResponse = resp["err"]
    } else {
      getPost()
    }
  }

  const refreshPrice = async () => {
    if (
      typeof post === "object" &&
      "market" in post &&
      post["market"].length > 0
    ) {
      marketId = post.market[0].id
      const final_amount = Number(amount) * 100_000_000
      if (marketId > 0) {
        let selected =
          post.market[0].selected === undefined ? 0 : post.market[0].selected
        countdown(parseInt(post.market[0].endDate) / 1_000_000)
        const resp = await $auth.actor.buyOutcome(
          marketId,
          final_amount,
          selected,
          false,
        )
        if ("ok" in resp) {
          tokens = resp["ok"]
        }
      }
    } else {
      setTimeout(refreshPrice, 2000)
    }
  }

  onMount(refreshPrice)
</script>

{#if isMain && post}
  <div id="main" style="border-top: 0px solid grey; ">
    <div
      style="display:flex; justify-content:start; text-align:start; width: 100%; padding: 0px; flex-direction:row; align-items:center; font-size: 1.2em; "
    >
      <div style="padding: 0px; margin: 0px 3px 3px 3px; height: 100%;">
        <a href={`/profile/${post?.author.handle}`} style="display:flex">
          {#if post.author.picture.includes("e4cao-6iaaa-aaaab-qah2q-cai")}
          <img
              src={`${post.author.picture}`}
              alt=""
              onError="this.src='{anon}';"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; border-color:transparent"
            />
          {:else if post.author.picture.includes("?tokenid=") && !post.author.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")  && !post.author.picture.includes("skjpp-haaaa-aaaae-qac7q-cai") && !post.author.picture.includes("pk6rk-6aaaa-aaaae-qaazq-cai")}
            <img
              src={`${post.author.picture}&type=thumbnail`}
              alt=""
              onError="this.src='{anon}';"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; border-color:transparent"
            />
          {:else if post.author.picture.includes("?tokenid=")}
            <iframe
              src={`${post.author.picture}&type=thumbnail`}
              title=""
              style="width: 46px; height: 50px; object-fit: cover; border-radius: 50%; border-color:transparent"
            />
          {:else}
            <img
              src={post?.author.picture
                ? post?.author.picture
                : anon + post?.author.handle}
              alt=""
              onError="this.src='{anon}';"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; border-color:transparent"
            />
          {/if}
        </a>
      </div>
      <div
        on:click={async () => {
          // viewuser(post?.author.handle)
          navigate(`/profile/${post?.author.handle}`, { replace: true })
        }}
        style="display:flex; flex-direction:column; height: 100%; flex-grow: 1"
      >
        <div>
          {post ? post.author.name : ""}
          {#if post?.verified}
            <Fa icon={faCheckCircle} color="rgb(29, 155, 240)" />
          {/if}
        </div>
        <span style="color:grey">
          @{post ? post.author.handle : ""}
        </span>
      </div>
      <!-- <div style="width: 100%; display:flex; justify-content:end"> -->
      <div class="menu-button-elli">
        <div class="dropdown">
          <button
            class="dropbtn"
            on:click|stopPropagation={() => {
              if (
                !document
                  .getElementById(`Dropdown-${post?.id}`)
                  .classList.contains("show") &&
                displayDropdown == "none"
              ) {
                displayDropdown = "block"
                document
                  .getElementById(`Dropdown-${post?.id}`)
                  .classList.toggle("show")
              } else {
                displayDropdown = "none"
              }
            }}><Fa icon={faEllipsis} /></button
          >
          {#if post?.author.handle == user?.handle}
            <div id="Dropdown-{post.id}" class="dropdown-content">
              <button
                on:click|stopPropagation={() => {
                  navigate(`/post/${post.id}/edit`, { replace: true })
                }}
                class="link">Edit</button
              >
              <button
                on:click|stopPropagation={() => submitDelete(post.id)}
                class="link">Delete</button
              >
            </div>
          {:else}
            <div id="Dropdown-{post?.id}" class="dropdown-content">
              <button on:click|stopPropagation={null} class="link"
                >Follow</button
              >
              <button on:click|stopPropagation={null} class="link">Block</button
              >
            </div>
          {/if}
        </div>
        <!-- </div> -->
      </div>
    </div>
    <div
      style="flex-grow: 1; justify-content: start; text-align:start; padding: 0px 5px; word-break:break-word;"
    >
      <div
        style="width: 100%; text-align:start; padding: 0px 0px; border-bottom: 0px solid grey;"
      >
        <div
          style="padding: 5px; font-size: 1.2em; white-space: pre-line; overflow-wrap:break-word"
        >
          {#if !isEditing}
            {@html post ? linkifyHtml(post.content, options) : ""}
          {:else}
            <textarea
              autofocus
              bind:value={post.content}
              rows="3"
              onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
              onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
              style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 5px 5px 5px 50px; border-radius: 15px"
            />
          {/if}
        </div>
      </div>
      {#if post && post.market.length > 0}
        <img
          src={post.market[0].imageUrl}
          alt=""
          style="width: 95%; border-radius: 15px; object-fit:cover"
          onerror="this.style.display = 'none'"
        />
        <div>
          {#each post.market[0].labels as label, i}
            <div
              style="width: 100%; display: flex; cursor: pointer; margin: 0px; padding: 0px; align-items: center; position: relative"
            >
              {#if "open" in post.market[0].state}
                <div
                  style={`background: rgb(56 55 55); width: ${
                    Number(post.market[0].probabilities[i]) * 0.0075
                  }%;  height:24px; display:flex;position:absolute;z-index:-100; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; justify-content:start; align-items:center;text-align:left`}
                />
                <button
                  style="all:unset; width: 200px; display:flex; margin-left: 5px; align-items:center"
                  on:click|stopPropagation={async () => {
                    post.market[0].selected = i
                    await refreshPrice()
                  }}
                >
                  {label.slice(0, 20)}
                  {#if post.market[0].selected == i || (post.market[0].selected === undefined && i == 0)}
                    <Fa
                      icon={faCircleCheck}
                      style="padding-left: 5px; color: #1d9bf0"
                    />
                  {/if}
                </button>
              {:else}
                <div
                  style={`background: rgb(56 55 55); width: ${Number(
                    Number(post.market[0].probabilities[i]) * 0.0075,
                  )}%; height:24px; display:flex;position:absolute;z-index:-100; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; justify-content:start; align-items:center;text-align:left`}
                />
                <div style="margin-left: 5px">
                  {label.slice(0, 20)}
                  {#if post.market[0].state["resolved"] == i || (post.market[0].state["resolved"] === undefined && post.market[0].state["closed"] === undefined && i == 0)}
                    <Fa icon={faCircleCheck} style="padding-left: 5px" />
                  {/if}
                </div>
              {/if}
              <div
                style="flex-grow: 1; justify-content:flex-end; text-align:end;padding: 5px; height: 24px; overflow:hidden;"
              >
                {(Number(post.market[0].probabilities[i]) / 10_000).toFixed(2)}
                {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
              </div>
            </div>
          {/each}
          <div
            style="width: 100%; display: flex; flex-direction: row; font-size: 1em; padding-top: 5px"
          >
            ID: {post.market[0].id}
            Volume: {printFloat(Number(post.market[0].volume) / 100_000_000)}
            {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
            Liquidity: {printFloat(
              Number(post.market[0].liquidity) / 100_000_000,
            )}
            {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
            Ends: {countdownStr}
          </div>

          <div
            style="display:flex; text-align:end; justify-content:start; flex-grow: 1"
          >
            {#if processing}
              <button
                class="btn-grad"
                style="width: 100px; margin: 15px 0px; overflow:hidden;"
                on:click|stopPropagation={() => {
                  if (principal === "") {
                    signIn()
                  } else {
                    submitBuy(
                      post.market[0].id,
                      post.market[0].selected,
                      amount,
                    )
                  }
                }}
              >
                <img
                  src={inf}
                  alt="inf"
                  style="width: 150px; height: 400%; margin: -75%;"
                />
              </button>

              <div
                style="display:flex; text-align:center; align-items:center; padding: 0px 5px; font-size: 1em; "
              >
                <input
                  style="font-size: 1em; font-family: 'Roboto Mono', monospace; border: 1px solid grey; padding: 0px 5px; margin: 0px 3px; width: 5ch;height: 40px; border-radius: 10px;"
                  bind:value={amount}
                />, win {(Number(tokens) / 100_000_000).toFixed(2)}
                {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
              </div>
            {:else if "open" in post.market[0].state}
              <button
                class="btn-grad"
                style="width: 100px; margin: 15px 0px; overflow:hidden;"
                on:click|stopPropagation={() => {
                  if (principal === "") {
                    signIn()
                  } else {
                    submitBuy(
                      post.market[0].id,
                      post.market[0].selected,
                      amount,
                    )
                  }
                }}>Bet</button
              >
              <div
                style="display:flex; text-align:center; align-items:center; padding: 0px 5px; font-size: 1em; "
              >
                <input
                  style="font-size: 1em; font-family: 'Roboto Mono', monospace; border: 1px solid grey; padding: 0px 5px; margin: 0px 3px; width: 5ch; height: 40px; border-radius: 10px;"
                  bind:value={amount}
                  on:change={refreshPrice}
                />, win {(Number(tokens) / 100_000_000).toFixed(2)}
                {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
              </div>
            {:else if "resolved" in post.market[0].state}
              Resolved to {post.market[0].labels[
                post.market[0].state["resolved"]
              ]}.
              <a
                href="/market/{post.market[0].id}"
                style="margin-left: 5px; color:#1d9bf0">More</a
              >
            {/if}
          </div>
        </div>
        {#if errorResponse != ""}
          <div style="text-align:center;color:red">
            {splitCamelCaseToString(errorResponse)}
          </div>
        {/if}
      {:else if post && post.images && post.images.length > 0}
        <div>
          <div style="width: 95%; display:flex;flex-wrap:wrap">
            {#each post.images as img, i}
              {#if post.images.length == 1}
                <img
                  src={img}
                  alt=""
                  style="width: 100%;border-radius: 15px 15px 15px 15px; max-height: 600px; object-fit:cover; border-color:transparent"
                  onerror="this.style.display = 'none'"
                  on:click|stopPropagation={() => {
                    imageFullPage = "block"
                    fullPageBackground = "url('" + img + "')"
                  }}
                />
              {:else if post.images.length == 2}
                {#if i == 0}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 400px;border-radius: 15px 0px 0px 15px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 400px;border-radius: 0px 15px 15px 0px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {/if}
              {:else if post.images.length == 3}
                {#if i == 0}
                  <img
                    src={img}
                    alt=""
                    style="width: 100%; max-height: 200px; border-radius: 15px 15px 0px 10px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else if i == 1}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 200px;border-radius: 0px 0px 0px 15px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 200px;border-radius: 0px 0px 15px 0px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {/if}
              {:else if post.images.length == 4}
                {#if i == 0}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 200px;border-radius: 15px 0px 0px 0px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else if i == 1}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%;max-height: 200px; border-radius: 0px 15px 0px 0px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else if i == 2}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 200px;border-radius: 0px 0px 0px 15px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {:else if i == 3}
                  <img
                    src={img}
                    alt=""
                    style="width: 50%; max-height: 200px;border-radius: 0px 0px 15px 0px; object-fit:cover"
                    onerror="this.style.display = 'none'"
                    on:click|stopPropagation={() => {
                      imageFullPage = "block"
                      fullPageBackground = "url('" + img + "')"
                    }}
                  />
                {/if}
              {/if}
            {/each}
            <div
              id="fullpage"
              style="display: {imageFullPage}!important; background-image: {fullPageBackground}!important;"
              on:click|stopPropagation={() => {
                imageFullPage = "none"
                fullPageBackground = ""
              }}
            />
          </div>
          <!-- {/if} -->
        </div>
      {:else if post && post.image.length > 0}
        <div>
          {#if post.image[0].includes("youtu")}
            <iframe
              width="100%"
              height="400px"
              src={`https://www.youtube.com/embed/${getId(post.image[0])}`}
              title="YouTube"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen
            />
          {:else if post.image[0].endsWith("mp4")}
            <!-- svelte-ignore a11y-media-has-caption -->
            <video width="100%" height="300" controls>
              <source src={post.image[0]} type="video/mp4" />
            </video>
          {:else}
            <img
              src={post.image[0]}
              alt=""
              style="width: 95%; max-height: 300px; border-radius: 15px; object-fit: contain ; border-color:transparent"
              onerror="this.style.display = 'none'"
            />
          {/if}
        </div>
      {:else if post && post.simpleMarket.length > 0}
        <DisplayBet
          {auth}
          {principal}
          {signIn}
          bet={post.simpleMarket[0]}
          doNotShowBorder={true}
          refresh={getPost}
          managed={true}
        />
      {:else if post && post.pdfs && post.pdfs.length > 0}
        <iframe src={post.pdfs[0]} title="pdf" width="100%" height="600px" />
        <p>
          You can <a href={post.pdfs[0]} target="_blank"
            >click here to download the PDF file.</a
          >
        </p>

        <!-- <embed src={post.pdfs[0]} style="width: 100%; height: 600px" /> -->
      {/if}
      <div style="color:grey; padding: 5px 0px;border-bottom: 1px solid #333;">
        {new Date(
          parseInt(post ? post.createdAt : 0) / 1_000_000,
        ).toDateString()}
        -
        {new Date(
          parseInt(post ? post.createdAt : 0) / 1_000_000,
        ).toLocaleTimeString()}
      </div>
      <div
        style="width: 100%; display:flex; gap: 30px; padding: 10px 0px; color:grey; border-bottom: 1px solid #333;"
      >
        <div style="width: fit-content; display:flex; gap: 15px">
          <div>{post ? post.retweeters.length : 0}</div>
          <div>Retweets</div>
        </div>
        <div style="width: 100px; display:flex; gap: 15px">
          <div>{post ? post.likes.length : 0}</div>
          <div>Likes</div>
        </div>
      </div>
      <div
        style="width: 100%; display:flex; gap: 30px; padding: 10px 0px; color:grey; border-bottom: 1px solid #333;"
      >
        <div style="min-width: 80px; display:flex; gap: 15px">
          <div><Fa icon={faComment} /></div>
        </div>
        <div style="min-width: 80px; display:flex; gap: 15px">
          <div><Fa icon={faRetweet} /></div>
        </div>
        <div style="min-width: 80px; display:flex; gap: 15px">
          <div>
            <button
              on:click|stopPropagation={() => {
                if (principal === "") signIn()
                else {
                  const liked = post.likes.find(
                    (ud) => ud.author.principal == principal,
                  )

                  if (liked) {
                    post.likes = post.likes.filter(
                      (ud) => ud.author.principal != liked.author.principal,
                    )
                  } else {
                    post.likes.push({ author: { principal } })
                    post.likes = post.likes
                  }

                  submitLike(post.id)
                }
              }}
              style={`color:${
                post?.likes.find((like) => like.author.principal == principal)
                  ? "rgb(249, 24, 128)"
                  : ""
              }`}
              class="like-bt"
            >
              <Fa
                icon={post?.likes.find(
                  (like) => like.author.principal == principal,
                )
                  ? faSolidHeart
                  : faHeart}
              />
            </button>
          </div>
        </div>
        <div style="min-width: 80px; display:flex; gap: 15px">
          <div>
            {#if post.market.length > 0}
              <a
                style="color:grey"
                href={"https://twitter.com/intent/tweet?text=" +
                  encodeURIComponent(post.content + "\n\n") +
                  "&hashtags=Seers,PredictionMarket" +
                  "&via=seers_app" +
                  "&url=" +
                  `https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/post/${post.id}#main`}
                target="_blank"><Fa icon={faArrowUpFromBracket} /></a
              >
            {:else}
              <a
                style="color:grey"
                href={"https://twitter.com/intent/tweet?text=" +
                  encodeURIComponent(post.content + "\n\n") +
                  "&hashtags=Seers" +
                  "&via=seers_app" +
                  "&url=" +
                  `https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/post/${post.id}#main`}
                target="_blank"><Fa icon={faArrowUpFromBracket} /></a
              >
            {/if}
          </div>
        </div>
      </div>
    </div>
    {#if isEditing}
      <DisplayButton
        {principal}
        label="Submit"
        {signIn}
        execute={async () => {
          processingEdit = true
          await submitEdit()
          processingEdit = false
        }}
        processing={processingEdit}
      />
    {/if}
  </div>
{:else if typeof post === "object"}
  <div style="width: 100%; display:flex; flex-direction:row">
    <div
      class="post-item"
      style={`display:flex; flex-grow: 1 ; justify-content:start; text-align:start; flex-direction:column; align-items:center; border-bottom: ${
        isThread || doNotShowBorder ? 0 : 1
      }px solid rgb(61, 60, 61); margin-top: 10px`}
    >
      {#if post && post.isRetweet.length > 0}
        <div
          style="display:flex; color:grey; font-size: 0.8em; justify-content:start; width: 100%"
        >
          <div style="padding: 15px 0px 0px 2px">
            <Fa icon={faRetweet} />
          </div>
          <div style="padding: 15px 0px 0px 5px">
            <a href={`/profile/${post.isRetweet[0].handle}`} style="color:grey">
              by @{post.isRetweet[0].handle}
            </a>
          </div>
        </div>
      {:else if post && !doNotShowParent && post.parent.length > 0}
        <div
          style="display:flex; color:grey; font-size: 0.8em; justify-content:start; width: 100%"
        >
          <div style="padding: 15px 0px 0px 2px">
            <Fa icon={faComment} />
          </div>
          <div style="padding: 15px 0px 0px 5px; color:grey">
            <a href={`/post/${post.parent[0].id}`} style="color:grey">
              Replying to @{post.parent[0].author.handle}
            </a>
          </div>
        </div>
      {/if}
      <div style="display:flex; width: 100%;">
        <div
          on:click={async () => {
            // viewuser(post?.author.handle)
            navigate(`/profile/${post?.author.handle}`, { replace: true })
          }}
          style="cursor:pointer; display:flex; flex-direction:column; padding: 0px; margin: 0px 3px 3px 3px; height: 100%"
        >
          {#if post.author.picture.includes("e4cao-6iaaa-aaaab-qah2q-cai")}
          <img
              src={`${post.author.picture}`}
              alt=""
              onError="this.src='{anon}';"
              loading="lazy"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; padding: 0px 0px 0px 0px;margin: {doNotShowParent
                ? '0px'
                : '10px'} 0px 0px 0px;; border-color:transparent"
            />
          {:else if post.author.picture.includes("?tokenid=") && !post.author.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai") && !post.author.picture.includes("skjpp-haaaa-aaaae-qac7q-cai") && !post.author.picture.includes("pk6rk-6aaaa-aaaae-qaazq-cai")}
            <img
              src={`${post.author.picture}&type=thumbnail`}
              alt=""
              onError="this.src='{anon}';"
              loading="lazy"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; padding: 0px 0px 0px 0px;margin: {doNotShowParent
                ? '0px'
                : '10px'} 0px 0px 0px;; border-color:transparent"
            />
          {:else if post.author.picture.includes("?tokenid=")}
            <iframe
              src={`${post.author.picture}&type=thumbnail`}
              title=""
              style="width: 46px; height: 50px; object-fit: cover; border-radius: 50%; border-color:transparent"
            />
          {:else}
            <img
              src={post.author.picture ? post.author.picture : anon}
              alt=""
              onError="this.src='{anon}';"
              loading="lazy"
              style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%; padding: 0px 0px 0px 0px;margin: {doNotShowParent
                ? '0px'
                : '10px'} 0px 0px 0px;; border-color:transparent"
            />
          {/if}
          {#if isThread}
            <div style="display:flex; justify-content:center; flex-grow: 1">
              <div
                style="margin-left: 1px; width: 1px; height: 100%; background:rgb(61,60,61)"
              >
                &nbsp;
              </div>
            </div>
          {/if}
        </div>
        <div
          style="flex-grow: 1; overflow: hidden; justify-content: start; text-align:start; padding: {doNotShowParent
            ? '0px 0px 10px 0px'
            : '10px 0px'};width:100%; word-break: break-word;"
        >
          <div style="display:flex; gap: 5px;">
            <div
              on:click={async () => {
                // viewuser(post?.author.handle)
                navigate(`/profile/${post?.author.handle}`, { replace: true })
              }}
              style="cursor:pointer; width:fit-content; max-width: 80%; overflow:hidden;height: fit-content;word-break: break-all;"
            >
              {post?.author?.name}
              {#if post.verified}
                <Fa icon={faCheckCircle} color="rgb(29, 155, 240)"/>
              {/if}
              <span style="color:grey">@{post?.author?.handle}</span>
            </div>
            <div
              style="color:grey; width: fit-content; display: flex; align-items:center; text-align:center"
            >
              - {parseTwitterDate(parseInt(post.createdAt) / 1_000_000)}
            </div>
          </div>
          <!-- <a href={`/post/${post.id}#main`} style="width: 50px"> -->
          <div
            on:click={async () => {
              if (viewpost) viewpost(post)
              navigate(`/post/${post.id}#main`, { replace: true })
            }}
            style="cursor:pointer; width: 100%; text-align:start; padding: 10px 10px 10px 0px;white-space: pre-line"
          >
            {#if post.retweet.length > 0}
              {post.retweet[0].content}
            {:else if !isEditing}
              {#if post.content.length > 600}
                {@html post
                  ? linkifyHtml(post.content.slice(0, 600) + "...", options)
                  : ""}
              {:else}
                {@html post ? linkifyHtml(post.content, options) : ""}
              {/if}
            {:else}
              <textarea
                bind:value={post.content}
                rows="3"
                onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
                onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
                style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 5px 5px 5px 50px; border-radius: 15px"
              />
            {/if}
          </div>
          {#if post && post.market.length > 0}
            <img
              src={post.market[0].imageUrl}
              alt=""
              style="width: 75%; max-height: 300px; border-radius: 15px; object-fit:cover"
              onerror="this.style.display = 'none'"
            />
            <div>
              {#each post.market[0].labels as label, i}
                <div
                  style="width: 100%; display: flex; cursor: pointer; margin: 0px; padding: 0px; align-items: center; position: relative;"
                >
                  {#if "open" in post.market[0].state}
                    <div
                      style={`background: rgb(56 55 55); width: ${Number(
                        Number(post.market[0].probabilities[i]) * 0.0075,
                      )}%; height:24px; display:flex;position:absolute;z-index:-100; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; justify-content:start; align-items:center;text-align:left`}
                    />
                    <button
                      style="all:unset; width: 200px; display:flex; margin-left: 5px; align-items:center"
                      on:click|stopPropagation={async () => {
                        post.market[0].selected = i
                        await refreshPrice()
                      }}
                    >
                      {label.slice(0, 20)}
                      {#if post.market[0].selected == i || (post.market[0].selected === undefined && i == 0)}
                        <Fa
                          icon={faCircleCheck}
                          style="padding-left: 5px; color: #1d9bf0;"
                        />
                      {/if}
                    </button>
                  {:else}
                    <div
                      style={`background: rgb(56 55 55); width: ${Number(
                        Number(post.market[0].probabilities[i]) * 0.0075,
                      )}%; height:24px; display:flex;position:absolute;z-index:-100; padding: 2px 2px 2px 2px; margin: 2px 2px 2px 2px; border: 0px solid black; border-radius: 5px 5px 5px 5px; justify-content:start; align-items:center;text-align:left`}
                    />
                    <div style="margin-left: 5px; align-items:center">
                      {label.slice(0, 20)}
                      {#if post.market[0].state["resolved"] == i || (post.market[0].state["resolved"] === undefined && post.market[0].state["closed"] === undefined && i == 0)}
                        <Fa icon={faCircleCheck} style="padding-left: 5px" />
                      {/if}
                    </div>
                  {/if}
                  <div
                    style="flex-grow: 1; justify-content:flex-end; text-align:end;padding: 5px;height: 24px; overflow:hidden"
                  >
                    {(Number(post.market[0].probabilities[i]) / 10_000).toFixed(
                      2,
                    )}
                    {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
                  </div>
                </div>
              {/each}
              <div
                style="width: 100%; display: flex; flex-direction: row; font-size: 1em; padding-top: 5px"
              >
                ID: {post.market[0].id}
                Vol: {printFloat(Number(post.market[0].volume) / 100_000_000)}
                {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
                Liq: {printFloat(
                  Number(post.market[0].liquidity) / 100_000_000,
                )}
                {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
                Ends: {countdownStr}
              </div>

              <div
                style="display:flex; text-align:end; justify-content:start; flex-grow: 1;"
              >
                {#if processing}
                  <button
                    class="btn-grad"
                    style="width: 100px; margin: 15px 0px; overflow:hidden;"
                    on:click|stopPropagation={() => {
                      if (principal === "") {
                        signIn()
                      } else {
                        submitBuy(
                          post.market[0].id,
                          post.market[0].selected,
                          amount,
                        )
                      }
                    }}
                  >
                    <!-- <Jumper size="60" color="#FFFFFF" unit="px" duration="1s" /> -->
    
                    <img
                      src={inf}
                      alt="inf"
                      style="width: 150px; height: 400%; margin: -75%;"
                    />
                  </button>

                  <div
                    style="display:flex; text-align:center; align-items:center; padding: 0px 5px; font-size: 1em;"
                  >
                    <input
                      style="font-size: 1em; font-family: 'Roboto Mono', monospace; border: 1px solid grey; padding: 0px 5px; margin: 0px 3px; width: 5ch;height: 40px; border-radius: 10px;"
                      bind:value={amount}
                    />
                    , win {(Number(tokens) / 100_000_000).toFixed(2)}
                    {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
                  </div>
                {:else if "open" in post.market[0].state}
                  <button
                    class="btn-grad"
                    style="width: 100px; margin: 15px 0px; overflow:hidden;"
                    on:click|stopPropagation={() => {
                      if (principal === "") {
                        signIn()
                      } else {
                        submitBuy(
                          post.market[0].id,
                          post.market[0].selected,
                          amount,
                        )
                      }
                    }}>Bet</button
                  >

                  <div
                    style="display:flex; text-align:center; align-items:center; padding: 0px 5px; font-size: 1em;"
                  >
                    <input
                      style="font-size: 1em; font-family: 'Roboto Mono', monospace; border: 1px solid grey; padding: 0px 5px; margin: 0px 3px; width: 5ch;height: 40px; border-radius: 10px;"
                      bind:value={amount}
                      on:change={refreshPrice}
                    />
                    , win {(Number(tokens) / 100_000_000).toFixed(2)}
                    {"seers" in post.market[0].collateralType ? "Σ" : "ICP"}
                  </div>
                {:else if "resolved" in post.market[0].state}
                  Resolved to {post.market[0].labels[
                    post.market[0].state["resolved"]
                  ]}.
                  <a
                    href="/market/{post.market[0].id}"
                    style="margin-left: 5px; color:#1d9bf0">More</a
                  >
                {/if}
              </div>
            </div>
            {#if errorResponse != ""}
              <div style="text-align:center;color:red">
                {splitCamelCaseToString(errorResponse)}
              </div>
            {/if}
          {:else if post && post.images && post.images.length > 0}
            <div>
              <div style="width: 95%; display:flex;flex-wrap:wrap">
                {#each post.images as img, i}
                  {#if post.images.length == 1}
                    <img
                      src={img}
                      alt=""
                      loading="lazy"
                      style="width: 100%; max-height: 600px; border-radius: 15px 15px 15px 15px; object-fit:cover; border-color:transparent"
                      onerror="this.style.display = 'none'"
                      on:click|stopPropagation={() => {
                        imageFullPage = "block"
                        fullPageBackground = "url('" + img + "')"
                      }}
                    />
                  {:else if post.images.length == 2}
                    {#if i == 0}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%; max-height: 400px;border-radius: 15px 0px 0px 15px; object-fit:cover"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%; max-height: 400px;border-radius: 0px 15px 15px 0px; object-fit:contain"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {/if}
                  {:else if post.images.length == 3}
                    {#if i == 0}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 100%; max-height: 200px; border-radius: 15px 15px 0px 0px; object-fit:cover; margin-bottom: 2px;"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else if i == 1}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="flex-grow: 1; max-width:50%; max-height: 200px;border-radius: 0px 0px 0px 15px; object-fit:cover;"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="flex-grow: 1; max-width:50%; max-height: 200px;border-radius: 0px 0px 15px 0px; object-fit:cover;"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {/if}
                  {:else if post.images.length == 4}
                    {#if i == 0}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%; max-height: 200px;border-radius: 15px 0px 0px 0px; object-fit:cover"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else if i == 1}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%;max-height: 200px; border-radius: 0px 15px 0px 0px; object-fit:cover"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else if i == 2}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%; max-height: 200px;border-radius: 0px 0px 0px 15px; object-fit:cover"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {:else if i == 3}
                      <img
                        src={img}
                        alt="main"
                        loading="lazy"
                        style="width: 50%; max-height: 200px;border-radius: 0px 0px 15px 0px; object-fit:cover"
                        onerror="this.style.display = 'none'"
                        on:click|stopPropagation={() => {
                          imageFullPage = "block"
                          fullPageBackground = "url('" + img + "')"
                        }}
                      />
                    {/if}
                  {/if}
                {/each}
                <div
                  id="fullpage"
                  style="display: {imageFullPage}!important; background-image: {fullPageBackground}!important;"
                  on:click|stopPropagation={() => {
                    imageFullPage = "none"
                    fullPageBackground = ""
                  }}
                />
              </div>
              <!-- {/if} -->
            </div>
          {:else if post && post.image.length > 0}
            <div>
              {#if post.image[0].includes("youtu")}
                <iframe
                  width="100%"
                  height="300px"
                  src={`https://www.youtube.com/embed/${getId(post.image[0])}`}
                  title="YouTube"
                  frameborder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowfullscreen
                />
              {:else if post.image[0].endsWith("mp4")}
                <!-- svelte-ignore a11y-media-has-caption -->
                <video width="100%" height="300" controls>
                  <source src={post.image[0]} type="video/mp4" />
                </video>
              {:else}
                <img
                  src={post.image[0]}
                  alt=""
                  style="width: 100%; max-height: 600px; border-radius: 15px; object-fit:contain;border-color:transparent"
                  onerror="this.style.display = 'none'"
                  on:click|stopPropagation={() => {
                    imageFullPage = "block"
                    fullPageBackground = "url('" + post.image[0] + "')"
                  }}
                />
              {/if}
              <div
                id="fullpage"
                style="display: {imageFullPage}!important; background-image: {fullPageBackground}!important;"
                on:click|stopPropagation={() => {
                  imageFullPage = "none"
                  fullPageBackground = ""
                }}
              />
            </div>
          {:else if post && post.pdfs && post.pdfs.length > 0}
            <iframe
              src={post.pdfs[0]}
              title="pdf"
              width="100%"
              height="300px"
              frameborder="1"
              scrolling="auto"
            />
            <p>
              You can <a href={post.pdfs[0]} target="_blank"
                >click here to download the PDF file.</a
              >
            </p>

            <!-- <object
            title="pdf"
            data={post.pdfs[0]}
            type="application/pdf"
            width="100%"
            height="300px"
          >
           </object> -->
            <!-- <embed src={post.pdfs[0]} style="width: 100%; height: 300px" /> -->
          {:else if post && post.simpleMarket.length > 0}
            <DisplayBet
              {auth}
              {principal}
              {signIn}
              bet={post.simpleMarket[0]}
              doNotShowBorder={true}
              refresh={getPost}
              managed={true}
            />
          {/if}
          <div
            style="width: 200px; display:flex; padding: 5px 0px; color:grey; justify-content:space-between"
          >
            <!-- <a href={`/post/${post.id}#main`} style="color:grey"> -->
            <div style="min-width: 80px; display:flex; gap: 15px;">
              <div>
                <Modal show={$modal}>
                  <NewContent
                    {post}
                    {auth}
                    {signIn}
                    {principal}
                    {user}
                    {setPreview}
                    getFeed={refresh}
                  />
                </Modal>
                <!-- <button class="reply-bt"><Fa icon={faComment} /></button> -->
              </div>
              {#if post.replies.length > 0}<div>{post.replies.length}</div>{/if}
            </div>
            <!-- </a> -->
            <div style="min-width: 80px; display:flex; gap: 15px;">
              <div>
                <button
                  class="retweet-bt"
                  on:click|stopPropagation={() => {
                    if (principal === "") {
                      signIn()
                    } else {
                      submitRetweet()
                    }
                  }}><Fa icon={faRetweet} /></button
                >
              </div>
              {#if post.retweeters.length > 0}<div>
                  {post.retweeters.length}
                </div>{/if}
            </div>
            <div style="min-width: 80px; display:flex; gap: 15px;">
              <div>
                <button
                  on:click|stopPropagation={() => {
                    if (principal === "") {
                      signIn()
                    }
                    const liked = post.likes.find(
                      (like) => principal == like.author.principal,
                    )

                    if (liked) {
                      post.likes = post.likes.filter(
                        (like) => like.author.principal != liked,
                      )
                    } else {
                      post.likes.push({ author: { principal } })
                      post.likes = post.likes
                    }

                    submitLike(post.id)
                  }}
                  style={`color:${
                    post?.likes.find(
                      (like) => like?.author?.principal == principal,
                    )
                      ? "rgb(249, 24, 128)"
                      : ""
                  }`}
                  class="like-bt"
                  ><Fa
                    icon={post?.likes.find(
                      (like) => like?.author?.principal == principal,
                    )
                      ? faSolidHeart
                      : faHeart}
                  /></button
                >
              </div>
              {#if post.likes.length > 0}
                <div
                  style={`color:${
                    post?.likes.find(
                      (like) => like?.author?.principal == principal,
                    )
                      ? "rgb(249, 24, 128)"
                      : ""
                  }`}
                >
                  {post.likes.length}
                </div>
              {/if}
            </div>
            <div
              style="min-width: 80px; display:flex; gap: 15px; margin-left: 20px"
            >
              <div>
                {#if post.market.length > 0}
                  <a
                    style="color:grey"
                    href={"https://twitter.com/intent/tweet?text=" +
                      encodeURIComponent(post.content + "\n\n") +
                      "&hashtags=Seers,PredictionMarket" +
                      "&via=seers_app" +
                      "&url=" +
                      `https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/post/${post.id}#main`}
                    target="_blank"><Fa icon={faArrowUpFromBracket} /></a
                  >
                {:else if post.id != 0}
                  <a
                    style="color:grey"
                    href={"https://twitter.com/intent/tweet?text=" +
                      encodeURIComponent(post.content + "\n\n") +
                      "&hashtags=Seers" +
                      "&via=seers_app" +
                      "&url=" +
                      `https://oulla-fyaaa-aaaag-qa6fa-cai.ic0.app/post/${post.id}#main`}
                    target="_blank"><Fa icon={faArrowUpFromBracket} /></a
                  >
                {/if}
              </div>
            </div>
          </div>
        </div>
        <div class="menu-button-elli">
          <div class="dropdown">
            <button
              class="dropbtn"
              on:click|stopPropagation={() => {
                if (
                  !document
                    .getElementById(`Dropdown-${post.id}`)
                    .classList.contains("show") &&
                  displayDropdown == "none"
                ) {
                  displayDropdown = "block"
                  document
                    .getElementById(`Dropdown-${post.id}`)
                    .classList.toggle("show")
                } else {
                  displayDropdown = "none"
                }
              }}><Fa icon={faEllipsis} /></button
            >
            {#if post?.author.handle == user?.handle}
              <div id="Dropdown-{post.id}" class="dropdown-content">
                <button
                  on:click|stopPropagation={() => {
                    navigate(`/post/${post.id}/edit`, { replace: true })
                  }}
                  class="link">Edit</button
                >
                <button
                  on:click|stopPropagation={async () => {
                    await submitDelete(post.id)
                    displayDropdown = "none"
                    // document
                    //   .getElementById(`Dropdown-${post.id}`)
                    //   .classList.toggle("show")
                    await refresh()
                  }}
                  class="link">Delete</button
                >
              </div>
            {:else}
              <div id="Dropdown-{post.id}" class="dropdown-content">
                <button on:click|stopPropagation={null} class="link"
                  >Follow</button
                >
                <button on:click|stopPropagation={null} class="link"
                  >Block</button
                >
              </div>
            {/if}
          </div>
        </div>
      </div>
    </div>
  </div>
{:else}
  <div style="width:100%; display:flex; justify-content:center">
    <Plane size="60" color="#50C878" unit="px" duration="1s" />
       
    <!-- <img src={inf} alt="inf" style="width: 150px; height: 150px;" /> -->
  </div>
{/if}

<style global>
  #brand {
    display: none;
  }
  #fullpage {
    display: none;
    position: fixed;
    z-index: 9999;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background-size: contain;
    background-repeat: no-repeat no-repeat;
    background-position: center center;
    background-color: rgba(0, 0, 0, 0.9);
  }
  .link {
    unset: all;
    padding: 12px 16px;
    font-size: 16px;
    cursor: pointer;
  }
  .show {
    display: block !important;
  }
  .handle-display {
    padding-bottom: 15px;
    text-align: center;
    width: fit-content;
    height: 25px;
  }

  @media screen and (max-width: 1100px) {
    .handle-display {
      width: fit-content;
      max-width: 120px;
    }
  }
  .menu-button-elli {
    display: flex;
    width: 20px;
    justify-content: start;
    text-align: start;
    padding: 0px 0px;
    cursor: pointer;
  }

  .menu-button-elli:hover {
    color: #1da1f2;
  }

  .like-bt {
    all: unset;
    cursor: pointer;
  }
  .like-bt:hover {
    color: rgb(249, 24, 128);
  }

  .retweet-bt {
    all: unset;
    cursor: pointer;
  }
  .retweet-bt:hover {
    color: #19cf86;
  }

  .reply-bt {
    all: unset;
    cursor: pointer;
  }
  .reply-bt:hover {
    color: #1da1f2;
  }

  .dropbtn {
    display: flex;
    justify-content: center;
    align-items: center;
    color: grey;
    margin-right: 10px;
    padding: 0px;
    font-size: 16px;
    border: none;
  }

  .dropdown {
    position: relative;
    display: inline-block;
  }

  .dropdown-content {
    display: none;
    position: absolute;
    background-color: rgb(48, 48, 48);
    min-width: 160px;
    margin-top: 0px;
    margin-left: -120px;
    box-shadow: 0px 8px 16px 0px rgba(0, 0, 0, 0.2);
    z-index: 1;
    border-radius: 5px;
    padding: 5px;
  }

  .dropdown-content a {
    padding: 12px 16px;
    text-decoration: none;
    display: block;
  }

  .dropdown-content button {
    unset: all;
    background: rgb(48, 48, 48);
    color: white;
    padding: 12px 16px;
    font-size: 16px;
    cursor: pointer;
    width: 100%;
    text-align: left;
  }

  .dropdown:hover .dropdown-content {
    display: block;
  }
  @media screen and (max-width: 1100px) {
    .dropdown:hover .dropdown-content {
      display: none;
    }
  }

  .dropdown-content button:hover {
    background-color: rgb(68, 68, 68);
  }

  .dropdown-content a:hover {
    background-color: rgb(68, 68, 68);
  }

  body.light-mode .dropdown-content {
    background-color: white;
    box-shadow: 0px 8px 16px 0px rgba(0, 0, 0, 0.2);
  }

  body.light-mode .dropdown-content button {
    unset: all;
    background: white;
    color: black;
    padding: 12px 16px;
    font-size: 16px;
    cursor: pointer;
    width: 100%;
    text-align: left;
  }

  body.light-mode .dropdown-content button:hover {
    background-color: rgb(221, 217, 217);
  }

  body.light-mode .dropdown-content a:hover {
    background-color: rgb(221, 217, 217);
  }

  body.light-mode .dropdown:hover .dropbtn {
    background-color: white;
  }
</style>
