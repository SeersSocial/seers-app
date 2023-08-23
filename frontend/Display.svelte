<script>
  const themes = ["dark-mode", "light-mode"]
  const icons = ["🌙", "🌞"]
  let index = 0
</script>

<button
  on:click={() => {
    index = (index + 1) % themes.length
  }}>{icons[index]}</button
>

<svelte:body class={themes[index]} />

<svelte:head />
