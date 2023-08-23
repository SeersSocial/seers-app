<script lang="ts">
  import * as linkify from "linkifyjs"
  import "linkify-plugin-hashtag"
  import "linkify-plugin-mention"
  import Fa from "svelte-fa"
  import { resizeImage } from "./utils/utils"
  import { faUpload } from "@fortawesome/free-solid-svg-icons"

  import { anon as anonImage } from "./utils/utils"
  import { loggedUser } from "./store/stores"

  export let auth
  export let principal
  export let user = $loggedUser
  export let setimage
  export let imageSize = 400

  $: imageSources = []
  $: imagePreviews = []

  let post = ""
  let imageInput = ""
  let uploading = ""
  let promises = []
  let fileNames = []
  let filesResized = []
  let imagesResized = []
  let anon = anonImage + user?.handle

  const imageDemo =
    "https://pbs.twimg.com/media/Fg2PbpmUoAEGB5Q?format=jpg&name=large"

  let image = {
    label: "Image URL",
    value: imageDemo,
  }
  let newPost = null

  function getId(url) {
    const regExp =
      /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/
    const match = url.match(regExp)

    return match && match[2].length === 11 ? match[2] : null
  }

  export const submitImage = async (parent) => {
    if (post.length < 3 || post.length > 600) return
    if (image.value.length > 300) return

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
      image: [image.value],
      images: imagePreviews.slice(0),
      verified: user.twitter ? true : false,
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
      image: [image.value],
      images: imageSources.slice(0),
      pdfs: [],
      verified: user.twitter ? true : false,
      mentions,
      hashtags,
      market: 0,
      simpleMarket: 0,
      retweet: [],
      isRetweet: [],
    }
    imagePreviews = []
    imageSources = []
    promises = []
    fileNames = []
    imagesResized = []

    post = ""
    uploading = ""
    image.value = imageDemo

    return [newPost, $auth.actor.submitPost(initData, [], [])]
  }

  const uploadFiles = async (files) => {
    if (files == null) return
    for (let file of files) {
      fileNames.push(file.name)
      const imgSrc = URL.createObjectURL(file)
      imagePreviews.push(imgSrc)
    }
    imagePreviews = imagePreviews
  }

  const resizeFiles = async (imageToResize) => {
    let fileRes = await resizeImage(imageToResize, imageSize)

    const url = URL.createObjectURL(fileRes)
    imagesResized.push(url)

    fileRes = new File([fileRes], fileNames[filesResized.length])
    filesResized.push(fileRes)

    imagesResized = imagesResized
    filesResized = filesResized

    if (filesResized.length == imagePreviews.length) {
      for (let file of filesResized) {
        promises.push(uploadFile(file))
      }

      uploading = "Uploading... please wait."
      await Promise.all(promises)
      if (setimage) {
        setimage(imageSources[0])
      } else {
      }
      uploading = "Upload complete. You can continue."
    }
  }

  let imagesToResize = []

  const uploadFile = async (file) => {
    if (!file) {
      return
    }

    const batch_name = file.name.replace(/[^a-z0-9\.]/gi, "_").toLowerCase()
    let newImageSrc = `https://b46ia-3qaaa-aaaap-qaaaq-cai.raw.ic0.app/assets/${batch_name}`
    imageSources.push(newImageSrc)

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

  const uploadChunk = async ({ batch_name, chunk }) => {
    const resp = await $auth.actor.create_chunk({
      batch_name,
      content: [...new Uint8Array(await chunk.arrayBuffer())],
    })
    return resp
  }
</script>

<div
  style="width: 100%; display:flex; flex-direction: column; align-items: center;justify-content:flex-start; padding: 5px"
>
  {#if !setimage}
    <div
      style="width: 100%; display: flex; justify-content: flex-start; padding: 5px;"
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
        autofocus
        bind:value={post}
        rows="3"
        onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
        onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
        style="width: 80%; font-size: 1.3em; border: 0px solid rgb(61, 60, 61); padding: 10px; border-radius: 15px"
        placeholder={"What's happening?"}
      />
    </div>
  {/if}
  <!-- <div class="feed-icon">
    <label for="file-input">
      <Fa icon={faUpload} scale={2} />
    </label>
  </div>
  <input
    id="file-input"
    class="file-input"
    alt=""
    type="file"
    bind:value={imageInput}
    on:change={async (event) => {
      await uploadFiles(event.target.files)
    }}
    multiple
    hidden
    accept="image/x-png,image/jpeg,image/gif,image/svg+xml,image/webp"
  /> -->
  {#if imagePreviews.length == 0}
    <div
      style="width: 80%; height:fit-content; border: 1px solid rgb(51, 54, 57); border-radius:14px; padding: 5px 15px; margin: 15px"
    >
      <input
        bind:value={image.value}
        on:change={() => {
          if (setimage) setimage(image.value)
        }}
        type="text"
        placeholder={image.label}
        style="border: 0px; width: 90%; height: 50px; font-size: 1.2em;"
      />
    </div>
    <div
      style="width: 80%; height:fit-content;  padding: 5px 15px; margin: 15px"
    >
      {#if image.value.includes("youtu")}
        <iframe
          width="100%"
          height="400px"
          src={`https://www.youtube.com/embed/${getId(image.value)}`}
          title="YouTube"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowfullscreen
        />
      {:else if !setimage}
        <img
          src={image.value}
          alt="main"
          style="width: 95%; border-radius: 15px; object-fit:cover"
          onerror="this.style.display = 'none'"
        />
      {/if}
    </div>
  {/if}
  <div
    style={`display: flex; flex-direction:column; flex-grow: 1; justify-content:space-evenly; display: ${
      setimage ? "none" : "block"
    }`}
  >
    <div
      style="height: fit-content; border: 0px solid rgb(51, 54, 57); border-radius:14px; padding: 5px 15px; margin: 15px"
    >
      {#each imagePreviews as imgSrc, idx (imgSrc)}
        <img
          bind:this={imagesToResize[idx]}
          on:load={async () => await resizeFiles(imagesToResize[idx])}
          src={imgSrc}
          alt="preview"
          style="max-height: 150px; max-width: 60%; border-radius: 3px;"
          hidden
        />
      {/each}
      {#each imagesResized as imgRes}
        <img
          src={imgRes}
          alt="resized"
          style={`max-height: 150px; max-width: 60%; border-radius: 3px;`}
        />
      {/each}
    </div>
  </div>
  {uploading}
</div>
