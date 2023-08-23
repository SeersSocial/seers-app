<script lang="ts">
  export let post
  export let principal
  export let signIn
  export let auth
  export let setLikes

  let heartClass = "heart"

  const submitLike = async (postId) => {
    const resp = await $auth.actor.submitLike(Number(postId))
  }

  const onLikeClick = async () => {
    if (principal === "") {
      signIn()
    } else {
      const like = {
        author: {
          principal,
          handle: "dummy",
          name: "dummy",
          picture: "dummy",
        },
        createdAt: Date.now(),
      }
      const liked = post.likes.find(
        (like) => like.author.principal == principal,
      )

      if (liked) {
        post.likes = post.likes.filter(
          (like) => like.author.principal != principal,
        )
      } else {
        post.likes.push(like)
        post.likes = post.likes
      }
      setLikes(post.likes)
      submitLike(post.id)
    }
  }
</script>

<div class="stage">
  <div
    class={post?.likes?.find((like) => like.author.principal == principal)
      ? "heart is-active"
      : "heart"}
    on:click={async () => {
      heartClass == "heart"
        ? (heartClass = "heart is-active")
        : (heartClass = "heart")
      await onLikeClick()
    }}
  />
</div>
Footer

<style>
  .heart {
    margin-left: -13px;
    margin-top: -13px;
    width: 50px;
    height: 50px;
    background: url("./assets/heart.png") no-repeat;
    background-position: 0 0;
    cursor: pointer;
    transition: background-position 1s steps(28);
    transition-duration: 0s;
  }

  .heart.is-active {
    transition-duration: 1s;
    background-position: -1400px 0;
  }

  .stage {
    top: 50%;
    left: 50%;
    transform: translate(0%, 0%);
  }
</style>
