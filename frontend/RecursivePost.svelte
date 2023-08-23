<script>
  import { children } from "svelte/internal"
  import DisplayPost from "./DisplayPost.svelte"
  import { feedStore, userToView, loggedUser } from "./store/stores"
  import { uniqBy } from "./utils/utils"

  export let auth
  export let principal
  export let signIn
  export let viewpost
  export let viewuser
  export let user = $loggedUser
  export let post = null
  export let tabNums = 0
  export let doNotShowBorder = true
  export let doNotShowParent = true

  let feed = []
  let newPost = null

  const getFeed = async () => {
    feed = await $auth.actor.getFeed()

    feed = feed.reverse()
    feed = feed.map((p) => {
      let post = p[0]["v3"]
      post.market = p[1]
      post.simpleMarket = p[2]

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

{#if post && "children" in post && tabNums < 2}
  <div
    style="width: 100%; height:fit-content; display:flex; flex-direction:column"
  >
    <DisplayPost
      {auth}
      {principal}
      {user}
      {signIn}
      {post}
      isThread={true}
      refresh={getFeed}
      setPreview={(preview) => {
        newPost = preview
      }}
      {viewpost}
      {viewuser}
      {doNotShowParent}
      doNotShowBorder={true}
    />
    {#each post.children
      .sort((a, b) => {
        return Number(b.createdAt - a.createdAt)
      })
      .slice(0, 3) as child, j (child.id)}
      <div style={`width: 100%; display:flex; flex-direction:row;  `}>
        <div
          style={`width: 50px; padding: 0px 3px; display:flex; border-bottom: 0px solid rgb(61, 60, 61)`}
        >
          <div
            style={`display:flex; flex-direction: column; justify-content:center; height: 100%; width: 50%;`}
          >
            <div
              style={`width: 25px; height: 35px; border-right: 1px solid rgb(61, 60, 61)`}
            />
            <div
              style={`width: 25px; flex-grow: 1; border-right: ${
                j < Math.min(post.children.length - 1, 2) ? 1 : 0
              }px solid rgb(61, 60, 61)`}
            />
          </div>
          <div
            style="display:flex; flex-direction:column; justify-content:center; height: 100%; width: 50%;"
          >
            <div
              style={`width: 25px; height: 35px; border-bottom: ${
                j < Math.min(post.children.length, 3) ? 1 : 0
              }px solid rgb(61, 60, 61)`}
            />
            <div style="width: 25px; flex-grow: 1" />
          </div>
        </div>
        <svelte:self
          {auth}
          {principal}
          {signIn}
          {user}
          post={child}
          lastChild={j == Math.min(post.children.length - 1, 2)}
          doNotShowBorder={true}
          doNotShowParent={true}
          refresh={getFeed}
          setPreview={(preview) => {
            newPost = preview
          }}
          tabNums={tabNums + 1}
          {viewpost}
          {viewuser}
        />
      </div>
    {/each}
  </div>
{:else if post}
  <DisplayPost
    {auth}
    {principal}
    {signIn}
    {post}
    {user}
    isThread={false}
    refresh={getFeed}
    setPreview={(preview) => {
      newPost = preview
    }}
    {viewpost}
    {viewuser}
    {doNotShowParent}
    doNotShowBorder={true}
  />
{/if}

{#if !doNotShowBorder}
  <div
    style="width: 100%; height: 10px; border-bottom: 1px solid rgb(61, 60, 61);"
  />
{/if}
