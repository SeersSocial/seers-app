<script lang="ts">
  import Fa from "svelte-fa"
  import { faPlus } from "@fortawesome/free-solid-svg-icons"

  import { splitCamelCaseToString } from "./utils/utils"
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"

  import { anon } from "./utils/utils"

  export let auth
  export let principal
  export let user
  export let parent

  let startDate = "01/05/2023"
  let endDate = "01/05/2023"
  let liquidity = 100.0
  let collateralSelected = "icp"
  let post = ""
  let errorResponse = ""

  let outcomes = [
    { id: 1, label: "Outcome 1", value: "" },
    { id: 2, label: "Outcome 2", value: "" },
  ]

  export const submitMarket = async (parent) => {
    let labels = outcomes.map((o) => o.value)

    let i = 0
    let probabilities = []
    for (; i < labels.length; i++) {
      probabilities.push(Math.floor(10_000 / labels.length))
    }

    const marketInitData = {
      id: 0,
      title: post,
      description: post,
      labels,
      images: [],
      probabilities: probabilities,
      category: { any: null },
      liquidity: Number(liquidity * 100_000_000),
      startDate: Date.parse(startDate) * 1_000_000,
      endDate: Date.parse(endDate) * 1_000_000,
      imageUrl: "",
      collateralType:
        collateralSelected == "icp" ? { icp: null } : { seers: null },
      author: principal,
    }
    const metadata = linkify.find(post)
    const mentions = metadata
      .filter((t) => t.type == "mention")
      .map((t) => t.value.slice(1))

    const hashtags = metadata
      .filter((t) => t.type == "hashtag")
      .map((t) => t.value.slice(1))

    let initData = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content: post,
      parent: parent ? [parent] : [],
      image: [],
      images: [],
      pdfs: [],
      verified: user && user.twitter ? true : false,
      mentions,
      hashtags,
      market: 0,
      simpleMarket: 0,
      retweet: [],
      isRetweet: [],
    }

    const newPost = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content: post + " (Creating market...)",
      parent: [],
      retweet: [],
      market: 0,
      simpleMarket: 0,
      image: [],
      images: [],
      likes: [],
      replies: [],
      retweeters: [],
      isRetweet: [],
      createdAt: Date.now() * 1_000_000,
      deleted: false,
    }
    post = ""
    return [newPost, $auth.actor.submitPost(initData, [marketInitData], [])]
  }
</script>

<div
  style="width: 100%; display: flex; align-items: center; justify-content: flex-start; padding: 5px;"
>
  {#if user && user.picture.includes("raw.ic0.app/?tokenid=") && !user.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")}
    <img
      src={`${user.picture}&type=thumbnail`}
      alt="avatar"
      onError="this.src='{anon + user.handle}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {:else}
    <img
      src={user ? user.picture : anon}
      alt="avatar"
      onError="this.src='{anon}';"
      style="width: 50px; height: 50px; object-fit: cover; border-radius: 50%"
    />
  {/if}
  <textarea
    bind:value={post}
    rows="3"
    onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
    onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
    style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
    placeholder={"What's happening?"}
  />
</div>

<div
  style="display:flex; flex-direction: column; height: fit-content; border: 1px solid rgb(47, 51, 54); border-radius: 16px; align-items:flex-end"
>
  <div
    style="display:flex; width: 100%; height: fit-content; border: 0px solid rgb(47, 51, 54); align-items:flex-end"
  >
    <div
      style="display: flex; flex-direction:column; flex-grow: 1; justify-content:space-evenly"
    >
      {#each outcomes as outcome (outcome.id)}
        <div
          style="height: fit-content; border: 1px solid rgb(51, 54, 57); border-radius:4px; padding: 5px; margin: 15px"
        >
          <input
            bind:value={outcome.value}
            type="text"
            placeholder={outcome.label}
            style="border: 0px; width: 90%; height: 50%;font-size: 1.2em;"
          />
        </div>
      {/each}
    </div>

    <div
      style="width: 50px; height: 60px  ; display:flex; justify-content:center; align-items:flex-end; "
    >
      <div
        style="height: 100%"
        on:click={() => {
          outcomes.push({
            id: outcomes.length + 1,
            label: `Outcome ${outcomes.length + 1}`,
            value: "",
          })
          outcomes = outcomes
        }}
      >
        <Fa icon={faPlus} scale={1.3} />
      </div>
    </div>
  </div>
  <div
    style="display:flex; width: 100%; height: 70px; border-top: 1px solid rgb(47, 51, 54); align-items:flex-end;"
  >
    <div style="display:flex; width: 100%; height: 100%; padding: 0px 5px;">
      <div
        style="width: 50%; height: 100%; border-right: 1px solid rgb(47, 51, 54); display:flex; flex-direction:column; justify-content:center; padding: 0px 10px"
      >
        <label for="start" style="width: 90%; color:grey">Start date:</label>

        <input
          type="datetime-local"
          id="start"
          bind:value={startDate}
          placeholder="2023-01-01"
          min="2023-01-01"
          max="2050-01-01"
          style="border: 0px; font-size: 1.1em; width: 90%"
        />
      </div>
      <div
        style="width: 50%; height: 100%; border-right: 0px solid rgb(47, 51, 54); display:flex; flex-direction:column; justify-content:center; padding: 0px 10px"
      >
        <label for="start" style="width: 90%; color:grey">End date:</label>

        <input
          type="datetime-local"
          id="end"
          placeholder="2023-01-01"
          bind:value={endDate}
          min="2023-01-01"
          max="2050-01-01"
          style="border: 0px; font-size: 1.1em; width: 90%;"
        />
      </div>
    </div>
  </div>
  <div
    style="display:flex; width: 100%; height: 70px; border-top: 1px solid rgb(47, 51, 54); align-items:flex-end;"
  >
    <div
      style="display:flex; width: 100%; height: 100%; padding: 0px 10px; text-align:center; justify-content:start; align-items:center"
    >
      <div style="color:grey; padding: 0px 5px;font-size: 1.1em;">
        Liquidity:
      </div>
      <div
        style="width: 80px; text-align:center; display:flex; justify-content:center"
      >
        <input
          type="text"
          id="start"
          bind:value={liquidity}
          style="font-family: Roboto Mono, monospace;border: 0px;font-size: 1.2em; width: 100%; text-align:center"
        />
      </div>
      <div
        style="display:flex; align-items:center; justify-content:center; text-align:center; padding: 5px;"
      >
        <select
          bind:value={collateralSelected}
          style="display:flex; border: 0px; font-size: 1.1em"
        >
          <option value="icp">ICP</option>
        </select>
      </div>
    </div>
  </div>
</div>
