<script lang="ts">
  import inf from "./assets/inf.gif"
  import { Jumper, Plane } from 'svelte-loading-spinners';
  
  export let principal = ""
  export let signIn
  export let label = "Submit"
  export let execute = () => {}
  export let processing = false
</script>

<div
  style="display:flex; text-align:center; justify-content: center;"
>
  <button
    class="btn-grad"
    style={`${processing ? "width: 100px; overflow:hidden;" : "width: 100px;"}`}
    on:click|stopPropagation={() => {
      if (principal === "") signIn()
      else if (!processing) execute()
    }}
  >
    {#if !processing}
      {label}
    {/if}
    <img
      src={inf}
      alt="inf"
      style={`${
        processing
          ? "width: 150px; height: 400%; margin: -75%;"
          : "display: none"
      }`}
    />
  </button>
</div>
