<script lang="ts">
  import inf from "./assets/inf.gif"

  export let auth
  export let market
  export let principal
  export let signIn

  let errorResponse = ""
  let processing = false
  let done = false

  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  const submitForecast = async () => {
    const values = market.labels.map((l) => Number(l.value) / 100.0)
    processing = true
    const r = await $auth.actor.submitForecast(market.id, values)
    if ("err" in r) {
      errorResponse =
        "Error: " + splitCamelCaseToString(Object.keys(r["err"]).toString())
    } else {
      errorResponse = ""
      done = true
    }
    processing = false
  }
</script>

<div
  style="margin: 0em 1em;display:flex; justify-content:start; flex-direction:column"
>
  <div class="market-controls">
    <div
      style="display:flex; justify-content:center; text-align:center; align-items:center;flex-direction:column;width: 100px;"
    >
      <h4>Forecast</h4>
      <div
        style="width: 100px; text-align: center; display: flex; flex-direction: column; justify-content: center; align-items:center"
      >
        {#if market}
          {#each market?.labels as label}
            <div
              style="display:flex; flex-direction:row; width: 100px; justify-content:center; align-items:center; padding: 5px"
            >
              <div style="width: 50px; margin-right: 20px">{label.label}</div>
              <div style="width: 50px;">
                <input
                  bind:value={label.value}
                  style="width: 100%; color: rgb(255, 255, 255); background-color: rgb(33, 36, 41); height: 1em; font-family: 'Roboto Mono', monospace; border: 0"
                  placeholder="0.0"
                /> %
              </div>
            </div>
          {/each}
          <div
            style="width: 100px; justify-content: center; text-align: center; display: flex; align-items:center"
          >
            {#if processing}
              <button
                class="btn-grad"
                on:click={() => 0}
                style="width: 150px; overflow:hidden"
              >
                <img
                  src={inf}
                  alt="inf"
                  style="width: 150%; height: 400%; margin: -75%;"
                />
              </button>
            {:else if principal != ""}
              <button
                class="btn-grad"
                on:click={async () => {
                  await submitForecast()
                }}
              >
                Submit
              </button>
            {:else}
              <button class="btn-grad" on:click={() => signIn()}>
                Login
              </button>
            {/if}
          </div>
          {#if errorResponse}
            <div style="width: 150px;text-align:center;color:red">
              {errorResponse}
            </div>
          {:else if done}
            <div style="width: 150px;text-align:center;color:green">Done!</div>
          {/if}
        {:else}
          <div
            style="width: 100px; justify-content: center; text-align: center; display: flex"
          >
            <button class="btn-grad" on:click={() => 0}> Login </button>
          </div>
        {/if}
      </div>
    </div>
  </div>
</div>

<style>
  input {
    font-size: 1.5em;
    color: black;
  }

  input:focus {
    font-size: 1.5em;
    color: black;
  }
</style>
