<script lang="ts">
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import Fa from "svelte-fa"

  import { anon as anonImage } from "./utils/utils"
  import { faUpload } from "@fortawesome/free-solid-svg-icons"

  export let auth
  export let principal
  export let user

  let pdf = null
  let post = null
  let newPost = null
  let pdfPreview = null
  let pdfSource = null
  let fileName = null
  let anon = anonImage + user?.handle

  export const submitPdf = async (parent) => {
    const metadata = linkify.find(post)
    const mentions = metadata
      .filter((t) => t.type == "mention")
      .map((t) => t.value.slice(1))

    const hashtags = metadata
      .filter((t) => t.type == "hashtag")
      .map((t) => t.value.slice(1))

    newPost = {
      id: 0,
      author: {
        principal,
        picture: user.picture,
        handle: user.handle,
        name: user.name,
      },
      content: post,
      parent: [],
      retweet: [],
      market: 0,
      simpleMarket: 0,
      image: [],
      images: [],
      pdfs: [pdfPreview],
      likes: [],
      replies: [],
      retweeters: [],
      isRetweet: [],
      createdAt: Date.now() * 1_000_000,
      deleted: false,
    }

    let initData = {
      id: 0,
      author: {
        principal,
        picture: "",
        handle: "",
        name: "",
      },
      content: post,
      parent: parent ? [parent] : [],
      image: [],
      images: [],
      pdfs: [pdfSource],
      verified: user.twitter ? true : false,
      mentions,
      hashtags,
      market: 0,
      simpleMarket: 0,
      retweet: [],
      isRetweet: [],
    }

    post = ""

    return [newPost, $auth.actor.submitPost(initData, [], [])]
  }

  const uploadPdf = async (files) => {
    if (files == null) return
    let file = files[0]
    fileName = file.name
    const pdfSrc = URL.createObjectURL(file)
    pdfPreview = pdfSrc
    await uploadFile(file)
  }

  const uploadChunk = async ({ batch_name, chunk }) => {
    const resp = await $auth.actor.create_chunk({
      batch_name,
      content: [...new Uint8Array(await chunk.arrayBuffer())],
    })
    return resp
  }

  const uploadFile = async (file) => {
    if (!file) {
      return
    }

    const batch_name = file.name.replace(/[^a-z0-9\.]/gi, "_").toLowerCase()
    pdfSource = `https://b46ia-3qaaa-aaaap-qaaaq-cai.raw.ic0.app/assets/${batch_name}`

    const promises = []
    const chunkSize = 500000

    for (let start = 0; start < file.size; start += chunkSize) {
      const chunk = file.slice(start, start + chunkSize)
      promises.push(
        uploadChunk({
          batch_name,
          chunk,
        }),
      )
    }

    const chunkIds = await Promise.all(promises)

    await $auth.actor.commit_batch({
      batch_name,
      chunk_ids: chunkIds.map(({ chunk_id }) => chunk_id),
      content_type: file.type,
    })
  }
</script>

<div
  style="width: 100%; display:flex; flex-direction: column; align-items: center;justify-content:flex-start; padding: 5px"
>
  <div
    style="width: 100%; display: flex; justify-content: flex-start; padding: 5px;"
  >
    {#if user && user.picture.includes("raw.ic0.app/?tokenid=") && !user.picture.includes("b46ia-3qaaa-aaaap-qaaaq-cai")}
      <img
        src={`${user.picture}&type=thumbnail`}
        alt="avatar"
        onError="this.src='{anon}';"
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
      autofocus
      bind:value={post}
      rows="3"
      onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
      placeholder={"What's happening?"}
    />
  </div>
  <div class="feed-icon">
    <label for="file-input">
      <Fa icon={faUpload} scale={2} />
    </label>
  </div>
  <input
    id="file-input"
    class="file-input"
    alt=""
    type="file"
    bind:value={pdf}
    on:change={async (e) => {
      await uploadPdf(e.target.files)
    }}
    hidden
    accept="application/pdf"
  />
  <embed src={pdfPreview} width="250" height="200" />
</div>
